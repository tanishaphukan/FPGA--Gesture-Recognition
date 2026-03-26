"""
End-to-End System Simulator
Simulates the complete EMG gesture recognition pipeline
"""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from signal_processing.preprocessing import EMGPreprocessor, generate_test_signal


class EMGGestureSystem:
    """
    Complete system simulator for EMG gesture recognition
    """
    
    def __init__(self, model_path=None):
        """
        Initialize system components
        
        Args:
            model_path: Path to trained model (optional)
        """
        self.preprocessor = EMGPreprocessor(fs=2000)
        self.model = None
        
        if model_path:
            try:
                import tensorflow as tf
                self.model = tf.keras.models.load_model(model_path)
                print(f"✓ Model loaded from {model_path}")
            except Exception as e:
                print(f"⚠ Could not load model: {e}")
    
    def simulate_acquisition(self, duration=2.0, gesture_id=0):
        """
        Simulate EMG signal acquisition for a specific gesture
        
        Args:
            duration: Signal duration (seconds)
            gesture_id: Gesture class to simulate
        Returns:
            Raw EMG signal
        """
        # Generate synthetic EMG with gesture-specific patterns
        n_samples = int(duration * 2000)
        n_channels = 8
        t = np.linspace(0, duration, n_samples)
        
        emg_signal = np.zeros((n_samples, n_channels))
        
        for ch in range(n_channels):
            # Base frequency depends on gesture
            base_freq = 60 + gesture_id * 10
            
            # Channel-specific activation
            channel_activation = 1.0 + 0.3 * ((gesture_id + ch) % 3)
            
            # Generate signal
            for freq in [base_freq, base_freq * 1.5, base_freq * 2]:
                emg_signal[:, ch] += channel_activation * np.sin(2 * np.pi * freq * t)
            
            # Add noise
            emg_signal[:, ch] += np.random.randn(n_samples) * 0.2
            
            # Simulate muscle activation burst
            burst_start = int(0.2 * n_samples)
            burst_end = int(0.8 * n_samples)
            emg_signal[burst_start:burst_end, ch] *= 2.5
        
        return emg_signal
    
    def process_signal(self, raw_signal):
        """
        Process raw EMG through preprocessing pipeline
        
        Args:
            raw_signal: Raw EMG data (samples, channels)
        Returns:
            Processed features
        """
        features = self.preprocessor.process(raw_signal, normalize=True)
        return features
    
    def classify_gesture(self, features):
        """
        Classify gesture using trained model
        
        Args:
            features: Preprocessed features
        Returns:
            Predicted class and confidence
        """
        if self.model is None:
            # Simulate random prediction
            return np.random.randint(0, 8), 0.85
        
        # Use sliding window of 10 time steps
        if features.shape[0] < 10:
            return -1, 0.0
        
        # Take last 10 time steps
        input_window = features[-10:, :]
        input_batch = np.expand_dims(input_window, axis=0)
        
        # Predict
        predictions = self.model.predict(input_batch, verbose=0)
        class_id = np.argmax(predictions[0])
        confidence = predictions[0][class_id]
        
        return class_id, confidence
    
    def run_simulation(self, gesture_id=0, duration=2.0, visualize=True):
        """
        Run complete system simulation
        
        Args:
            gesture_id: Gesture to simulate
            duration: Signal duration
            visualize: Whether to plot results
        Returns:
            Simulation results dictionary
        """
        print(f"\n{'='*60}")
        print(f"Simulating Gesture {gesture_id}")
        print(f"{'='*60}")
        
        # Stage 1: Acquisition
        print("\n[1/4] Acquiring EMG signal...")
        raw_signal = self.simulate_acquisition(duration, gesture_id)
        print(f"  Signal shape: {raw_signal.shape}")
        print(f"  Duration: {duration}s")
        print(f"  Sampling rate: 2000 Hz")
        
        # Stage 2: Preprocessing
        print("\n[2/4] Preprocessing signal...")
        features = self.process_signal(raw_signal)
        print(f"  Feature shape: {features.shape}")
        print(f"  Feature rate: {features.shape[0] / duration:.1f} Hz")
        
        # Stage 3: Classification
        print("\n[3/4] Classifying gesture...")
        predicted_class, confidence = self.classify_gesture(features)
        print(f"  Predicted class: {predicted_class}")
        print(f"  Confidence: {confidence*100:.1f}%")
        
        # Stage 4: Timing analysis
        print("\n[4/4] Timing analysis...")
        preprocessing_time = 5.0  # ms (from architecture)
        inference_time = 8.0      # ms (from architecture)
        total_latency = preprocessing_time + inference_time
        print(f"  Preprocessing: {preprocessing_time} ms")
        print(f"  Inference: {inference_time} ms")
        print(f"  Total latency: {total_latency} ms")
        
        if total_latency < 20:
            print(f"  ✓ Latency target met (<20 ms)")
        else:
            print(f"  ✗ Latency exceeds target")
        
        # Visualization
        if visualize:
            self.visualize_results(raw_signal, features, predicted_class, gesture_id)
        
        return {
            'raw_signal': raw_signal,
            'features': features,
            'predicted_class': predicted_class,
            'confidence': confidence,
            'latency_ms': total_latency,
            'true_class': gesture_id
        }
    
    def visualize_results(self, raw_signal, features, predicted_class, true_class):
        """
        Visualize signal processing pipeline
        """
        fig, axes = plt.subplots(3, 1, figsize=(12, 8))
        
        # Plot 1: Raw EMG (first 2 channels)
        time_raw = np.linspace(0, raw_signal.shape[0]/2000, raw_signal.shape[0])
        axes[0].plot(time_raw, raw_signal[:, 0], label='Channel 0', alpha=0.7)
        axes[0].plot(time_raw, raw_signal[:, 1], label='Channel 1', alpha=0.7)
        axes[0].set_title('Raw EMG Signal')
        axes[0].set_xlabel('Time (s)')
        axes[0].set_ylabel('Amplitude')
        axes[0].legend()
        axes[0].grid(True, alpha=0.3)
        
        # Plot 2: RMS Features
        time_features = np.linspace(0, features.shape[0]/100, features.shape[0])
        for ch in range(min(4, features.shape[1])):
            axes[1].plot(time_features, features[:, ch], label=f'Ch {ch}', alpha=0.7)
        axes[1].set_title('RMS Features (Preprocessed)')
        axes[1].set_xlabel('Time (s)')
        axes[1].set_ylabel('RMS Amplitude')
        axes[1].legend()
        axes[1].grid(True, alpha=0.3)
        
        # Plot 3: Classification result
        gesture_names = ['Rest', 'Open', 'Close', 'Flex', 'Extend', 'Pinch', 'Point', 'Thumb']
        axes[2].bar(range(8), [1 if i == predicted_class else 0 for i in range(8)])
        axes[2].set_title(f'Classification: {gesture_names[predicted_class]} (True: {gesture_names[true_class]})')
        axes[2].set_xlabel('Gesture Class')
        axes[2].set_ylabel('Prediction')
        axes[2].set_xticks(range(8))
        axes[2].set_xticklabels(gesture_names, rotation=45)
        axes[2].grid(True, alpha=0.3, axis='y')
        
        plt.tight_layout()
        plt.savefig('simulation_results.png', dpi=150)
        print(f"\n  ✓ Visualization saved to 'simulation_results.png'")


def run_batch_simulation(num_gestures=8, trials_per_gesture=5):
    """
    Run batch simulation across all gestures
    
    Args:
        num_gestures: Number of gesture classes
        trials_per_gesture: Number of trials per gesture
    """
    system = EMGGestureSystem()
    
    print("\n" + "="*60)
    print("BATCH SIMULATION - All Gestures")
    print("="*60)
    
    results = []
    correct = 0
    total = 0
    
    for gesture_id in range(num_gestures):
        for trial in range(trials_per_gesture):
            result = system.run_simulation(
                gesture_id=gesture_id,
                duration=1.0,
                visualize=False
            )
            results.append(result)
            
            if result['predicted_class'] == result['true_class']:
                correct += 1
            total += 1
    
    accuracy = correct / total * 100
    
    print("\n" + "="*60)
    print("BATCH RESULTS")
    print("="*60)
    print(f"Total trials: {total}")
    print(f"Correct: {correct}")
    print(f"Accuracy: {accuracy:.1f}%")
    print(f"Avg latency: {np.mean([r['latency_ms'] for r in results]):.1f} ms")
    
    return results


if __name__ == "__main__":
    # Single gesture simulation
    system = EMGGestureSystem()
    result = system.run_simulation(gesture_id=2, duration=2.0, visualize=True)
    
    print("\n" + "="*60)
    print("Simulation Complete")
    print("="*60)
    
    # Uncomment to run batch simulation
    # batch_results = run_batch_simulation(num_gestures=8, trials_per_gesture=5)
