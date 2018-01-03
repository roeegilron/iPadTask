classdef BioSemiSerialPort
    % BioSemiSerialPort - function send triggers to BioSemi EEG systems 
    % This function requires the purchase (or manufacture) of a USB to serial 
    % hardware device. 
    % https://www.biosemi.com/faq/USB%20Trigger%20interface%20cable.htm
    %
    % Syntax:  sp = BioSemiSerialPort();
    %
    % Inputs: none.  
    %
    % Outputs: sp - serial port object 
    %
    % Example:
    %    sp = BioSemiSerialPort(); % open serial port 
    %    sp.testTriggers; % test pins 1-8 
    %    sp.sendTrigger(5); % send trigger '5' to eeg system  
    %    sp.findSerialPortName(); % for troubleshoot if not connecting
    %    properly
    % Other m-files required: none
    % Subfunctions: none
    % MAT-files required: none
    % Toolboxes requires: instrument control toolbox 
    %
    % See also: instrhwinfo,instrreset,serial 
    
    % Version:  v1.0
    % Date:     Dec-19 2017, 10:00 AM PST
    % Author:   Roee Gilron, UCSF, SF, CA.
    % URL/Info: github.com/roeegilron/biosemitrigger
    
    properties
        sp
    end
    % The internal data implementation is not publicly exposed
    properties (Access = 'protected')
        props = containers.Map;
    end
    methods (Static = true)
        function portnames = getPortNames()
            % set serial port names for each os, may need modifcation
            portnames.mac = '/dev/cu.usbserial-DN17M98C';
            portnames.pc = 'COM3';
            portnames.linux = '/dev/cu.usbserial-DN17M98C';
        end
    end
    methods
        % Overload property names retrieval
        function names = properties(obj)
            names = fieldnames(obj);
        end
        % Overload clspass object display
        function disp(obj)
            disp([obj.props.keys', obj.props.values']);  % display as a cell-array
        end
        function obj = BioSemiSerialPort(~)
            sp = [];
            pnms = obj.getPortNames;
            % get serial port name(serial COM name different across OS's)
            if ismac % mac systems
                nameuse = pnms.mac;
            elseif ispc  % pc's
                nameuse = pnms.pc;
            end
            % clear any ports alraedy openeed 
            delete(instrfindall);
            % open serial port
            
            obj.sp = serial(nameuse,....
                'BaudRate',115200,...
                'DataBits',8,...
                'StopBits',1);
            fopen(obj.sp);
            if isvalid(obj.sp)
                fprintf('succesfully connected to serial port %s\n',obj.sp.Port);
            end
            
            
        end
    
        function testTriggers(obj)
            for i = 1:7
                fwrite(obj.sp,uint8(2^i))
                pause(0.2);
            end
        end
        function sendTrigger(obj,code)
            try
                fwrite(obj.sp,uint8(code))
                if code > 255
                    warning('This cable only supports triggers in the range of 1-255 (int) - 8 bits');
                end
            catch
                if ~isvalid(obj.sp) % calbe not connected
                    error('cable is not connected anymore / was disconneted. Please delete object and reconnect cable'); 
                end
            end
        end
    end
end