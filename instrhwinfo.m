function obj = instrhwinfo(object, adaptor, interface)
%INSTRHWINFO Return information on available hardware.
%
%   OUT = INSTRHWINFO returns instrument control hardware information.
%   This information includes the toolbox version, MATLAB version,
%   supported interfaces and supported driver types.
%
%   OUT = INSTRHWINFO('INTERFACE') returns information related to the
%   specified interface, INTERFACE. INTERFACE can be 'gpib', 'visa',
%   'serial', 'tcpip', 'udp' 'i2c' 'Bluetooth' 'modbus' or 'spi'. For the
%   GPIB and VISA interfaces, this information includes installed adaptors.
%   For the serial port interface, this information includes available
%   hardware. For the TCPIP and UDP interfaces, this information includes
%    the local host address. For modbus, this information includes the
%    available transports.
%
%   OUT = INSTRHWINFO('DRIVERTYPE') returns information related to the
%   specified driver type, DRIVERTYPE. DRIVERTYPE can be 'matlab',
%   'vxipnp', or 'ivi'. If DRIVERTYPE is MATLAB, this information includes
%   the MATLAB instrument drivers found on the MATLAB path. If DRIVERTYPE
%   is vxipnp, this information includes the found VXIplug&play drivers. If
%   DRIVERTYPE is ivi, this information includes the available logical
%   names and information on the IVI configuration store.
%
%   OUT = INSTRHWINFO('INTERFACE', 'ADAPTOR') returns information related
%   to the specified adaptor, ADAPTOR, for the specified INTERFACE. This
%   information includes adaptor version and available hardware. INTERFACE
%   can be set to either 'gpib' or 'visa'. Supported adaptors include:
%
%             Interface:      Adaptor:
%             ==========      ========
%             gpib            agilent, ics, ni
%             visa            agilent, ni, tek
%             i2c             aardvark, ni845x
%             spi             aardvark, ni845x
%
%   OUT = INSTRHWINFO('I2C', 'ADAPTOR') or returns information related to
%   the specified adaptor.
%
%   OUT = INSTRHWINFO('SPI', 'ADAPTOR') or returns information related to
%   the specified adaptor.
%
%   OUT = INSTRHWINFO('Bluetooth', 'RemoteName') or OUT =
%   INSTRHWINFO('Bluetooth', 'RemoteID') returns information related to the
%   specified remote device.
%
%   OUT = INSTRHWINFO('DRIVERTYPE', 'DRIVERNAME') returns information
%   related to the specified driver, DRIVERNAME for the specified
%   DRIVERTYPE. DRIVERTYPE can be set to 'matlab', 'vxipnp'. The available
%   DRIVERNAME values are returned by INSTRHWINFO('DRIVERTYPE').
%
%   OUT = INSTRHWINFO('ivi', 'LOGICALNAME') returns information related to
%   the specified logical name, LOGICALNAME. The available logical name
%   values are returned by INSTRHWINFO('ivi').
%
%   OUT = INSTRHWINFO('INTERFACE', 'ADAPTOR', 'TYPE') returns information
%   on the specified type, TYPE. INTERFACE can only be 'visa'. ADAPTOR can
%   be 'agilent', 'ni' or 'tek'. TYPE can be  'gpib', 'vxi', 'gpib-vxi',
%   'serial', 'tcpip', 'usb', 'rsib', 'pxi' or 'generic'.
%
%   OUT = INSTRHWINFO(OBJ) where OBJ is any instrument object or a device
%   group object, returns information on OBJ. For GPIB and VISA objects,
%   OUT contains adaptor and vendor supplied DLL information. For serial
%   port, tcpip and udp objects, OUT contains JAR file information. For
%   device objects and device group objects, OUT contains driver and
%   instrument information. If OBJ is an array of objects then OUT is a
%   1-by-N cell array of structures where N is the length of OBJ.
%
%   OUT = INSTRHWINFO(OBJ, 'FieldName') returns the hardware information
%   for the specified fieldname, FieldName, to OUT. FieldName can be any of
%   the fieldnames defined in the INSTRHWINFO(OBJ) structure. FieldName can
%   be a single string or a cell array of strings. OUT is a M-by-N cell
%   array where M is the length of OBJ and N is the length of FieldName.
%
%   Example:
%       out1 = instrhwinfo
%       out2 = instrhwinfo('serial')
%       out3 = instrhwinfo('gpib', 'ni')
%       out4 = instrhwinfo('visa', 'ni')
%       out5 = instrhwinfo('visa', 'ni', 'gpib')
%       obj  = visa('ni', 'ASRL1::INSTR')
%       out6 = instrhwinfo(obj)
%       out7 = instrhwinfo(obj, 'AdaptorName')
%
%   See also INSTRHELP.
%

%   Copyright 1999-2017 The MathWorks, Inc.

% Error if java is not running.
if ~usejava('jvm')
    error(message('instrument:instrhwinfo:nojvm'));
end

switch nargin
    case 0
        % Ex. out = instrhwinfo

        % Create the output structure.
        out.MATLABVersion = localGetVersion('MATLAB');
        out.SupportedInterfaces = {'gpib', 'serial', 'tcpip', 'udp', 'visa', 'Bluetooth', 'i2c', 'spi', 'modbus'};
        if ispc
            out.SupportedDrivers = {'matlab', 'ivi', 'vxipnp'};
        else
            out.SupportedDrivers = {'matlab'};
        end
        out.ToolboxName = 'Instrument Control Toolbox';
        out.ToolboxVersion = localGetVersion('instrument');

    case 1
        % Ex. out = instrhwinfo('serial');

        % Determine the jar file version.
        jarFileVersion = com.mathworks.toolbox.instrument.Instrument.jarVersion;

        % convert to char in order to accept string datatype
        object = instrument.internal.stringConversionHelpers.str2char(object);

        if ~ischar(object)
            error(message('instrument:instrhwinfo:invalidInterface'));
        end

        % Create the output structure.
        switch lower(object)
            case 'serial'
                try
                    fields = {'AvailableSerialPorts', 'JarFileVersion', ...
                        'ObjectConstructorName', 'SerialPorts'};
                    try
                        s = javaObject('com.mathworks.toolbox.instrument.SerialComm','temp');
                        tempOut = hardwareInfo(s);
                        dispose(s);
                    catch
                        tempOut = {{}, '', {}, {}}';
                    end

                    % Get all serial ports for the machine (in-use and not in-use ports)
                    allSerialPorts = cellstr(seriallist('all'));

                    % Prepare the tempOut cell structure
                    tempOut = cell(tempOut);
                    tempOut{4} = allSerialPorts';
                    tempOut{3} = cell(0,1);
                    s = size(tempOut{4});
                    for iloop = 1 : s(1)
                        tempOut{3}{iloop, 1} = ['serial(''',tempOut{4}{iloop},''');'];
                    end
                    out = cell2struct(tempOut', fields, 2);
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException);
                end
            case 'gpib'
                pathToDll  = localFindPath;
                try
                    out.InstalledAdaptors = com.mathworks.toolbox.instrument.GpibDll.findValidAdaptors(pathToDll);
                    out.InstalledAdaptors = out.InstalledAdaptors';
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException);
                end
            case {'visa'}
                pathToDll =  localFindPath;
                try
                    out.InstalledAdaptors = com.mathworks.toolbox.instrument.SerialVisa.findValidAdaptors(pathToDll);
                    out.InstalledAdaptors = out.InstalledAdaptors';
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException);
                end
            case 'tcpip'
                try
                    fields = {'LocalHost','JarFileVersion'};
                    t = com.mathworks.toolbox.instrument.TCPIP('temp',80);
                    tempOut = hardwareInfo(t);
                    dispose(t);

                    % Create the output structure.
                    tempOut = cell(tempOut);
                    out = cell2struct(tempOut', fields, 2);
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException);
                end
            case 'udp'
                try
                    fields = {'LocalHost','JarFileVersion'};
                    u = com.mathworks.toolbox.instrument.UDP('temp',9090);
                    tempOut = hardwareInfo(u);
                    dispose(u);

                    % Create the output structure.
                    tempOut = cell(tempOut);
                    out = cell2struct(tempOut', fields, 2);
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException);
                end
            case 'bluetooth' % Ex. blueInfo = instrhwinfo('Bluetooth')
                try
                    Fields = {'RemoteNames','RemoteIDs', 'BluecoveVersion','JarFileVersion'};
                    BluetoothDevices = com.mathworks.toolbox.instrument.BluetoothDiscovery.hardwareInfo();
                    tempOut = cell(BluetoothDevices);
                    tempOut = bluetoothCombinedDevices(tempOut);
                    out = cell2struct(tempOut', Fields, 2);
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException);
                end
            case 'i2c'
                try
                    pathToDll =  localFindPath;
                    out.InstalledAdaptors = cellstr(char(com.mathworks.toolbox.instrument.I2C.findValidAdaptors(pathToDll)))';
                    out.JarFileVersion = jarFileVersion;
                catch aException
                    rethrow(aException)
                end
            case 'spi'
                hwInfo = instrument.interface.spi.HardwareInfo();
                out = hwInfo.instrhwinfoDisplay();
            case 'matlab'
                out = localFindMATLABDrivers;
            case 'vxipnp'
                out = localFindVXIPnPDrivers;
            case 'ivi'
                out = localFindIVIDrivers;
            case 'modbus'
                out = instrument.interface.modbus.HardwareInfo.GetHardwareInfo();
            otherwise
                error(message('instrument:instrhwinfo:invalidInterface'));
        end
    case 2
        % Ex. out = instrhwinfo('gpib', 'ni');
        % Ex. out = instrhwinfo('gpib', 'keithley');

        % convert to char in order to accept string datatype
        object = instrument.internal.stringConversionHelpers.str2char(object);
        adaptor = instrument.internal.stringConversionHelpers.str2char(adaptor);

        if ~ischar(object)
            error(message('instrument:instrhwinfo:invalidInterface'));
        end

        if ~ischar(adaptor)
            if any(strcmp(object, {'gpib', 'serial', 'tcpip', 'udp', 'visa', 'Bluetooth', 'i2c', 'modbus'}))
                error(message('instrument:instrhwinfo:invalidAdaptor'));
            else
                error(message('instrument:instrhwinfo:invalidDriverName'));
            end
        end

        switch lower(object)
            case 'gpib'
                adaptor = lower(adaptor);

                % Find the path to the dll.
                pathToDll  = localFindAdaptor(['mw' adaptor 'gpib']);

                % Create the output structure.
                try
                    fields = {'AdaptorDllName', 'AdaptorDllVersion', 'AdaptorName',...
                        'InstalledBoardIds', 'ObjectConstructorName', 'VendorDllName', ...
                        'VendorDriverDescription'};
                    jobject = javaObject(['com.mathworks.toolbox.instrument.Gpib' upper(adaptor)], pathToDll, 0, 0);
                    tempOut = hardwareInfo(jobject, pathToDll, adaptor, fileparts(pathToDll));
                    out = localCreateOutputStructure(tempOut, fields);
                    dispose(jobject);
                catch
                    error(message('instrument:instrhwinfo:adpatorNotFound'));
                end

                % Format InstalledBoardIds and ObjectConstructorName.
                out.InstalledBoardIds = unique(double(out.InstalledBoardIds))';
                if (isempty(out.ObjectConstructorName))
                    out.ObjectConstructorName = {};
                end
            case 'visa'
                adaptor = lower(adaptor);

                % Find the path to the dll.
                pathToDll  = localFindAdaptor(['mw' adaptor 'visa']);

                % Construct the input to the SerialVisa constructor.
                [path, name, ext] = fileparts(pathToDll);
                vendor = [name ext];
                name = 'ASRL1::INSTR';

                % If a valid adaptor is specified create the output structure.
                try
                    fields = {'AdaptorDllName', 'AdaptorDllVersion', 'AdaptorName',...
                        'AvailableChassis', 'AvailableSerialPorts', 'InstalledBoardIds',...
                        'ObjectConstructorName', 'SerialPorts', 'VendorDllName',...
                        'VendorDriverDescription', 'VendorDriverVersion'};
                    jobject = com.mathworks.toolbox.instrument.SerialVisa(path,vendor,name,'');
                    tempOut = hardwareInfo(jobject, pathToDll, adaptor);
                    out = localCreateOutputStructure(tempOut, fields);
                    dispose(jobject);
                catch %#ok<*CTCH>
                    error(message('instrument:instrhwinfo:adpatorNotFound'));
                end
            case 'bluetooth' % Ex. blueInfo = instrhwinfo('Bluetooth','IRXON_WIN64')
                %find the services available on a discovered device.
                device = lower(adaptor);
                if strcmpi(computer('arch'),'glnxa64')
                    error(message('instrument:instrhwinfo:noBluetoothSupportInLinux'));
                else
                    % If a valid adaptor is specified create the output structure.
                    try
                        fields = {'RemoteName', 'RemoteID','ObjectConstructorName','Channels'};
                        tempOut = com.mathworks.toolbox.instrument.BluetoothDiscovery.hardwareInfo(device);
                    catch
                        error(message('instrument:instrhwinfo:adpatorNotFound'));
                    end
                    out = localCreateOutputStructure(tempOut, fields);
                    if isempty(out.RemoteName)
                        % when no information returned, try one more step
                        % further to get the information from
                        % com.mathworks.toolbox.instrument.BluetoothDiscovery.hardwareInfo()
                        try
                            btDevices = com.mathworks.toolbox.instrument.BluetoothDiscovery.hardwareInfo();
                            if isempty(btDevices(1))
                                noDeviceException = MException(message('instrument:instrhwinfo:invalidAdaptor'));
                                throw(noDeviceException);
                            end
                            bt = cell(btDevices);
                            btDevices = bluetoothCombinedDevices(bt);
                            btInstrInfo = struct('RemoteNames', btDevices(1), 'RemoteIDs', btDevices(2));
                        catch aException
                            rethrow(aException);
                        end
                        if  ~isempty(btInstrInfo) % Instrument found
                            % Initialize out stucture
                            out = struct('RemoteName','','RemoteID','','ObjectConstructorName','','Channels','');
                            for Index = 1 : length(btInstrInfo.RemoteNames)
                                if strcmpi(btInstrInfo.RemoteNames(Index), adaptor)
                                    % fill out the structure
                                    out.RemoteName = [out.RemoteName; char(btInstrInfo.RemoteNames(Index))];
                                    out.RemoteID = [out.RemoteID; char(btInstrInfo.RemoteIDs(Index))];
                                    % use the RemoteIDs for the
                                    % ObjectConstructorName
                                    out.ObjectConstructorName = [out.ObjectConstructorName; {sprintf('Bluetooth(''%s'', %d);',char(btInstrInfo.RemoteIDs(Index)), 1)}];
                                    %If the bluetooth obj is created, use
                                    %its channel information. otherwise,
                                    %use '1' as default channel.
                                    remoteID = regexprep(char(btInstrInfo.RemoteIDs(Index)),'btspp://','');
                                    instrFound = instrfind('RemoteID',char(remoteID)); % remove the 'btspp://' part
                                    if ~isempty(instrFound)
                                        out.Channels = [out.Channels; {int2str(instrFound(1).Channel)}];
                                    else % isempty(instrFound)
                                        out.Channels = [out.Channels; {'1'}];
                                    end
                                end
                            end
                            if length(out.Channels) > 1
                                % if more than one bluetooth devices is
                                % found, call cellstr to convert the string
                                % array to cell array.
                                out.RemoteName= cellstr(out.RemoteName);
                                out.RemoteID = cellstr(out.RemoteID);
                            elseif length(out.Channels) == 1
                                % if only one bluetooth devices is
                                % found, use the RemoteName for the
                                % ObjectConstructorName
                                out.ObjectConstructorName = {sprintf('Bluetooth(''%s'', %d);',char(out.RemoteName), 1)};
                            end
                        end
                    end
                end
            case 'i2c'

                % Find the path to the dll.
                pathToDll  = localFindAdaptor(['mw' lower(adaptor) 'i2c']);

                % Create the output structure.
                try
                    fields = {'AdaptorDllName', 'AdaptorDllVersion', 'AdaptorName',...
                        'InstalledBoardIDs', 'ObjectConstructorName', 'VendorDllName', ...
                        'VendorDriverDescription', 'BoardIdsInUse'};
                    jobject = javaObject(['com.mathworks.toolbox.instrument.I2C' upper(adaptor)],  pathToDll, adaptor, 0, 0);
                    tempOut = hardwareInfo(jobject, pathToDll, adaptor, fileparts(pathToDll));
                    jobject.dispose;
                catch ex
                    error(message('instrument:instrhwinfo:adpatorNotFound'));
                end
                % Create the output structure.
                tempOut = cell(tempOut);
                out = cell2struct(tempOut', fields, 2);

                % Format AvailableBoardIndices and ObjectConstructorName.

                out.InstalledBoardIDs = unique(double(out.InstalledBoardIDs))';
                out.BoardIdsInUse = unique(double(out.BoardIdsInUse))';
                if (isempty(out.ObjectConstructorName))
                    out.ObjectConstructorName = {};
                end
                % Retrieve board Serials if available
                numBoards = numel(out.InstalledBoardIDs) + numel(out.BoardIdsInUse);
                out.DetectedBoardSerials = cell(numBoards,1);
                for boardIndex = 0:numBoards-1
                    jobject = javaObject(['com.mathworks.toolbox.instrument.I2C' upper(adaptor)],  pathToDll, adaptor, boardIndex, 0);
                    serialNum =char(jobject.getBoardSerial());
                    %format boardSerial
                    formattedSerial = {[serialNum ' (BoardIndex: ' num2str(boardIndex) ')']};
                    out.DetectedBoardSerials(boardIndex+1) = formattedSerial;
                    dispose(jobject);
                end
                out = orderfields(out);
                perm = 1:numel(fieldnames(out));
                perm([5 6]) = perm([6 5]); % Swap the fields
                out = orderfields(out, perm);

            case 'spi'
                hwInfo = instrument.interface.spi.HardwareInfo();
                out = hwInfo.instrhwinfoDisplayByVendor(adaptor);
                if (isempty(out))
                    error(message('instrument:instrhwinfo:adpatorNotFound'));
                end
            case 'matlab'
                out = localGetMATLABDriverInfo(adaptor);
            case 'vxipnp'
                out = localGetVXIPnPDriverInfo(adaptor);
            case 'ivi'
                out = localGetIVIDriverInfo(adaptor);
            otherwise
                error(message('instrument:instrhwinfo:invalidInterface'));
        end

    case 3
        % Ex. instrhwinfo('visa', 'ni', 'serial');

        % convert to char in order to accept string datatype
        object = instrument.internal.stringConversionHelpers.str2char(object);
        adaptor = instrument.internal.stringConversionHelpers.str2char(adaptor);
        interface = instrument.internal.stringConversionHelpers.str2char(interface);

        % Error checking.
        if ~strcmpi(object, 'visa')
            error(message('instrument:instrhwinfo:invalidSyntax'));
        end

        % Get the object specific information.
        out = localFindSpecificVisaInformation(adaptor, interface);

end

obj = instrument.HardwareInfo.Struct2Obj(out);

function out = localCreateOutputStructure(tempOut, fields)
% Create the output structure.
tempOut = cell(tempOut);
out = cell2struct(tempOut', fields, 2);


% *********************************************************************
% Three input case.
function  out  = localFindSpecificVisaInformation(adaptor, interface)

% Find the path to the dll.
pathToDll = localFindAdaptor(['mw' adaptor 'visa']);

% Verify type of interface.
if ~ischar(interface)
    newExc =  MException ('instrument:instrhwinfo:invalidInterface','Invalid TYPE specified. Type ''instrhelp instrhwinfo'' for a list of valid TYPEs.' );
    throwAsCaller(newExc);
end

% Construct inputs to SerialVisa constructor.
[path, vendor, ext] = fileparts(pathToDll);
vendor = [vendor ext];
name = 'ASRL1::INSTR';

% Get the interface specific information.
try
    % Define the fields.
    fields = {'AdaptorDllName', 'AdaptorDllVersion', 'AdaptorName',...
        'AvailableChassis', 'AvailableSerialPorts', 'InstalledBoardIds',...
        'ObjectConstructorName', 'SerialPorts', 'VendorDllName',...
        'VendorDriverDescription', 'VendorDriverVersion'};

    % Create the object.
    jobject =  com.mathworks.toolbox.instrument.SerialVisa(path,vendor,name,'');

    % Get the information.
    switch lower(interface)
        case 'serial'
            tempOut = hardwareInfoOnSerial(jobject, pathToDll, adaptor);
        case 'gpib'
            tempOut = hardwareInfoOnGPIB(jobject, pathToDll, adaptor);
        case 'vxi'
            tempOut = hardwareInfoOnVXI(jobject, pathToDll, adaptor);
        case 'pxi'
            tempOut = hardwareInfoOnPXI(jobject, pathToDll, adaptor);
        case 'gpib-vxi'
            tempOut = hardwareInfoOnGPIBVXI(jobject, pathToDll, adaptor);
        case 'rsib'
            tempOut = hardwareInfoOn(jobject, pathToDll, adaptor, 'RSIB');
        case 'tcpip'
            tempOut = hardwareInfoOn(jobject, pathToDll, adaptor, 'TCPIP?*');
        case 'usb'
            tempOut = hardwareInfoOn(jobject, pathToDll, adaptor, 'USB?*');
        case 'generic'
            tempOut = hardwareInfoOnGeneric(jobject, pathToDll, adaptor);
        otherwise
            dispose(jobject);
            newExc = MException('instrument:instrhwinfo:invalidInterface', 'Invalid TYPE specified. Type ''instrhelp instrhwinfo'' for a list of valid TYPEs.');
            throwAsCaller(newExc);
    end

    % Get rid of the object.
    dispose(jobject);
catch r
    newExc =  MException( 'instrument:instrhwinfo:invalidAdaptor', 'Specified ADAPTOR was not found or could not be loaded.' );
    throwAsCaller(newExc);
end

% Create the output structure.
tempOut = cell(tempOut);
out = cell2struct(tempOut', fields, 2);

% -------------------------------------------------------------------
% Find the path to the dll.
function pathToDll = localFindPath

% Define the toolbox root location.
pathToDll = which('instrgate', '-all');

dirname = instrgate('privatePlatformProperty', 'dirname');

if (isempty(dirname))
    newExc =  MException('instrument:instrhwinfo:invalidPlatform' , 'The specified INTERFACE is not supported on this platform.' );
    throwAsCaller (newExc);
end

pathToDll = [fileparts(pathToDll{1}) 'adaptors'];
pathToDll = fullfile(pathToDll, dirname);

% -------------------------------------------------------------------
% Find the adaptor that is being loaded. The path was not specified.
% name is mwnigpib, mwnivisa, mwagilentgpib, etc.
function adaptorPath = localFindAdaptor(name)

% Define the toolbox root location.
instrRoot = which('instrgate', '-all');

dirname = instrgate('privatePlatformProperty', 'dirname');
extension = instrgate('privatePlatformProperty', 'libext');

if (isempty(dirname) || isempty(extension))
    newExc = MException('instrument:instrhwinfo:invalidPlatform', 'The specified INTERFACE is not supported on this platform.');
    throwAsCaller(newExc);
    
end

% Define the adaptor directory location.
instrRoot = [fileparts(instrRoot{1}) 'adaptors'];
adaptorRoot = fullfile(instrRoot, dirname, [name extension]);

% Determine if the adaptor exists.
if exist(adaptorRoot, 'file')
    adaptorPath = adaptorRoot;
else
    newExc = MException('instrument:instrhwinfo:adpatorNotFound', 'The specified VENDOR adaptor could not be found.');
    throwAsCaller(newExc);
end

% -------------------------------------------------------------------
% Output the version of the toolbox and MATLAB.
function str = localGetVersion(product)

try
    % Get the version information.
    verinfo = ver(product);

    % Get the version string.
    str = [verinfo(1).Version ' ' verinfo(1).Release];
catch
    str = '';
end

% -------------------------------------------------------------------
% Called by: instrhwinfo('matlab')
function out = localFindMATLABDrivers

import com.mathworks.toolbox.instrument.device.icdevice.ICDriverInfo;

% Scan for the MATLAB instrument drivers. Scan can take a long time so
% store the data away so that if user calls instrhwinfo('matlab', driver)
% we can just look up the driver path information.
ICDriverInfo.defineMATLABDrivers(privateBrowserHelper('find_MATLAB_drivers'));
out.InstalledDrivers = cell(ICDriverInfo.getMATLABDriverNames)';

% -------------------------------------------------------------------
% Called by: instrhwinfo('vxipnp')
function out = localFindVXIPnPDrivers

% Scan for VXIplug&play drivers. Information is of the form: Name, Directory.
driverInfo = privateBrowserHelper('find_vxipnp_drivers');

out.InstalledDrivers = '';
out.VXIPnPRootPath   = privateGetVXIPNPPath;

if isempty(driverInfo)
    return;
end

% Construct the cell of VXIplug&play driver names.
names = cell(1, length(driverInfo)/2);
count = 1;
for i=1:2:length(driverInfo)
    names{count} = driverInfo{i};
    count = count+1;
end

out.InstalledDrivers = names;

% -------------------------------------------------------------------
% Called by: instrhwinfo('ivi')
function out = localFindIVIDrivers

% Determine if IVI is installed.
rootPath = privateGetIviPath;

if isempty(rootPath)
    % IVI is not installed.
    out.LogicalNames = {};
    out.Modules      = {};
    out.ConfigurationServerVersion = '';
    out.MasterConfigurationStore   = '';
    out.IVIRootPath                = '';
    return;
end

% Create the configuration store object.
store = iviconfigurationstore;

% Construct the output.
out.LogicalNames               = {};
out.Modules                    = {};
out.ConfigurationServerVersion = get(store, 'Revision');
out.MasterConfigurationStore   = get(store, 'MasterLocation');
out.IVIRootPath                = rootPath;

logicalNames = get(store, 'LogicalNames');
if ~isempty(logicalNames)
    out.LogicalNames = {logicalNames.Name};
end

modules = get(store, 'SoftwareModules');

for idx = 1:length(modules)
    if (~isempty(modules(idx).ProgID))

        % empty progid is not the only criteria to differentiate a ivi-c
        % and ivi-com driver
        modulepathname = modules(idx).ModulePath;
        if (~isempty(modulepathname))
            seperator = strfind(modulepathname, '.');
            ivicDrivername = modulepathname(1:(seperator - 1));

            %32 bit or 64 bit
            if length(ivicDrivername) > 3 % Trim the suffix only if ivi-c Driver name length greater than three
                if (strcmp(ivicDrivername(end-2:end), '_32') || strcmp(ivicDrivername(end-2:end), '_64') )
                    ivicDrivername = ivicDrivername(1:end-3);
                end
            end

            ivicDriverFPFname = instrgate('privateGetIviCDriverName', ivicDrivername);
            if (~isempty(ivicDriverFPFname) && ~any(ismember (out.Modules ,ivicDrivername )))
                out.Modules{end + 1} = ivicDrivername;
            end
        end
    else
        name = modules(idx).ModulePath;
        % a workaround for g649241  since IVI.NET driver will insert a empty
        % module after installation
        if isempty (name)
            continue;
        end
        tmpidx = strfind(name, '.');
        if (~isempty(tmpidx))
            name = name(1:(tmpidx(1) - 1));
        end
        % 32 bit or 64 bit
        if (strcmp(name(end-2:end), '_32') || strcmp(name(end-2:end), '_64'))
            name = name(1:end-3);
        end

        %         if (isempty(out.Modules))
        %             out.Modules = {name};
        %         else
        if ~any (ismember (  name, out.Modules ))
            out.Modules{end + 1} = name;
        end
        %         end
    end
end

% --------------------------------------------------------------------
% Called by: instrhwinfo('matlab', driver)
function out  = localGetMATLABDriverInfo(driverName)

import com.mathworks.toolbox.instrument.device.icdevice.ICDriverInfo;

% Initialize variables.
out     = [];
% Extract just the driver name and just the extension.
[~, driverName, ext] = fileparts(driverName);
if isempty(ext)
    ext = '.mdd';
end
driverName = [driverName ext];

% If the driver does not exist. Scan for it.
if ICDriverInfo.isDriver(driverName) == false
    ICDriverInfo.defineMATLABDrivers(privateBrowserHelper('find_MATLAB_drivers'));

    % If the driver does not exist after scanning for it, error.
    if ICDriverInfo.isDriver(driverName) == false
        newExc = MException('instrument:instrhwinfo:driverNotFound','The specified MATLAB instrument driver could not be found on the MATLAB path.' );
        throwAsCaller(newExc);
    end
end

% Determine if the driver is still at the specified location.
driverPath = char(ICDriverInfo.getMATLABDriverPath(driverName));
driverName = char(ICDriverInfo.getMATLABDriverName(driverName));
fullDriverName = fullfile(driverPath, driverName);

if exist(fullfile(driverPath, driverName), 'file') == 0
    % The driver no longer exists. Re-scan.
    ICDriverInfo.defineMATLABDrivers(privateBrowserHelper('find_MATLAB_drivers'));

    % If the driver does not exist after scanning for it, error.
    if ICDriverInfo.isDriver(driverName) == false
        newExc = MException('instrument:instrhwinfo:driverNotFound', 'The specified MATLAB instrument driver could not be found on the MATLAB path.');
        throwAsCaller(newExc);
    end

    if exist(fullfile(driverPath, driverName), 'file') == 0
        newExc = MException('instrument:instrhwinfo:driverNotFound', 'The specified MATLAB instrument driver could not be found on the MATLAB path.');
        throwAsCaller(newExc);
    end
end

% Parse the driver.
try
    parser = com.mathworks.toolbox.instrument.device.drivers.xml.Parser(fullDriverName);
    parser.parse;
catch
    newExc =  MException('The specified MATLAB instrument driver could not be parsed.', 'instrument:instrhwinfo:driverInvalid');
    throwAsCaller(newExc);
end

% Construct the output.
out.Manufacturer  = char(parser.getInstrumentManufacturer);
out.Model         = char(parser.getInstrumentModel);
out.Type          = char(parser.getInstrumentType);
out.DriverType    = char(parser.getDriverType);
out.DriverName    = fullDriverName;
out.DriverVersion = char(parser.getInstrumentVersion);
out.DriverDllName = '';

switch (out.DriverType)
    case 'VXIplug&play'
        driverDllName     = [char(parser.getDriverName) '_32.dll'];
        out.DriverDllName = fullfile(privateGetVXIPNPPath, 'bin',driverDllName);
    case 'IVI-COM'
        % COM drivers do not necessarily have a 1-1 dll mapping like the other
        % drivers.
    case 'IVI-C'
        driverDllName     = [char(parser.getDriverName) '.dll'];
        out.DriverDllName = fullfile(privateGetIviPath, 'bin',driverDllName);
end

% -------------------------------------------------------------------
% Called by: instrhwinfo('vxipnp', driver)
function out = localGetVXIPnPDriverInfo(driverName)

import com.mathworks.toolbox.instrument.device.drivers.vxipnp.VXIPnPLoader;

% Initialize variables.
out     = [];

% Scan for VXIplug&play drivers. Information is of the form: Name, Directory.
driverInfo = privateBrowserHelper('find_vxipnp_drivers');

% Determine if the driver name the user specified exists.
driverLocation = -1;
for i=1:2:length(driverInfo)
    if strcmpi(driverInfo{i}, driverName)
        driverLocation = i;
        break;
    end
end

% Return if the driver is not found.
if driverLocation == -1
    newExc =  MException('instrument:instrhwinfo:driverNotFound', 'The specified VXIplug&play driver could not be found.');
    throwAsCaller(newExc);
end

% Parse the driver.
fullDriverName = fullfile(driverInfo{driverLocation+1}, driverName);

if strcmpi(computer, 'pcwin64')
    driverDllName  = [lower(driverName) '_64.dll'];
else
    driverDllName  = [lower(driverName) '_32.dll'];
end

model          = VXIPnPLoader.toBasicMatlabDriverModel([fullDriverName '.fp']);

% Construct the output.
out.Manufacturer   = char(model.getInstrumentManufacturer);
out.Model          = char(model.getInstrumentModel);
out.DriverVersion  = char(model.getInstrumentVersion);
out.DriverDllName  = fullfile(privateGetVXIPNPPath, 'bin',driverDllName);

% -------------------------------------------------------------------
% Called by: instrhwinfo('ivi', 'logicalName')
function out = localGetIVIDriverInfo(logicalName)

% Initialize variables.
out = [];

% Determine if IVI is installed.
rootPath = privateGetIviPath;

if isempty(rootPath)
    % IVI is not installed.
    newExc = MException('instrument:instrhwinfo:IVIInstall', 'The IVI Configuration Server could not be accessed or is not installed.');
    throwAsCaller(newExc);
end

% Initialize the output structure.
out.DriverSession             = '';
out.HardwareAsset             = '';
out.SoftwareModule            = '';
out.IOResourceDescriptor      = '';
out.SupportedInstrumentModels = '';
out.ModuleDescription         = '';
out.ModuleLocation            = '';

% Create the store.
store = iviconfigurationstore;

% Find the information for the specified logical name.
lnInfo = get(store, 'LogicalName');
info = localFindIVIInfo(lnInfo, logicalName);

% The specified logical name could not be found.
if isempty(info)
    newExc = MException('instrument:instrhwinfo:invalidLogicalName', 'Invalid logical name specified. Type ''instrhwinfo(''ivi'')'' for a list of valid logical names.');
    throwAsCaller(newExc);
end

% If no driver session is specified for this logical name, return.
out.DriverSession = info.Session;
if isempty(out.DriverSession)
    return;
end

% Find the information about the driver session.
dsInfo = get(store, 'DriverSession');
info = localFindIVIInfo(dsInfo, out.DriverSession);

% Get the software module and hardware asset used by driver session.
out.SoftwareModule = info.SoftwareModule;
out.HardwareAsset  = info.HardwareAsset;

% Fill in the hardware asset information.
if ~isempty(out.HardwareAsset)
    haInfo = get(store, 'HardwareAsset');
    info = localFindIVIInfo(haInfo, out.HardwareAsset);

    if ~isempty(info)
        out.IOResourceDescriptor = info.IOResourceDescriptor;
    end
end

% Fill in the software module fields.
if ~isempty(out.SoftwareModule)
    smInfo = get(store, 'SoftwareModule');
    info = localFindIVIInfo(smInfo, out.SoftwareModule);

    if ~isempty(info)
        out.SupportedInstrumentModels = info.SupportedInstrumentModels;
        out.ModuleDescription         = info.Description;
        out.ModuleLocation            = info.ModulePath;
    end
end

% -----------------------------------------------------------------------
function out = localFindIVIInfo(allInfo, value)

% Initialize variables.
out   = [];
found = false;

% Search for the value.
for i=1:length(allInfo)
    if strcmpi(allInfo(i).Name, value)
        found = true;
        break;
    end
end

% The value was not found. Return empty.
if (found == false)
    return;
end

% Extract the value.
out = allInfo(i);

% Combining instrhwinfo('Bluetooth') and instrfind
function tempOut = bluetoothCombinedDevices(tempOut)

instrF = instrfind;
sizeInstrF = size(instrF, 2);
if(sizeInstrF ~= 0)
    flag = false;
    jloop = 1;
    for iloop = 1 : sizeInstrF

        % Look for devices in instrfind of type
        % "Bluetooth" which are "open"
        if(strcmpi(instrF(iloop).Type,'bluetooth') && strcmpi(instrF(iloop).Status,'open'))

            % Capture these BT names and IDs
            instrFBTRemote{jloop,1} = instrF(iloop).RemoteName;
            instrFBTRemote{jloop,2} = ['btspp://', instrF(iloop).RemoteID];
            jloop = jloop + 1;
            flag = true;
        end
    end

    % if instrfind "BT" "open" returns a value
    if(flag)
        allBTName = tempOut{1};
        allBTID = tempOut{2};
        for iloop = 1 : (jloop-1)

        % Combine intrhwinfo BT and instrfind results
            allBTName = [allBTName; instrFBTRemote{iloop,1}];
            allBTID = [allBTID; instrFBTRemote{iloop,2}];
        end

        % Find unique remote names and IDs to prevent
        % duplicate remote IDs
        [uniqueBTID, uniqueRowOrder, ~] = unique(allBTID);
        uniqueBTName = allBTName(uniqueRowOrder);
        tempOut{1} = uniqueBTName;
        tempOut{2} = uniqueBTID;
    end
end