classdef wDBInterfaceTemplate < WDataBase
    properties
    end
    
    methods
        function obj = wDBInterfaceTemplate(dbFile)
            obj@WDataBase(dbFile);
        end
    end
    
    methods (Access = protected)
        function dtable = loadUnRegularTabel(obj, tableName, subpara)
        % code your table load function here
        end
    end
end