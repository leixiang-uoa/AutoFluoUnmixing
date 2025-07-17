function [ result, metadata, probeMetadata ] = RtafGetMetadata( fileName )
%RTAFGETMETADATA Get metadata from RTAF file
%
% NOTES: 
%  1) This implementation is HIGHLY dependent on the existing file
%     format. If any change occurs in the file format, this function may
%     fail (probably in a spectacular manner).
%  2) It doesn't make any attempt to validate that the existing file is
%     correct. It will read what it expects and will continue given the
%     data it sees (regardless of whether it is valid or not).
%  3) 'metadata' and 'probeMetadata" are structures whose fields will vary
%     depending on the type of data stored in the file and the version
%     of the files.
%
%   Input:
%       fileName     Name of RTAF file containing processed (A Scan/IFFT) data
%
%   Output:
%       result          Result code (0 if function successful, non-zero otherwise)
%       metadata        Probe-independent metadata
%       probeMetadata   Probe-specific metadata 
%

    % Open the file
    handle = fopen(fileName, 'r');
    if (handle ~= -1)

        % Get probe-independent metadata
        fseek(handle, 0, 'bof');
        [headerSize] = fread(handle, 1, '*uint32');  % Size of metadata header
        [metadata.entryType] = fread(handle, 1, '*uint32');

        if (metadata.entryType == 1)
            % Spectral data file
            [metadata.numEntries] = fread(handle, 1, '*uint64');
            [metadata.dataLength] = fread(handle, 1, '*uint32');
            [metadata.elementSize] = fread(handle, 1, '*uint32');
            [metadata.version] = fread(handle, 1, '*uint32');
            if (metadata.version ~= 0)
                [metadata.probeOffset] = fread(handle, 1, '*uint32');
                
                if (metadata.version == 2)
                    [metadata.spectrometerResolution] = fread(handle, 1, '*float');
                    [metadata.refractiveIndex] = fread(handle, 1, '*float');
                    [metadata.singleArmMode] = fread(handle, 1, '*uint8');
                    [metadata.minWavelength] = fread(handle, 1, '*float');
                    [metadata.maxWavelength] = fread(handle, 1, '*float');
                end
            end
        elseif (metadata.entryType == 2)
            % A Scan file
            [metadata.numEntries] = fread(handle, 1, '*uint64');
            [metadata.dataSize] = fread(handle, 1, '*uint32');
            [metadata.opdMin] = fread(handle, 1, '*float');
            [metadata.opdMax] = fread(handle, 1, '*float');
            [metadata.version] = fread(handle, 1, '*uint32');
            if (metadata.version ~= 0)
                [metadata.probeOffset] = fread(handle, 1, '*uint32');
				
				if (metadata.version > 1)
					% Included since version 2 
                    [metadata.spectrometerResolution] = fread(handle, 1, '*float');
                    [metadata.refractiveIndex] = fread(handle, 1, '*float');
                    [metadata.singleArmMode] = fread(handle, 1, '*uint8');
                    [metadata.minWavelength] = fread(handle, 1, '*float');
                    [metadata.maxWavelength] = fread(handle, 1, '*float');
				end
				
				if (metadata.version > 2)
					% Included since version 3
                    [metadata.dcUsed] = fread(handle, 1, '*logical');
                    [metadata.dc2] = fread(handle, 1, '*double');
                    [metadata.dc3] = fread(handle, 1, '*double');
				end
				
            end
        elseif (metadata.entryType == 5)
            % Fluorescence file
            [metadata.numSamples] = fread(handle, 1, '*uint64');
            [metadata.version] = fread(handle, 1, '*uint32');
            if (metadata.version ~= 0)
                [metadata.probeOffset] = fread(handle, 1, '*uint32');
            end
        elseif (metadata.entryType == 6)
            % Generic data file
            [metadata.numEntries] = fread(handle, 1, '*uint64');
            [metadata.dataLength] = fread(handle, 1, '*uint32');
            [metadata.elementSize] = fread(handle, 1, '*uint32');
            [metadata.elementType] = fread(handle, 1, '*uint32');
            [metadata.minWavelength] = fread(handle, 1, '*float');
            [metadata.maxWavelength] = fread(handle, 1, '*float');
            [metadata.version] = fread(handle, 1, '*uint32');
            if (metadata.version ~= 0)
                [metadata.probeOffset] = fread(handle, 1, '*uint32');
            end
        end
        
        % Get probe-specific metadata
        if (metadata.version ~= 0)
            % Get common probe metadata
            fseek(handle, 4 + metadata.probeOffset, 'bof');
            [probeMetadata.version] = fread(handle, 1, '*uint32');
            [probeMetadata.probeType] = fread(handle, 1, '*uint32');
            [probeMetadata.length] = fread(handle, 1, '*uint32');
            
            if (probeMetadata.probeType == 0)
                % Needle probe metadata
                [probeMetadata.startAngle] = fread(handle, 1, '*float');
                [probeMetadata.scanAngle] = fread(handle, 1, '*float');
                [probeMetadata.aScansPerLocation] = fread(handle, 1, '*uint32');
                [probeMetadata.aScansPerSweep] = fread(handle, 1, '*uint32');
                [probeMetadata.aScansPerStep] = fread(handle, 1, '*uint32');
                if (probeMetadata.version ~= 1)
                    [probeMetadata.StepSizeMm] = fread(handle, 1, '*float');
                    [probeMetadata.NeedleDiameterMm] = fread(handle, 1, '*float');
                    [probeMetadata.CapillaryDiameterMm] = fread(handle, 1, '*float');
                end
            elseif (probeMetadata.probeType == 1)
                % Galvo XY probe metadata
                [probeMetadata.aScansPerLocation] = fread(handle, 1, '*uint32');
                [probeMetadata.aScansPerBScan] = fread(handle, 1, '*uint32');
                [probeMetadata.bScansPerLocation] = fread(handle, 1, '*uint32');
                [probeMetadata.bScansPerVolume] = fread(handle, 1, '*uint32');
                [probeMetadata.startXmm] = fread(handle, 1, '*float');
                [probeMetadata.endXmm] = fread(handle, 1, '*float');
                [probeMetadata.startYmm] = fread(handle, 1, '*float');
                [probeMetadata.endYmm] = fread(handle, 1, '*float');
            else
                probeMetadata.version = 0;
            end
        else
            probeMetadata.version = 0;
        end

        % Close the file
        fclose(handle);
        
        result = 0;
    else
        % Initialise so unassigned results don't cause Matlab to print error
        metadata = 0;
        probeMetadata = 0;

        result = -1;
    end
    
end

