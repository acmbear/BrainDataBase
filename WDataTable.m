classdef WDataTable
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        data;
        rowAttribute;
        columnAttribute;
    end
    
    methods
        function obj = WDataTable(varargin)
            if nargin == 0
                obj.data = [];
                obj.rowAttribute = [];
                obj.columnAttribute = [];
            elseif nargin == 1 
                obj = openDataTable(obj, varargin{1});
            elseif nargin == 3
                obj.data = varargin{1};
                obj.rowAttribute = varargin{2};
                obj.columnAttribute = varargin{3};
            else
                error('WDataTable: invalid parameter.');
            end
%             if ~dtValidation(obj)
%                 error('WDataTable: data and attribute unmatched.');
%             end
        end

        function [obj, rowIndex, colIndex] = selectDataTable(obj, rowExpr, colExpr)
            if nargin <= 2
                colExpr = '';
            end
            
            rowIndex = [];
            colIndex = [];
            
            if ~isempty(rowExpr)
                rowIndex = select_dataset(obj.rowAttribute, rowExpr);
            end
            if ~isempty(colExpr)
                colIndex = select_dataset(obj.columnAttribute, colExpr);
            end
            obj = rangeDataTableIndex(obj, rowIndex, colIndex);
        end
        
        function obj = sortDataTable(obj, rowKeys, colKeys)
            if nargin <= 2
                colKeys = '';
            end
            % need to complete
            obj = obj;
        end
        
        function obj = rangeDataTableIndex(obj, rowIndex, columnIndex)
            if nargin <= 2
                columnIndex = [];
            end
            
            if ~isempty(rowIndex)
                obj.data = obj.data(rowIndex,:);
                func = @(x) x(rowIndex,:);
                obj.rowAttribute = wtraversestruct(func, obj.rowAttribute);
            end
            if ~isempty(columnIndex)
                obj.data = obj.data(:,columnIndex);
                func = @(x) x(:,columnIndex);
                obj.columnAttribute = wtraversestruct(func, obj.columnAttribute);
            end
        end
        
        function obj = transposeDataTable(obj)
            obj.data = obj.data';
            func = @(x) x';
            if ~isempty(obj.columnAttribute)
                rowAttr = wtraversestruct(func, obj.columnAttribute);
                obj.rowAttribute = rowAttr;
            end
            if ~isempty(obj.rowAttribute)
                columnAttr = wtraversestruct(func, obj.rowAttribute);
                obj.columnAttribute = columnAttr;
            end
        end
        
        function obj = uniqueDataTable(obj, rowExpr, colExpr)
            % need to complete
            obj = obj;
        end
        
        function [obj, rowIndex, columnIndex] = refDataTable(obj, rowKey, foreignRowValue, columnKey, foreignColumnValue)
            if nargin <= 3 
                columnKey = ''; 
            end
            rowIndex = [];
            columnIndex = [];
            if ~isempty(rowKey)
                refRowValue = obj.rowAttribute.(rowKey);
                rowIndex = wgetrefindex(foreignRowValue, refRowValue);
            end
            if ~isempty(columnKey)
                refColumnValue = obj.columnAttribute.(columnKey);
                columnIndex = wgetrefindex(foreignColumnValue, refColumnValue);
            end
            obj = rangeDataTableIndex(obj, rowIndex, columnIndex);
        end
    end
    
    methods (Access = private)
        function obj = openDataTable(obj, dtFile)
            s = load(dtFile);
            obj.data = s.data;
            obj.rowAttribute = s.rowAttribute;
            obj.columnAttribute = s.columnAttribute;
        end
        
        function result = dtValidation(obj)
            if ~isempty(obj.data)
                rowResult = false;
                colResult = false;
                [dataRowNum, dataColNum] = size(obj.data);
                [raRowNum, ~] = size(obj.rowAttribute);  % wrong, need to fix
                [~, caColNum] = size(obj.columnAttribute);  % wrong, need to fix
                if raRowNum == 0 || raRowNum == dataRowNum % row attribute can be empty, or must have the same row number as the data
                    rowResult = true;
                end
                if caColNum == 0 || caColNum == dataColNum % column attribute can be empty, or must have the same column number as the data
                    colResult = true;
                end
                result = rowResult & colResult;
            else   % data can be empty, just left row and column attribute
                result = true;
            end
        end
    end
end

function indSelected = select_dataset(metaData, expr)
% select_dataset    Select features from dataSet
%
% This file is a part of BrainDecoderToolbox2.
%
% Usage:
%
%     [y, indSelected] = select_data(dataSet, metaData, expr)
%
% Inputs:
%
% - dataSet  : Dataset matrix
% - metaData : Metadata structure
% - expr     : Feature selection expression (see below)
%
% Outputs:
%
% - y           : Matrix of selected features
% - indSelected : Column index of `dataSet` for the selected features
%
% Examples of selection expression (`expr`):
%
% - 'ROI_A = 1' : Return features in ROI_A
% - 'ROI_A = 1 | ROI_B = 1' : Return features in the union of ROI_A and ROI_B
% - 'ROI_A = 1 & ROI_B = 1' : Return features in the intersect of ROI_A and ROI_B
% - 'Stat_P top 100' : Return the top 100 features for Stat_P value
% - 'Stat_P top 100 @ ROI_A = 1' : Return the top 100 features for Stat_P value within ROI_A
%

selectExpr = parse_selectexpr(expr);

results = {}; % Stack to store results
bufSel  = []; % Buffer to store num of featrures to be selected by 'top'
for n = 1:length(selectExpr)

    if strcmp(selectExpr{n}, '=')
        % 'A = B' => A is B
        [results, mdVal] = pop_stack(results);
        [results, mdKey] = pop_stack(results);

        md = metaData.(mdKey);
        md(isnan(md)) = 0;
        
        results = push_stack(results, ...
            metaData.(mdKey) == str2num(mdVal));
    elseif strcmp(selectExpr{n}, 'not')
        [results, mdVal] = pop_stack(results);
        [results, mdKey] = pop_stack(results);

        md = metaData.(mdKey);
        md(isnan(md)) = 0;
        
        results = push_stack(results, ...
            metaData.(mdKey) ~= str2num(mdVal));
    elseif strcmp(selectExpr{n}, 'top')
        % 'A top n'
        [results, topNum] = pop_stack(results);
        [results, mdKey] = pop_stack(results);

%         mdVal = get_metadata(metaData, mdKey);
        mdVal = metaData.(mdKey);
        mdVal(isnan(mdVal)) = -Inf;
        
        [ junk, ind ] = sort(mdVal, 'descend');

        order(ind) = 1:length(mdVal);
        
        results = push_stack(results, order);
        bufSel(end + 1) = str2num(topNum);
    elseif strcmp(selectExpr{n}, '@')
        % 'A @ B' => A in B
        [results, rightTerm] = pop_stack(results);
        [results, leftTerm] = pop_stack(results);

        leftTerm(~rightTerm) = NaN;

        [selectedInd, bufSel] = select_order(leftTerm, bufSel);

        results = push_stack(results, selectedInd);
    elseif strcmp(selectExpr{n}, '|') || strcmp(selectExpr{n}, '&')
        % 'A | B' => A or B
        % 'A & B' => A and B
        [results, rightTerm] = pop_stack(results);
        [results, leftTerm] = pop_stack(results);

        if ~islogical(rightTerm)
            [rightTerm, bufSel] = select_order(rightTerm, bufSel);
        end

        if ~islogical(leftTerm)
            [leftTerm, bufSel] = select_order(leftTerm, bufSel);
        end

        if strcmp(selectExpr{n}, '|')
            results = push_stack(results, leftTerm | rightTerm);
        elseif strcmp(selectExpr{n}, '&')
            results = push_stack(results, leftTerm & rightTerm);
        end
    else
        results = push_stack(results, selectExpr{n});
    end

end

[results, indSelected] = pop_stack(results);
if ~isempty(bufSel)
    indSelected = indSelected <= bufSel(end);
end
end

%------------------------------------------------------------------------------
function rpn = parse_selectexpr(expr)
% parse_selectexpr    Lexicial analyser and parser for feature selection expression
%

signs = {'(', ')'};
operators = {'=', '|', '&', '@', 'top', 'not'};

% Lexical analysis
buf    = [];
tokens = {};

for n = 1:length(expr)
    if strcmp(expr(n), ' ')
        continue;
    elseif sum(strcmp(expr(n), signs)) | sum(strcmp(expr(n), operators))
        if ~isempty(buf)
            tokens{end+1} = buf;
            buf = [];
        end
        tokens{end+1} = expr(n);
    else
        buf = [ buf, expr(n) ];
    end
    
    if length(buf) >= 3 && strcmp(buf(end-2:end), 'not')
        if length(buf) ~= 3
            tokens{end + 1} = buf(1:end-3);
        end
        tokens{end + 1} = 'not';
        buf = [];
    end

    if length(buf) >= 3 && strcmp(buf(end-2:end), 'top')
        if length(buf) ~= 3
            tokens{end + 1} = buf(1:end-3);
        end
        tokens{end + 1} = 'top';
        buf = [];
    end
end

if ~isempty(buf)
    tokens{end+1} = buf;
    buf = [];
end

% Parser (shunting-yard)
outQue    = {};
opStack   = {};
opStackPt = 0;

for n = 1:length(tokens)
    if sum(strcmp(tokens{n}, operators))
        pp = true;
        while pp
            if opStackPt == 0
                pp = false;
            elseif strcmp(opStack{opStackPt}, '(') || strcmp(opStack{opStackPt}, ')')
                pp = false;
            elseif op_precede(tokens{n}, opStack{opStackPt})
                pp = false;
            else
                outQue{end + 1} = opStack{opStackPt};
                opStackPt = opStackPt - 1;
            end
        end

        opStackPt = opStackPt + 1;
        opStack{opStackPt} = tokens{n};
    elseif strcmp(tokens{n}, '(')
        opStackPt = opStackPt + 1;
        opStack{opStackPt} = tokens{n};
    elseif strcmp(tokens{n}, ')')
        pp = true;
        while pp
            if opStackPt == 0
                error('Parentheses mismatch');
            elseif strcmp(opStack{opStackPt}, '(')
                pp = false;
            else
                outQue{end + 1} = opStack{opStackPt};
                opStackPt = opStackPt - 1;
            end
        end
        opStackPt = opStackPt - 1;
    else
        outQue{end + 1} = tokens{n};
    end
end

for n = opStackPt:-1:1
    outQue{end + 1} = opStack{n};
end

% Output
rpn = outQue;
end

%------------------------------------------------------------------------------
function stack = push_stack(stack, element)
% push_stack    Push `element` to `stack`

stack{end + 1} = element;
end

%------------------------------------------------------------------------------
function [stack, element] = pop_stack(stack)
% pop_stack    Pop `element` from `stack`

element = stack{end};
stack = { stack{1:end-1} };
end

%------------------------------------------------------------------------------
function isPrecede = op_precede(a, b)
% op_precedence    Return true if operator precedence a > b

isPrecede = false;
switch a
  case {'=', 'not', 'top'}
    a_preced = 7;
  case {'&', '|'}
    a_preced = 5;
  case {'@'}
    a_preced = 3;
  otherwise
    error('op_precede:UnknwonOperator', ...
          [ 'Unknown operator: ', a ]);
end

switch b
  case {'=', 'not', 'top'}
    b_preced = 7;
  case {'&', '|'}
    b_preced = 5;
  case {'@'}
    b_preced = 3;
  otherwise
    error('op_precede:UnknwonOperator', ...
          [ 'Unknown operator: ', b ]);
end

isPrecede = a_preced > b_preced;
end

%------------------------------------------------------------------------------
function [ind, buf] = select_order(order, buf)
% select_order    Select `buf(end)` elements from order

numSel = buf(end);
buf = buf(1:end-1);

[junk, indOrder] = sort(order);

ind = false(size(order));
ind(indOrder(1:numSel)) = true;
end

