Global_Node();  % �۷ι� ���� ����
waitbar(1/3,h2,sprintf('Define Nodes ...'))
Define_Node();  % OPC-UA���� ����, bSimReset��� ���� �Ϲ������� �׽�Ʈ�� �ʿ��� ������ ����
waitbar(2/3,h2,sprintf('Run OTS Mode ...'))
OTS = RunOTS(); % OTS ��� ����

% Log ������Ʈ
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