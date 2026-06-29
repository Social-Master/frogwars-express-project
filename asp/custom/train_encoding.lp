#include "basics/directions.lp".
#include "basics/movement.lp".
#include "basics/transitions.lp".
#include "basics/actions.lp".

% possible times

 time(0..MaxTime) :- global(MaxTime).

% define celltypes 

celltype(C) :- cell(_,C).

% convert start predicate to position predicate

position(ID,(X,Y),Dep+1,Dir) :- start(ID,(X,Y),Dep,Dir).

% define states (cell, time, direction), which are reachable by a train 

reachable(ID,T,A,X2,Y2,T2,Dir2) :- A!= wait, position(ID,(X,Y),T,Dir1), cell((X,Y),Cell), transition(Cell,Dir1,A,Dir2),delta(A,Dir2,DX,DY), X2 = X + DX, Y2 = Y + DY, speed(ID,S), T2 = T + S, time(T2).

reachable(ID,T,wait,X,Y,T+1,Dir) :- position(ID,(X,Y),T,Dir), time(T+1).


% transitions: for every combination of ID and T, choose one reachable(), which gets true as a position()

1 { position(ID,(X2,Y2),T2,Dir2) :  reachable(ID,T,A,X2,Y2,T2,Dir2) } 1 :- position(ID,(_,_),T,_), not reached(ID,T).


% define action predicate (this is just for visualization purposes)

chosen(ID,T,A,X,Y,X2,Y2,T2) :- position(ID,(X,Y),T,_), position(ID,(X2,Y2),T2,_), reachable(ID,T,A,X2,Y2,T2,_).

% for inverse speed !=1: define interval to stay in a cell

stay(ID,X,Y,T1) :- chosen(ID,T,_,X,Y,_,_,T2), time(T1), T <= T1, T1 < T2.

 
% trains can not occupy the same cell at the same time

:- stay(ID1,X,Y,T), stay(ID2,X,Y,T), ID1 < ID2.

% trains can not swap their position

:- stay(ID1,X1,Y1,T), stay(ID2,X2,Y2,T), stay(ID1,X2,Y2,T+1), stay(ID2,X1,Y1,T+1), ID1 < ID2.

% a train reached its target if their position matches 

reached(ID,T) :- position(ID,(X,Y),T,_), end(ID,(X,Y),_). 

% a train is not allowed to reach its target after the latest arrival time

:- reached(ID,T), end(ID,(_,_),Arr), T > Arr.

% stop searching if train is not able to reach its target anymore

:- position(ID,(X,Y),T,_), end(ID,(EX,EY),_), speed(ID,InvSpd), global(MaxTime), T + (|X-EX| + |Y-EY|)*InvSpd > MaxTime.

% the arrival times should be minimized (@2-higher priority than wait minimization)

reached_earlier(ID,T) :- reached(ID,T), reached(ID,T0), T0 < T.
arrival(ID,T) :- reached(ID,T), not reached_earlier(ID,T).

% prefer to not wait (HEURISTICS NEED CLINGO 5 OR HIGHER)
% Does not significantly reduce mean runtime because proving optimality is
% the main bottleneck, but tends to find good solutions earlier and reduces
% runtime variance by guiding the search more consistently. 

wait_position(ID,X2,Y2,T2,Dir2) :- reachable(ID,T,wait,X2,Y2,T2,Dir2).

#heuristic position(ID,(X2,Y2),T2,Dir2) : wait_position(ID,X2,Y2,T2,Dir2). [-50,1]

% minimize summed arrival times

#minimize { T@2,ID : arrival(ID,T) }.