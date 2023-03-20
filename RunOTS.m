function OTS = RunOTS()
    Global_Node();  % �۷ι� ���� ����
    OTS = 0;
    
    % OTS��� on
    writeValue(Active_OTS,1); writeValue(bSimMode,1); writeValue(dEngineSpeed,10);
    pause(2)
    Reset();
    
    % ���� Start, op_mode�� sync�� �� 4�� ���� ����
    writeValue(bSimStart,1);
    tic;
    dt = toc;
    while readValue(op_mode) ~= 4 && dt < 60
        readValue(op_mode);
        dt = toc;
        pause(1);
    end
    pause(2);
    writeValue(bSimStart,0);
    
    Set_Condition(100,100);
    
    if readValue(op_mode) == 4
        OTS = 1;
    end
end