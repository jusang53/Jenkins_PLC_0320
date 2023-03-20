Global_Node();
for reset = 1:3
    writeValue(bSimReset, 1);
    pause(2)
    writeValue(bSimReset, 0);
    pause(2)
end
pause(2)