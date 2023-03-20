function OTS = RunOTS()
    Global_Node();  % 글로벌 변수 선언
    OTS = 0;
    
    % OTS모드 on
    writeValue(Active_OTS,1); writeValue(bSimMode,1); writeValue(dEngineSpeed,10);
    pause(2)
    Reset();
    
    % 엔진 Start, op_mode는 sync일 때 4의 값을 가짐
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