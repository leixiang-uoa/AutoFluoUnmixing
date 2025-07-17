function [result, timestamp, location, data] = RtafGetGenericData(fileName, recordNumber)
%RTAFGetGenericData Get Generic Data record from RTAF file
%
% NOTES: 
%  1) This function MAY fail if the required record is too far into the
%       file (probably if the file position is more than 4 billion). 
%  2) This implementation is HIGHLY dependent on the existing file
%     format. If any change occurs in the file format, this function may
%     fail (probably in a spectacular manner).
%  3) To make it easy for others to use this function, it isn't as
%     optimised as it could be.
%
%   Input:
%       fileName     Name of RTAF file containing fluorescence sample
%       recordNumber Index number of record to retrieve (starting at 1)
%
%   Output:
%       result       Result code (0 if function successful, non-zero otherwise)
%       timestamp    Time record was acquired
%       location     Spatial location of record
%       data         Generic Data record

    timestamp = 0;
    location = 0;
    data = 0;

    [result, metadata, ~] = RtafGetMetadata(fileName);
    if (result == 0)

        % Open file
        handle = fopen(fileName, 'r');
        if (handle ~= -1)

            headerSize = double(fread(handle, 1, '*uint32'));  % Size of metadata header
            recordSize = 4 + 1 + (6 * 4) + metadata.dataLength;

            % Seek to the required record
            seekStatus = fseek(handle, 4 + headerSize + (recordNumber - 1) * recordSize, 'bof');
            if (seekStatus == 0)
                
                result = 0;

                [timestamp, elementCount] = fread(handle, 1, '*uint32');
                if (elementCount == 1)
                    fseek(handle, 1, 'cof'); % Skip over "is location valid" flag
                    [location, elementCount] = fread(handle, 6, '*float');
                else
                    result = -1;
                end

                if (elementCount == 6)
                    % Read data(based on element type
                    numElements = double(metadata.dataLength) / double(metadata.elementSize);
                    switch (metadata.elementType)
                        case 0      % GET_Double
                            [data, elementCount] = fread(handle, numElements, '*float64');
                    end
                    if (elementCount ~= numElements)
                        result = -1;
                    end

                else
                    result = -1;
                end

            else
                result = -1;
            end
        else
            result = -1;
        end
        
        % Close file
        fclose(handle);
    end

end

