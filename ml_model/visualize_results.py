"""
Visualization and Analysis Script for EMG Gesture Recognition
Generates plots and analysis for the trained model
"""

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import torch
from sklearn.metrics import confusion_matrix
import os

# Set style
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

def plot_training_history(train_losses, train_accs, test_accs, save_path='training_history.png'):
    """Plot training and validation metrics"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    epochs = range(1, len(train_losses) + 1)
    
    # Loss plot
    ax1.plot(epochs, train_losses, 'b-', linewidth=2, label='Training Loss')
    ax1.set_xlabel('Epoch', fontsize=12)
    ax1.set_ylabel('Loss', fontsize=12)
    ax1.set_title('Training Loss Over Time', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Accuracy plot
    ax2.plot(epochs, train_accs, 'g-', linewidth=2, label='Training Accuracy')
    ax2.plot(epochs, test_accs, 'r-', linewidth=2, label='Test Accuracy')
    ax2.set_xlabel('Epoch', fontsize=12)
    ax2.set_ylabel('Accuracy (%)', fontsize=12)
    ax2.set_title('Model Accuracy Over Time', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved training history plot: {save_path}")
    plt.close()

def plot_confusion_matrix(y_true, y_pred, save_path='confusion_matrix.png'):
    """Plot confusion matrix heatmap"""
    gesture_names = ['Rest', 'Open', 'Close', 'Flex', 'Extend', 'Pinch', 'Point', 'Thumb']
    
    cm = confusion_matrix(y_true, y_pred)
    
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=gesture_names, yticklabels=gesture_names,
                cbar_kws={'label': 'Count'})
    plt.xlabel('Predicted Gesture', fontsize=12, fontweight='bold')
    plt.ylabel('True Gesture', fontsize=12, fontweight='bold')
    plt.title('Confusion Matrix - Gesture Recognition', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved confusion matrix: {save_path}")
    plt.close()

def plot_emg_preprocessing_stages(raw_signal, filtered_signal, rectified_signal, 
                                   rms_features, save_path='preprocessing_stages.png'):
    """Visualize preprocessing pipeline stages"""
    fig, axes = plt.subplots(4, 1, figsize=(14, 10))
    
    time_raw = np.linspace(0, 1, raw_signal.shape[1])
    time_rms = np.linspace(0, 1, rms_features.shape[1])
    
    # Raw signal
    axes[0].plot(time_raw, raw_signal[0], 'b-', linewidth=0.5, alpha=0.7)
    axes[0].set_title('Stage 1: Raw EMG Signal (Channel 0)', fontweight='bold')
    axes[0].set_ylabel('Amplitude')
    axes[0].grid(True, alpha=0.3)
    
    # Filtered signal
    axes[1].plot(time_raw, filtered_signal[0], 'g-', linewidth=0.5, alpha=0.7)
    axes[1].set_title('Stage 2: Bandpass Filtered (20-450 Hz)', fontweight='bold')
    axes[1].set_ylabel('Amplitude')
    axes[1].grid(True, alpha=0.3)
    
    # Rectified signal
    axes[2].plot(time_raw, rectified_signal[0], 'r-', linewidth=0.5, alpha=0.7)
    axes[2].set_title('Stage 3: Full-Wave Rectified', fontweight='bold')
    axes[2].set_ylabel('Amplitude')
    axes[2].grid(True, alpha=0.3)
    
    # RMS features
    axes[3].plot(time_rms, rms_features[0], 'purple', linewidth=2, marker='o', markersize=3)
    axes[3].set_title('Stage 4: RMS Features (50ms window, 10ms step)', fontweight='bold')
    axes[3].set_xlabel('Time (s)')
    axes[3].set_ylabel('RMS Amplitude')
    axes[3].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved preprocessing visualization: {save_path}")
    plt.close()

def plot_model_comparison(fp32_size, int8_size, fp32_acc, int8_acc, 
                          fp32_time, int8_time, save_path='model_comparison.png'):
    """Compare FP32 vs INT8 models"""
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    # Size comparison
    sizes = [fp32_size, int8_size]
    labels = ['FP32', 'INT8']
    colors = ['#3498db', '#e74c3c']
    axes[0].bar(labels, sizes, color=colors, alpha=0.7, edgecolor='black')
    axes[0].set_ylabel('Model Size (KB)', fontsize=12)
    axes[0].set_title('Model Size Comparison', fontsize=14, fontweight='bold')
    axes[0].grid(True, alpha=0.3, axis='y')
    for i, v in enumerate(sizes):
        axes[0].text(i, v + 5, f'{v:.1f} KB', ha='center', fontweight='bold')
    
    # Accuracy comparison
    accs = [fp32_acc, int8_acc]
    axes[1].bar(labels, accs, color=colors, alpha=0.7, edgecolor='black')
    axes[1].set_ylabel('Accuracy (%)', fontsize=12)
    axes[1].set_title('Accuracy Comparison', fontsize=14, fontweight='bold')
    axes[1].set_ylim([0, 100])
    axes[1].grid(True, alpha=0.3, axis='y')
    for i, v in enumerate(accs):
        axes[1].text(i, v + 2, f'{v:.2f}%', ha='center', fontweight='bold')
    
    # Inference time comparison
    times = [fp32_time, int8_time]
    axes[2].bar(labels, times, color=colors, alpha=0.7, edgecolor='black')
    axes[2].set_ylabel('Inference Time (ms)', fontsize=12)
    axes[2].set_title('Inference Speed Comparison', fontsize=14, fontweight='bold')
    axes[2].grid(True, alpha=0.3, axis='y')
    for i, v in enumerate(times):
        axes[2].text(i, v + 0.05, f'{v:.3f} ms', ha='center', fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved model comparison: {save_path}")
    plt.close()

def plot_gesture_samples(generator, save_path='gesture_samples.png'):
    """Plot sample EMG signals for each gesture class"""
    gesture_names = ['Rest', 'Open', 'Close', 'Flex', 'Extend', 'Pinch', 'Point', 'Thumb']
    
    fig, axes = plt.subplots(4, 2, figsize=(14, 12))
    axes = axes.flatten()
    
    for i, gesture_name in enumerate(gesture_names):
        signal = generator.generate_gesture_signal(i)
        time = np.linspace(0, 1, signal.shape[1])
        
        # Plot first 3 channels
        for ch in range(3):
            axes[i].plot(time, signal[ch], alpha=0.6, linewidth=0.8, 
                        label=f'Ch {ch}')
        
        axes[i].set_title(f'Gesture {i}: {gesture_name}', fontweight='bold')
        axes[i].set_xlabel('Time (s)')
        axes[i].set_ylabel('Amplitude')
        axes[i].legend(loc='upper right', fontsize=8)
        axes[i].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved gesture samples: {save_path}")
    plt.close()

def plot_feature_distribution(features, labels, save_path='feature_distribution.png'):
    """Plot feature distribution across gesture classes"""
    gesture_names = ['Rest', 'Open', 'Close', 'Flex', 'Extend', 'Pinch', 'Point', 'Thumb']
    
    # Calculate mean RMS per channel for each gesture
    mean_features = np.zeros((8, 12))
    for gesture_id in range(8):
        gesture_mask = labels == gesture_id
        gesture_features = features[gesture_mask]
        mean_features[gesture_id] = gesture_features.mean(axis=(0, 2))
    
    plt.figure(figsize=(12, 8))
    sns.heatmap(mean_features.T, annot=True, fmt='.2f', cmap='YlOrRd',
                xticklabels=gesture_names, yticklabels=[f'Ch {i}' for i in range(12)],
                cbar_kws={'label': 'Mean RMS Amplitude'})
    plt.xlabel('Gesture Class', fontsize=12, fontweight='bold')
    plt.ylabel('EMG Channel', fontsize=12, fontweight='bold')
    plt.title('Mean RMS Features per Gesture and Channel', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved feature distribution: {save_path}")
    plt.close()

def plot_mac_operations_breakdown(save_path='mac_operations.png'):
    """Visualize MAC operations per layer"""
    layers = ['Conv1D-1', 'Conv1D-2', 'Dense-1', 'Dense-2']
    mac_ops = [90240, 144384, 188416, 1024]
    colors = ['#3498db', '#2ecc71', '#f39c12', '#e74c3c']
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # Bar chart
    ax1.bar(layers, mac_ops, color=colors, alpha=0.7, edgecolor='black')
    ax1.set_ylabel('MAC Operations', fontsize=12)
    ax1.set_title('MAC Operations per Layer', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3, axis='y')
    for i, v in enumerate(mac_ops):
        ax1.text(i, v + 5000, f'{v:,}', ha='center', fontweight='bold')
    
    # Pie chart
    ax2.pie(mac_ops, labels=layers, colors=colors, autopct='%1.1f%%',
            startangle=90, textprops={'fontsize': 11, 'fontweight': 'bold'})
    ax2.set_title('MAC Operations Distribution', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved MAC operations breakdown: {save_path}")
    plt.close()

if __name__ == "__main__":
    print("="*70)
    print("EMG GESTURE RECOGNITION - VISUALIZATION SCRIPT")
    print("="*70)
    print("\nThis script generates visualizations for the trained model.")
    print("Run complete_emg_pipeline.py first to generate the required data.\n")
