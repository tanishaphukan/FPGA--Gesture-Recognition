"""
Lightweight 1D CNN for EMG Gesture Classification
Optimized for FPGA deployment with minimal parameters
"""

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models


def create_emg_cnn_model(input_shape=(10, 8), num_classes=8):
    """
    Create lightweight 1D CNN for EMG gesture recognition
    
    Args:
        input_shape: (time_steps, channels) - default (10, 8)
        num_classes: Number of gesture classes
    Returns:
        Keras model
    """
    model = models.Sequential([
        # Input layer
        layers.Input(shape=input_shape),
        
        # Conv1D Layer 1
        layers.Conv1D(filters=32, kernel_size=5, activation='relu', 
                      padding='valid', name='conv1d_1'),
        layers.MaxPooling1D(pool_size=2, name='maxpool_1'),
        
        # Conv1D Layer 2
        layers.Conv1D(filters=64, kernel_size=5, activation='relu',
                      padding='valid', name='conv1d_2'),
        layers.MaxPooling1D(pool_size=2, name='maxpool_2'),
        
        # Flatten
        layers.Flatten(name='flatten'),
        
        # Dense layers
        layers.Dense(128, activation='relu', name='dense_1'),
        layers.Dropout(0.3, name='dropout_1'),
        
        layers.Dense(64, activation='relu', name='dense_2'),
        layers.Dropout(0.2, name='dropout_2'),
        
        # Output layer
        layers.Dense(num_classes, activation='softmax', name='output')
    ])
    
    return model


def generate_synthetic_dataset(n_samples=5000, n_channels=8, 
                                time_steps=10, num_classes=8):
    """
    Generate synthetic EMG dataset for training
    In production, replace with real EMG recordings
    
    Args:
        n_samples: Number of samples per class
        n_channels: Number of EMG channels
        time_steps: Number of time steps per sample
        num_classes: Number of gesture classes
    Returns:
        X_train, y_train, X_test, y_test
    """
    np.random.seed(42)
    
    total_samples = n_samples * num_classes
    X = np.zeros((total_samples, time_steps, n_channels))
    y = np.zeros(total_samples, dtype=int)
    
    for class_id in range(num_classes):
        start_idx = class_id * n_samples
        end_idx = start_idx + n_samples
        
        # Generate class-specific patterns
        for i in range(start_idx, end_idx):
            # Base pattern with class-specific characteristics
            base_amplitude = 0.5 + class_id * 0.1
            
            for ch in range(n_channels):
                # Channel-specific activation pattern
                channel_weight = np.random.rand() * (1 + 0.2 * (class_id % (ch + 1)))
                
                # Temporal pattern
                t = np.linspace(0, 1, time_steps)
                pattern = base_amplitude * channel_weight * np.sin(2 * np.pi * (class_id + 1) * t)
                
                # Add noise
                noise = np.random.randn(time_steps) * 0.1
                
                X[i, :, ch] = pattern + noise
            
            y[i] = class_id
    
    # Shuffle and split
    indices = np.random.permutation(total_samples)
    X = X[indices]
    y = y[indices]
    
    split_idx = int(0.8 * total_samples)
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    return X_train, y_train, X_test, y_test


def train_model(model, X_train, y_train, X_test, y_test, epochs=50):
    """
    Train the CNN model
    
    Args:
        model: Keras model
        X_train, y_train: Training data
        X_test, y_test: Test data
        epochs: Number of training epochs
    Returns:
        Trained model and history
    """
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Callbacks
    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-6
        )
    ]
    
    # Train
    history = model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=epochs,
        batch_size=32,
        callbacks=callbacks,
        verbose=1
    )
    
    return model, history


def evaluate_model(model, X_test, y_test):
    """
    Evaluate model performance
    
    Args:
        model: Trained Keras model
        X_test, y_test: Test data
    Returns:
        Dictionary with metrics
    """
    # Predictions
    y_pred_probs = model.predict(X_test)
    y_pred = np.argmax(y_pred_probs, axis=1)
    
    # Accuracy
    accuracy = np.mean(y_pred == y_test)
    
    # Per-class accuracy
    class_accuracies = []
    for class_id in range(8):
        mask = y_test == class_id
        if np.sum(mask) > 0:
            class_acc = np.mean(y_pred[mask] == y_test[mask])
            class_accuracies.append(class_acc)
    
    # Inference time (approximate)
    import time
    start = time.time()
    _ = model.predict(X_test[:100])
    end = time.time()
    avg_inference_time = (end - start) / 100 * 1000  # ms
    
    return {
        'accuracy': accuracy,
        'class_accuracies': class_accuracies,
        'avg_inference_time_ms': avg_inference_time
    }


if __name__ == "__main__":
    print("=" * 60)
    print("EMG Gesture Recognition - Model Training")
    print("=" * 60)
    
    # Generate dataset
    print("\n[1/4] Generating synthetic dataset...")
    X_train, y_train, X_test, y_test = generate_synthetic_dataset(
        n_samples=500, num_classes=8
    )
    print(f"  Training samples: {X_train.shape[0]}")
    print(f"  Test samples: {X_test.shape[0]}")
    print(f"  Input shape: {X_train.shape[1:]}")
    
    # Create model
    print("\n[2/4] Creating CNN model...")
    model = create_emg_cnn_model(input_shape=(10, 8), num_classes=8)
    model.summary()
    
    # Count parameters
    total_params = model.count_params()
    print(f"\n  Total parameters: {total_params:,}")
    
    # Train model
    print("\n[3/4] Training model...")
    model, history = train_model(model, X_train, y_train, X_test, y_test, epochs=50)
    
    # Evaluate
    print("\n[4/4] Evaluating model...")
    metrics = evaluate_model(model, X_test, y_test)
    print(f"\n  Test Accuracy: {metrics['accuracy']*100:.2f}%")
    print(f"  Avg Inference Time: {metrics['avg_inference_time_ms']:.2f} ms")
    
    # Save model
    model.save('emg_gesture_model.h5')
    print("\n✓ Model saved to 'emg_gesture_model.h5'")
    
    print("\n" + "=" * 60)
    print("Next step: Run quantize_model.py to optimize for FPGA")
    print("=" * 60)
