function Log_update(name,fuel,op,type,forcing,pass,fail,note)
    Global_Node();
    nameinput = " ";
    a = length(TestNumber)+1;
    TestNumber = [TestNumber; a];
%     fprintf("Test Names \n")
%     current_Testname
%     latest_Test
    if isequal(current_Testname, latest_Test) ~= 1
        nameinput = current_Testname;
        latest_Test = current_Testname;
    else
        nameinput = " ";
    end
%     fprintf("NAME INPUT \n")
%     nameinput
    TestName = [TestName; nameinput];
    FuelMode = [FuelMode; fuel];
    OperationMode = [OperationMode; op];
    ForcingValue = [ForcingValue; forcing];
    Passed = [Passed; pass];
    Failed = [Failed; fail];
    Note = [Note; note];
    TestType = [TestType; type];
end