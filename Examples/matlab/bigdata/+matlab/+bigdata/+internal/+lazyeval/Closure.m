%Closure
% A class that represents an operation combined with its corresponding inputs.

% Copyright 2015-2017 The MathWorks, Inc.

classdef (Sealed) Closure < handle
    properties (SetAccess = immutable)
        % A unique ID.
        Id;
        
        % A unique ID char vector.
        IdStr;
        
        % The underlying operation of this closure.
        Operation;
        
        % An ordered list of ClosureFuture instances that represent each of
        % the inputs to be given the operation.
        InputFutures;
        
        % An ordered list of ClosurePromise instances that represent each
        % of the outputs generated by the operation.
        OutputPromises;
        
        % Unique Predecessor nodes.
        Predecessors;
    end
    
    properties (Dependent)
        % Unique Successor nodes.
        Successors;
    end
    
    properties (Access = private, Constant)
        % The means by which this class receives unique IDs.
        IdFactory = matlab.bigdata.internal.util.UniqueIdFactory('Closure');
    end
    
    methods
        % The main constructor.
        %  inputFutures must be a list of ClosureFuture instances.
        %  operation must be an instance of a subclass of Operation.
        function obj = Closure(inputFutures, operation, isPartitionIndependent)
            import matlab.bigdata.internal.lazyeval.ClosurePromise;
            
            if nargin < 3
                isPartitionIndependent = true;
            end
            if isscalar(isPartitionIndependent)
                isPartitionIndependent = false(operation.NumOutputs, 1) | isPartitionIndependent;
            end
            
            obj.Id = obj.IdFactory.nextId();
            obj.IdStr = sprintf('closure_%s', obj.Id);
            obj.InputFutures = inputFutures;
            obj.Operation = operation;
            
            numOutputs = operation.NumOutputs;
            outputPromises = cell(numOutputs, 1);
            for ii = 1:numOutputs
                outputPromises{ii} = ClosurePromise(obj, ii, isPartitionIndependent(ii));
            end
            obj.OutputPromises = vertcat(outputPromises{:});
            
            obj.Predecessors = unique(obj.InputFutures);
        end
        
        function succ = get.Successors(obj)
            % We do not need to call unique, it is not valid for multiple
            % outputs of a closure to correspond to the same ClosurePromise
            % object.
            succ = obj.OutputPromises;
        end
        
        % Get a list of the closures that this instance directly depends on.
        function dependencies = getDirectDependencies(obj)
            inputPromises = vertcat(obj.InputFutures.Promise);
            if isempty(inputPromises)
                dependencies = matlab.bigdata.internal.lazyeval.Closure.empty();
            else
                inputClosures = vertcat(inputPromises.Predecessors);
                [~, idx] = unique({inputClosures.Id});
                dependencies = inputClosures(idx);
            end
        end
    end
end