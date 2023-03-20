classdef Node < handle
    %Node OPC UA Node class
    %   An OPC UA Node object stores information about a node in an OPC UA server. A node can be an Object node containing
    %   other Object nodes and Variable nodes but no data Value, or a Variable node which has a Value and possibly other
    %   Variable nodes.
    %
    %   You can read and write current data, and read historical data using Variable nodes. You can browse the name space
    %   using Object and Variable nodes.
    %
    %   A node's type is described by the NodeType property of the node object. Other properties of nodes describe other
    %   characteristics of the node such as the Node's ServerDataType, or whether the server is Historizing the node.
    %
    %   Node properties:
    %       Identity properties:
    %       Name                    - Display name for the node
    %       NodeType                - Type of node: 'Object' or 'Variable'
    %       NamespaceIndex          - Namespace index for this node
    %       IdentifierType          - Type of identifier: 'string', 'numeric' or 'GUID'
    %       Identifier              - Unique Identifier: A string or integer, depending on the IdentifierType
    %       Relationship properties:
    %       Parent                  - Parent node of this node
    %       Children                - Child nodes of this node
    %       Client                  - Reference to OPC UA Client associated with the node
    %       FullyQualifiedId        - String uniquely describing this node
    %       Essential attributes:
    %       Description             - String describing the node
    %       MinimumSamplingInterval	- Minimum rate at which node Value will change (*)
    %       Historizing             - True if the server is storing history for the node (*)
    %       ServerDataType          - OPC UA Data Type for node (*)
    %       Informative attributes:
    %       AccessLevelCurrent      - User's access level to current value: 'none', 'read', 'write', or 'read/write' (*)
    %       AccessLevelHistory      - User's access level to historical values: 'none', 'read', 'write', or 'read/write' (*)
    %       ServerValueRank         - Size restrictions on the server Value: 'unrestricted', 'scalar', 'vector', or 'array' (*)
    %       ServerArrayDimensions   - Array dimensions of the server Value. Can be empty, as this property is optional for servers (*)
    %
    %   (Properties marked with a * in the description are empty for Object nodes.)
    %
    %   Node functions:
    %       getAllChildren    - Recursively retrieve all children of this node
    %       getNodeAttributes - Retrieve all or selected attributes from the node as a structure
    %       findNodeById      - Find a node by namespace index and identifier
    %       findNodeByName    - Find a node by name
    %       isVariableType    - True if the node is a variable node
    %       isObjectType      - True if the node is an object node
    %       readValue         - Read current value of node, including quality and timestamp
    %       readHistory       - Read historical data stored on the server for the node
    %       readAtTime        - Read (possibly) interpolated history data from the server at specific times
    %       readProcessed     - Read processed (aggregate) history data from the server
    %       writeValue        - Write current value to the server
    %
    %   See also opc.ua.Client/browseNamespace, opc.ua.Client/getNamespace.
    
    % Copyright 2015 The MathWorks, Inc.
    % Developed by Opti-Num Solutions (Pty) Ltd
    
    properties (SetAccess = public)
        %Name - Display name for the node. Populated from the server, or made up of the namespace index and identifier.
        Name = '';
    end
    properties (Dependent, SetAccess = private)
        %NodeType - Type of node. One of 'Object' or 'Variable'. Object nodes do not have a Value, and so you cannot
        %read current or historical data or write to the node. In OPC UA servers, Variable nodes may have Children.
        NodeType
    end
    properties (SetAccess = private)
        %NamespaceIndex - Namespace index for this node. Servers expose multiple name spaces to clients, identified by
        %the namespace index. All OPC UA Servers include a namespace with index 0 named 'Server', containing server
        %information.
        NamespaceIndex = [];
    end
    properties (Dependent, SetAccess = private)
        %IdentifierType - Type of identifier. One of 'string', 'numeric', or 'GUID'. If you construct a node using
        %opcuanode, the identifier type will depend on the data type passed for the Identifier argument; GUIDs are
        %automatically detected when the string conforms to the GUID description '{xxxx-yyyy-zzzz-kkkk-mmmm}'.
        %   See also opcuanode
        IdentifierType
    end
    properties (SetAccess = private)
        %Identifier - Unique Identifier in the namespace. Can be a string, number, or GUID (represented as a string
        %'{xxxx-yyyy-zzzz-kkkk-mmmm}').
        Identifier = [];
        %Parent - Parent node of this node. Nodes constructed with opcuanode may not have a Parent defined.
        Parent = opc.ua.Node.empty;
    end
    properties (Dependent, SetAccess = private)
        %Children - Child nodes of this node. Querying or displaying the Chidren property automatically browses the
        %server for child nodes, if the Client associated with this node is not empty and is connected to the server.
        Children;
    end
    properties (SetAccess = private)
        %Client - Reference to OPC UA Client owning the node. If you construct a node using opcuanode, and do not pass
        %the client object, then the Client will remain empty and you will only be able to browse, read and write from
        %the node using the Client object as the first argument.
        %   See also opcuanode
        Client = [];
    end
    properties (Dependent, SetAccess = private)
        %FullyQualifiedId - A string uniquely representing the node. Made up of all ancestors of the node separated by
        %'.' and including the Namespace Index of the topmost ancestor.
        FullyQualifiedId
    end
    properties (Access = private)
        IdentifierTypeId = uint32(0); % Internal typeId. 0 = Numeric, 1 = String, 2 = GUID. (As per UA spec)
        NodeTypeId = uint32(0); % Node type. 1 = Object node, 2 = Variable node. (Internal enum)
        %  Child nodes of this node. Querying or displaying the Chidren node automatically browses the server for the child nodes.
        ChildNodes = opc.ua.Node.empty;
        IsChildrenPopulated = false; % Becomes true when we populate the children node.
        % The following are read when required, if they are empty.
        DescriptionPrivate = '';
        DescriptionQueried = false; % We need this in case the description is in fact empty.
        MinimumSamplingIntervalPrivate = []; % Cannot be empty on server.
        HistorizingPrivate = logical.empty; % Can be empty on the server, for objects.
        HistorizingQueried = false;
        ServerDataTypePrivate = ''; % Can be empty on the server, for objects.
        ServerDataTypeQueried = false;
        UserAccessLevel = []; % Can be empty on the server, for objects.
        UserAccessLevelQueried = false;
        ServerValueRankPrivate = [];
        ServerValueRankQueried = false;
        ServerArrayDimensionsPrivate = [];
        ServerArrayDimensionsQueried = false;
    end
    properties (Dependent, SetAccess = private)
        %Description - A string dDescription of the node as stored on the server.
        Description;
        %MinimumSamplingInterval - The minimum sampling interval (in seconds) for this Variable node on the server.
        %Indicates how fast the server can reasonably sample the value for changes. A value of -1 means the minimum
        %sampling interval is indeterminate; a value of 0 means continuous sampling. For Object nodes this property will
        %be empty.
        MinimumSamplingInterval;
        %Historizing - True if the server is actively historizing data for this Variable node, or false otherwise. For
        %Object nodes this property will be empty.
        Historizing;
        %ServerDataType - A string describing the data type of the Variable node on the server. OPC UA Data Types and
        %their translation to MATLAB data types are described in opc.ua.DataTypeId. For Object nodes this property will
        %be empty.
        %   See also opc.ua.DataTypeId
        ServerDataType;
        %AccessLevelCurrent - User access restrictions to Current value of the Variable on this node. One of 'none',
        %'read', 'write', or 'read/write'. You access the current value of a node using readValue and writeValue
        %functions. For Object nodes this property will be empty.
        AccessLevelCurrent;
        %AccessLevelHistory - User access restrictions to Historical values of the node. One of 'none', 'read', 'write',
        %or 'read/write'. You access the historical values of a node using readHistory, readAtTime, and readProcessed
        %functions. For Object nodes this property will be empty.
        %   See also readHistory, readAtTime, readProcessed.
        AccessLevelHistory;
        %ServerValueRank - An integer describing whether the Value of the node is an array, and how many dimensions it
        %has. A positive value indicates the number of dimensions of an array Value; 0 indicates one or more dimensions;
        %-1 indicates a scalar value only; -2 indicates no restriction (scalar or array), and -3 indicates a scalar or
        %vector only. Note that array-like data types such as ByteString, or string, are considered to be scalars in OPC
        %UA semantics.
        ServerValueRank;
        %ServerArrayDimensions - Dimensions of a fixed array for the node Value. This property is only set if the
        %ValueRank is positive, and indicates the maximum size of the array, not the current size.
        ServerArrayDimensions;
    end        
    properties (Access = private)
        ClientDeletingListener = []; % Listener for client being deleted. Deletes the object.
    end
    
    methods % Constructor, display
        function this = Node(s, uaClient, parentNode)
            %Node OPC UA Node object constructor
            %   You should not use opc.ua.Node to construct node objects. Instead, use opcuanode when you know the
            %   namespace index and identifier for a node, or browse the namespace of the server using the Namespace
            %   property of the client connected to the server or the browseNamespace function.
            %   
            %   See also opcua, opcuanode, opc.ua.Client/Namespace, opc.ua.Client/browseNamespace.
            
            % We support empty node objects.
            if nargin>0
                narginchk(3,3);
                reqFieldsIn = {'DisplayName', 'StringId', 'NumericId', 'NamespaceIndex', 'IdType', 'ClassType'};
                if ~isstruct(s) 
                    error(message('opc:General:InvalidArgument', 'opc.ua.Node'));
                end
                fldExists = isfield(s, reqFieldsIn);
                if any(~fldExists)
                    error(message('opc:General:MissingField', reqFieldsIn{find(~fldExists, 1, 'first')}));                 
                end
                if isempty(uaClient)
                    uaClient = opc.ua.Client.empty;
                else
                    validateattributes(uaClient, {'opc.ua.Client'}, {'scalar'}, 'opc.ua.Node', 'ClntObj');
                end
                if isempty(parentNode)
                    parentNode = opc.ua.Node.empty;
                else
                    validateattributes(parentNode, {'opc.ua.Node'}, {'scalar'}, 'opc.ua.Node', 'ParentNode');
                end
                % Now construct these backwards so that we don't grow our vector
                if numel(s)==0
                    this = opc.ua.Node.empty;
                else
                    for k=numel(s):-1:1
                        this(k).Parent = parentNode;
                        this(k).Client = uaClient;
                        if ~isempty(uaClient)
                            % Register for client shutdown
                            % this(k).ClientDeletingListener = addlistener(uaClient, 'Deleting', @(obj,evt)clientDeleteHandler(this(k)));
                        end
                        % Populate Identifier based on the IdType
                        this(k).IdentifierTypeId = s(k).IdType;
                        if (s(k).IdType == 0) % Numeric ID
                            this(k).Identifier = uint32(s(k).NumericId);
                        else % String ID
                            this(k).Identifier = s(k).StringId;
                        end
                        this(k).NamespaceIndex= s(k).NamespaceIndex;
                        % ClassType is complicated because the node could be constructed by opcuanode.
                        if (s(k).ClassType == 0) && ~isempty(uaClient) && isConnected(uaClient)
                            ctTry = getNodeAttributes(uaClient, this(k), opc.ua.AttributeId.NodeClass);
                            if ~isempty(ctTry)
                                s(k).ClassType = ctTry;
                            end
                            % Also try to get the node name
                            nmTry = getNodeAttributes(uaClient, this(k), opc.ua.AttributeId.DisplayName);
                            if ~isempty(nmTry)
                                s(k).DisplayName = nmTry;
                            end
                        end
                        this(k).NodeTypeId = s(k).ClassType;
                        this(k).Name = s(k).DisplayName;
                    end
                end
            end
        end
        function disp(this)
            %disp Display function for OPC UA Node objects.
            isLoose = strcmpi(get(0,'FormatSpacing'),'loose');
            switch numel(this)
                case 0
                    fprintf('Empty OPC UA Node object.\n');
                case 1
                    this.dispScalar;
                otherwise
                    this.dispArray;
            end
            % Show an empty line if required
            if isLoose
                fprintf('\n');
            end
        end
        function delete(this)
            %delete Remove OPC UA Node objects
            
            % Help the cleanup by removing references to my parent, children  and client.
            this.Client = [];
            this.Parent = [];
            this.ChildNodes = [];
        end
    end
    methods % Getters and Setters
        function idTypeStr = get.IdentifierType(this)
            %get.IdentifierType Return IdentifierType property
            switch this.IdentifierTypeId
                case 0
                    idTypeStr = 'numeric';
                case 1
                    idTypeStr = 'string';
                case 2
                    idTypeStr = 'guid';
                otherwise
                    idTypeStr = '<unknown>';
            end
        end
        function typeStr = get.NodeType(this)
            %get.NodeType Return NodeType property
            switch this.NodeTypeId
                case 1
                    typeStr = 'Object';
                case 2
                    typeStr = 'Variable';
                otherwise
                    typeStr = 'Unknown';
            end
        end
        function fqid = get.FullyQualifiedId(this)
            %get.FullyQualifiedId Return the FullyQualifiedID of a node.
            fqid = escapeFqidString(this.Name);
            nsInd = this.NamespaceIndex;
            pNode = this.Parent;
            while ~isempty(pNode)
                fqid = sprintf('%s.%s', escapeFqidString(pNode.Name), fqid);
                % Capture the last namespace index up the tree.
                nsInd = pNode.NamespaceIndex;
                pNode = pNode.Parent;
            end
            % Add the namespace index to the string.
            fqid = sprintf('%d:%s', nsInd, fqid);
        end
        function nodes = get.Children(this)
            %get.Chldren Return Children of the node.
            if ~this.IsChildrenPopulated && ~isempty(this.Client) && isConnected(this.Client)
                % Fetch the Children
                try
                    nodes = getNamespace(this.Client, this, '-force');
                catch opcExc
                    warning(message('opc:ua:Client:ChildrenNotRetrievable', this.Name, opcExc.message));
                    nodes = opc.ua.Node.empty;
                end
                this.ChildNodes = nodes;
                this.IsChildrenPopulated = true;
            else
                nodes = this.ChildNodes;
            end
        end
        function descStr = get.Description(this)
            %get.Description Retrieve Description property
            if ~this.DescriptionQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.DescriptionPrivate = getNodeAttributes(this.Client, this, opc.ua.AttributeId.Description);
                this.DescriptionQueried = true;
            end
            descStr = this.DescriptionPrivate;
        end
        function dtStr = get.ServerDataType(this)
            %get.ServerDataType Retrieve ServerDataType property
            if isVariableType(this) && ~this.ServerDataTypeQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.ServerDataTypePrivate = getNodeAttributes(this.Client, this, opc.ua.AttributeId.DataType);
                this.ServerDataTypeQueried = true;
            end
            dtStr = this.ServerDataTypePrivate;
        end
        function minSI = get.MinimumSamplingInterval(this)
            %get.MinimumSamplingInterval Retrieve MinimumSamplingInterval property
            if isempty(this.MinimumSamplingIntervalPrivate) && ~isempty(this.Client) && isConnected(this.Client)
                this.MinimumSamplingIntervalPrivate = getNodeAttributes(this.Client, this, opc.ua.AttributeId.MinimumSamplingInterval);
            end
            minSI = this.MinimumSamplingIntervalPrivate;
        end
        function tf = get.Historizing(this)
            %get.Historizing Retrieve Historizing property
            if isVariableType(this) && ~this.HistorizingQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.HistorizingPrivate = getNodeAttributes(this.Client, this, opc.ua.AttributeId.Historizing);
                this.HistorizingQueried = true;
            end
            tf = this.HistorizingPrivate;
        end
        function rwStr = get.AccessLevelCurrent(this)
            %get.AccessLevelCurrent Retrieve AccessLevelCurrent property
            if isVariableType(this) && ~this.UserAccessLevelQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.UserAccessLevel = getNodeAttributes(this.Client, this, opc.ua.AttributeId.UserAccessLevel);
                this.UserAccessLevelQueried = true;
            end
            if isempty(this.UserAccessLevel)
                rwStr = '';
            else
                switch bitand(this.UserAccessLevel, 3)
                    case 0
                        rwStr = 'none';
                    case 1
                        rwStr = 'read';
                    case 2
                        rwStr = 'write';
                    otherwise
                        rwStr = 'read/write';
                end
            end
        end
        function rwStr = get.AccessLevelHistory(this)
            %get.AccessLevelHistory Retrieve AccessLevelCurrent property
            if isVariableType(this) && ~this.UserAccessLevelQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.UserAccessLevel = getNodeAttributes(this.Client, this, opc.ua.AttributeId.UserAccessLevel);
                this.UserAccessLevelQueried = true;
            end
            % For History access, we are interested in bits 3-4.
            if isempty(this.UserAccessLevel)
                rwStr = '';
            else
                switch bitand(this.UserAccessLevel, 12)
                    case 0
                        rwStr = 'none';
                    case 4
                        rwStr = 'read';
                    case 8
                        rwStr = 'write';
                    otherwise
                        rwStr = 'read/write';
                end
            end
        end
        function valRank = get.ServerValueRank(this)
            %get.ServerValueRank Retrieve ServerValueRank property
            if isVariableType(this) && ~this.ServerValueRankQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.ServerValueRankPrivate = getNodeAttributes(this.Client, this, opc.ua.AttributeId.ValueRank);
                this.ServerValueRankQueried = true;
            end
            valRank = this.ServerValueRankPrivate;
        end
        function arrayDim = get.ServerArrayDimensions(this)
            %get.ServerArrayDimensions Retrieve ServerArrayDimensions property
            if isVariableType(this) && ~this.ServerArrayDimensionsQueried && ~isempty(this.Client) && isConnected(this.Client)
                this.ServerArrayDimensionsPrivate = getNodeAttributes(this.Client, this, opc.ua.AttributeId.ArrayDimensions);
                this.ServerArrayDimensionsQueried = true;
            end
            arrayDim = this.ServerArrayDimensionsPrivate;
        end
    end
    methods (Hidden) % Hidden but not private because Client needs them
        function argStruct = getBrowseArg(this)
            %getBrowseArg Return browse argument for device calls
            %   This function is intended for internal use only.
            argStruct(numel(this)) = struct('IdType', [], 'StringId', '', 'NumericId', [], 'NamespaceIndex', []);
            for k=1:numel(this)
                argStruct(k).IdType = uint32(this(k).IdentifierTypeId);
                argStruct(k).NamespaceIndex = uint32(this(k).NamespaceIndex);
                switch this(k).IdentifierTypeId
                    case 0
                        argStruct(k).NumericId = this(k).Identifier;
                        argStruct(k).StringId = '';
                    case {1, 2, 3}
                        argStruct(k).StringId = this(k).Identifier;
                        argStruct(k).NumericId = uint32(0);
                    otherwise
                        error(message('opc:ua:Node:IdTypeUnknown', this(k).IdentifierTypeId));
                end
            end
        end
        function setChildren(this, nodes)
            %setChildren Set Children of Node
            %   This function is intended for internal use only.
            narginchk(2,2);
            if isempty(nodes)
                nodes = opc.ua.Node.empty;
            else
                validateattributes(nodes, {'opc.ua.Node'}, {}, 'setChildren', 'Nodes');
            end
            this.ChildNodes = nodes;
            this.IsChildrenPopulated = true;
        end
        function setClient(this, uaClient)
            %setClient Set Client property of Node
            %   This function is intended for internal use only.
            narginchk(2,2);
            validateattributes(uaClient, {'opc.ua.Client'}, {'scalar'}, 'setClient', 'uaClient');
            if all(cellfun(@isempty, {this.Client}))
                for k=1:numel(this)
                    this(k).Client = uaClient;
                    % Refetch the node attributes
                    ctTry = getNodeAttributes(uaClient, this(k), 2);
                    if ~isempty(ctTry)
                        this(k).NodeTypeId = ctTry;
                    end
                    % Register for client shutdown
                    % this(k).ClientDeletingListener = addlistener(uaClient, 'Deleting', @(obj,evt)clientDeleteHandler(this(k)));
                end
            else
                error(message('opc:ua:Node:SetClientNotEmpty'));
            end
        end
    end
    methods (Access = private)
        function idStr = getIdAsString(this)
            idCell = cell(size(this));
            for k=1:numel(this)
                switch this(k).IdentifierTypeId
                    case {1, 2}
                        idCell{k} = this(k).Identifier;
                    case 0
                        idCell{k} = sprintf('%d', this(k).Identifier);
                    otherwise
                        idCell{k} = '';
                end
            end
            if numel(this) == 1
                idStr = idCell{1};
            else
                idStr = idCell;
            end
        end
        function dispScalar(this)
            % Can we display hyperlinks?
            isLoose = strcmpi(get(0,'FormatSpacing'),'loose');
            canHyperlink = feature('hotlinks');
            indent = 4;
            nodeIdString = this.getIdAsString;
            % If this has an empty client, make it an orphan
            fprintf('OPC UA Node object:\n');
            propLen = length('AccessLevelCurrent')+indent;    % Hard-coded longest prop.
            fprintf('%*s%s: %s\n', indent, ' ', ...
                opc.internal.makePropHelp('opc.ua.Node/Name', propLen, canHyperlink), ...
                this.Name);
            fprintf('%*s%s: %s\n', indent, ' ', ...
                opc.internal.makePropHelp('opc.ua.Node/Description', propLen, canHyperlink), ...
                this.Description);
            fprintf('%*s%s: %d\n', indent, ' ', ...
                opc.internal.makePropHelp('opc.ua.Node/NamespaceIndex', propLen, canHyperlink), ...
                this.NamespaceIndex);
            fprintf('%*s%s: %s\n', indent, ' ', ...
                opc.internal.makePropHelp('opc.ua.Node/Identifier', propLen, canHyperlink), ...
                nodeIdString);
             fprintf('%*s%s: %s\n', indent, ' ', ...
                opc.internal.makePropHelp('opc.ua.Node/NodeType', propLen, canHyperlink), ...
                this.NodeType);
            if isLoose
                fprintf('\n');
            end
            % For orphan nodes, show only a message.
            if isempty(this.Client)
                msg = message('opc:ua:Node:OrphanNode');
                fprintf('%*s%s\n', indent, ' ', msg.getString);
            else
                if ~isempty(this.Parent)
                    fprintf('%*s%s: %s\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Node/Parent', propLen, canHyperlink), ...
                        this.Parent.Name);
                end
                % Children can belong to any node...
                fprintf('%*s%s: %d nodes.\n', indent, ' ', ...
                    opc.internal.makePropHelp('opc.ua.Node/Children', propLen, canHyperlink), ...
                    numel(this.Children));
                % Variable-only properties
                if isVariableType(this)
                    if isLoose
                        fprintf('\n');
                    end
                    fprintf('%*s%s: %s\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Node/ServerDataType', propLen, canHyperlink), ...
                        this.ServerDataType);
                    fprintf('%*s%s: %s\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Node/AccessLevelCurrent', propLen, canHyperlink), ...
                        this.AccessLevelCurrent);
                    fprintf('%*s%s: %s\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Node/AccessLevelHistory', propLen, canHyperlink), ...
                        this.AccessLevelHistory);
                    fprintf('%*s%s: %d\n', indent, ' ', ...
                        opc.internal.makePropHelp('opc.ua.Node/Historizing', propLen, canHyperlink), ...
                        this.Historizing);
                end
            end
        end
        function dispArray(this)
            indent = 4;
            sizeStr = sprintf('%dx', size(this));
            fprintf('%s OPC UA Node array:\n', sizeStr(1:end-1));
            myTbl = internal.DispTable;
            myTbl.Indent = indent;
            myTbl.ColumnSeparator = '  ';
            myTbl.addColumn('index', 'center');
            myTbl.addColumn(internal.DispTable.helpLink('Name', ...
                'opc.ua.Node/Name'));
            myTbl.addColumn(internal.DispTable.helpLink('NsInd', ...
                'opc.ua.Node/NamespaceIndex'));  
            myTbl.addColumn(internal.DispTable.helpLink('Identifier', ...
                'opc.ua.Node/Identifier'));
            myTbl.addColumn(internal.DispTable.helpLink('NodeType', ...
                'opc.ua.Node/NodeType'));  
            myTbl.addColumn(internal.DispTable.helpLink('Children', ...
                'opc.ua.Node/Children'));
            for k=1:numel(this)
                nodeIdString = getIdAsString(this(k));
                myTbl.addRow(k, this(k).Name, sprintf('%d', this(k).NamespaceIndex), nodeIdString, ...
                    this(k).NodeType, numel(this(k).Children));
            end
            disp(myTbl);
        end
        function tf = isSameClient(this)
            %isSameClient True if all nodes have the same non-empty Client property
            tf = ~isempty(this(1).Client);
            if tf
                for k=2:numel(this)
                    tf = isequal(this(k).Client, this(1).Client);
                    if ~tf
                        break;
                    end
                end
            end
        end
    end
    methods % Public, useful methods
        function allChildNodes = getAllChildren(this)
            %getAllChidren Recursively retrieve all children of a node
            %   AllChildNodes = getAllChildren(StartNode) returns all children of a given node as a vector of Node objects.
            %   AllChildNodes is a vector of Node objects representing all children (and their children, and so on) of StartNode.
            %
            %   NOTE: This function is memory intensive and should be used only when necessary. Consider instead using the Children
            %   property of OPC UA Nodes or the browseNamespace, findNodeByName, or findNodeById functions.
            %
            %   Example: Return all children of the Server node. 
            %       uaClient = opcua('localhost', 51210);
            %       connect(uaClient);
            %       serverNode = uaClient.Namespace(1);
            %       allServerNodes = getAllChildren(serverNode);
            %       
            %   See also opc.ua.Client/Namespace, opc.ua.Client/getNamespace, opc.ua.Client/browseNamespace, opc.ua.Node/findNodeByName, opc.ua.Node/findNodeById.
            allChildNodes = opc.ua.Node.empty;
            for tI = 1:numel(this)
                allChildNodes(end+1) = this(tI); %#ok<AGROW> We want the nodes to be ordered so have to grow it
                for k=1:numel(this(tI).Children)
                    allChildNodes(end+1) = this(tI).Children(k); %#ok<AGROW> We have no idea how large this can be, so grow it.
                    if ~isempty(this(tI).Children(k))
                        childNodes = getAllChildren(this.Children(k));
                        allChildNodes(end+1:end+numel(childNodes)) = childNodes;
                    end
                end
            end
        end
        function foundNode = findNodeById(this, nsInd, id)
            %findNodeById Find an OPC UA node by namespace index and identifier
            %   FoundNode = findNodeById(StartNode, NsInd, Id) searches the nodes in StartNode for a node with NamespaceIndex and
            %   Identifier matching NsInd and Id, respectively. NsInd must be an integer, and Id must be a string or integer.
            %
            %   This function might query the server for further sub-nodes of StartNode, until one  matching node is found or no more
            %   nodes can be searched.
            %
            %   Example: Find the ServerCapabilities node (Index 0, Identifier 2268)
            %       uaClient = opcua('localhost', 51210);
            %       connect(uaClient);
            %       capabilitiesNode = findNodeById(uaClient.Namespace, 0, 2268);
            %
            %   See also opc.ua.Client/Namespace, findNodeByName.
            narginchk(3,3);
            validateattributes(nsInd, {'numeric'}, {'scalar'}, 'findNodeById', 'nsInd');
            validateattributes(id, {'numeric','char','string'}, {}, 'findNodeById', 'id');
            foundNode = opc.ua.Node.empty;
            children = [this.Children];
            while isempty(foundNode) && ~isempty(children)
                indMatch = ([children.NamespaceIndex] == nsInd);
                idMatch = cellfun(@(x)isequal(x,char(id)), {children.Identifier});
                allMatch = (indMatch & idMatch);
                if any(allMatch)
                    foundNode = children(allMatch);
                    break;
                else
                    children = [children.Children];
                end
            end
        end
        function foundNode = findNodeByName(this, nodeName, varargin)
            %findNodeByName Find OPC UA Nodes by Name
            %   FoundNodes = findNodeByName(StartNode, NodeName) searches StartNode and its sub-nodes for all OPC UA Nodes with Name
            %   matching NodeName. The search is case-insensitive.
            %
            %   FoundNodes = findNodeByName(StartNode, NodeName, '-once') stops searching when one node has been found.
            %
            %   FoundNodes = findNodeByName(StartNode, NodeName, '-partial') finds all nodes that start with NodeName.
            %
            %   You can use both '-once' and '-partial' at the same time.
            %
            %   This function might query the server for further sub-nodes of StartNode, until one or more matching nodes are found
            %   or no more nodes can be searched. On servers with a large namespace, this can take a long time.
            %
            %   Example: Find the ServerCapabilities node from the Server node. 
            %       uaClient = opcua('localhost', 51210);
            %       connect(uaClient);
            %       serverNode = findNodeByName(uaClient.Namespace, 'Server', '-once');
            %       capabilitiesNode = findNodeByName(serverNode, 'ServerCapabilities');
            %
            %   See also opc.ua.Client/Namespace, findNodeById.
            narginchk(2,4);
            validateattributes(nodeName, {'char','string'}, {'row'}, 'findNodeByName', 'NodeName');
            nodeName = char(nodeName);
            validateattributes(this, {'opc.ua.Node'}, {}, 'findNodeByName', 'StartNode'); 
            isPartial = false;
            isOnce = false;
            if nargin>2
                % Additional argument checking
                while ~isempty(varargin)
                    thisArg = varargin{1};
                    if ~ischar(thisArg)&&~isstring(thisArg)
                        error(message('opc:ua:General:FindByNameArgInvalid', sprintf('of type %s', class(thisArg))));
                    end
                    if strcmpi(thisArg, '-once')
                        isOnce = true;
                    elseif strcmpi(thisArg, '-partial')
                        isPartial = true;
                    else
                        error(message('opc:ua:General:FindByNameArgInvalid', thisArg));
                    end
                    varargin(1)=[];
                end
            end
            % Define the correct string comparison
            if isPartial
                compFun = @(x,y)strncmpi(x, y, numel(y));
            else
                compFun = @(x,y)strcmpi(x, y);
            end
            % Perform the search
            foundNode = opc.ua.Node.empty;
            currentNodes = this;
            while ~isempty(currentNodes)
                nameMatch = compFun({currentNodes.Name}, nodeName);
                if any(nameMatch)
                    matchNodes = currentNodes(nameMatch);
                    if isOnce
                        foundNode = matchNodes(1);
                        break;
                    else
                        foundNode(end+1:end+numel(matchNodes)) = matchNodes;
                    end
                end
                currentNodes = [currentNodes.Children];
            end
        end
        function tf = isVariableType(this)
            %isVariableType True for Variable nodes
            %   tf = isVariableType(NodeObj) returns true for nodes that are Variable type nodes (have a Value) or false
            %   otherwise. You can read current and historical values from Variable type Nodes using readValue, readHistory,
            %   readAtTime or readProcessed functions. You can also write current values to Variable type Nodes using
            %   writeValue.
            %
            %   See also: opc.ua.Client/isObjectType, opc.ua.Client/readValue, opc.ua.Client/readHistory, opc.ua.Client/writeValue.
            tf = false(size(this));
            for k=1:numel(this)
                tf(k) = strcmp(this(k).NodeType,'Variable');
            end
        end
        function tf = isObjectType(this)
            %isObjectType True for Object nodes
            %   tf = isObjectType(NodeObj) returns true for nodes that are Object type nodes, or false otherwise. You cannot read
            %   current and historical values from Object type Nodes. Object nodes are used only to organize the server name space.
            %
            %   See also: opc.ua.Client/isVariableType.
            tf = false(size(this));
            for k=1:numel(this)
                tf(k) = strcmp(this(k).NodeType,'Object');
            end
        end
        function tf = isEmptyNode(this)
            %isEmptyNode True for nodes with an empty NamespaceIndex or Identifier
            %   tf = isEmptyNode(NodeObj) returns true for nodes that are empty nodes, or false otherwise. A
            %   node is empty if the NamespaceIndex or Identifier properties are empty. Note that an empty node
            %   may not be used in any read, write or query operation on a connected client.
            %
            %   See also isVariableTYpe, isObjectType.
            tf = arrayfun(@(x)isempty(x.NamespaceIndex)||isempty(x.Identifier),this);
        end   
    end
    methods % Public, friendly accessor methods for client functions
        function propVals = getNodeAttributes(nodeList, attributeIds)
            %getNodeAttributes Read server node attributes
            %   Values = getNodeAttributes(NodeList, AttributeIds) reads the attributes defined by AttributeIds from the nodes given
            %   by NodeList, from the server. NodeList must be an array of OPC UA Node objects with the same connected Client. You
            %   create Node objects using getNamespace, browseNamespace, or opcuanode. AttributeIds can be an array of UInt32
            %   values, or an array of cell strings or strings. Valid attributes are defined in opc.ua.AttributeId.
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
            %       dType = getNodeAttributes(ftxNodes, 'DisplayName')
            %
            %   See also: opc.ua.Client/getNamespace, opc.ua.Client/browseNamespace, opc.ua.AttributeId.
            
            % Node list must not be empty
            throwErrorIfEmptyNode(nodeList);
            % Make sure the parent is the same and connected
            if ~isSameClient(nodeList)
                error(message('opc:ua:Node:MustHaveSameClient', 'getNodeAttributes'));
            end
            propVals = getNodeAttributes(nodeList(1).Client, nodeList, attributeIds);
            
        end        
        function varargout = readValue(nodeList)
            %   [Values, Timestamps, Qualities] = readValue(NodeList) reads the value, quality, and timestamp from the nodes
            %   identified by NodeList. NodeList must be an array of OPC UA Node objects with the same connected Client. You create
            %   OPC UA Node objects using getNamespace, browseNamespace, or opcuanode.
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
            %       [val, ts, qual] = readValue(dblNodes)
            %
            %   See also: writeValue, getNodeAttributes, opc.ua.DataTypeId, opc.ua.QualityId.

            % Node list must not be empty
            throwErrorIfEmptyNode(nodeList);
            % Make sure the parent is the same and connected
            if ~isSameClient(nodeList)
                error(message('opc:ua:Node:MustHaveSameClient', 'readValue'));
            end
            [varargout{1:nargout}] = readValue(nodeList(1).Client, nodeList);
        end
        function d = readHistory(nodeList, varargin)
            %readHistory Read stored historical data from nodes of an OPC UA Server
            %   OpcData = readHistory(NodeList, StartTime, EndTime) reads stored historical data from the nodes given by NodeList,
            %   with a Source Timestamp between StartTime (inclusive) and EndTime (exclusive). StartTime and EndTime can be MATLAB
            %   datetime variables or date numbers. NodeList must be an array of OPC UA Node objects with the same connected Client.
            %   You create OPC UA Node objects using getNamespace, browseNamespace, or opcuanode.
            %
            %   OpcData = readHistory(NodeList, StartTime, EndTime, ReturnBounds) allows you to specify whether you want the
            %   returned data to include Bounding Values. Bounding Values are the values immediately outside the time range
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
            %       dataObj = readHistory(nodeList, datetime('today'), datetime('now'));
            %
            %   See also readValue, readAtTime, readProcessed, opc.ua.Data, opcuanode
            
            % Node list must not be empty
            throwErrorIfEmptyNode(nodeList);
            % Make sure the parent is the same and connected
            if ~isSameClient(nodeList)
                error(message('opc:ua:Node:MustHaveSameClient', 'readHistory'));
            end
            d = readHistory(nodeList(1).Client, nodeList, varargin{:});
        end
        function d = readAtTime(nodeList, varargin)
            %readAtTime Read historical data from nodes of an OPC UA Server at specific times
            %   OpcData = readAtTime(NodeList, TimeVector) reads stored historical data from the nodes given by NodeList, at the
            %   specified times in TimeVector. TimeVector can an array of MATLAB datetimes or date numbers. NodeList must be an
            %   array of OPC UA Node objects with the same connected Client. You create OPC UA Node objects using getNamespace,
            %   browseNamespace, or opcuanode.
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
            %       dataObj = readAtTime(nodeList, datetime('today'):minutes(10):datetime('now'));
            %
            %   See also readValue, readHistory, readProcessed, opc.ua.Data, opcuanode
            
            % Node list must not be empty
            throwErrorIfEmptyNode(nodeList);
            % Make sure the parent is the same and connected
            if ~isSameClient(nodeList)
                error(message('opc:ua:Node:MustHaveSameClient', 'readAtTime'));
            end
            d = readAtTime(nodeList(1).Client, nodeList, varargin{:});
        end
        function d = readProcessed(nodeList, varargin)
            %readProcessed Read processed (aggregate) data from nodes of an OPC UA Server
            %   OpcData = readProcessed(NodeList, AggregateFn, AggrInterval, StartTime, EndTime) reads processed historical data
            %   from the nodes given by NodeList. NodeList must be an array of OPC UA Node objects with the same connected Client.
            %   You create OPC UA Node objects using getNamespace, browseNamespace, or opcuanode.
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
            %       dataObj = readProcessed(nodeList, 'Average', minutes(10), datetime('today'), datetime('now'));
            %
            %   See also readValue, readHistory, readAtTime, opc.ua.Data, opc.ua.AggregateFnId, opcuanode
            
            % Node list must not be empty
            throwErrorIfEmptyNode(nodeList);
            % Make sure the parent is the same and connected
            if ~isSameClient(nodeList)
                error(message('opc:ua:Node:MustHaveSameClient', 'readProcessed'));
            end
            d = readProcessed(nodeList(1).Client, nodeList, varargin{:});
        end
        function writeValue(nodeList, varargin)
            %writeValue Write values to nodes on an OPC UA server
            %   writeValue(NodeList, Vals) writes values in Vals, to the nodes given by NodeList. NodeList must be an array of OPC
            %   UA Node objects with the same connected Client. You create OPC UA Node objects using getNamespace, browseNamespace,
            %   or opcuanode.
            %
            %   If NodeList is a single Node, then Vals is the value to be written to the node. If NodeList is an array of nodes,
            %   then Vals must be a cell array the same size as NodeList, and each element of the cell array is written to the
            %   corresponding element of NodeList.
            %
            %   The data type of the value you are writing does not need to match the Node's ServerDataType property. All values are
            %   automatically converted to the Node's ServerDataType before writing to the server. However, a warning or error is
            %   generated if the data type conversion fails. For DateTime data types, you can pass a MATLAB datetime or a number;
            %   any numeric value will be be interpreted as a MATLAB date number.
            %
            %   Example: Write a new value to the Static DoubleValue node on a local server.
            %       uaClient = opcua('localhost', 51210); 
            %       connect(uaClient); 
            %       staticNode = findNodeByName(uaClient.Namespace, 'Static', '-once');
            %       scalarNode = findNodeByName(staticNode, 'Scalar', '-once');
            %       dblNode = findNodeByName(staticNode, 'DoubleValue'); 
            %       writeValue(dblNode, 3.14159)
            %       [newVal, newTS] = readValue(dblNode)
            %
            %   See also readValue, opc.ua.Client/browseNamespace, opc.ua.Client/getNamespace, opcuanode.

            % Node list must not be empty
            throwErrorIfEmptyNode(nodeList);
            % Make sure the parent is the same and connected
            if ~isSameClient(nodeList)
                error(message('opc:ua:Node:MustHaveSameClient', 'writeValue'));
            end
            writeValue(nodeList(1).Client, nodeList, varargin{:});
        end
    end
    methods (Hidden) % Public but hidden methods
        function throwErrorIfEmptyNode(this)
            %throwErrorIfEmptyNodes Error if array contains an empty node
            if any(isEmptyNode(this))
                throwAsCaller(MException(message('opc:ua:Node:EmptyNodeNotSupported')));
            end
        end
    end
    methods (Access = private) % Event handler methods
        function clientDeleteHandler(this)
            fprintf('Destroying node %s\n', this.Name);
            delete(this);
        end
    end
end

