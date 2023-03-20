% Test_name, Test_case, fuelmode, opmode, PLC_number

% Test_case = [27 28];
fuelmode = 111;
opmode = 111;
PLC_number = '172.16.9.101';

% Define_Node();

load("Table.mat");
% T1 = table2array(T1);

[T1_len,~] = size(T1);

for i = 1:length(Test_case)
    for j = 3:T1_len
        T1_num = T1(j,1);
        T1_num = table2array(T1_num);
        T1_num = T1_num{1,1};
        T1_num = str2num(T1_num);
        testcase_num = Test_case(i);
        if isequal(T1_num, testcase_num)
            A = T1(j,4);
            A = A{1,1};
            A = erase(A{1,1},char(10));
            B = T1(j,6);
            B = B{1,1};
            B = erase(B{1,1},char(10));
            C = T1(j,26);
            C = C{1,1};
            C = erase(C,char(10));
            Test_name(i) = A + " / " + B + " / " + C;
        end
    end
end
Test_case
% Test_Runner_for_GUI(Test_name, Test_case, fuelmode, opmode, PLC_number)
