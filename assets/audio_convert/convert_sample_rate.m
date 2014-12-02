function [] = convert_sample_rate(filepath, desired_sample_rate, desired_bps)
% 6.111 11/21/2012
% Author: Dylan Sherry dsherry@mit.edu
%
% Usage: Given a wav file, the desired sample rate and bits per sample,
% this script generates a new wav with a different sample rate and bps
%
% It would be faster to simply use ffmpeg but it's not installed on the lab boxes

% IMPORTANT: this script may not work with versions older than R2012b (version 8.0)
% To run R2012b in Athena:
% add matlab; matlab -ver 8.0

% Inputs:
% -filepath: the local path to (i.e. name of) the file. i.e., 'lion_11025Hz.wav'
% -desired_sample_rate: desired frequency, default 44.1 kHz
% -desired_bps: bits per sample, one of [8 16 32] (I think), default is 8

% (note on desired_bps: the soundDemo script takes care of setting the appropriate
% bps for the coe file. This is just for the audio file.)

% Usage:
% convert_sample_rate('lion_11025Hz.wav')
% Or if you wish to specify a desired freq other than 48 kHz:
% convert_sample_rate('lion_11025Hz.wav', 44100.0)
% You can also add a bitrate other than 8:
% convert_sample_rate('lion_11025Hz.wav', 44100.0, 16)

% ********************************

% handle user input
if nargin == 0
    fprintf('Error: must specify filepath as argument to convert_sample_rate\n');
    return;
end
if nargin <= 2
        desired_bps = 8;
end
if nargin <= 1
        desired_sample_rate = 48000.0;
end

[file_dir, file_name, file_suffix] = fileparts(filepath);
[input_data, sample_freq, bits_per_sample] = wavread(filepath);

% display sample rate
fprintf('Sample rate of %s is %f kHz with %i bits per sample.\n', filepath, sample_freq/1e3, bits_per_sample);

if (sample_freq ~= desired_sample_rate)
    % resample
    fprintf('Resampling %s at %f kHz with %i bits per sample.\n', filepath, desired_sample_rate/1e3, desired_bps);
    input_data = resample(input_data, desired_sample_rate, sample_freq);
    % normalize by the largest sample -- the 1e-3 is so the new max sample is just under 1 in magnitude
    input_data = input_data / (max(max(input_data), -min(input_data)) + 1e-3);
    % write to new file
    newpath = fullfile(file_dir, [file_name, sprintf('_resampled_%.0fHz.wav',desired_sample_rate)]);
    wavwrite(input_data, desired_sample_rate, desired_bps, newpath);
    fprintf('Output saved at %s\n', newpath);
else
    fprintf('%s is already at %f. No further action',filepath, desired_sample_rate);
end
fprintf('Done.\n');
end
