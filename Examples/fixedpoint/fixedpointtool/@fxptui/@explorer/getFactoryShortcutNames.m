function [factoryNames, actions] = getFactoryShortcutNames(h) %#ok<INUSD>
% GETFACTORYSHORTCUTNAMES Get the factoryBatchActionSettings.

%   Copyright 2010-2015 The MathWorks, Inc.

factoryNames = {...
    fxptui.message('lblDblOverride'),... 
    fxptui.message('lblFxptOverride'),... 
    fxptui.message('lblSglOverride'),... 
    fxptui.message('lblMMOOff'),... 
    fxptui.message('lblDTOMMOOff')...
    };
actions = [];




% [EOF]
