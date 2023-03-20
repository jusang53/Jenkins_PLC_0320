function y = Check_Condition(fuel, op)
    % fuel : diesel=100 / gas=10 / backup = 1
    % op : run=100 / start=10 / stop = 1
    Global_Node();
    y = 0;
    fuel_state = IF_MONITOR.Children(3);    % diesel=0 / gas=9 / backup=11
    op_state = IF_MONITOR.Children(2);  % run=4 / start=2 / stop=1
    a = readValue(fuel_state);
    b = readValue(op_state);
    c = readValue(dEngineSpeed);
    if b == 1 && op == 10
        y = 1;
    elseif c > 0.1 && op == 1
        y = 1;
    elseif b == 4 && op == 100 && a == 0 && fuel == 100
        y = 1;
    elseif b == 4 && op == 100 && a == 9 && fuel == 10
        y = 1;
    elseif b == 4 && op == 100 && a == 11 && fuel == 1
        y = 1;
    end
end