@echo off
REM Windows Batch Script for FPGA Build and Programming
REM EMG Gesture Recognition System

echo ==========================================
echo EMG Gesture Recognition - FPGA Deployment
echo ==========================================
echo.

REM Check if Vivado is in PATH
where vivado >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Vivado not found in PATH!
    echo.
    echo Please add Vivado to your PATH or run this from Vivado command prompt.
    echo Example: C:\Xilinx\Vivado\2020.1\bin\vivado.bat
    echo.
    pause
    exit /b 1
)

echo [1/4] Checking prerequisites...
echo.

REM Check if weight file exists
if not exist "ml_model\weights_real_data_init.mem" (
    echo WARNING: Weight file not found!
    echo Running training script first...
    echo.
    python ml_model\train_with_real_dataset.py
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Training failed!
        pause
        exit /b 1
    )
)

echo [2/4] Creating Vivado project...
echo.
vivado -mode batch -source create_vivado_project.tcl
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Project creation failed!
    pause
    exit /b 1
)

echo.
echo [3/4] Running complete build flow...
echo This will take 20-30 minutes. Please be patient...
echo.
vivado -mode batch -source run_complete_flow.tcl
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    echo Check logs in: vivado_project\emg_gesture_fpga.runs\
    pause
    exit /b 1
)

echo.
echo [4/4] Programming FPGA...
echo.
echo Please ensure your FPGA board is connected via USB.
echo.
pause

vivado -mode batch -source program_fpga.tcl
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Programming failed!
    echo.
    echo Troubleshooting:
    echo   1. Check USB cable connection
    echo   2. Verify board is powered on
    echo   3. Install Digilent Adept drivers
    echo   4. Try a different USB port
    pause
    exit /b 1
)

echo.
echo ==========================================
echo SUCCESS! FPGA is programmed and running!
echo ==========================================
echo.
echo Your EMG gesture recognition system is now active.
echo.
echo Next steps:
echo   1. Check status LEDs on the board
echo   2. Press BTN0 to test with built-in pattern
echo   3. Connect EMG sensor to Pmod JA
echo   4. Open serial terminal (115200 baud) to monitor output
echo.
echo For serial monitoring, use PuTTY or Tera Term:
echo   - Find COM port in Device Manager
echo   - Baud rate: 115200
echo   - Data bits: 8, Stop bits: 1, Parity: None
echo.
pause
