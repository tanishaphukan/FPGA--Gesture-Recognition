"""
Advanced Feature Extraction for EMG Signals
Includes time-domain, frequency-domain, and time-frequency features
"""

import numpy as np
from scipy import signal
from scipy.fft import fft, fftfreq


class EMGFeatureExtractor:
    """
    Extract multiple feature types from EMG signals
    """
    
    def __init__(self, fs=2000, window_size=100):
        """
        Args:
            fs: Sampling frequency (Hz)
            window_size: Window size for feature extraction (samples)
        """
        self.fs = fs
        self.window_size = window_size
    
    def extract_rms(self, signal_window):
        """Root Mean Square"""
        return np.sqrt(np.mean(signal_window**2, axis=0))
    
    def extract_mav(self, signal_window):
        """Mean Absolute Value"""
        return np.mean(np.abs(signal_window), axis=0)
    
    def extract_wl(self, signal_window):
        """Waveform Length - measure of signal complexity"""
        return np.sum(np.abs(np.diff(signal_window, axis=0)), axis=0)
    
    def extract_zc(self, signal_window, threshold=0.01):
        """Zero Crossings - frequency indicator"""
        signs = np.sign(signal_window)
        sign_changes = np.diff(signs, axis=0)
        zc = np.sum(np.abs(sign_changes) > threshold, axis=0)
        return zc
    
    def extract_ssc(self, signal_window, threshold=0.01):
        """Slope Sign Changes - frequency indicator"""
        slopes = np.diff(signal_window, axis=0)
        slope_signs = np.sign(slopes)
        ssc = np.sum(np.abs(np.diff(slope_signs, axis=0)) > threshold, axis=0)
        return ssc
    
    def extract_var(self, signal_window):
        """Variance - signal power indicator"""
        return np.var(signal_window, axis=0)
    
    def extract_median_freq(self, signal_window):
        """Median Frequency - spectral feature"""
        n_channels = signal_window.shape[1]
        median_freqs = np.zeros(n_channels)
        
        for ch in range(n_channels):
            # Compute FFT
            fft_vals = np.abs(fft(signal_window[:, ch]))
            freqs = fftfreq(len(signal_window[:, ch]), 1/self.fs)
            
            # Only positive frequencies
            pos_mask = freqs > 0
            fft_vals = fft_vals[pos_mask]
            freqs = freqs[pos_mask]
            
            # Compute median frequency
            power = fft_vals**2
            cumsum_power = np.cumsum(power)
            total_power = cumsum_power[-1]
            
            median_idx = np.argmin(np.abs(cumsum_power - total_power/2))
            median_freqs[ch] = freqs[median_idx]
        
        return median_freqs
    
    def extract_all_features(self, signal_window):
        """
        Extract comprehensive feature set
        
        Args:
            signal_window: Signal window (samples, channels)
        Returns:
            Feature vector (channels × num_features)
        """
        features = {
            'rms': self.extract_rms(signal_window),
            'mav': self.extract_mav(signal_window),
            'wl': self.extract_wl(signal_window),
            'zc': self.extract_zc(signal_window),
            'ssc': self.extract_ssc(signal_window),
            'var': self.extract_var(signal_window),
            'mdf': self.extract_median_freq(signal_window)
        }
        
        # Stack features
        feature_vector = np.hstack([features[key] for key in features.keys()])
        
        return feature_vector, features
    
    def extract_features_from_signal(self, emg_signal, step_size=20):
        """
        Extract features from entire signal using sliding window
        
        Args:
            emg_signal: Full EMG signal (samples, channels)
            step_size: Step size for sliding window
        Returns:
            Feature matrix (windows, features)
        """
        n_samples = emg_signal.shape[0]
        n_windows = (n_samples - self.window_size) // step_size + 1
        
        feature_list = []
        
        for i in range(n_windows):
            start = i * step_size
            end = start + self.window_size
            window = emg_signal[start:end, :]
            
            feature_vec, _ = self.extract_all_features(window)
            feature_list.append(feature_vec)
        
        return np.array(feature_list)


def compare_feature_sets():
    """
    Compare different feature extraction methods
    """
    from signal_processing.preprocessing import generate_test_signal
    
    print("="*60)
    print("Feature Extraction Comparison")
    print("="*60)
    
    # Generate test signal
    test_signal = generate_test_signal(duration=1.0, fs=2000, n_channels=8)
    
    # Extract features
    extractor = EMGFeatureExtractor(fs=2000, window_size=100)
    
    # Single window analysis
    window = test_signal[0:100, :]
    feature_vec, features = extractor.extract_all_features(window)
    
    print("\nFeature Values (first window, channel 0):")
    print(f"  RMS:           {features['rms'][0]:.4f}")
    print(f"  MAV:           {features['mav'][0]:.4f}")
    print(f"  Waveform Len:  {features['wl'][0]:.4f}")
    print(f"  Zero Cross:    {features['zc'][0]:.0f}")
    print(f"  Slope Changes: {features['ssc'][0]:.0f}")
    print(f"  Variance:      {features['var'][0]:.4f}")
    print(f"  Median Freq:   {features['mdf'][0]:.1f} Hz")
    
    # Full signal analysis
    all_features = extractor.extract_features_from_signal(test_signal, step_size=20)
    print(f"\nFull signal feature matrix: {all_features.shape}")
    print(f"  Windows: {all_features.shape[0]}")
    print(f"  Features per window: {all_features.shape[1]}")
    
    print("\n" + "="*60)
    print("Note: For FPGA implementation, RMS is preferred due to")
    print("hardware simplicity. Other features can be added if resources allow.")
    print("="*60)


if __name__ == "__main__":
    compare_feature_sets()
