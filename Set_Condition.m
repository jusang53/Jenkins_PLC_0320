function Set_Condition(fuel, op)
    % fuel : diesel=100 / gas=10 / backup = 1
    % op : run=100 / stop=10 /  start=1
    Global_Node();
    Reset();
    fuel_state = IF_MONITOR.Children(3);    
    op_state = IF_MONITOR.Children(2);  
    a = readValue(fuel_state);          % diesel=0 / gas=9 / backup=11
    b = readValue(op_state);            % run=4 / start=2 / stop=1
    if op == 10 || op == 1
        writeValue(Diesel_mode,0);
        writeValue(Gas_mode,0);
        writeValue(Backup_mode,0);
        writeValue(Diesel_mode,1);
        Reset();
        writeValue(bSimStart,0);
        writeValue(bSimStop,0);
        writeValue(bSimStop,1);
        tic;
        dt = toc;
        while readValue(op_state) ~= 1 && dt < 60
            dt = toc;
            pause(1);
        end
        Reset();
        if op == 1
            writeValue(bSimStop,0);
            writeValue(bSimStart,1);
%             Reset();
            tic;
            dt = toc;
            while readValue(dEngineSpeed) <= 0 && dt < 60
                dt = toc;
                pause(1);
            end
            writeValue(bSimStart,0);
        end
    elseif op == 100
        if a == 11
            writeValue(Diesel_mode,0);
            writeValue(Gas_mode,0);
            writeValue(Backup_mode,0);
            writeValue(Diesel_mode,1);
            Reset();
            writeValue(bSimStart,0);
            writeValue(bSimStop,0);
            writeValue(bSimStop,1);
            tic;
            dt = toc;
            while readValue(op_state) ~= 1 && dt < 60
                dt = toc;
                pause(1);
            end
            Reset();
            if op == 1
                writeValue(bSimStop,0);
                writeValue(bSimStart,1);
    %             Reset();
                tic;
                dt = toc;
                while readValue(dEngineSpeed) <= 0 && dt < 60
                    dt = toc;
                    pause(1);
                end
                writeValue(bSimStart,0);
            end
        end
        pause(2);
        if b == 1 || a == 11
            Reset();
            writeValue(bSimStop,0);
            writeValue(bSimStart,1);
            tic;
            dt = toc;
            while readValue(op_state) ~= 4 && dt < run_limit_time
                readValue(op_state);
                dt = toc;
                pause(1);
            end
            pause(2);
            writeValue(bSimStart,0);
        elseif a == 9
            writeValue(Diesel_mode,0);
            writeValue(Gas_mode,0);
            writeValue(Backup_mode,0);
            writeValue(Diesel_mode,1);
        end
        
        tic;
        dt = toc;
        while readValue(op_state) ~= 4 && dt < 180
            dt = toc;
            pause(1);
        end
        
        if fuel == 100
        elseif fuel == 10
            writeValue(Diesel_mode,0);
            writeValue(Gas_mode,0);
            writeValue(Backup_mode,0);
            pause(1)
            writeValue(Gas_mode,1);
            tic;
            dt = toc;
            while (readValue(fuel_state) ~= 9) && dt < 180
                dt = toc;
                pause(1);
            end
        elseif fuel == 1
            writeValue(Diesel_mode,0);
            writeValue(Gas_mode,0);
            writeValue(Backup_mode,0);
            pause(1)
            writeValue(Backup_mode,1);
            tic;
            dt = toc;
            while (readValue(fuel_state) ~= 11) && dt < 180
                dt = toc;
                pause(1);
            end
        end
    end
end