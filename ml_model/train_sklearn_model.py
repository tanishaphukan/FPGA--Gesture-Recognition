"""
Train EMG Gesture Recognition Model using scikit-learn
=======================================================
This script trains a model using traditional ML methods (no PyTorch required)
Uses Random Forest or SVM for classification
"""

import numpy as np
from scipy import signal
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import confusion_matrix, accuracy_score, classification_report
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import seaborn as sns
import pickle
import time
import os

np.random.seed(42)

print("="*70)
print("EMG GESTURE RECOGNITION - SKLEARN TRAINING")
print("="*70)

# ============================================================================
# SECTION 1: DATA GENERATION
# ============================================================================
print("\n[1/6] REALISTIC EMG DATA GENERATION")
print("-" * 70)

def generate_realistic_emg_trial(gesture_id, num_channels=8, duration=3.0, sampling_rate=200):
    """Generate realistic EMG signal for one trial"""
    time_steps = int(duration * sampling_rate)
    t = np.linspace(0, duration, time_steps)
    emg_signal = np.zeros((num_channels, time_steps))
    
    # Gesture-specific parameters
    gesture_params = {
        0: {'freq': 30, 'burst_strength': 0.5, 'channels': [0, 1, 2]},
        1: {'freq': 45, 'burst_strength': 2.0, 'channels': [0, 1, 2, 3]},
        2: {'freq': 55, 'burst_strength': 2.5, 'channels': [4, 5, 6, 7]},
        3: {'freq': 40, 'burst_strength': 1.8, 'channels': [0, 1, 4, 5]},
        4: {'freq': 50, 'burst_strength': 1.8, 'channels': [2, 3, 6, 7]},
        5: {'freq': 60, 'burst_strength': 2.2, 'channels': [0, 2, 4, 6]},
        6: {'freq': 48, 'burst_strength': 1.5, 'channels': [1, 3]},
        7: {'freq': 52, 'burst_strength': 1.7, 'channels': [0, 4]},
    }
    
    params = gesture_params[gesture_id]
    base_freq = params['freq']
    burst_strength = params['burst_strength']
    active_channels = params['channels']
    
    for ch in range(num_channels):
        activation = burst_strength if ch in active_channels else 0.3
        
        # Multi-frequency EMG signal
        for harmonic in [1, 1.5, 2, 2.5]:
            freq = base_freq * harmonic
            emg_signal[ch] += activation * np.sin(2 * np.pi * freq * t) / harmonic
        
        # Muscle activation burst
        burst_start = int(0.5 * time_steps)
        burst_end = int(2.5 * time_steps)
        burst_envelope = np.ones(time_steps) * 0.3
        burst_envelope[burst_start:burst_end] = 1.0
        emg_signal[ch] *= burst_envelope
        
        # Add noise
        emg_signal[ch] += np.random.randn(time_steps) * 0.15
        emg_signal[ch] += 0.05 * np.sin(2 * np.pi * 60 * t)  # Powerline
    
    return emg_signal

# Generate dataset
print("Generating realistic EMG dataset...")
num_samples_per_class = 500
num_classes = 8
num_channels = 8

X_raw = []
y = []

for gesture_id in range(num_classes):
    for i in range(num_samples_per_class):
        emg_trial = generate_realistic_emg_trial(gesture_id, num_channels)
        X_raw.append(emg_trial)
        y.append(gesture_id)
    print(f"  Generated {num_samples_per_class} samples for gesture {gesture_id}")

X_raw = np.array(X_raw)
y = np.array(y)

print(f"\n✓ Dataset generated:")
print(f"  Shape: {X_raw.shape}")
print(f"  Total samples: {len(y)}")
print(f"  Samples per class: {num_samples_per_class}")

# ============================================================================
# SECTION 2: PREPROCESSING
# ============================================================================
print("\n[2/6] SIGNAL PREPROCESSING")
print("-" * 70)

def preprocess_emg(emg_signal, sampling_rate=200):
    """Preprocess EMG signal"""
    # Bandpass filter (20-95 Hz)
    nyquist = sampling_rate / 2
    low = 20 / nyquist
    high = 95 / nyquist
    b, a = signal.butter(4, [low, high], btype='band')
    filtered = signal.filtfilt(b, a, emg_signal, axis=1)
    
    # Rectification
    rectified = np.abs(filtered)
    
    # RMS extraction (200ms window, 50ms step)
    window_size = int(0.2 * sampling_rate)
    step_size = int(0.05 * sampling_rate)
    
    num_channels, num_samples = rectified.shape
    num_windows = (num_samples - window_size) // step_size + 1
    rms_features = np.zeros((num_channels, num_windows))
    
    for i in range(num_windows):
        start = i * step_size
        end = start + window_size
        window = rectified[:, start:end]
        rms_features[:, i] = np.sqrt(np.mean(window ** 2, axis=1))
    
    return rms_features

print("Preprocessing EMG signals...")
X_processed = []

for i, emg_signal in enumerate(X_raw):
    features = preprocess_emg(emg_signal)
    X_processed.append(features.flatten())  # Flatten to 1D feature vector
    
    if (i + 1) % 1000 == 0:
        print(f"  Processed {i+1}/{len(X_raw)} samples")

X_processed = np.array(X_processed)

print(f"\n✓ Preprocessing complete:")
print(f"  Feature shape: {X_processed.shape}")
print(f"  Features per sample: {X_processed.shape[1]}")

# ============================================================================
# SECTION 3: TRAIN-TEST SPLIT
# ============================================================================
print("\n[3/6] DATASET PREPARATION")
print("-" * 70)

X_train, X_test, y_train, y_test = train_test_split(
    X_processed, y, test_size=0.3, random_state=42, stratify=y
)

# Normalize features
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

print(f"✓ Dataset split:")
print(f"  Training samples: {len(X_train)}")
print(f"  Testing samples: {len(X_test)}")

# ============================================================================
# SECTION 4: MODEL TRAINING
# ============================================================================
print("\n[4/6] MODEL TRAINING")
print("-" * 70)

print("Training Random Forest Classifier...")
start_time = time.time()

# Random Forest model
rf_model = RandomForestClassifier(
    n_estimators=200,
    max_depth=20,
    min_samples_split=5,
    min_samples_leaf=2,
    random_state=42,
    n_jobs=-1,
    verbose=1
)

rf_model.fit(X_train, y_train)
training_time = time.time() - start_time

print(f"\n✓ Training complete in {training_time:.2f} seconds")

# ============================================================================
# SECTION 5: EVALUATION
# ============================================================================
print("\n[5/6] MODEL EVALUATION")
print("-" * 70)

# Predictions
y_pred_train = rf_model.predict(X_train)
y_pred_test = rf_model.predict(X_test)

# Accuracies
train_acc = accuracy_score(y_train, y_pred_train)
test_acc = accuracy_score(y_test, y_pred_test)

print(f"✓ Model Performance:")
print(f"  Training accuracy: {train_acc*100:.2f}%")
print(f"  Testing accuracy: {test_acc*100:.2f}%")

# Cross-validation
cv_scores = cross_val_score(rf_model, X_train, y_train, cv=5)
print(f"  Cross-validation accuracy: {cv_scores.mean()*100:.2f}% (+/- {cv_scores.std()*100:.2f}%)")

# Confusion matrix
conf_matrix = confusion_matrix(y_test, y_pred_test)
print(f"\nConfusion Matrix:")
print(conf_matrix)

# Classification report
gesture_names = ['Rest', 'Open', 'Close', 'Flex', 'Extend', 'Pinch', 'Point', 'Thumb']
print(f"\nClassification Report:")
print(classification_report(y_test, y_pred_test, target_names=gesture_names))

# Feature importance
feature_importance = rf_model.feature_importances_
print(f"\nTop 10 Most Important Features:")
top_indices = np.argsort(feature_importance)[-10:][::-1]
for idx in top_indices:
    print(f"  Feature {idx}: {feature_importance[idx]:.4f}")

# ============================================================================
# SECTION 6: SAVE MODEL
# ============================================================================
print("\n[6/6] SAVE MODEL")
print("-" * 70)

# Save model
with open('emg_rf_model.pkl', 'wb') as f:
    pickle.dump(rf_model, f)

# Save scaler
with open('emg_scaler.pkl', 'wb') as f:
    pickle.dump(scaler, f)

# Save preprocessing parameters
preprocessing_params = {
    'sampling_rate': 200,
    'lowcut': 20,
    'highcut': 95,
    'window_size_ms': 200,
    'step_size_ms': 50,
    'num_channels': 8
}

with open('preprocessing_params.pkl', 'wb') as f:
    pickle.dump(preprocessing_params, f)

print(f"✓ Model saved:")
print(f"  emg_rf_model.pkl")
print(f"  emg_scaler.pkl")
print(f"  preprocessing_params.pkl")

# Model size
model_size = os.path.getsize('emg_rf_model.pkl') / 1024
print(f"\nModel size: {model_size:.2f} KB")

# ============================================================================
# VISUALIZATION
# ============================================================================
print("\n[BONUS] GENERATING VISUALIZATIONS")
print("-" * 70)

# Plot confusion matrix
plt.figure(figsize=(10, 8))
sns.heatmap(conf_matrix, annot=True, fmt='d', cmap='Blues',
            xticklabels=gesture_names, yticklabels=gesture_names)
plt.xlabel('Predicted Gesture', fontsize=12)
plt.ylabel('True Gesture', fontsize=12)
plt.title('Confusion Matrix - Random Forest Model', fontsize=14)
plt.tight_layout()
plt.savefig('confusion_matrix_rf.png', dpi=300)
print("✓ Saved: confusion_matrix_rf.png")
plt.close()

# Plot feature importance
plt.figure(figsize=(12, 6))
plt.bar(range(len(feature_importance)), feature_importance, alpha=0.7)
plt.xlabel('Feature Index', fontsize=12)
plt.ylabel('Importance', fontsize=12)
plt.title('Feature Importance - Random Forest', fontsize=14)
plt.tight_layout()
plt.savefig('feature_importance_rf.png', dpi=300)
print("✓ Saved: feature_importance_rf.png")
plt.close()

# ============================================================================
# REAL-TIME INFERENCE DEMO
# ============================================================================
print("\n[DEMO] REAL-TIME INFERENCE SIMULATION")
print("-" * 70)

print("Simulating real-time gesture recognition...\n")

for test_id in range(10):
    # Generate random gesture
    true_gesture = np.random.randint(0, 8)
    
    # Generate EMG signal
    raw_signal = generate_realistic_emg_trial(true_gesture)
    
    # Preprocess
    features = preprocess_emg(raw_signal).flatten()
    features_scaled = scaler.transform([features])
    
    # Predict
    start_time = time.time()
    prediction = rf_model.predict(features_scaled)[0]
    probabilities = rf_model.predict_proba(features_scaled)[0]
    inference_time = (time.time() - start_time) * 1000
    
    confidence = probabilities[prediction] * 100
    status = "✓" if prediction == true_gesture else "✗"
    
    print(f"Test {test_id+1:2d}: True={gesture_names[true_gesture]:8s} | "
          f"Pred={gesture_names[prediction]:8s} | "
          f"Conf={confidence:5.1f}% | "
          f"Time={inference_time:.2f}ms {status}")

print("\n" + "="*70)
print("TRAINING COMPLETE!")
print("="*70)
print(f"""
Summary:
- Model: Random Forest (200 trees)
- Training samples: {len(X_train)}
- Test accuracy: {test_acc*100:.2f}%
- Model size: {model_size:.2f} KB
- Inference time: ~1-2 ms per sample

Files Generated:
- emg_rf_model.pkl (trained model)
- emg_scaler.pkl (feature scaler)
- preprocessing_params.pkl (preprocessing config)
- confusion_matrix_rf.png (visualization)
- feature_importance_rf.png (visualization)

This model can be deployed on embedded systems or used as a baseline
for comparison with the CNN model.

For FPGA deployment, the CNN model (PyTorch) is recommended due to
better hardware acceleration support.
""")
