Global_Node(); % 글로벌 변수 선언

% OPC-UA 서버 접속
addpath('C:\Windows\System32\drivers\etc');
waitbar(1/3,h2,sprintf('Addpath !'))

% plc_ip = strcat('172.16.9.10',int2str(plc_no));
s=opcuaserverinfo(plc_no);
waitbar(1/3,h2,sprintf('opcuaserverinfo !'))
uaClient=opcua(s);
waitbar(1/3,h2,sprintf('uaClient !'))
connect(uaClient);
waitbar(1/3,h2,sprintf('Connected !'))

% SafetyList와 MemMapInfo파일 import
path = string(pwd);
addpath(pwd)
% excelfile1 = "\safetylist_auto_integration.xlsx";
% excelfile2 = "\MemMapInfo.xlsx";
global T1; global T2;
% T1 = readtable(path+excelfile1);
% T2 = readtable(path+excelfile2);
% T1 = readtable("C:\safetylist_auto_integration.xlsx");
% T2 = readtable("C:\MemMapInfo.xlsx");
load('C:\Table.mat')
[var_num, ~] = size(T2);
waitbar(1/3,h2,sprintf('Import Tables !'))

% 기본적인 변수 선언
dEngineSpeed = findNodeByName(uaClient.Namespace,'::dEngineSpeed');
Active_OTS = findNodeByName(uaClient.Namespace,'::Active_OTS');
bSimMode = findNodeByName(uaClient.Namespace,'::bSimMode');
modbus123 = findNodeByName(uaClient.Namespace,'::Modbus_hold123_2');
bSimReset = modbus123.Children(2);
bSimStart = modbus123.Children(3);
bSimStop = modbus123.Children(4);
Diesel_mode = modbus123.Children(5);
Gas_mode = modbus123.Children(6);
Backup_mode = modbus123.Children(7);
abMemAICode = findNodeByName(uaClient.Namespace,'::abMemAlCode');
abMemPtCode = findNodeByName(uaClient.Namespace,'::abMemPtCode');
abMemGtCode = findNodeByName(uaClient.Namespace,'::abMemGtCode');
abMemSdCode = findNodeByName(uaClient.Namespace,'::abMemSdCode');
abMemEsdCode = findNodeByName(uaClient.Namespace,'::abMemEsdCode');
abSf_En = findNodeByName(uaClient.Namespace,'::abSf_En');
afRef = findNodeByName(uaClient.Namespace,'::afRef');
afSf_T = findNodeByName(uaClient.Namespace,'::afSf_T');
modbus15 = findNodeByName(uaClient.Namespace,'::Modbus_hold15_2');
bSigForceMode = modbus15.Children(3);
IF_MONITOR = findNodeByName(uaClient.Namespace,'::IF_MONITOR');
op_mode = IF_MONITOR.Children(2);
IF_ICP_MONITOR = findNodeByName(uaClient.Namespace,'::IF_ICP_MONITOR');
Engine_speed = IF_ICP_MONITOR.Children(83);
modbus130 = findNodeByName(uaClient.Namespace,'::Modbus_hold130_2');
modbus135 = findNodeByName(uaClient.Namespace,'::Modbus_hold135_2');
waitbar(1/3,h2,sprintf('Called Nodes !'))
