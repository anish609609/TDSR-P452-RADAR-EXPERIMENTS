function [configData, requestData, scanData, detectData] = readMrmRetLog(varargin)
% READMRMRETLOG Parses MRM-RET log CSV files and extracts structured data.
%
% Syntax:
%   [configData, requestData, scanData, detectData] = readMrmRetLog()
%   [configData, requestData, scanData, detectData] = readMrmRetLog(fileName)
%   [configData, requestData, scanData, detectData] = readMrmRetLog(dirName, fileName)

    % Define input rules
    targetFile = '';
    switch nargin
        % No arguments: Open file selection dialog
        case 0
            [file, path] = uigetfile('*.csv', 'Select MRM-RET Log File');
            if isequal(file, 0)
                error('File selection cancelled by user.');
            end
            targetFile = fullfile(path, file);
            
        % One argument: Assume it's the full path or file name
        case 1
            targetFile = varargin{1};
            
        % Two arguments: Combine directory and file name
        case 2
            targetFile = fullfile(varargin{1}, varargin{2});
            
        otherwise
            error('Invalid number of input arguments.');
    end

    % Open the target file safely
    fileID = fopen(targetFile, 'rt');
    if fileID == -1
        error('Unable to open file: %s', targetFile);
    end

    % Initialize output data storage arrays
    configData  = [];
    requestData = [];
    scanData    = [];
    detectData  = [];

    % Row tracking indices
    idxCfg = 0; 
    idxReq = 0; 
    idxScn = 0; 
    idxDet = 0;

    % Read through the file line by line
    while ~feof(fileID)
        currentLine = fgetl(fileID);
        if ~ischar(currentLine) || isempty(currentLine)
            continue;
        end
        
        % Locate entry markers by finding comma separations
        commaPositions = strfind(currentLine, ',');
        if length(commaPositions) < 2
            continue; 
        end
        
        % Extract the primary log identifier fields
        headerBlock = textscan(currentLine(1:commaPositions(2)-1), '%s %s', 'Delimiter', ',');
        rowType = headerBlock{1}{1};
        dataType = headerBlock{2}{1};
        
        % Ignore standard metadata descriptions
        if strcmp(rowType, 'Timestamp')
            continue;
        end
        
        % Parse rows depending on the log data category
        switch dataType
            case 'Config'
                idxCfg = idxCfg + 1;
                parsed = textscan(currentLine, '%f %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'Delimiter', ',');
                
                configData(idxCfg).T = parsed{1};
                configData(idxCfg).nodeID = parsed{3};
                configData(idxCfg).Tstrt = parsed{4};
                configData(idxCfg).Tstp = parsed{5};
                configData(idxCfg).Nbin = parsed{6};
                configData(idxCfg).BII = parsed{7};
                configData(idxCfg).seg1Nsamp = parsed{8};
                configData(idxCfg).seg2Nsamp = parsed{9};
                configData(idxCfg).seg3Nsamp = parsed{10};
                configData(idxCfg).seg4Nsamp = parsed{11};
                configData(idxCfg).seg1Iadd = parsed{12};
                configData(idxCfg).seg2Iadd = parsed{13};
                configData(idxCfg).seg3Iadd = parsed{14};
                configData(idxCfg).seg4Iadd = parsed{15};
                configData(idxCfg).Iant = parsed{16};
                configData(idxCfg).Gtmt = parsed{17};
                configData(idxCfg).Ichan = parsed{18};

            case 'MrmControlRequest'
                idxReq = idxReq + 1;
                parsed = textscan(currentLine, '%f %s %f %f %f', 'Delimiter', ',');
                
                requestData(idxReq).T = parsed{1};
                requestData(idxReq).msgID = parsed{3};
                requestData(idxReq).Nscn = parsed{4};
                requestData(idxReq).Tint = parsed{5};
                requestData(idxReq).stat = NaN; % Default status confirmation placeholder

            case 'MrmControlConfirm'
                parsed = textscan(currentLine, '%f %s %f %f', 'Delimiter', ',');
                msgID = parsed{3};
                statusValue = parsed{4};
                
                % Map confirmation back to the matching request ID
                if idxReq > 0 && requestData(idxReq).msgID == msgID
                    requestData(idxReq).stat = statusValue;
                else
                    error('MrmControlConfirm ID mismatch with current control request.');
                end

            case 'MrmFullScanInfo'
                idxScn = idxScn + 1;
                parsed = textscan(currentLine(1:commaPositions(16)-1), '%f %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'Delimiter', ',');
                
                scanData(idxScn).T = parsed{1};
                scanData(idxScn).msgID = parsed{3};
                scanData(idxScn).srcID = parsed{4};
                scanData(idxScn).Tstmp = parsed{5};
                scanData(idxScn).Tstrt = parsed{10};
                scanData(idxScn).Tstp = parsed{11};
                scanData(idxScn).Nbin = parsed{12};
                scanData(idxScn).Nfilt = parsed{13};
                scanData(idxScn).antID = parsed{14};
                scanData(idxScn).Imode = parsed{15};
                scanData(idxScn).Nscn = parsed{16};
                
                % Parse remaining line data as array vectors
                scanData(idxScn).scn = str2num(currentLine(commaPositions(16)+1:end));

            case 'MrmDetectionListInfo'
                idxDet = idxDet + 1;
                if length(commaPositions) < 4
                    endPos = length(currentLine) + 1;
                else
                    endPos = commaPositions(4);
                end
                
                parsed = textscan(currentLine(1:endPos-1), '%f %s %f %f', 'Delimiter', ',');
                detectData(idxDet).T = parsed{1};
                detectData(idxDet).msgID = parsed{3};
                detectData(idxDet).Ndet = parsed{4};
                detectData(idxDet).det = [];
                
                % Format detection positions into coordinate pairs
                if detectData(idxDet).Ndet > 0
                    detectData(idxDet).det = reshape(str2num(currentLine(endPos+1:end)), 2, []);
                end
        end
    end

    % Housekeeping: close data stream safely
    fclose(fileID);
end
