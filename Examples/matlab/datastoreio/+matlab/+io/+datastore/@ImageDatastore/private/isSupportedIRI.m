function tf = isSupportedIRI(filename)
% Verify if the filename provided is an IRI and if the IRI is supported
tf = strncmpi(filename,'s3://',5) | ...
     strncmpi(filename, 'wasb://',7) |...
     strncmpi(filename, 'wasbs://',8);
end