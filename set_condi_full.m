clc;
Global_Node();
addpath('C:\Windows\System32\drivers\etc');
plc_no = 1;
plc_ip = strcat('172.16.9.10',int2str(plc_no));
s=opcuaserverinfo(plc_ip);
uaClient=opcua(s);
connect(uaClient);
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


fuel_state = IF_MONITOR.Children(3);    
op_state = IF_MONITOR.Children(2);  
a = readValue(fuel_state);          % diesel=0 / gas=9 / backup=11
b = readValue(op_state);            % run=4 / start=2 / stop=1

condi = [100, 100; 10, 100; 1, 100; 100, 10; 100, 1];
% i=2
% a = readValue(fuel_state)
% b = readValue(op_state)
% Set_Condition(condi(i,1), condi(i,2));
% a = readValue(fuel_state)
% b = readValue(op_state)
% pause(30)
% a = readValue(fuel_state)
% b = readValue(op_state)
Aaa = zeros(5,5);
Bbb = zeros(5,5);

for i = 1:5
    for j = 1:5
        clc
        fprintf("Diesel Gas Backup Stop Start \n")
        [i j]
        disconnect(uaClient)
        connect(uaClient)
        Set_Condition(condi(i,1), condi(i,2));
        pause(3);
        fprintf("Starting \n")
        Aaa(i,j) = 10*readValue(fuel_state)+readValue(op_state);
        pause(3);
        Set_Condition(condi(j,1), condi(j,2));
        pause(3);
        fprintf("Ending \n")
        Bbb(i,j) = 10*readValue(fuel_state)+readValue(op_state);
        pause(3);
    end
end