function createFLSubdialog(dlg)
% Create Fraction Length content for Numeric Type dialog
%
% We don't actually register a dialog here; this is just a helper
% function that contributes UI controls to a parent dialog.

%   Copyright 2010-2012 The MathWorks, Inc.

hParent = dlg.ContentPanel;
bg = get(hParent,'BackgroundColor');
ppos = get(hParent,'Position');
pdx = ppos(3); % initial width of parent panel, in pixels
pixelFactor = dlg.UserData.dp.PixelFactor;

% LSB dialog
dy = 108 * pixelFactor;
hBAFLPanel = uipanel('Parent',hParent, ...
    'Units','pix', ...
    'Position', [2 1 pdx-4 dy], ...
    'BorderType','none',...
    'Tag','fl_subpanel',...
    'BackgroundColor',bg);
dlg.hBAFLPanel = hBAFLPanel;

inBorder = 2;
outBorder = 2;
xL = inBorder; % inMargin - # pix separation from border to widget
xb = outBorder; % lineWidth # pix on each side of panel taken by border line
x0 = inBorder+1;
y0 = inBorder+76;
dx = pdx-2*inBorder-4;
dy = 20 * pixelFactor;
dyt = 16 * pixelFactor; % text prompt heights

% Create LSB widgets
%tip = 'Automatically set underflow threshold';

flPromptStr = getString(message('fixed:NumericTypeScope:FLConstraintPrompt'));
dlg.hBAFLPrompt =  uicontrol( ...
    'Parent', hBAFLPanel, ...
    'BackgroundColor',bg, ...
    'Units','pix', ...
    'HorizontalAlignment','left', ...
    'TooltipString','', ...
    'Position',[x0 y0 dx dyt], ...
    'String',flPromptStr,...
    'Tag','fl_constraint_prompt',...
    'Style','text'); 

y0 = y0-dy-4;    
tip = getString(message('fixed:NumericTypeScope:FLConstraintMethodToolTip'));
FLConstraintEntries = strcat(getString(message('fixed:NumericTypeScope:ConstraintOptionsSmallestMag')),'|',...
                     getString(message('fixed:NumericTypeScope:ConstraintOptionsFracBits')));
dlg.hBAFLMethod = uicontrol( ...
    'Parent', hBAFLPanel, ...
    'BackgroundColor','w', ...
    'Units','pix', ...
    'TooltipString',tip, ...
    'Position',[x0 y0 dx dy], ...
    'Callback',@(h,e)setBAFLMethod(dlg), ...
    'Value',dlg.BAFLMethod, ...
    'Style','popup', ...
    'Tag','fl_constraint_popup',...
    'String',FLConstraintEntries);  
% xxx NOTE:
% We purposefully removed 'Specify Underflow' from the popup control.
% It should be the 4th entry in the popup, if we wish to re-enable
% this method of fraction length specification in the future.
pdx2 = floor(pdx/2); % midpoint
dxL = pdx2-xb-xL-13;  % Left side is 10 pix shorter
xR = xL+dxL+4; % 1-pix gap to start of xR
dxR = pdx-xR-xb-2;

y0=y0-dy-8;
flValuePromptStr = getString(message('fixed:NumericTypeScope:FLValuePrompt'));
dlg.hBAFLValuePrompt = uicontrol( ...
    'Parent', hBAFLPanel, ...
    'BackgroundColor',bg, ...
    'HorizontalAlignment','right', ...
    'Enable','inactive', ...  % allow mouse drag on panel
    'Units','pix', ...
    'Position',[x0 y0 dxL dyt], ...
    'String',flValuePromptStr, ...
    'Tag','fl_value_prompt',...
    'Style','text');

tip = getString(message('fixed:NumericTypeScope:SmallestMagToolTip'));
dlg.hBAFLSpecifyMagnitude = uicontrol( ...
    'Parent',hBAFLPanel, ...
    'BackgroundColor','w', ...
    'TooltipString',tip, ...
    'HorizontalAlignment','left', ...
    'Units','pix', ...
    'Position',[xR y0 dxR dy], ...
    'String',sprintf('%g',dlg.BAFLSpecifyMagnitude), ...
    'Callback',@(h,e)setBAFLMagEdit(dlg,h), ...
    'Tag','fl_lsb_magnitude_edit',...
    'Style','edit'); 

tip = getString(message('fixed:NumericTypeScope:FLBitsToolTip'));
dlg.hBAFLSpecifyBits = uicontrol( ...
    'Parent',hBAFLPanel, ...
    'BackgroundColor','w', ...
    'TooltipString',tip, ...
    'HorizontalAlignment','left', ...
    'Units','pix', ...
    'Position',[xR y0 dxR dy], ...
    'String',sprintf('%g',dlg.BAFLSpecifyBits), ...
    'Callback',@(h,e)setBAFLSpecifyBits(dlg,h), ...
    'Tag','fl_bits_edit',...
    'Style','edit'); 

y0=y0-dy-8;
tip = getString(message('fixed:NumericTypeScope:ExtraFLBitsToolTip'));
flExtraBitsPromptStr = getString(message('fixed:NumericTypeScope:FLExtraBitsPrompt'));
dlg.hBAFLExtraBitsPrompt = uicontrol( ...
    'Parent',hBAFLPanel, ...
    'BackgroundColor',bg, ...
    'TooltipString',tip, ...
    'HorizontalAlignment','right', ...
    'Enable','inactive', ...
    'Units','pix', ...
    'Position',[x0 y0 dxL dyt], ...
    'String',flExtraBitsPromptStr, ...
    'Tag','fl_extra_bits_prompt',...
    'Style','text'); 

dlg.hBAFLExtraBits = uicontrol( ...
    'Parent',hBAFLPanel, ...
    'BackgroundColor','w', ...
    'TooltipString',tip, ...
    'HorizontalAlignment','left', ...
    'Units','pix', ...
    'Position',[xR y0 dxR dy], ...
    'String',sprintf('%d',dlg.BAFLExtraBits), ...
    'Callback',@(h,e)setBAFLExtraBits(dlg,h), ...
    'Tag','fl_extra_bits_edit',...
    'Style','edit'); 
