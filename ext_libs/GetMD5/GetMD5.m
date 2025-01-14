function GetMD5(varargin)
% GetMD5 - 128 bit MD5 checksum: file, string, array, byte stream
% This function calculates a 128 bit checksum for arrays or files.
% Digest = GetMD5(Data, Mode, Format)
% INPUT:
%   Data:   File name or array.
%   Mode:   CHAR to declare the type of the 1st input. Not case-sensitive.
%             'File':   Data is a file name as CHAR.
%             '8Bit':   If Data is a CHAR array, only the 8 bit ASCII part is
%                       used. Then the digest is the same as for a ASCII text
%                       file e.g. created by: FWRITE(FID, Data, 'uchar').
%                       This is ignored if Data is not of type CHAR.
%             'Binary': The MD5 sum is obtained for the contents of Data.
%                       This works for numerical, CHAR and LOGICAL arrays.
%             'Array':  Include the class and dimensions of Data in the MD5
%                       sum. This can be applied for (nested) structs, cells
%                       and sparse arrays also.
%           Optional. Default: '8Bit' for CHAR, 'Binary' otherwise.
%   Format: CHAR, format of the output. Only the first character matters.
%           The upper/lower case matters for 'hex' only.
%             'hex':    [1 x 32] lowercase hexadecimal CHAR.
%             'HEX':    [1 x 32] uppercase hexadecimal CHAR.
%             'double': [1 x 16] double vector with UINT8 values.
%             'uint8':  [1 x 16] uint8 vector.
%             'base64': [1 x 22] CHAR, encoded to base 64 (A:Z,a:z,0:9,+,/).
%                       The CHAR is not padded to keep it short.
%           Optional, default: 'hex'.
%
% OUTPUT:
%   Digest: A 128 bit number is replied in the specified format.
%
% NOTE:
% * For sparse arrays, function handles, java and user-defined objects the
%   M-file GetMD5_helper is called.
% * This replies the same MD5 hash as DataHash, but much faster.
%
% EXAMPLES:
% Three methods to get the MD5 of a file:
%   1. Direct file access (recommended):
%     MD5 = GetMD5(which('GetMD5.m'), 'File')
%   2. Import the file to a CHAR array (no text mode for exact line breaks!):
%     FID = fopen(which('GetMD5.m'), 'r');
%     S   = fread(FID, inf, 'uchar=>char');
%     fclose(FID);
%     MD5 = GetMD5(S, '8bit')
%   3. Import file as a byte stream:
%     FID = fopen(which('GetMD5.m'), 'r');
%     S   = fread(FID, inf, 'uint8=>uint8');
%     fclose(FID);
%     MD5 = GetMD5(S, 'bin');  % 'bin' is optional
%
%   Test data:
%     GetMD5(char(0:511), '8bit', 'HEX')
%       % => F5C8E3C31C044BAE0E65569560B54332
%     GetMD5(char(0:511), 'bin')
%       % => 3484769D4F7EBB88BBE942BB924834CD
%     GetMD5(char(0:511), 'array')
%       % => b9a955ae730b25330d4f4ebb0a51e8f0
%     GetMD5('abc')   % implicit '8bit' for CHAR
%       % => 900150983cd24fb0d6963f7d28e17f72
%
% COMPILATION:
%   The C-Mex-file is compiled automatically, when this function is called the
%   first time.
%   See GetMD5.c for details or a manual compilation.
%
% Tested: Matlab/64 7.8, 7.13, 8.6, 9.1, Win7/64
% Author: Jan Simon, Heidelberg, (C) 2009-2019 matlab.2010(a)n(MINUS)simon.de
% License: This program is derived from the RSA Data Security, Inc.
%          MD5 Message Digest Algorithm, RFC 1321, R. Rivest, April 1992
%          This implementation is published under the BSD license.
%
% See also CalcCRC32, DataHash.
%
% For more checksum methods see:
%   http://www.mathworks.com/matlabcentral/fileexchange/31272-datahash

% $JRev: R5G V:038 Sum:yFie32x5VgiF Date:04-Mar-2019 16:20:44 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $UnitTest: uTest_GetMD5 $
% $File: Tools\GLFile\GetMD5.m $
% History:
% 015: 15-Dec-2009 16:53, BUGFIX: UINT32 has 32 bits on 64 bit systems now.
%      Thanks to Sebastiaan Breedveld!
% 026: 30-Jan-2015 00:12, 64 bit arrays larger than 2.1GB accepted.
%      Successor of "CalcMD5".
% 031: 04-Jun-2016 22:26, Structs and cells are handled.
% 033: 03-May-2018 20:37, BUGFIX: Null pointer in data array.
% 035: 27-Aug-2018 00:52, Consider string class.

% Dummy code, which calls the auto-compilation only: ---------------------------
% This M-function is not called, if the compiled MEX function is in the path.

error('Cannot find Mex file: %s', [mfilename '.' mexext]);
