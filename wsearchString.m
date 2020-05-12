function indx = wsearchString(sList, s, iCase)

indx = [];
for i = 1 : length(sList)
    if iCase
        if strcmpi(sList{i}, s)
            indx = [indx, i];
            return;
        end
    else
        if strcmp(sList{i}, s)
            indx = [indx, i];
            return;
        end
    end
end