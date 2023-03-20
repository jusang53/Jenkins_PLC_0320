function s = opcuaserverinfo(hostName)
%opcuaserverinfo Query a host for installed OPC UA servers
%   S = opcuaserverinfo(HostName) queries the host named HostName for the OPC UA
%   servers installed on that host. HostName can be a host name, or IP address expressed as a string.
%
%   S is returned as an OPC UA ServerInfo object, containing read-only properties Hostname,
%   Port, and Description.
%
%   You can construct an OPC UA Client directly from an OPC UA ServerInfo object
%   using the opcua function.
%
%   Examples: 
%   Find all available local servers.
%       localServers = opcuaserverinfo('localhost')
%   Construct an OPC UA Client from the first server found.
%       uaClient = opcua(localServers(1));
%
%   See also opcua, opc.ua.ServerInfo.

% Copyright 2015-2016 The MathWorks, Inc.
% Developed by Opti-Num Solutions (Pty) Ltd

narginchk(1, 1)
validateattributes(hostName, {'char','string'}, {}, 'opcuaserverinfo', 'hostName');

% Now hand off the coding to the class.
s = opc.ua.getServerInfo(char(hostName));
