classdef WDataBase
    
    properties (Access = public)
        DBPath
        DBName
        DBFile
        DB
    end
    
    properties (Access = private)
        INTERFACECLASSFIELD = 'interfaceclass';
        TABLENAMEFIELD = 'table';
    end
    
    methods
        function obj = WDataBase(dbFile)
            obj = openDataBase(obj, dbFile);
        end
        
        function dtable = loadTable(obj, tableName, subpara)
            ind = wsearchString(obj.DB.(obj.TABLENAMEFIELD)(:,1), tableName, 1);
            if isempty(ind)
                dtable = loadUnRegularTabel(obj, tableName, subpara);
            else
                relativePath = obj.DB.(obj.TABLENAMEFIELD){ind(1),2};
                if isempty(relativePath)
                    dtable = loadUnRegularTabel(obj, tableName, subpara);
                else
                    dtable = loadRegularTabel(obj, tableName, subpara);
                end
            end
        end
        
        function obj = addTable(obj, tableName, tableFile)
            tableList = obj.DB.(obj.TABLENAMEFIELD);
            if ~isempty(tableList)
                ind = wsearchString(tableList(:,1), tableName, 1);
                if ~isempty(ind)
                    error('table: %s exists, cannot create a new one',tableName);
                end
            end
            if isempty(tableFile)
                relTableFile = '';
            else
                [tableFilePath,tableFileName,tableFileExt] = fileparts(tableFile);
                tableFilePath = wabsolutePath(tableFilePath);
                relPath = relativepath(tableFilePath, obj.DBPath);
                relTableFile = fullfile(relPath,[tableFileName,tableFileExt]);
            end
            tableList = [tableList; {tableName, relTableFile}];
            obj.DB.(obj.TABLENAMEFIELD) = tableList;
            saveDB(obj);
        end
        
        function obj = saveDB(obj)
            db = obj.DB;
            save(obj.DBFile, 'db');
        end
    end
    
    methods (Access = protected)
        function dtable = loadUnRegularTabel(obj, tableName, subpara)
            dtable = WDataTable();
        end
        
        function dtable = loadRegularTabel(obj, tableName, subpara)
            ind = wsearchString(obj.DB.(obj.TABLENAMEFIELD)(:,1), tableName, 1);
            relativePath = obj.DB.(obj.TABLENAMEFIELD){ind(1),2};
            tPath = fullfile(obj.DBPath, relativePath);
            dtable = WDataTable(tPath);
        end
        
        function obj = openDataBase(obj, dbFile)
            load(dbFile, 'db');
            [result, msg] = dbValidation(obj, db);
            if result
                obj.DBFile = dbFile;
                obj.DB = db;
                [dbPath, dbName, dbExt] = fileparts(dbFile);
                obj.DBPath = wabsolutePath(dbPath);
                obj.DBName = dbName;
            else
                error(msg);
            end
        end
        
        function [result, msg] = dbValidation(obj, DB)
            result = true;
            msg = '';
            if ~isfield(DB, obj.INTERFACECLASSFIELD)
                result = false;
                msg = sprintf('error: find no interfaceclass in DB.');
                return;
            end
            
            if ~strcmpi(DB.(obj.INTERFACECLASSFIELD), class(obj))
                result = false;
                msg = sprintf('error: interfaceclass unmatched. DB.interfaceclass=%s, current class=%s',...
                    DB.(obj.INTERFACECLASSFIELD), class(obj));
                return;
            end
        end
    end
end