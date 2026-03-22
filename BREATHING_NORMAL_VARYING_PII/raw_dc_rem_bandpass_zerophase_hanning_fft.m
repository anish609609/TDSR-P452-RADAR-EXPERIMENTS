% plotMrmRetLog.m
%
% ======================= PIPELINE OVERVIEW =======================
% Step 1: Load radar logfile (.csv) using file selection dialog
% Step 2: Parse logfile into configuration, scan data, and detections
% Step 3: Separate scans into:
%         - Raw scans
%         - Band-pass filtered scans
%         - Motion filtered scans
%
% Step 4: Convert time bins → range bins (distance in meters)
%
% Step 5: Compute envelope of motion filtered data
%         (|signal| + low-pass filtering)
%
% Step 6: Generate waterfall plot
%         (Range vs Scan index vs amplitude)
%
% Step 7: Select region of interest (ROI) in range (e.g., 2.8–4 m)
%
% Step 8: For each selected range bin:
%         - Extract slow-time signal
%         - Remove DC component
%         - Apply bandpass filter (1–40 BPM)
%         - Apply zero-phase filtering (filtfilt)
%         - Apply Hanning window
%
% Step 9: Perform FFT per range bin
%
% Step 10: Detect dominant peaks → convert to BPM
%
% Step 11: Plot FFT spectrum with top BPM estimates
%
% ===============================================================
clear all; close all; clc

%% Query user for logfile
%dnm = '.'; fnm = 'day1_exp_1.006.csv';
[fnm,dnm] = uigetfile('*.csv');
fprintf('Reading logfile %s\n',fullfile(dnm,fnm));
[cfg,req,scn,det] = readMrmRetLog(fullfile(dnm,fnm));

%% Separate raw, bandpassed, and motion filtered data from scn structure
% (only motion filtered is used)

%% Pull out the raw scans (if saved)
rawscansI = find([scn.Nfilt] == 1);
rawscansV = reshape([scn(rawscansI).scn],[],length(rawscansI))';
% band-pass filtered scans
bpfscansI = find([scn.Nfilt] == 2);
bpfscansV = reshape([scn(bpfscansI).scn],[],length(bpfscansI))';
% motion filtered scans
mfscansI = find([scn.Nfilt] == 4);
mfscansV = reshape([scn(mfscansI).scn],[],length(mfscansI))';


%% Create the waterfall horizontal and vertical axes
Tbin = 32/(512*1.024);  % ns
T0 = 0; % ns
c = 0.29979;  % m/ns
Rbin = c*(Tbin*(0:size(mfscansV,2)-1) - T0)/2;  % Range Bins in meters

IDdat = [scn(mfscansI).msgID]; % msgID == scanID


%% The envelope of the motion filtered scans is a low pass of abs value
fprintf('Computing the envelope of the motion filtered data...\n');

%[b,a] = butter(6,0.4);  % only available with sig proc toolbox
% Hard code instead
b = [0.0103 0.0619 0.1547 0.2063 0.1547 0.0619 0.0103];
a = [1.0000 -1.1876 1.3052 -0.6743 0.2635 -0.0518 0.0050];
edat = max(filter(b,a,abs(mfscansV),[],2),0);

%% Plot enveloped motion filtered data as a waterfall
fprintf('Plotting motion filtered data as a waterfall plot...\n');

figure('Units','normalized','Position',[0.1 0.2 0.7 0.7],'Color','w')
imagesc(Rbin,IDdat,edat);
hold on
xlabel('R (m)')
ylabel('Scan Number')
title('Waterfall plot of motion filtered scans')
drawnow
%%

%% ================= FFT PER BIN (BANDPASS + FILTFILT + WINDOW) =================
fprintf('FFT per range bin with bandpass (1–40 BPM)...\n');

% --- PARAMETERS ---
fs_slow = 1 / (125e-3);   % Hz (change if needed)
num_peaks = 3;

% BPM → Hz
f_low = 1/60;     % 1 BPM
f_high = 40/60;   % 40 BPM

% --- BANDPASS FILTER DESIGN (Butterworth) ---
[b_bp, a_bp] = butter(4, [f_low f_high]/(fs_slow/2), 'bandpass');

% --- RANGE SELECTION ---
r_min = 2.8;
r_max = 4;
range_idx = find(Rbin >= r_min & Rbin <= r_max);

% --- FFT SETTINGS ---
N = size(rawscansV,1);
Nfft = 8 * 2^nextpow2(N);

f = (0:Nfft-1)*(fs_slow/Nfft);
half = 1:floor(Nfft/2);
f = f(half);

% --- LOOP CONTROL ---
plots_per_fig = 10;
plot_count = 0;

for i = 1:length(range_idx)
    
    bin_idx = range_idx(i);
    
    % --- Extract slow-time signal ---
    slow_signal = rawscansV(:, bin_idx);
    
    % --- DC REMOVAL ---
    slow_signal = slow_signal - mean(slow_signal);
    
    % --- BANDPASS + ZERO-PHASE FILTERING ---
    filtered_signal = filtfilt(b_bp, a_bp, slow_signal);
    
    % --- HANNING WINDOW ---
    win = hann(length(filtered_signal));
    windowed_signal = filtered_signal .* win;
    
    % --- FFT ---
    fft_data = fft(windowed_signal, Nfft);
    fft_mag = abs(fft_data(half));
    
    % --- FIND TOP PEAKS ---
    [pks, locs] = findpeaks(fft_mag, 'SortStr','descend');
    
    num_valid = min(num_peaks, length(locs));
    top_freqs = f(locs(1:num_valid));
    top_bpms = top_freqs * 60;
    
    % --- FORMAT TITLE STRING ---
    bpm_str = sprintf('%.1f ', top_bpms);
    
    % --- NEW FIGURE EVERY 10 ---
    if mod(plot_count, plots_per_fig) == 0
        figure('Color','w');
        plot_count = 0;
    end
    
    plot_count = plot_count + 1;
    
    subplot(5,2,plot_count);
    plot(f, fft_mag, 'LineWidth', 1.5);
    grid on;
    
    title(sprintf('R = %.2f m | Top BPM: [%s]', ...
        Rbin(bin_idx), bpm_str));
    
    xlabel('Frequency (Hz)');
    ylabel('|FFT|');
    
end