Global_Node();
n_excel = 0;
size_temp = size(T1);

for i = 1:size_temp(1)
    num = T1(i,1);
    num = table2array(num);
    num = str2num(num{1,1});
    if Test_number == num
        n_excel = i;
        break
    end
end

test_structure = table2array(T1(n_excel,31));
test_structure = test_structure{1,1};
test_structure = str2num(test_structure);