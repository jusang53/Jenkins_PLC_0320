function y = SafetyTest(structure_num,fuel,op)
    Global_Node(); % �۷ι� ���� ����
    waitbar(progress_bar_1/progress_bar_2,h2,sprintf('Fuel and Run mode Checked !'))  % 3
    progress_bar_1 = progress_bar_1 + 1;
    y = 0;
    
    % ���� ���� ���� Test Structure ���� �׽�Ʈ ����
    if structure_num == 1
        y = structure_1(fuel,op);
        Reset();
    end
    if structure_num == 2
        y = structure_2(fuel,op);   % ��ǲ ������ �ٸ��� structure_1�� ���� ����
        Reset();
    end
end