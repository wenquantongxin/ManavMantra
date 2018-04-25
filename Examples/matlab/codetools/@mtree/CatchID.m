function o = CatchID(o)
%CatchID  o = CatchID(obj)   the catch IDs of TRY nodes in obj

% Copyright 2006-2014 The MathWorks, Inc.

    % fast for single nodes...
    lix = o.Linkno.CatchID;
    J = o.T( o.IX, 3 );
    KKK = o.Linkok( lix, o.T( o.IX, 1 ) ) & (J~=0)';
    J = J(KKK);
    J = o.T( J, 2 );  % apply 'Left' again
    J = J(J~=0);
    o.IX(o.IX) = false;   % reset
    o.IX(J)= true;
    o.m = length(J);
end