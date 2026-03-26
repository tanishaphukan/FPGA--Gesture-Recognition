"""
EMG Signal Preprocessing Module
Implements bandpass filtering, rectification, and RMS feature extraction
"""

import numpy as np
from scipy import signal
from scipy.signal import butter, filtfilt


class EMGPreprocessor:
    """
    Preprocesses multi-channel EMG signals for gesture recognition
    """
    
    def __init__(self, fs=2000, lowcut=20, highcut=450, 
                 window_ms=50, step_ms=10):
        """
        Args:
            fs: Sampling frequency (Hz)
            lowcut: Lower cutoff frequency (Hz)
            highcut: Upper cutoff frequency (Hz)
            window_ms: RMS window size (milliseconds)
            step_ms: RMS step size (milliseconds)
        """
        self.fs = fs
        self.lowcut = lowcut
        self.highcut = highcut
        self.window_size = int(window_ms * fs / 1000)  # 100 samples
        self.step_size = int(step_ms * fs / 1000)      # 20 samples
        
        # Design bandpass filter
        self.b, self.a = self._design_bandpass_filter()
        
    def _design_bandpass_filter(self):
        """Design 4th order Butterworth bandpass filter"""
        nyquist = 0.5 * self.fs
        low = self.lowcut / nyquist
        high = self.highcut / nyquist
        b, a = butter(4, [low, high], btype='band')
        return b, a
    
    def bandpass_filter(self, data):
        """
        Apply bandpass filter to remove DC offset and high-frequency noise
        
        Args:
            data: Input signal (samples, channels)
        Returns:
            Filtered signal (samples, channels)
        """
        filtered = np.zeros_like(data)
        for ch in range(data.shape[1]):
            filtered[:, ch] = filtfilt(self.b, self.a, data[:, ch])
        return filtered
    
    def rectify(self, data):
        """
        Full-wave rectification (absolute value)
        
        Args:
            data: Input signal (samples, channels)
        Returns:
            Rectified signal (samples, channels)
        """
        return np.abs(data)
    
    def extract_rms(self, data):
        """
        Extract RMS features using sliding window
        
        Args:
            data: Input signal (samples, channels)
        Returns:
            RMS features (windows, channels)
        """
        n_samples, n_channels = data.shape
        n_windows = (n_samples - self.window_size) // self.step_size + 1
        
        rms_features = np.zeros((n_windows, n_channels))
        
        for i in range(n_windows):
            start = i * self.step_size
            end = start + self.window_size
            window_data = data[start:end, :]
            rms_features[i, :] = np.sqrt(np.mean(window_data**2, axis=0))
        
        return rms_features
    
    def normalize(self, features, method='zscore'):
        """
        Normalize features for ML model input
        
        Args:
            features: RMS features (windows, channels)
            method: 'zscore' or 'minmax'
        Returns:
            Normalized features
        """
        if method == 'zscore':
            mean = np.mean(features, axis=0)
            std = np.std(features, axis=0) + 1e-8
            return (features - mean) / std
        elif method == 'minmax':
            min_val = np.min(features, axis=0)
            max_val = np.max(features, axis=0) + 1e-8
            return (features - min_val) / (max_val - min_val)
        else:
            return features
    
    def process(self, raw_data, normalize=True):
        """
        Complete preprocessing pipeline
        
        Args:
            raw_data: Raw EMG signal (samples, channels)
            normalize: Whether to normalize features
        Returns:
            Processed features ready for ML model
        """
        # Step 1: Bandpass filtering
        filtered = self.bandpass_filter(raw_data)
        
        # Step 2: Rectification
        rectified = self.rectify(filtered)
        
        # Step 3: RMS extraction
        rms_features = self.extract_rms(rectified)
        
        # Step 4: Normalization (optional)
        if normalize:
            rms_features = self.normalize(rms_features, method='zscore')
        
        return rms_features


def generate_test_signal(duration=1.0, fs=2000, n_channels=8):
    """
    Generate synthetic EMG signal for testing
    
    Args:
        duration: Signal duration (seconds)
        fs: Sampling frequency (Hz)
        n_channels: Number of channels
    Returns:
        Synthetic EMG signal
    """
    n_samples = int(duration * fs)
    t = np.linspace(0, duration, n_samples)
    
    # Simulate EMG with multiple frequency components
    emg_signal = np.zeros((n_samples, n_channels))
    
    for ch in range(n_channels):
        # Base muscle activation (50-150 Hz)
        for freq in [60, 80, 120]:
            emg_signal[:, ch] += np.sin(2 * np.pi * freq * t) * np.random.rand()
        
        # Add noise
        emg_signal[:, ch] += np.random.randn(n_samples) * 0.1
        
        # Simulate burst pattern (gesture activation)
        burst_start = int(0.3 * n_samples)
        burst_end = int(0.7 * n_samples)
        emg_signal[burst_start:burst_end, ch] *= 3.0
    
    return emg_signal


if __name__ == "__main__":
    # Test preprocessing pipeline
    print("Testing EMG Preprocessing Pipeline...")
    
    # Generate test signal
    test_signal = generate_test_signal(duration=2.0, fs=2000, n_channels=8)
    print(f"Input signal shape: {test_signal.shape}")
    
    # Initialize preprocessor
    preprocessor = EMGPreprocessor(fs=2000)
    
    # Process signal
    features = preprocessor.process(test_signal)
    print(f"Output features shape: {features.shape}")
    print(f"Feature extraction rate: {features.shape[0] / 2.0} Hz")
    
    # Verify dimensions
    expected_windows = (2000 * 2 - 100) // 20 + 1
    assert features.shape[0] == expected_windows, "Window count mismatch"
    assert features.shape[1] == 8, "Channel count mismatch"
    
    print("✓ Preprocessing pipeline validated")
