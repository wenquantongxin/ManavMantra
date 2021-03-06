function y = beta(z,w)
%BETA   Beta function.
%   Y = BETA(Z,W) computes the beta function for corresponding
%   elements of Z and W.  The beta function is defined as
%
%   beta(z,w) = integral from 0 to 1 of t.^(z-1) .* (1-t).^(w-1) dt.
%
%   The arrays Z and W must be real and nonnegative. Both arrays must be 
%   the same size, or either can be scalar.
%
%   Class support for inputs Z,W:
%      float: double, single
%
%   See also BETAINC, BETALN.

%   Ref: Abramowitz & Stegun, Handbook of Mathematical Functions, sec. 6.2.
%   Copyright 1984-2012 The MathWorks, Inc. 

y = exp(betaln(z,w));

