classdef WDBHelper
    properties (Access = private)
        DBINTERFACEFOLDERPOSTFIX = '_dbinterface';
        DBINTERFACETEMPLATENAME = 'wDBInterfaceTemplate';
        interfaceList
    end
    
    methods
        function obj = WDBHelper()
            obj.interfaceList = {};
        end
        
        function [obj, wdb] = connectDB(obj, dbFile)
            [dbPath, dbName, ~] = fileparts(dbFile);
            interfaceFolder = fullfile(dbPath, [dbName,obj.DBINTERFACEFOLDERPOSTFIX]);
            addpath(interfaceFolder);
            load(dbFile);
            ind = wsearchString(obj.interfaceList, db.interfaceclass, 1);
            if ~isempty(ind)
                warning('dbinterface: %s has already been opened, may override the original one!',db.interfaceclass);
            end
            wdb = feval(db.interfaceclass, dbFile);
            obj.interfaceList = [obj.interfaceList, db.interfaceclass];
%             rmpath(interfaceFolder);
        end
        
        function obj = createDB(obj, dbPath, dbName, dbInterfaceClassName)
            dbFile = fullfile(dbPath, [dbName,'.mat']);
            interfaceFolder = fullfile(dbPath, [dbName,obj.DBINTERFACEFOLDERPOSTFIX]);
            if exist(dbFile, 'file')
                error('dbFile: %s exist, cannot create a new one.', dbFile);
            end
            if exist(interfaceFolder, 'dir')
                error('dbInterfaceFolder: %s exist, cannot create a new one.', interfaceFolder);
            end
            db.interfaceclass = dbInterfaceClassName;
            db.table = {};
            try
                save(dbFile,'db');
                mkdir(interfaceFolder);
                createInterfaceMFile(obj, dbInterfaceClassName, interfaceFolder);
            catch
                delete(dbFile);
                rmdir(interfaceFolder);
                error('failed to create wDataBase: %s',dbName);
            end
            fprintf('wDataBase: %s is successfully created.\n',dbName);
            fprintf('  dbpath: %s.\n', dbPath);
            fprintf('  interfacename: %s.\n', dbInterfaceClassName);
        end
    end
    
    methods (Access = private)
        function createInterfaceMFile(obj, dbInterfaceClassName, interfaceFolder)
            templateDir = fileparts(mfilename('fullpath'));
            templateFile = fullfile(templateDir, [obj.DBINTERFACETEMPLATENAME,'.m']);
            temptext = fileread(templateFile);
            temptext = strrep(temptext, [' ',obj.DBINTERFACETEMPLATENAME], [' ',dbInterfaceClassName]);
            interfaceFile = fullfile(interfaceFolder, [dbInterfaceClassName,'.m']);
            fid = fopen(interfaceFile, 'w');
            fprintf(fid, '%s', temptext);
            fclose(fid);
        end
    end
end
