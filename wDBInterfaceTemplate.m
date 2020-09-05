classdef wDBInterfaceTemplate < WDataBase
    properties
    end
    
    methods
        function obj = wDBInterfaceTemplate(dbFile, readonly)
            obj@WDataBase(dbFile, readonly);
        end
    end
    
    methods (Access = protected)
        function [obj, dtable] = loadUnRegularTabel(obj, tableName, subpara)
        % code your table load function here
        end
    end
end