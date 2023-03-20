function [f, r] = mode_check(fuel, op)
    Global_Node();
    f = " ";
    r = " ";
    if fuel == 100
        f = "Diesel";
    elseif fuel == 10
        f = "Gas";
    elseif fuel == 1
        f = "Backup";
    end
    
    if op == 100
        r = "Run";
    elseif op == 10
        r = "Stop";
    elseif op == 1
        r = "Start";
    end
end