#include "basics/directions.lp".
#include "basics/movement.lp".
#include "basics/transitions.lp".
#include "basics/actions.lp".

% energy cost factor of trains based on power type + weight

pow_cost_fac(ID,1) :- pow_type(ID, electro).
pow_cost_fac(ID,2) :- pow_type(ID, hybrid).
pow_cost_fac(ID,3) :- pow_type(ID, diesel).
pow_cost_fac(ID,4) :- pow_type(ID, hydrogen).

cost_fac(ID,CF) :- pow_cost_fac(ID,PCF), weight(ID,W), CF = PCF * W.

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

% define energy costs of transitions:


prev_wait(ID,T) :- action(train(ID),_,T), time(T-1), action(train(ID),wait,T-1).

energy(ID,T+1,E) :- action(train(ID),wait,T), speed(ID,S), not prev_wait(ID,T), cost_fac(ID,CF), E = CF * 24 / S.

energy(ID,T2,E) :- action(train(ID),A,T), A != wait, position(ID,_,T,Dir), speed(ID,S), T2 = T + S, position(ID,_,T2,Dir), cost_fac(ID,CF), E = CF .

energy(ID,T2,E) :- position(ID,_,T,Dir1), speed(ID,S), T2 = T + S, position(ID,_,T2,Dir2), Dir1 != Dir2, cost_fac(ID,CF), E = CF * 12 / S.


 
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

% the arrival times should be minimized 

reached_earlier(ID,T) :- reached(ID,T), reached(ID,T0), T0 < T.
arrival(ID,T) :- reached(ID,T), not reached_earlier(ID,T).


#minimize { T@2,ID : arrival(ID,T) }.

#minimize { E@1,ID,T : energy(ID,T,E) }.

