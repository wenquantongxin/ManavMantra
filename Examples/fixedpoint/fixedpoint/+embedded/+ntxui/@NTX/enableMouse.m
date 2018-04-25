function enableMouse(ntx)
% Requires a figure handle, not a uipanel

%   Copyright 2010 The MathWorks, Inc.

set(ntx.hFig, ...
    'WindowButtonUpFcn','', ...
    'WindowScrollWheelFcn',@(h,e)wheelMove(ntx,e), ...
    'WindowButtonMotionFcn',@(h,e)mouseMove(ntx), ...
    'WindowButtonDownFcn',@(h,e)mouseDown(ntx));