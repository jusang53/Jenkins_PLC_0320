Global_Node();  % 글로벌 변수 선언
waitbar(1/3,h2,sprintf('Define Nodes ...'))
Define_Node();  % OPC-UA서버 접속, bSimReset등과 같은 일반적으로 테스트에 필요한 변수들 선언
waitbar(2/3,h2,sprintf('Run OTS Mode ...'))
OTS = RunOTS(); % OTS 모드 실행

% Log 업데이트
TestNumber = [TestNumber; string(length(TestNumber)+1)];
TestName = [TestName; "Setting"];
FuelMode = [FuelMode; " "];
OperationMode = [OperationMode; " "];
ForcingValue = [ForcingValue; " "];
TestType = [TestType; " "];
if OTS == 1
    Passed = [Passed; "o"];
    Failed = [Failed; " "];
    Note = [Note; " "];
else
    Passed = [Passed; " "];
    Failed = [Failed; "o"];
    Note = [Note; "Run fail"];
end
waitbar(3/3,h2,sprintf('OTS mode is running ...'))