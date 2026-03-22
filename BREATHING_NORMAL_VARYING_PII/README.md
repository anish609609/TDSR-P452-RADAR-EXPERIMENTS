# Breathing (Normal) – Varying PII

This folder contains radar recordings of normal breathing collected using the TDSR P452 module at a distance of 0.5 m. The goal is to explore real-world radar data, understand system behavior through experiments, and build intuition by working directly with measured signals.

## Dataset Details
- Number of scans: 600
- Slow-time sampling rate: 8 Hz
- Fast-time samples per scan: 864
- Scan range: 0 ps to 52781 ps
- Antenna gain: 63
- Motion filter: IIR (order 3) via GUI

## Results (Manual Counting)

| File Name                           | PII | Trial | Respiration Rate (BPM) |
|------------------------------------|-----|-------|------------------------|
| breathing_normal_0_5m_pii_7_000     | 7   | 1     | ~13                    |
| breathing_normal_0_5m_pii_7_001     | 7   | 2     | ~16                    |
| breathing_normal_0_5m_pii_7_002     | 7   | 3     | ~12                    |
| breathing_normal_0_5m_pii_9_003     | 9   | 1     | ~15                    |
| breathing_normal_0_5m_pii_9_004     | 9   | 2     | ~12–13                 |
| breathing_normal_0_5m_pii_9_005     | 9   | 3     | ~12–13                 |
| breathing_normal_0_5m_pii_11_000    | 11  | 1     | ~16                    |
| breathing_normal_0_5m_pii_11_001    | 11  | 2     | ~15                    |
| breathing_normal_0_5m_pii_11_002    | 11  | 3     | ~14                    |

## Observations
- Typical respiration range: 12–16 BPM  
- PII variation affects signal clarity and stability  
- Manual counting performed over ~75 seconds  

## Processing Scripts

- `readMrmRetLog.m`  
  Parses raw radar log files and converts them into scan matrices.

- `raw_dc_rem_bandpass_zerophase_hanning_fft.m`  
  Processing pipeline:  
  DC removal → band-pass filtering (0.1–0.5 Hz) → zero-phase filtering → Hanning window → FFT → respiration rate estimation.

## How to Run

1. Download all files in this folder.
2. Open MATLAB and navigate to this folder.
3. Ensure all `.m` files and dataset files are in the same directory.
4. Run the processing script:

   ```matlab
   raw_dc_rem_bandpass_zerophase_hanning_fft

   % After running the script, a file selection window will appear.
   % Select any .xlsx file from this folder.
   % The script will process the data and display the respiration results.