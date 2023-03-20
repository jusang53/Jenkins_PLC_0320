function uaObj = opcua(varargin)
%opcua Construct an OPC UA Client object
%   UaClient = opcua(ServerInfoObj) constructs an OPC UA client associated with the server referenced by OPC UA ServerInfo
%   object ServerInfoObj. You create ServerInfo objects by calling opcuaserverinfo.
%
%   UaClient = opcua(ServerUrl) constructs a client associated with the server referenced by the URL string
%   provided in ServerUrl. The Server URL must use the 'opc.tcp' protocol; http and/or https connections are not
%   supported in OPC Toolbox.
%
%   UaClient = opcua(Hostname, Portnum) constructs an OPC UA Client object associated with the server at port Portnum on
%   the machine identified by Hostname. Hostname is an IP address, or host name (short or fully qualified). The client
%   attempts to retrieve available endpoints, but will not error if the endpoints cannot be retrieved.
%
%   Some OPC UA servers require security for any connection to that server. OPC Toolbox currently supports only
%   anonymous, unsecured connections to servers.
%
%   Examples:
%   Create a client from the first server found on the local host.
%       sInfo = opcuaserverinfo('localhost');
%       uaClient = opcua(sInfo(1));
%   
%   Create a client for the server at port 51210 on the local host.
%       uaClient = opcua('localhost',51210);
%
%   See also: opcuaserverinfo, opc.ua.Client, opc.ua.Client/connect.

% Copyright 2015 The MathWorks, Inc.
% Developed by Opti-Num Solutions (Pty) Ltd

% This is a helper function to enable easy access to the OPC HDA Client
% constructor.
uaObj = opc.ua.Client(varargin{:});
end