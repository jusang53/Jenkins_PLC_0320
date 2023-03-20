classdef Client < matlab.mixin.SetGet
    %Client OPC Unified Architecture (UA) Client Class
    %   The OPC UA Client is used to connect to an OPC UA server, browse the server's name space, read and write data
    %       from and to the server.
    %
    %   OPC UA Client Properties:
    %       Hostname                - Server host name or IP address
    %       Port                    - TCP/IP port number to connect to server on
    %       Name                    - Server description
    %       Timeout                 - Time to wait for all operations on the server
    %       EndpointUrl             - URL to use for connection to the server
    %       Namespace               - Server namespace nodes
    %       UserData                - User-defined data to associate with the client
    %       MinSampleRate           - Minimum sample rate in seconds that the server can generally support
    %       AggregateFunctions      - List of aggregate functions supported by this server
    %       MaxHistoryValuesPerNode - Maximum history values returned per node in historical read operations
    %       MaxHistoryReadNodes     - Maximum number of nodes supported by historical read operations
    %       MaxReadNodes            - Maximum number of nodes supported per read operation
    %       MaxWriteNodes           - Maximum number of nodes supported per write operation
    %
    %   OPC UA Client Methods:
    %       connect                 - Connect client to server     
    %       disconnect              - Disconnect client from server
    %       isConnected             - Determine if client is connected to the server
    %       getServerStatus         - Retrieve status of server
    %       getNamespace            - Retrieve one level of the namespace from the server
    %       browseNamespace         - Graphically browse namespace and select nodes
    %       readValue               - Read current data values from the server
    %       readHistory             - Read historical data from the server
    %       readAtTime              - Read historical data at specified times from the server
    %       readProcessed           - Read processed (aggregated) data from the server
    %       writeValue              - Write current values to the server
    %       getNodeAttributes       - Retrieve node attributes
    %
    %   See also: opcua, opcuaserverinfo, opcuanode.
    
    % Copyright 2015 The MathWorks, Inc.
    % developed by Opti-Num Solutions (Pty) Ltd
    
    %% Properties
    properties
        %Hostname - A string containing the host name or IP address of the machine hosting the UA server.
        Hostname = ''; 
        %Port - The TCP/IP port number for the OPC UA server.
        Port = 4840;            
        %Name - The server name. The Name property is automatically set to the server description if the OPC UA Client
        %is created  from an OPC UA ServerInfo object. Otherwise a descriptive string is used to set the Name property.
        Name = '';
        %EndpointUrl - URL to use for connections to the server. You should not set this directly, unless your IT
        %administrator has disabled the Local Discovery Server on the server host.
        EndpointUrl = '';
        %UserData - A free-form container for user-defined data to associated with the client. You can set this property
        %to any MATLAB data you require for the client.
        UserData = [];
    end
    properties (Dependent)
        %Status - Connection status. This is initially set to 'Disconnected', and changes to 'Connected' when the OPC UA
        %Client successfully connects to the server. See also isConnected.
        Status;
        %ServerState - State of the OPC UA Server. The server state can be 'Running', 'Failed', 'No Configuration',
        %'Suspended', 'Shutdown', 'Test', 'Comms Fault', or 'Unknown'.
        ServerState;
        %Timeout - Time in seconds to wait for all operations on the server to complete. Note that the timeout property
        %is sent to the server, and may be ignored by some servers.
        Timeout;
    end
    properties (Dependent, SetAccess = protected, Hidden)
        MessageSecurityMode;    %The Message Security Mode to be used for connections.
        ChannelSecurityPolicy;  %The Channel Security Policy to be used for connections.
    end
    properties (Dependent, SetAccess = protected)
        %AggregateFunctions - A cell array of string describing available Aggregates supported by the server. You use
        %aggregates in the readProcessed function. Note that some nodes may support only a sub-set of available
        %Aggregates on a server. 
        %   See also readProcessed, opc.ua.AggregateFnId
        AggregateFunctions;
    end
    properties (SetAccess = protected, Hidden)
        AvailableEndpoints = [];%List of all available endpoints for the OPC UA server.
        ServerCertificate = []; %Server certificate to use for channel and message encryption.
    end        
    properties (SetAccess = protected)
        %Namespace - Root nodes of the OPC UA server namespace. This property is automatically populated when you
        %connect to the server. You browse the namespace using the Children property of the Namespace nodes, or using
        %getNamespace, browseNamespace, findNodeById or findNodeByName.
        %   See also getNamespace, browseNamespace, opc.ua.Node/findNodeById, opc.ua.Node/findNodeByName
        Namespace = [];         
        %MinSampleRate - The minimum sample rate in seconds that the server can generally support. Individual nodes on the server may override this value.
        MinSampleRate = 0;
        %MaxHistoryValuesPerNode - The maximum history values returned per node in historical read operations. If this
        %value is zero then the server has no published limit.
        MaxHistoryValuesPerNode = uint32(0);
        %MaxHistoryReadNodes - The maximum number of nodes supported by historical read operations. If this value is
        %zero then the server has no published limit.
        MaxHistoryReadNodes = uint32(0);
        %MaxReadNodes - The maximum number of nodes supported per readValue operation. If this value is zero then the
        %server has no published limit.
        MaxReadNodes = uint32(0);
        %MaxWriteNodes - The maximum number of nodes supported per writeValue operation. If this value is zero then the
        %server has no published limit.
        MaxWriteNodes = uint32(0);
    end
    properties (Access = private, Transient) % Internal use properties that are not saved
        ServerStateFlag = [];   % Exposed through ServerState property.
        AsyncChannel            % AsyncIO Channel object
        ClosedListener          % Listener on Channel Closed event
        DataAvailableListener   % Listener on Data Available event
        ServerErrorListener     % Listener on Server Error event
        CustomEventListener     % Listener on Custom events
        IsConnected = false;    % Connected status
        LastMessageTime = 0;    % Last time a message was sent from the client
        AggregatesSupported = opc.ua.Node.empty;  % Aggregates supported by the server.
    end
    properties (Access = private)
        TimeoutMS = uint32(10000);   % Internal timeout value in milliseconds
        MessageSecurityModeEnum = uint8(0);     % Message security mode enum
        ChannelSecurityPolicyEnum = uint8(0);   % Channel security policy enum
        ClientId = uint32(0);                   % Unique ID for a running client in this session of MATLAB
        TraceEnabled = false;                   % Trace state for async channel.
    end
    
    %% Getters and Setters
    methods 
        function statusStr = get.Status(this)
            %get.Status Return Status property
            if this.IsConnected
                statusStr = 'Connected';
            else
                statusStr = 'Disconnected';
            end
        end
        function stateStr = get.ServerState(this)
            %get.ServerState Return ServerState property
            if ~this.IsConnected || isempty(this.ServerStateFlag)
                stateStr = '<Not connected>';
            else
                stateStr = getUaServerStateString(this.ServerStateFlag);
            end
        end
        function modeStr = get.MessageSecurityMode(this)
            %get.MessageSecurityMode Return MessageSecurityMode property
            modeStr = getMessageSecurityModeString(this.MessageSecurityModeEnum);
        end
        function policyStr = get.ChannelSecurityPolicy(this)
            %get.ChannelSecurityPolicy Return ChannelSecurityPolicy property
            policyStr = getChannelSecurityPolicyString(this.ChannelSecurityPolicyEnum);
        end
        function set.Hostname(this, newHost)
            %set.Hostname Set Hostname property
            
            % Property is RO while connected.
            throwErrorIfConnected(this, 'Hostname');
            validateattributes(newHost, {'char','string'}, {'row'}, 'opc.ua.Client/Hostname', 'Hostname')
            this.Hostname = char(newHost);
        end
        function set.Port(this, newPort)
            %set.Port Set Port property
            
            % Property is RO while connected
            throwErrorIfConnected(this, 'Port');
            % Check data type
            validateattributes(newPort, {'numeric'}, {'scalar', 'positive', 'integer'}, 'opc.ua.Client/Port', 'Port');
            this.Port = newPort;
        end
        function set.EndpointUrl(this, newUrl)
            %set.EndpointUrl Set EndpointUrl property
            
            % Property is RO while connected
            throwErrorIfConnected(this, 'EndpointUrl');
            % Confirm that there is a hostname and a port for the Url, but only if not empty.
            if isempty(newUrl)
                this.EndpointUrl = '';
            else
                validateattributes(newUrl, {'char','string'}, {'row'}, 'opc.ua.Client/EndpointUrl', 'EndpointUrl');
                [~, ~] = parseUrlHostnameAndPort(char(newUrl));
                this.EndpointUrl = char(newUrl);
            end
        end
        function set.MessageSecurityMode(this, newMode)
            %set.MessageScurityMode Set MessageSecurityMode property
            
            % Property is RO while connected
            throwErrorIfConnected(this, 'MessageSecurityMode');
            validateattributes(newMode, {'char', 'string'}, {'row'}, 'opc.ua.Client/MessageSecurityMode', 'Mode')
            allModes = {'None', 'Sign', 'SignAndEncrypt'};
            modeInd = find(strcmpi(newMode, allModes));
            if (numel(modeInd) ~= 1)
                error(message('opc:ua:Client:InvalidMessageMode', newMode));
            end 
            this.MessageSecurityModeEnum = modeInd;
        end
        function set.ChannelSecurityPolicy(this, newPolicy)
            %set.ChannelSecurityPolicy Set ChannelSecurityPolicy property
            
            % Property is RO while connected
            throwErrorIfConnected(this, 'ChannelSecurityPolicy');
            validateattributes(newPolicy, {'char','string'}, {'row'}, 'opc.ua.Client/ChannelSecurityPolicy', 'Policy')
            allPolicies = {'None', 'Basic128Rsa15', 'Basic256', 'Basic256Sha256'};
            policyInd = find(strcmpi(newPolicy, allPolicies));
            if (numel(policyInd) ~= 1)
                error(message('opc:ua:Client:InvalidChannelPolicy', newPolicy));
            end 
            this.ChannelSecurityPolicyEnum = policyInd;
        end
        function set.Timeout(this, newTimeout)
            %set.Timeout Set Timeout property
            validateattributes(newTimeout, {'numeric'}, {'scalar', 'real', 'positive'});
            if (newTimeout < 0.001)
                warning(message('opc:ua:Client:TimeoutTooSmall'));
                newTimeout = 0.001;
            end
            if isinf(newTimeout)
                this.TimeoutMS = intmax('uint32');
            else
                this.TimeoutMS = uint32(newTimeout*1000);
            end
            % Now if we are connected, pass this on to the device
            if this.IsConnected
                this.AsyncChannel.execute('SetTimeout', struct('Timeout', this.TimeoutMS));
            end
        end
        function timeout = get.Timeout(this)
            %get.Timeout Retrieve Timeout property
            if (this.TimeoutMS == intmax('uint32'))
                timeout = inf;
            else
                timeout = double(this.TimeoutMS)/1000;
            end
        end
        function aggregates = get.AggregateFunctions(this)
            %get.AggregateFunctions Retrieve AggregateFunctions property
            aggregates = {this.AggregatesSupported.Name}';
        end
    end 
    %% Constructor, desctructor, connect, disconnect, display methods
    methods 
        function this = Client(varargin)
            %opc.ua.Client Construct an OPC UA Client
            %   uaObj = opc.ua.Client(ServerInfoObj) constructs a client associated with the server referenced by OPC UA ServerInfo
            %   object ServerInfoObj. You create Server Info objects by calling opcuaserverinfo.
            %
            %   UaObj = opc.ua.Client(ServerUrl) constructs a client associated with the server referenced by the URL string
            %   provided in ServerUrl. The Server URL must use the 'opc.tcp' protocol; http and/or https connections are not
            %   supported in OPC Toolbox.
            %
            %   uaObj = opc.ua.Client(Hostname, Portnum) constructs an OPC UA Client object associated with the server at port
            %   Portnum on the machine identified by Hostname. Hostname is an IP address, or host name (short or fully qualified).
            %   The client attempts to retrieve available endpoints, but will not error if the endpoints cannot be retrieved.
            %
            %   Some OPC UA servers require security for any connection to that server. OPC Toolbox currently supports only
            %   anonymous, unsecured connections to servers.
            %
            %   Examples:
            %   Create a client from the first server found on the local host.
            %       sInfo = opcuaserverinfo('localhost');
            %       uaObj = opcua(sInfo(1));
            %
            %   Create a client for the server at port 51210 on the local host.
            %       uaObj = opcua('localhost',51210);
            %
            %   See also: opcuaserverinfo, opc.ua.Client, opc.ua.Client/connect.
            
            %Ensure Connector is running - see g1733221
            connector.ensureServiceOn;
            
            % Argument checking
            switch nargin
                case 0
                    % Do nothing, but allow this to be legal
                    mustGetEndpoints = false;
                case 1
                    if isa(varargin{1}, 'opc.ua.ServerInfo')
                        % Unpack the ServerInfo into the Client properties
                        siObj = varargin{1};
                        mustGetEndpoints = false;
                        if isempty(siObj)
                            % Error with "ServerInfo object is empty"
                            error(message('opc:General:EmptyArgument', 'ServerInfoObj'));
                        else
                            for k=numel(siObj):-1:1
                                this(k).AvailableEndpoints = siObj(k).Endpoints;
                                this(k).Hostname = siObj(k).Hostname;
                                this(k).Port = siObj(k).Port;
                                % We have to update the channel security and message security based on endpoints.
                                [msgMode, channelPolicyEnum, serverCertificate, endpointUrl] = getBestSecurityConfig(siObj(k).Endpoints);
                                this(k).MessageSecurityModeEnum = msgMode;
                                this(k).ChannelSecurityPolicyEnum = channelPolicyEnum;
                                this(k).ServerCertificate = serverCertificate;
                                this(k).EndpointUrl = endpointUrl;
                                this(k).Name = siObj(k).Description;
                            end
                        end
                    elseif ischar(varargin{1}) || iscellstr(varargin{1}) || isstring(varargin{1}) % ServerUrl option
                        % Parse the URL(s) to find the hostname and port
                        serverUrl = varargin{1};
                        if isempty(serverUrl)
                            error(message('opc:General:EmptyArgument', 'ServerUrl'));
                        end
                        if isstring(serverUrl)
                            serverUrl = cellstr(serverUrl);
                        end
                        if ischar(serverUrl)
                            serverUrl = {serverUrl};
                        end
                        for k=numel(serverUrl):-1:1
                            urlParts = regexp(serverUrl{k}, 'opc.tcp://(?<Hostname>[^:]+):(?<Port>[0-9]+)/','names');
                            if (numel(urlParts) ~= 1) || isempty(urlParts.Hostname) || isempty(urlParts.Port)
                                error(message('opc:ua:Client:ServerUrlInvalid'));
                            end
                            this(k).Hostname = urlParts.Hostname;
                            this(k).Port = str2double(urlParts.Port);
                            this(k).EndpointUrl = serverUrl{k};
                        end
                        mustGetEndpoints = true;
                    else
                        error(message('opc:ua:Client:InvalidConstructorArgs'));
                    end
                case 2 % Hostname and Port. Fetch endpoints automatically.
                    % Check the parameter types
                    [hostName, portNum] = varargin{1:2};
                    validateattributes(hostName, {'char','string'}, {'row'});
                    validateattributes(portNum, {'numeric'}, {'positive', 'integer','scalar'});
                    this.Hostname = char(hostName);
                    this.Port = portNum;
                    mustGetEndpoints = true;
                case 4 % EndpointURL, MessageSecurityMode, ChannelSecurityPolicy, ServerCertificate. Do not fetch Endpoints.
                    [endpointUrl, messageSecurityMode, channelSecurityPolicy, serverCertificate] = varargin{1:4};
                    validateattributes(endpointUrl, {'char','string'}, {'row'}, 'opc.ua.Client', 'EndpointUrl');
                    validateattributes(messageSecurityMode, {'char','string'}, {'row'}, 'opc.ua.Client', 'MessageSecurityMode');
                    validateattributes(channelSecurityPolicy, {'char','string'}, {'row'}, 'opc.ua.Client', 'EndpointUrl');
                    validateattributes(serverCertificate, {'uint8'}, {'row'}, 'opc.ua.Client', 'ServerCertificate');
                    endpointUrl = char(endpointUrl);
                    messageSecurityMode = char(messageSecurityMode);
                    channelSecurityPolicy = char(channelSecurityPolicy);
                    % Parse the hostname and port number from the endpoint url
                    [hostName, portNum] = parseUrlHostnameAndPort(endpointUrl);
                    this.EndpointUrl = endpointUrl;
                    this.MessageSecurityMode = messageSecurityMode;
                    this.ChannelSecurityPolicy = channelSecurityPolicy;
                    this.ServerCertificate = serverCertificate;
                    this.Hostname = hostName;
                    this.Port = portNum;
                    this.Name = sprintf('OPC UA Server on host %s at port %d', hostName, portNum);
                    mustGetEndpoints = false;
                otherwise
                    % Three input arguments. Invalid.
                    error(message('opc:ua:Client:InvalidConstructorArgs'));
            end
            if mustGetEndpoints
                try %#ok<TRYNC> % If this fails because endpoints could not be found, do nothing at this time.
                    this.fetchEndpoints;
                    % We have to update the channel security and message security based on endpoints.
                    [msgMode, channelPolicyEnum, serverCertificate, endpointUrl] = getBestSecurityConfig(this.AvailableEndpoints);
                    this.MessageSecurityModeEnum = msgMode;
                    this.ChannelSecurityPolicyEnum = channelPolicyEnum;
                    this.ServerCertificate = serverCertificate;
                    this.EndpointUrl = endpointUrl;
                end

                % We assume that all endpoints are identical If no endpoints, use a general name
                if isempty(this.AvailableEndpoints)
                    this.Name = sprintf('OPC UA Server at %s on port %d', this.Hostname, this.Port);
                else
                    this.Name = this.AvailableEndpoints(1).ApplicationName;
                end
            end
            % Assign a client Id to each of the clients
            for k=1:numel(this)
                this(k).ClientId = opc.ua.Client.getUniqueId; %#ok<AGROW>
            end
        end
        function delete(this)
            %delete Delete OPC UA Client from memory
            for k=1:numel(this)
                if this(k).IsConnected
                    disconnect(this(k));
                end
            end
            notify(this, 'Deleting');
        end
        function connect(this, varargin)
            %connect Connect OPC UA Client to Server
            %   connect(UaClient) connects the OPC UA Client UaObj to its server using anonymous user authentication.
            %
            %   OPC Toolbox supports only unsecured connections.
            %
            %   When the client successfully connects to the server, the Status property of UaClient is set to 'Connected', the
            %   first level of the server's namespace is retrieved, and various essential properties are read from the server. 
            %
            %   If UaClient is a vector of clients and some clients can connect but some cannot, a warning is issued. If no clients
            %   can be connected, an error is generated.
            %
            %   Example: Create a client for a local server and connect to the client.
            %       s = opcuaserverinfo('localhost');
            %       uaClient = opcua(s(1));
            %       connect(uaClient)
            %   Check connection status.
            %       disp(uaClient.Status)
            %       isConnected(uaClient)
            %
            %   See also disconnect, isConnected, opc.ua.Client/Status
            
            narginchk(1,1);
            if numel(this)==0
                error(message('opc:General:EmptyObject', 'Client'));
            end
            oneSucceeded = false;
            oneFailed = false;
            combinedMsg = '';
            for tI = 1:numel(this)
                clnt = this(tI);
                try
                    if ~clnt.IsConnected
                        % If we have no endpoints, attempt to retrieve them. If we fail, error as we don't have one.
                        if isempty(clnt.EndpointUrl)
                            % The user hasn't specified the endpoint URL. Fetch the available ones
                            errorCode = clnt.fetchEndpoints;
                            % If we couldn't connect, figure out why.
                            if getUaMessageSeverity(errorCode) == 2
                                % Error: We don't know the EndpointUrl for the server
                                errMsg = message(getUaMessageId(errorCode));
                                error(message('opc:ua:Client:ConnectEmptyUrl', errMsg.getString));
                            end
                        end
                        % What type of connection is being attempted?
                        switch nargin
                            case 1
                                authMask = uint8(1); % Anonymous
                                authStr = 'anonymous';
                            case 2
                                authMask = uint8(4); % Certificate
                                authStr = 'certificate';
                            case 3
                                authMask = uint8(2); % Username/password
                                authStr = 'username';
                        end
                        % Check the current configuration
                        if (clnt.MessageSecurityModeEnum == 0) || (clnt.ChannelSecurityPolicyEnum == 0) && ~isempty(this.AvailableEndpoints)
                            [msgMode, channelPolicyEnum, serverCertificate, endpointUrl] = getBestSecurityConfig(this.AvailableEndpoints);
                            this.MessageSecurityModeEnum = msgMode;
                            this.ChannelSecurityPolicyEnum = channelPolicyEnum;
                            this.ServerCertificate = serverCertificate;
                            this.EndpointUrl = endpointUrl;
                        end
                        % Now check if we can find an endpoint with this configuration
                        epInd = clnt.findMatchingEndpoint(authMask, clnt.MessageSecurityModeEnum, clnt.ChannelSecurityPolicyEnum);
                        if ~isempty(epInd)
                            % We found an endpoint matching our requirements. Get that information for the connection
                            options = clnt.AvailableEndpoints(epInd);
                        else
                            if ~isempty(clnt.AvailableEndpoints) && (clnt.MessageSecurityModeEnum ~= 0) && (clnt.ChannelSecurityPolicyEnum ~= 0)
                                warning(message('opc:ua:General:EndpointMismatch', authStr));
                            end
                            % Just use the stuff we have stored in the client properties
                            options = struct('EndpointUrl', clnt.EndpointUrl, ...
                                'MessageSecurityModeNumber', clnt.MessageSecurityModeEnum, ...
                                'ChannelSecurityPolicy', sprintf('http://opcfoundation.org/UA/SecurityPolicy#%s', clnt.ChannelSecurityPolicy), ...
                                'ServerCertificate', clnt.ServerCertificate);
                        end
                        options.Timeout = clnt.TimeoutMS;
                        versionInfo = ver('MATLAB');
                        if ispc
                            machineName = getenv('computername');
                        else
                            machineName = getenv('hostname');
                        end
                        options.ProductName = sprintf('MATLAB %s', versionInfo.Version);
                        options.ClientName = sprintf('%s on %s [#%d]', options.ProductName, machineName, clnt.ClientId);
                        options.ProductUri = 'https://www.mathworks.com/matlab';
                        % We now have all the information we need. Construct the Channel
                        % Initialise channel.
                        clnt.AsyncChannel = opc.ua.Channel(options, [Inf,0]);
                        clnt.AsyncChannel.TraceEnabled = clnt.TraceEnabled;
                        % Register listener for close.
                        clnt.ClosedListener = addlistener(clnt.AsyncChannel, 'Closed',...
                            @(source,data) clnt.onClosed() );
                        
                        % Register listener for data available.
                        clnt.AsyncChannel.InputStream.flush(); % Flush the input stream first
                        clnt.DataAvailableListener = addlistener(clnt.AsyncChannel.InputStream, ...
                            'DataWritten', @(source,data) clnt.onDataAvailable() );
                        clnt.CustomEventListener = addlistener(clnt.AsyncChannel, 'Custom', ...
                            @(source, data) clnt.onCustomEvent(data.Type, data.Data));
                        
                        % Open Channel
                        clnt.AsyncChannel.open();
                        err = clnt.AsyncChannel.getSuccess();
                        if( getUaMessageSeverity(err)==2)
                            % We must back out of the client here.
                            delete(clnt.ClosedListener);
                            clnt.ClosedListener = [];
                            delete(clnt.DataAvailableListener);
                            clnt.DataAvailableListener = [];
                            clnt.AsyncChannel.close();
                            clnt.AsyncChannel.InputStream.flush();
                            delete(clnt.AsyncChannel);
                            clnt.AsyncChannel = [];
                            error(message(getUaMessageId(err)));
                        end
                        clnt.IsConnected = true;

                        % Fetch the namespace of the root
                        clnt.getNamespace();
                        % Retrieve server capabilities
                        clnt.populateCapabilities();
                        
                        clnt.ServerStateFlag = 0;
                        % By now we have connected this client. One connect call succeeded.
                        oneSucceeded = true;
                    end
                catch opcExc
                    combinedMsg = sprintf('%s\t[%s] %s\n', combinedMsg, clnt.Name, opcExc.message);
                    if ~isempty(this(tI).AsyncChannel)
                        % Unregister listeners silently.
                        if ~isempty(this(tI).ClosedListener)
                            delete(this(tI).ClosedListener);
                            this(tI).ClosedListener = [];
                        end
                        if ~isempty(this(tI).DataAvailableListener)
                            delete(this(tI).DataAvailableListener);
                            this(tI).DataAvailableListener = [];
                        end
                        % Now close and remove the channel.
                        this(tI).AsyncChannel.close();
                        this(tI).AsyncChannel.InputStream.flush();
                        delete(this(tI).AsyncChannel);
                        this(tI).AsyncChannel = [];
                    end
                    oneFailed = true;
                end
            end
            if oneFailed
                if numel(this)==1
                    rethrow(opcExc);
                else
                    if ~oneSucceeded
                        throwAsCaller(MException(message('opc:ua:Client:ConnectFailed', combinedMsg)));
                    else
                        warning(message('opc:ua:Client:ConnectFailed', combinedMsg));
                    end
                end
            end
        end
        function disconnect(this)
            %disconnect Disconnect OPC UA Client from the server
            %   disconnect(UaClient) disconnectes the OPC UA Client UaClient from its server. The Status property of UaClient is
            %   set to Disconnected.
            %   
            %   Example: Create a client for a local server and connect to the client.
            %       s = opcuaserverinfo('localhost');
            %       uaClient = opcua(s(1));
            %       connect(uaClient)
            %   Check connection status.
            %       disp(uaClient.Status)
            %       isConnected(uaClient)
            %   Disconnect from the server.
            %       disconnect(uaClient)
            %       disp(uaClient.Status)
            %       isConnected(uaClient)
            %
            %   See also: connect, isConnected, opc.ua.Client/Status
            for tI = 1:numel(this)
                % Close the Async Channel
                if ~isempty(this(tI).AsyncChannel)
                    this(tI).AsyncChannel.close();
                    this(tI).AsyncChannel.InputStream.flush();
                    % Unregister listeners.
                    if ~isempty(this(tI).CustomEventListener)
                        delete(this(tI).CustomEventListener);
                        this(tI).CustomEventListener = [];
                    end
                    if ~isempty(this(tI).ClosedListener)
                        delete(this(tI).ClosedListener);
                        this(tI).ClosedListener = [];
                    end
                    if ~isempty(this(tI).DataAvailableListener)
                        delete(this(tI).DataAvailableListener);
                        this(tI).DataAvailableListener = [];
                    end
                    delete(this(tI).AsyncChannel);
                    this(tI).AsyncChannel = [];
                end
                % Set connected status off
                this(tI).IsConnected = false;
            end
        end
        function tf = isConnected(this)
            %isConnected Determine if OPC UA client is connected to its server
            %   tf = isConnected(UaClient) returns true if the client UaClnt is connected to the server, or false otherwise. If UaClnt
            %   is a vector, tf is a vector representing the connected state of each client.
            %
            %   Example: Create OPC UA Clients for all local servers. Connect only to the first one.
            %       s = opcuaserverinfo('localhost');
            %       uaClient = opcua(s)
            %       connect(uaClient(1));
            %   Check connection status.
            %       isConnected(uaClient)
            %
            %   See also: opcua, connect, disconnect, opc.ua.Client/Status.
            tf = [this.IsConnected];
        end
        function errorCodeOut = fetchEndpoints(this)
            %fetchEndpoints Retrieve available endpoints from the Server's Discovery Service
            %   fetchEndpoints(UaClnt) attempts to retrieve the endpoint configuration from the Server Discovery Service at the URL
            %   specified by the EndpointUrl property of UaClnt. If the EndpointUrl is empty but the Hostname and Port are not, then
            %   the Url is constructed from those properties.
            %
            %   Note that you do not have to call this function directly, but may do so to discover Endpoints for a server.
            %
            %   See also opcuaserverinfo, opcua, connect
            this.throwErrorIfConnected('fetchEndpoints');
            if isempty(this.EndpointUrl)
                % Endpoint URL is empty. Try a Root connection to the port.
                if isempty(this.Hostname)
                    error(message('opc:ua:Client:PropertyEmpty', 'Hostname'));
                end
                if isempty(this.Port)
                    error(message('opc:ua:Client:PropertyEmpty', 'Port'));
                end
                discoveryUrl = sprintf('opc.tcp://%s:%d', this.Hostname, this.Port);
            else
                discoveryUrl = this.EndpointUrl;
            end
            % Call the findServer service on the server. This returns the server's unique URL
            [serverList, errorCode ]= opc.internal.opcuadiscoverymex('getServerList', discoveryUrl);
            if (getUaMessageSeverity(errorCode) == 2)
                error(message(getUaMessageId(errorCode)));
            end
            % Now there should be exactly one discoveryUrl
            discoveryUrl = serverList(1).DiscoveryUrl;
            [serverEndpoints, errorCode] = opc.internal.opcuadiscoverymex('getEndpointConfig', discoveryUrl);
            if (getUaMessageSeverity(errorCode) == 0)
                % We succeeded. Set the Available Endpoints
                this.AvailableEndpoints = serverEndpoints;
            end
            % Now only return the error code if requested
            if nargout>0
                errorCodeOut = errorCode;
            end
        end
        function disp(this)
            %disp Display OPC UA Clients
            isLoose = strcmpi(get(0,'FormatSpacing'),'loose');
            % Can we display hyperlinks?
            canHyperlink = feature('hotlinks');
            switch numel(this)
                case 0
                    fprintf('Empty OPC UA Client object.\n');
                case 1
                    this.dispScalar;
                otherwise
                    this.dispArray;
            end
            % Show the methods link
            if canHyperlink
                if isLoose
                    fprintf('\n');
                end
                disp('<a href="matlab:methods(opc.ua.Client)">Client functions</a>');
            end
        end
    end
    %% Browse, read, write methods
    methods 
        function nodeList = getNamespace(this, browseNode, forceRescan)
            %getNamespace Retrieve namespace of server associated with client
            %   Nodes = getNamespace(UaClient) retrieves the first layer of the namespace of the server associated with client
            %   object UaClient. The first layer is stored in the Namespace property of UaClient, and returned in Nodes.
            %
            %   Nodes = getNamespace(UaClient, BrowseNode) retrieves the single layer of sub-nodes contained in BrowseNode from the
            %   server associated with client object UaClient. The sub-nodes are stored in the Children property of BrowseNode and
            %   are returned in Nodes.
            %
            %   This function may not need to retrieve nodes from the server. If the nodes already exist locally, they are returned
            %   automatically.
            %
            %   Nodes = getNamespace(..., '-force') retrieves the namespace from the server, even if the nodes already exist
            %   locally. Retrieved nodes are stored in the Children property of BrowseNode, or in the Namespace property of UaClient
            %   if BrowseNode is empty.
            %
            %   You do not necessarily need to call this function to browse the namespace. The server namespace is automatically
            %   retrieved when you query the Children property of a Node, or the Namespace property of a Client.
            %
            %   Example: Force retrieval of the first layer of sub-nodes in the Server node.
            %       uaClient = opcua('localhost', 51210);
            %       connect(uaClient);
            %       topNodes = uaClient.Namespace;
            %       serverNodes = getNamespace(uaClient, topNodes(1), '-force')
            %   Retrieve the children of the third element of serverNodes
            %       statusNodes = getNamespace(uaCLient, serverNodes(3))
            %
            %   See also opc.ua.Client/browseNameSpace, opc.ua.Client/Namespace
            narginchk(1,3);
            % Validate '-force' input
            if (nargin == 3) % Full syntax used. Check forceRescan
                validatestring(forceRescan, {'-force'}, 'getNamespace');
                mustRescan = true;
            elseif (nargin == 2) && ischar(browseNode) && strcmp(browseNode, '-force') % Client, '-force' option
                mustRescan = true;
                browseNode = [];
            else % -force argument not provided
                mustRescan = false;
            end
            if nargin<2 || isempty(browseNode)
                browseNode = [];
                browseArg = struct('NodeInfo', struct('IdType', uint32(0), ...
                'StringId', '', 'NumericId', uint32(85), ...
                'NamespaceIndex', uint32(0)));
                mustRescan = true;
            else
                if numel(browseNode)>1
                    error(message('opc:ua:Client:NodeIdMustBeScalar', 'getNamespace'));
                end
                if ~isa(browseNode, 'opc.ua.Node')
                    error(message('opc:ua:General:InvalidNodeArg'));
                end
                browseArg.NodeInfo = browseNode.getBrowseArg;
            end
            
            % Do we have to fetch from the server?
            if mustRescan
                % Call execute for Browse
                this.AsyncChannel.execute('Browse',browseArg);
                
                % Get browse results
                [err, res] = this.AsyncChannel.getBrowseResults();
                
                % If succcessful
                if (err == 0)
                    nodeList = opc.ua.Node(res, this, browseNode);
                    % Attach this to the Children property of the passed node
                    if nargin<2 || isempty(browseNode)
                        this.Namespace = nodeList;
                    else
                        setChildren(browseNode, nodeList);
                    end
                else
                    error(message(getUaMessageId(err)));
                end
            else
                % This operation may retrieve from the server anyway
                nodeList = browseNode.Children;
            end
        end
        function newNodeList = browseNamespace(this, nodeList)
            %browseNamespace Graphically browse namespace and select nodes from server
            %   NodeList = browseNamespace(UaClient) opens a graphical namespace browser for OPC UA Client object UaClient. Using
            %   the graphical interface, you can construct a list of nodes of interest, and return an array of those nodes in
            %   NodeList. You use NodeList to retrieve data for those items using read, readHistory, readProcessed, readAtTime, or
            %   readModified.
            %
            %   The name space is retrieved from the server incrementally, as needed. UaClient must be connected when you call this
            %   function.
            %
            %   NewNodeList = browseNamespace(UaClient, NodeList) allows you to specify an initial list of nodes to add to. If you
            %   Cancel the browsing (by pressing the Cancel button) then NewNodeList will be empty.
            %
            %   See also getNamespace, readValue, readHistory, readProcessed, readAtTime, writeValue, opc.ua.Node
            narginchk(1,2);
            this.throwErrorIfArray('browseNamespace');
            this.throwErrorIfNotConnected('browseNamespace');
            if nargin<2 || isempty(nodeList) % itmList may be '' or [], so force a cell.
                nodeList = opc.ua.Node.empty;
            elseif ~isa(nodeList, 'opc.ua.Node')
                error(message('opc:ua:Client:InvalidNodeList'));
            end
            newNodeList = opc.internal.UaNamespaceBrowser.create(this, nodeList);
        end
        function propVals = getNodeAttributes(this, nodeList, attributeIds)
            %getNodeAttributes Read server node attributes
            %   Values = getNodeAttributes(ClntObj, NodeList, AttributeIds) reads the attributes defined by AttributeIds from the
            %   nodes given by NodeList, from the server. NodeList must be an array of OPC UA Node objects. You create Node objects
            %   using getNamespace, browseNamespace, or opcuanode. AttributeIds can be an array of UInt32 values, or an array of
            %   cell strings or strings. Valid attributes are defined in opc.ua.AttributeId.
            %
            %   If NodeList is a single OPC UA Node, and AttributeIds is a single Attrbiute ID, then Values is the value of that
            %   attribute for that node. Otherwise, Values is returned as a structure array containing the fields given by the
            %   AttributeIds. If an Attribute cannot be read for a Node, the relevant field will be empty.
            %
            %   Example: Retrieve the DisplayName attribute from all sub-nodes of 'Boiler #1' starting with 'FTX' on a local server.
            %       uaClient = opcua('localhost', 51210);
            %       connect(uaClient);
            %       boilerNode = findNodeByName(uaClient.Namespace, 'Boiler #1', '-once');
            %       ftxNodes = findNodeByName(boilerNode, 'FTX', '-partial');
            %       dType = getNodeAttributes(uaClient, ftxNodes, 'DisplayName')
            %
            %   See also: getNamespace, browseNamespace, readValue, opc.ua.AttributeId.
            narginchk(3,3)
            this.throwErrorIfArray('getNodeAttributes');
            this.throwErrorIfNotConnected('getNodeAttributes');
            validateattributes(nodeList, {'opc.ua.Node'}, {}, 'getNodeAttributes', 'NodeList');
            % Convert attributeIds. Auto-generate, or numeric, or string or cell string converted.
            if isnumeric(attributeIds)
                attributeIds = uint32(attributeIds);
            else
                if ischar(attributeIds) || isstring(attributeIds)
                    attributeIds = cellstr(attributeIds);
                elseif ~iscellstr(attributeIds)
                    error(message('opc:ua:General:InvalidAttributeIdsArgument'));
                end
                % Convert strings to ids
                attribNumber = zeros(size(attributeIds), 'uint32');
                try
                    for k=1:numel(attributeIds)
                        attribNumber(k) = uint32(opc.ua.AttributeId.(attributeIds{k}));
                    end
                    attributeIds = attribNumber;
                catch opcExc
                    error(message('opc:ua:General:AttributeIdInvalid', attributeIds{k}));
                end
            end
            % Node check: Cannot be empty node
            throwErrorIfEmptyNode(nodeList);
            % If nodes have no client, set it
            emptyClient = cellfun(@isempty, {nodeList.Client});
            if any(emptyClient)
                setClient(nodeList(emptyClient), this);
            end
            % Build up the arguments structure
            attributeIds = attributeIds(:); % Force into a column vector.
            nodeList = nodeList(:)'; % Force into a row vector.
            attribCount = numel(attributeIds);
            nodeCount = numel(nodeList);
            nodeInfoOnce = nodeList.getBrowseArg;
            args.NodeInfo = reshape(repmat(nodeInfoOnce, attribCount, 1), 1, nodeCount * attribCount);
            args.AttributeId = reshape(repmat(attributeIds, 1, nodeCount), 1, nodeCount * attribCount);
            % Execute the synchronous instruction
            this.AsyncChannel.execute('GetProperties',args);
            % Get the results
            [err, res]=this.AsyncChannel.getReadResults();
            
            % If succcessful
            if (err == 0)
                propVals = parseAttributes(nodeList, attributeIds, res);
            else
                error(message(getUaMessageId(err)));
            end            
        end
        function status = getServerStatus(this)
            %getServerStatus Retrieve OPC UA server status
            %   Status = getServerStatus(UaClient) retrieves the status of the OPC UA server associated with UaClient.
            %   UaClient must be a single connected OPC UA Client.
            %
            %   Status is returned as a structure containing the following fields:
            %       StartTime           - Time the server was started (MATLAB datetime value)
            %       CurrentTime         - Current time on the server (MATLAB datetime value)
            %       State               - State of the server (string)
            %       BuildInfo           - A structure describing the build information for the server
            %       SecondsTillShutdown - If the server is shutting down, how long until shutdown occurs
            %       ShutdownReason      - The reason for the server shutting down, or an empty string
            %
            %   Example: FInd out when a local server was started.
            %       sInfo = opcuaserverinfo('localhost');
            %       uaClient = opcua(sInfo(1));
            %       connect(uaClient);
            %       status = getServerStatus(uaClient);
            %       disp(status.StartTime);
            %
            %   See also connect, disconnect
            throwErrorIfArray(this, 'getServerStatus');
            throwErrorIfNotConnected(this, 'getServerStatus');
            status = readValue(this, opcuanode(0, 2256));
        end
        function [v,t,q] = readValue(this, nodeList)
            %readValue Read current value from nodes on the server
            %   [Values, Timestamps, Qualities] = readValue(UaClient, NodeList) reads the value, quality, and timestamp from the
            %   nodes identified by NodeList, on the server associated with connected client UaClient. NodeList must be an array of
            %   OPC UA Node objects. You create OPC UA Node objects using getNamespace, browseNamespace, or opcuanode.
            %
            %   Values is returned as a cell array if multiple nodes are requested, or as the MATLAB equivalent data type of the
            %   returned Node's ValueType. For a list of how OPC UA Value Types are translated to MATLAB data types, see
            %   opc.ua.DataTypeIds.
            %
            %   Timestamps is returned as a vector of MATLAB datetime objects, representing the time that the source provided the
            %   data to the server.
            %
            %   Qualities is returned as an array of OPC UA Qualities. For information on OPC UA Qualities, see opc.ua.QualityId.
            %
            %   You cannot read data from Object type nodes. If you pass an Object node to read, the value will be returned as an
            %   empty array, and the Quality will be set to Bad:AttributeIdInvalid.
            %
            %   Example: Read the current value from all nodes named 'DoubleValue' from a local server.
            %       uaClient = opcua('localhost', 51210); 
            %       connect(uaClient); 
            %       dblNodes = findNodeByName(uaClient.Namespace, 'DoubleValue'); 
            %       [val, ts, qual] = readValue(uaClient, dblNodes)
            %
            %   See also: writeValue, getNodeAttributes, opc.ua.DataTypeId, opc.ua.QualityId.
            narginchk(2,2)
            if ~isa(nodeList, 'opc.ua.Node')
                error(message('opc:ua:General:InvalidNodeArg'));
            end
            % Error if not connected, or not a scalar
            throwErrorIfArray(this, 'readValue');
            throwErrorIfNotConnected(this);
            % Node check: Cannot be empty node
            throwErrorIfEmptyNode(nodeList);
            % If nodes have no client, set it
            emptyClient = cellfun(@isempty, {nodeList.Client});
            if any(emptyClient)
                setClient(nodeList(emptyClient), this);
            end
            % Now error if any node is still classified as Unknown type
            throwErrorIfNodeUnknown(nodeList, 'readValue');
            % Build up the arguments structure
            args.NodeInfo = nodeList.getBrowseArg;
            % Execute the synchronous instruction
            this.AsyncChannel.execute('Read', args);
            % Get the results
            [err, res]=this.AsyncChannel.getReadResults();
            
            % If successful
            if (err == 0)
                if numel(nodeList)==1
                    v = translateValueFromUa(res.Value, nodeList.ServerDataType);
                    q = opc.ua.QualityId(res.Quality);
                    t = opcUaDateTime2datetime(res.TimeStamp);
                else
                    % Value needs to be translated one at a time, so call in a loop
                    v = cell(numel(res),1);
                    for k=1:numel(res)
                        v{k} = translateValueFromUa(res(k).Value, nodeList(k).ServerDataType);
                    end
                    if nargout>1
                        t = opcUaDateTime2datetime([res.TimeStamp]');
                    end
                    if nargout > 2
                        q = opc.ua.QualityId([res.Quality]');
                    end
                end
            else
                error(message(getUaMessageId(err)));
            end            
        end
        function dataObj = readHistory(this, nodeList, startTime, endTime, boundsFlag)
            %readHistory Read stored historical data from nodes of an OPC UA Server
            %   OpcData = readHistory(UaClient, NodeList, StartTime, EndTime) reads stored historical data from the nodes given by
            %   NodeList, with a Source Timestamp between StartTime (inclusive) and EndTime (exclusive). StartTime and EndTime can
            %   be MATLAB datetime variables or date numbers. NodeList must be an array of OPC UA Node objects. You create OPC UA
            %   Node objects using getNamespace, browseNamespace, or opcuanode.
            %
            %   OpcData = readHistory(UaClient, NodeList, StartTime, EndTime, ReturnBounds) allows you to specify whether you want
            %   the returned data to include Bounding Values. Bounding Values are the values immediately outside the time range
            %   requested (the first value just before StartTime, or the first value after EndTime) when a value does not exist
            %   exactly on the boundary of the time range. Setting ReturnBounds to true returns Bounding Values; setting
            %   ReturnBounds to false (the default) returns values strictly within the start and end times.
            %
            %   OpcData is returned as a vector of OPC UA Data objects. Note that if readHistory fails to retrieve history for a
            %   given node, that node will not appear in the returned OPC UA Data object and a warning will be issued. If all
            %   requested nodes fail, an error is generated.
            %
            %   OPC UA Servers provide historical data only from nodes of type Variable. If you attempt to read values from an
            %   Object node, no data is returned for that node, and the status for that node is set to Bad:AttributeNotSupported, a
            %   warning is issued, and the node is not included in the output.
            %
            %   Example: Retrieve history for the current day from a local server.
            %       uaClient = opcua('localhost', 62550); 
            %       connect(uaClient); 
            %       nodeId = '1:Quickstarts.HistoricalAccessServer.Data.Dynamic.Double.txt'; 
            %       nodeList = opcuanode(2, nodeId, uaClient); 
            %       dataObj = readHistory(uaClient, nodeList, datetime('today'), datetime('now'));
            %
            %   See also readValue, readAtTime, readProcessed, opc.ua.Data, opcuanode
            narginchk(4,5);
            if nargin < 5
                % Could be returnFormat
                boundsFlag = false;
            else
                validateattributes(boundsFlag, {'logical'}, {'scalar'}, 'readHistory', 'BoundsFlag');
            end
            if ~isa(nodeList, 'opc.ua.Node')
                error(message('opc:ua:General:InvalidNodeArg'));
            end
            % Error if not connected, or not a scalar
            throwErrorIfArray(this, 'readHistory');
            throwErrorIfNotConnected(this);
            % Node check: Cannot be empty node
            throwErrorIfEmptyNode(nodeList);
            % If nodes have no client, set it
            emptyClient = cellfun(@isempty, {nodeList.Client});
            if any(emptyClient)
                setClient(nodeList(emptyClient), this);
            end
            % Now error if any node is still classified as Unknown type
            checkNodeIsUsable(nodeList, 'readHistory');
            [startTime, endTime] = validateStartAndEndTime(startTime, endTime);
            
            % Build up the arguments structure
            args.NodeInfo = nodeList.getBrowseArg;
            args.StartTime = makeUaDateTime(startTime);
            args.EndTime = makeUaDateTime(endTime);
            args.BoundsFlag = boundsFlag;
            % Execute the synchronous instruction
            this.AsyncChannel.execute('HistoryReadRaw',args);
            % Get the results
            [status, results] = this.AsyncChannel.getHistoryReadResults();
            if (status==0)
                % Construct an OPC UA Data object, and throw warnings or errors
                nodeStatus = [results.NodeStatus];
                hasNoData = false(size(results));
                for k=1:numel(results)
                    hasNoData(k) = (numel(results(k).Value) == 0);
                end
                failedNodes = (getUaMessageSeverity(nodeStatus) == 2) | hasNoData;
                if any(failedNodes)
                    % Construct the error string and pass off to warning/error handler
                    msg = constructNodeResultsMessage(nodeList(failedNodes), [results(failedNodes).NodeStatus]);
                    if all(failedNodes)
                        error(message('opc:ua:Client:OperationFailed', 'readHistory', msg));
                    else
                        warning(message('opc:ua:Client:OperationFailed', 'readHistory', msg));
                    end
                end
                % Strip out the failed nodes
                results(failedNodes) = [];
                successfulNodes = nodeList(~failedNodes);
                if isempty(successfulNodes)
                    dataObj = opc.ua.Data.empty;
                else
                    for k = numel(results):-1:1
                        data(k).Name = successfulNodes(k).Name;
                        data(k).Timestamp = opcUaDateTime2datetime(results(k).SourceTimeStamp);
                        data(k).Quality = opc.ua.QualityId(results(k).Quality, true);
                        data(k).Value = translateValueFromUa(results(k).Value, successfulNodes(k).ServerDataType);
                    end
                    dataObj = opc.ua.Data(data);
                end
            else
                error(message(getUaMessageId(status)));
            end
        end
        function dataObj = readAtTime(this, nodeList, timeVector)
            %readAtTime Read historical data from nodes of an OPC UA Server at specific times
            %   OpcData = readAtTime(UaClient, NodeList, TimeVector) reads stored historical data from the nodes given by NodeList,
            %   at the specified times in TimeVector. TimeVector can an array of MATLAB datetimes or date numbers. NodeList must be
            %   an array of OPC UA Node objects. You create OPC UA Node objects using getNamespace, browseNamespace, or opcuanode.
            %
            %   OpcData is returned as a vector of OPC UA Data objects. The server will interpolate or extrapolate data if it is not
            %   stored at the times specified in TimeVector; Data Quality will be set appropriately for interpolated data. If
            %   readHistory fails to retrieve history for a given node, that node will not appear in the returned OPC UA Data object
            %   and a warning will be issued. If all requested nodes fail, an error is generated.
            %
            %   OPC UA Servers provide historical data only from nodes of type Variable. If you attempt to read values from an
            %   Object node, no data is returned for that node, and the status for that node is set to Bad:AttributeNotSupported, a
            %   warning is issued, and the node is not included in the returned output.
            %
            %   Example: Retrieve 10 minute sampled history for the current day from a local server.
            %       uaClient = opcua('localhost', 62550);
            %       connect(uaClient);
            %       nodeId = '1:Quickstarts.HistoricalAccessServer.Data.Dynamic.Double.txt';
            %       nodeList = opcuanode(2, nodeId, uaClient);
            %       dataObj = readAtTime(uaClient, nodeList, datetime('today'):minutes(10):datetime('now'));
            %
            %   See also readValue, readHistory, readProcessed, opc.ua.Data, opcuanode
            narginchk(3,3);
            % Error if not connected, or not a scalar
            throwErrorIfArray(this, 'readAtTime');
            throwErrorIfNotConnected(this);
            if ~isa(nodeList, 'opc.ua.Node')
                error(message('opc:ua:General:InvalidNodeArg'));
            end
            % Node check: Cannot be empty node
            throwErrorIfEmptyNode(nodeList);
            % If nodes have no client, set it
            emptyClient = cellfun(@isempty, {nodeList.Client});
            if any(emptyClient)
                setClient(nodeList(emptyClient), this);
            end
            % Now error if any node is still classified as Unknown type
            throwErrorIfNodeUnknown(nodeList, 'readAtTime');
            % timeVector will be validated by makeUaDateTime
            
            % Build up the arguments structure
            args.NodeInfo = nodeList.getBrowseArg;
            args.TimesRequested = makeUaDateTime(timeVector);
            args.UseSimpleBounds = false;
            % Execute the synchronous instruction
            this.AsyncChannel.execute('HistoryReadAtTime',args);
            % Get the results
            [status, results] = this.AsyncChannel.getHistoryReadResults();
            if (status==0)
                % Construct an OPC UA Data object, and throw warnings or errors for failed or empty data.
                nodeStatus = [results.NodeStatus];
                hasNoData = false(size(results));
                for k=1:numel(results)
                    hasNoData(k) = (numel(results(k).Value) == 0);
                end
                failedNodes = (getUaMessageSeverity(nodeStatus) == 2) | hasNoData;
                if any(failedNodes)
                    % Construct the error string and pass off to warning/error handler
                    msg = constructNodeResultsMessage(nodeList(failedNodes), [results(failedNodes).NodeStatus]);
                    if all(failedNodes)
                        error(message('opc:ua:Client:OperationFailed', 'readAtTime', msg));
                    else
                        warning(message('opc:ua:Client:OperationFailed', 'readAtTime', msg));
                    end
                end
                % Strip out the failed nodes
                results(failedNodes) = [];
                successfulNodes = nodeList(~failedNodes);
                % Build the Data object
                for k=numel(results):-1:1
                    data(k).Name = successfulNodes(k).Name;
                    data(k).Timestamp = opcUaDateTime2datetime(results(k).SourceTimeStamp);
                    data(k).Quality = opc.ua.QualityId(results(k).Quality, true);
                    data(k).Value = translateValueFromUa(results(k).Value, successfulNodes(k).ServerDataType);
                end
                dataObj = opc.ua.Data(data);
            else
                error(message(getUaMessageId(status)));
            end
        end
        function dataObj = readProcessed(this, nodeList, aggregateStr, aggregateInterval, startTime, endTime)
            %readProcessed Read processed (aggregate) data from nodes of an OPC UA Server
            %   OpcData = readProcessed(UaClient, NodeList, AggregateFn, AggrInterval, StartTime, EndTime) reads processed
            %   historical data from the nodes given by NodeList. NodeList must be an array of OPC UA Node objects. You create OPC
            %   UA Node objects using getNamespace, browseNamespace, or opcuanode.
            %
            %   The interval between StartTime and EndTime (which can be datetime variables or date numbers) is split into intervals
            %   of AggrInterval, a MATLAB duration variable, or a double representing the interval seconds. For each interval of
            %   time, the server calculates a processed value based on the AggregateFn requested. AggregateFn can be specified as a
            %   string or as an AggregateFnId object. A Client stores the available Aggregates for a server in the
            %   AggregateFunctions property. For a description of Aggregate functions, see opc.ua.AggregateFnId.
            %
            %   OpcData is returned as a vector of OPC UA Data objects. Note that if readProcessed fails to retrieve history for a
            %   given node, that node will not appear in the returned OPC UA Data object and a warning will be issued. If all
            %   requested nodes fail, an error is generated.
            %
            %   OPC UA Servers provide historical data only from nodes of type Variable. If you attempt to read values from an
            %   Object node, no data is returned for that node, and the status for that node is set to Bad:AttributeNotSupported, a
            %   warning is issued, and the node is not included in the returned OpcData object.
            %
            %   Example: Retrieve the average value for each 10 minute interval of the current day from a local server.
            %       uaClient = opcua('localhost', 62550);
            %       connect(uaClient);
            %       nodeId = '1:Quickstarts.HistoricalAccessServer.Data.Dynamic.Double.txt';
            %       nodeList = opcuanode(2, nodeId, uaClient);
            %       dataObj = readProcessed(uaClient, nodeList, 'Average', minutes(10), datetime('today'), datetime('now'));
            %
            %   See also readValue, readHistory, readAtTime, opc.ua.Data, opc.ua.AggregateFnId, opcuanode
            narginchk(6,6);
            % Error if not connected, or not a scalar
            throwErrorIfArray(this, 'readProcessed');
            throwErrorIfNotConnected(this);
            if ~isa(nodeList, 'opc.ua.Node')
                error(message('opc:ua:General:InvalidNodeArg'));
            end
            % Node check: Cannot be empty node
            throwErrorIfEmptyNode(nodeList);
            % If nodes have no client, set it
            emptyClient = cellfun(@isempty, {nodeList.Client});
            if any(emptyClient)
                setClient(nodeList(emptyClient), this);
            end
            % Now error if any node is still classified as Unknown type
            throwErrorIfNodeUnknown(nodeList, 'readProcessed');
            
            % Aggregate Type must be a string and known to server
            aggregateNode = checkAggregateType(this, aggregateStr);
            % AggregateInterval must be a double
            if isa(aggregateInterval, 'duration')
                aggregateInterval = seconds(aggregateInterval);
            end
            validateattributes(aggregateInterval, {'double'}, {'scalar', 'nonnegative'}, 'readProcessed', 'aggregateInterval');
            [startTime, endTime] = validateStartAndEndTime(startTime, endTime);

            % Build up the arguments structure
            args.NodeInfo = nodeList.getBrowseArg;
            args.AggregateNode = aggregateNode.getBrowseArg;
            args.ProcessingInterval = aggregateInterval * 1e3; % Convert seconds to milliseconds
            args.StartTime = makeUaDateTime(startTime);
            args.EndTime = makeUaDateTime(endTime);
            
            % Execute the synchronous instruction
            this.AsyncChannel.execute('HistoryReadProcessed',args);
            % Get the results
            [status, results] = this.AsyncChannel.getHistoryReadResults();
            if (status==0)
                % Construct an OPC UA Data object, and throw warnings or errors
                nodeStatus = [results.NodeStatus];
                hasNoData = false(size(results));
                for k=1:numel(results)
                    hasNoData(k) = (numel(results(k).Value) == 0);
                end
                failedNodes = (getUaMessageSeverity(nodeStatus) == 2) | hasNoData;
                if any(failedNodes)
                    % Construct the error string and pass off to warning/error handler
                    msg = constructNodeResultsMessage(nodeList(failedNodes), [results(failedNodes).NodeStatus]);
                    if all(failedNodes)
                        error(message('opc:ua:Client:OperationFailed', 'readProcessed', msg));
                    else
                        warning(message('opc:ua:Client:OperationFailed', 'readProcessed', msg));
                    end
                end
                % Strip out the failed nodes
                results(failedNodes) = [];
                successfulNodes = nodeList(~failedNodes);
                % Build the Data object
                for k=numel(results):-1:1
                    data(k).Name = successfulNodes(k).Name;
                    data(k).Timestamp = opcUaDateTime2datetime(results(k).SourceTimeStamp);
                    data(k).Quality = opc.ua.QualityId(results(k).Quality, true);
                    data(k).Value = translateValueFromUa(results(k).Value, successfulNodes(k).ServerDataType);
                end
                dataObj = opc.ua.Data(data);
            else
                error(message(getUaMessageId(status)));
            end
        end
        function writeValue(this, nodeList, vals)
            %writeValue Write values to nodes on an OPC UA server
            %   writeValue(UaClient, NodeList, Vals) writes values in Vals, to the nodes given by NodeList. NodeList must be an
            %   array of OPC UA Node objects. You create OPC UA Node objects using getNamespace, browseNamespace, or opcuanode.
            %
            %   If NodeList is a single Node, then Vals is the value to be written to the node. If NodeList is an array
            %   of nodes, then Vals must be a cell array the same size as NodeList, and each element of the cell array
            %   is written to the corresponding element of NodeList.
            %
            %   The data type of the value you are writing does not need to match the Node's ServerDataType property. All
            %   values are automatically converted to the Node's ServerDataType before writing to the server. However, a
            %   warning or error is generated if the data type conversion fails. For DateTime data types, you can
            %   pass a MATLAB datetime or a number; any numeric value will be be interpreted as a MATLAB date number.
            %
            %   You can only write scalar data to nodes that have a numeric ServerDataType.
            %
            %   Example: Write a new value to the Static DoubleValue node on a local server.
            %       uaClient = opcua('localhost', 51210); 
            %       connect(uaClient); 
            %       staticNode = findNodeByName(uaClient.Namespace, 'Static', '-once');
            %       scalarNode = findNodeByName(staticNode, 'Scalar', '-once');
            %       dblNode = findNodeByName(staticNode, 'DoubleValue'); 
            %       writeValue(uaClient, dblNode, 3.14159)
            %       [newVal, newTS] = readValue(uaClient, dblNode)
            %
            %   See also opc.ua.Client/readValue, opc.ua.Client/browseNamespace, opc.ua.Client/getNamespace, opcuanode.
            
            narginchk(3,3)
            % Error if not connected, or not a scalar
            throwErrorIfArray(this, 'writeValue');
            throwErrorIfNotConnected(this);
            % Validate the nodes argument
            if ~isa(nodeList, 'opc.ua.Node')
                error(message('opc:ua:General:InvalidNodeArg'));
            end
            % Node check: Cannot be empty node
            throwErrorIfEmptyNode(nodeList);
            % If nodes have no client, set it
            emptyClient = cellfun(@isempty, {nodeList.Client});
            if any(emptyClient)
                setClient(nodeList(emptyClient), this);
            end
            % Now error if any node is still classified as Unknown type
            throwErrorIfNodeUnknown(nodeList, 'readHistory');
            
            % Make sure that values is correct
            nodeCnt = numel(nodeList);
            if (nodeCnt == 1) 
                if ~iscell(vals) || iscellstr(vals)
                    vals = {vals};
                end
            end
            validateattributes(vals, {'cell'}, {'numel', numel(nodeList)}, 'writeValue', 'Vals');
            % Make sure numeric nodes only have scalar values
            numericTypes = {'Double', 'Float', 'Boolean', ...
                'SByte', 'Int16', 'Int32', 'Int64', ...
                'Byte', 'UInt16', 'UInt32', 'UInt64', ...
                'Number', 'UInteger', 'Integer', 'StatusCodeValue'};
            isNumericNode = ismember({nodeList.ServerDataType}, numericTypes);
            % Test only those values
            isArrayForNumericNode = cellfun(@(x)isnumeric(x)&&numel(x)>1, vals(isNumericNode));
            if any(isArrayForNumericNode)
                error(message('opc:ua:Client:WriteArrayNotSupported'));
            end

            % Build up the arguments structure
            args.NodeInfo = nodeList.getBrowseArg;
            args.DataValue = makeWriteDataValue(vals, nodeList);
            % Execute the synchronous instruction
            this.AsyncChannel.execute('Write', args);
            % Get the results
            [err, results]=this.AsyncChannel.getWriteResults();
            if (err ~= 0)
                error(message(getUaMessageId(err)));
            end
            % What about individual failures?
            failedNodes = (results ~= 0);
            if any(failedNodes)
                msg = constructNodeResultsMessage(nodeList(failedNodes), results(failedNodes));
                if all(failedNodes)
                    error(message('opc:ua:Client:OperationFailed', 'readProcessed', msg));
                else
                    warning(message('opc:ua:Client:OperationFailed', 'readProcessed', msg));
                end
            end
        end
    end
    %% Display methods
    methods (Access = private) 
        function dispScalar(this)
            %dispScalar Scalar display function
            if isvalid(this)
                % Can we display hyperlinks?
                isLoose = strcmpi(get(0,'FormatSpacing'),'loose');
                canHyperlink = feature('hotlinks');
                indent = 4;
                fprintf('OPC UA Client %s:\n', this.Name);
                propLen = length('MaxHistoryValuesPerNode')+2;    % Hard-coded longest prop.
                fprintf('%*s%s: %s\n', indent, ' ', ...
                    opc.internal.makePropHelp('opc.ua.Client/Hostname', propLen, canHyperlink), ...
                    this.Hostname);
                fprintf('%*s%s: %d\n', indent, ' ', ...
                    opc.internal.makePropHelp('opc.ua.Client/Port', propLen, canHyperlink), ...
                    this.Port);
                fprintf('%*s%s: %g\n', indent, ' ', ...
                    opc.internal.makePropHelp('opc.ua.Client/Timeout', propLen, canHyperlink), ...
                    this.Timeout);
                % blank line
                if isLoose
                    fprintf('\n');
                end
                fprintf('%*s%s: %s\n', indent, ' ', ...
                    opc.internal.makePropHelp('opc.ua.Client/Status', propLen, canHyperlink), ...
                    this.Status);
                if this.IsConnected
                    % blank line
                    if isLoose
                        fprintf('\n');
                    end
                    fprintf('%*s%s: %s\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Client/ServerState', propLen, canHyperlink), ...
                        this.ServerState);
                    if isLoose
                        fprintf('\n');
                    end
                    fprintf('%*s%s: %s\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Client/MinSampleRate', propLen, canHyperlink), ...
                        char(this.MinSampleRate));
                    fprintf('%*s%s: %d\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Client/MaxHistoryReadNodes', propLen, canHyperlink), ...
                        this.MaxHistoryReadNodes);
                    fprintf('%*s%s: %d\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Client/MaxHistoryValuesPerNode', propLen, canHyperlink), ...
                        this.MaxHistoryValuesPerNode);
                    fprintf('%*s%s: %d\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Client/MaxReadNodes', propLen, canHyperlink), ...
                        this.MaxReadNodes);
                    fprintf('%*s%s: %d\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Client/MaxWriteNodes', propLen, canHyperlink), ...
                        this.MaxWriteNodes);
                end
            end 
        end
        function dispArray(this)
            %dispArray Display arrays of OPC UA objects
            indent = 4;
            sizeStr = sprintf('%dx', size(this));
            fprintf('%s OPC UA Client array:\n', sizeStr(1:end-1));
            myTbl = internal.DispTable;
            myTbl.Indent = indent;
            myTbl.ColumnSeparator = '  ';
            myTbl.addColumn('index', 'center');
            myTbl.addColumn(internal.DispTable.helpLink('Name', ...
                'opc.ua.Client/Name'));
            myTbl.addColumn(internal.DispTable.helpLink('Hostname', ...
                'opc.ua.Client/Hostname'));
            myTbl.addColumn(internal.DispTable.helpLink('Port', ...
                'opc.ua.Client/Port'));
            myTbl.addColumn(internal.DispTable.helpLink('Timeout', ...
                'opc.ua.Client/Timeout'));
            myTbl.addColumn(internal.DispTable.helpLink('Status', ...
                'opc.ua.Client/Status'));
            myTbl.addColumn(internal.DispTable.helpLink('Server State', ...
                'opc.ua.Client/ServerState'));
            for k=1:numel(this)
                myTbl.addRow(k, this(k).Name, this(k).Hostname, this(k).Port, this(k).Timeout, this(k).Status, this(k).ServerState);
            end
            disp(myTbl);
        end
    end
    %% Helper methods
    methods(Access = private)
        function throwErrorIfArray(this, opStr)
            %throwErrorIfArray Error if passed object is not scalar
            if numel(this)>1
                throwAsCaller(MException(message('opc:ua:Client:ArrayNotSupported', opStr)));
            end                
        end
        function throwErrorIfConnected(this, propName)
            %throwErrorIfConnected Error if object is connected
            if ~isempty(this) && this.IsConnected
                throwAsCaller(MException(message('opc:ua:Client:ReadOnlyWhileConnected', propName)));
            end                
        end
        function throwErrorIfNotConnected(this, ~)
            %throwErrorIfNotConnected Error if object is not connected.
            msgObj = [];
            if isempty(this)
                msgObj = message('opc:General:EmptyObject', 'Client');
            elseif ~this.IsConnected
                msgObj = message('opc:ua:Client:NotConnected');
            end
            if ~isempty(msgObj)
                throwAsCaller(MException(msgObj));
            end
        end
        function epMatch = findMatchingEndpoint(this, authMask, msgModeEnum, channelPolicyEnum)
            %findMatchingEndpoint Identify endpoint matching a given authentication, message and channel security mode.
            %   epInd = findMatchingEndpoint(UaObj, AuthMask, MsgMode, ChannelPolicy)
            throwErrorIfArray(this);
            epMatch = [];
            epInd = 0;
            epCount = numel(this.AvailableEndpoints);
            while isempty(epMatch) && epInd < epCount
                epInd = epInd + 1;
                thisEP = this.AvailableEndpoints(epInd);
                if (bitand(thisEP.UserAuthTypes, authMask) > 0) && (thisEP.MessageSecurityModeNumber == msgModeEnum) && ...
                        (getUaChannelSecurityMode(thisEP.ChannelSecurityPolicy) == channelPolicyEnum)
                    epMatch = epInd;
                    break;
                end
            end
        end
        function populateCapabilities(this)
            %populateCapabilities Read server capabilities
            throwErrorIfNotConnected(this);
            throwErrorIfArray(this);
            % Find the capabilities node.
            serverNode = findNodeByName(this.Namespace, 'Server', '-once');
            capabilitiesNode = findNodeByName(serverNode, 'ServerCapabilities', '-once');
            try
                % We know that the MinSampleRate is a required node
                this.MinSampleRate = readValue(this, findNodeByName(capabilitiesNode, 'MinSupportedSampleRate', '-once'))./1000; % Convert from milliseconds to seconds
                % The OperationLimits node is optional, so these may fail.
                opLimitsNode = findNodeByName(capabilitiesNode, 'OperationLimits', '-once');
                if ~isempty(opLimitsNode)
                    this.MaxReadNodes = findAndReadNode(opLimitsNode, 'MaxNodesPerRead', uint32(0));
                    this.MaxWriteNodes = findAndReadNode(opLimitsNode, 'MaxNodesPerWrite', uint32(0));
                    this.MaxHistoryReadNodes = findAndReadNode(opLimitsNode, 'MaxNodesPerHistoryReadData', uint32(0));
                    this.MaxHistoryValuesPerNode = findAndReadNode(opLimitsNode, 'MaxReturnDataValues', uint32(0));
                end
                % AggregateFunctions are mandatory, but may be empty
                aggrFnsNode = findNodeByName(capabilitiesNode, 'AggregateFunctions', '-once');
                aggregates = aggrFnsNode.Children;
                if ~isempty(aggregates)
                    this.AggregatesSupported = aggregates;
                end
            catch opcExc
                warning(message('opc:ua:Client:CapabilitiesNotFound', opcExc.message));
            end
        end
        function aggrNode = checkAggregateType(this, aggrStr)
            %checkAggregateType Ensure that aggregate string is known to server
            hasAggr = strcmpi(aggrStr, this.AggregateFunctions);
            if ~any(hasAggr)
                error(message('opc:ua:Client:UnknownAggregateType', char(aggrStr)));
            end
            aggrNode = this.AggregatesSupported(hasAggr);
        end
    end
    % Internal-use methods for trace management.
    methods (Hidden)
        function setTrace(this, traceValue)
            validateattributes(traceValue, {'logical'}, {'scalar'}, 'setTrace', 'traceValue');
            this.TraceEnabled = traceValue;
            for k=1:numel(this)
                if this(k).IsConnected
                    this(k).AsyncChannel.TraceEnabled = traceValue;
                end
            end
        end
    end
    
    %% Event Handlers
    events(NotifyAccess='private')
        Closed
        ServerStateChanged
        Deleting
    end
    
    methods(Access='private')
        function onClosed(this)
            %onClosed Handle Closed event
            
            % Pass it along to any of our listeners.
            notify(this, 'Closed');
        end
        function onDataAvailable(this,~,~)
            %onDataAvailable Callback for data available listener.
            %   The onDataAvailable function manages keepalive messages and group updates from the server.
            groupUpdates=this.AsyncChannel.InputStream.read();
            % Look for all the DataChange and StatusChange updates
            for n=1:numel(groupUpdates)
               % Check if not just a Keep-Alive update
               if numel(groupUpdates(n).DataResults)>0
                   if isfield(groupUpdates(n).DataResults.Update, 'Value')
                       newStateFlag = groupUpdates(n).DataResults.Update.Value;
                       if (newStateFlag ~= this.ServerStateFlag)
                           % Server is changing state. Warn but without showing stack
                           oldWarnState = warning('off', 'backtrace');
                           warning(message('opc:ua:Client:ServerStateChanged', this.Name, this.ServerState, getUaServerStateString(newStateFlag)));
                           warning(oldWarnState);
                           notify(this, 'ServerStateChanged');
                           if any(newStateFlag == [1, 2, 3, 4, 6, 7])
                               % We now disconnect the client to gracefully exit.
                               disconnect(this);
                           end
                       end
                       this.ServerStateFlag = newStateFlag;
                   end
               end
            end
            this.LastMessageTime = now;
        end
        function onCustomEvent(this, type, data)
            %onCustomEvent Custom event generated by Channel.
            switch type
                case 'SubscriptionFailed'
                    if isempty(data)
                        resultCode = opc.ua.StatusCodeId.Bad_UnexpectedError;
                    else
                        resultCode = opc.ua.StatusCodeId(data.ResultCode);
                    end
                    oldWarnState = warning('off', 'backtrace');
                    if (resultCode == opc.ua.StatusCodeId.Bad_ServerHalted) || (resultCode == opc.ua.StatusCodeId.Bad_SubscriptionIdInvalid)
                        % Server halted. Call it Shutdown and disconnect.
                        newStateFlag = 4;
                        warning(message('opc:ua:Client:ServerStateChanged', this.Name, this.ServerState, getUaServerStateString(newStateFlag)));
                        this.ServerStateFlag = newStateFlag;
                        disconnect(this);
                    elseif (resultCode ~= opc.ua.StatusCodeId.Bad_Disconnect) && (resultCode ~= opc.ua.StatusCodeId.Bad_InvalidState)
                        warning('opc:ua:Client:SubscriptionFailed', 'Subscription Update Failure: %s. Client is disconnecting.', char(resultCode));
                        % For now, since we are not using subscriptions for anything but status notifications, a failure
                        % means the connection is broken; disconnect.
                        disconnect(this);
                    end
                    warning(oldWarnState);
            end
        end
    end
    methods(Static, Access = private)
        function id = getUniqueId()
            %getNextSessionId Return a unique identifier for a session
            %   This function is a simple counter of calls for the lifetime of the Client class in memory.
            persistent internalId
            if isempty(internalId)
                internalId = uint32(1);
            else
                internalId = internalId + 1;
            end
            id = internalId;
        end
    end
end

