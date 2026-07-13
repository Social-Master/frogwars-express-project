#include "basics/directions.lp".
#include "basics/movement.lp".
#include "basics/transitions.lp".
#include "basics/actions.lp".

% possible times
time(0..MaxTime) :- global(MaxTime).

% define celltypes 
celltype(C) :- cell(_,C).

% interpret given train speeds as maximum speeds
max_speed(ID,S) :- speed(ID,S).

% trains start with a speed of 1/4 
temp_speed(ID, Dep, 4) :- start(ID,(_,_),Dep,_).

% convert start predicate to position predicate
position(ID,(X,Y),Dep+1,Dir) :- start(ID,(X,Y),Dep,Dir).

% define states (cell, time, direction), which are reachable by a train 
reachable(ID,T,A,X2,Y2,T2,Dir2) :- A!= wait, position(ID,(X,Y),T,Dir1), cell((X,Y),Cell), transition(Cell,Dir1,A,Dir2),delta(A,Dir2,DX,DY), X2 = X + DX, Y2 = Y + DY, temp_speed(ID,T,S), T2 = T + S, time(T2).

% to be able to wait, you need to have speed 1/4
reachable(ID,T,wait,X,Y,T+1,Dir) :- position(ID,(X,Y),T,Dir), time(T+1), temp_speed(ID,T,4).

% transitions: for every combination of ID and T, choose one reachable(), which gets true as a position()
1 { position(ID,(X2,Y2),T2,Dir2) :  reachable(ID,T,A,X2,Y2,T2,Dir2) } 1 :- position(ID,(_,_),T,_), not reached(ID,T).

% define action predicate (this is just for visualization purposes)
chosen(ID,T,A,X,Y,X2,Y2,T2) :- position(ID,(X,Y),T,_), position(ID,(X2,Y2),T2,_), reachable(ID,T,A,X2,Y2,T2,_).

% a train can change its speed by one each position change, if not exceeding a limit
1{temp_speed(ID,T2,S-1); temp_speed(ID,T2,S); temp_speed(ID,T2,S+1) }1 :- chosen(ID,T,A,_,_,_,_,T2), A != wait, temp_speed(ID,T,S), max_speed(ID,MS), S-1 >= MS, S+1 <= 4.
1{temp_speed(ID,T2,S-1); temp_speed(ID,T2,S)                        }1 :- chosen(ID,T,A,_,_,_,_,T2), A != wait, temp_speed(ID,T,S), max_speed(ID,MS), S-1 >= MS, S+1 > 4. 
1{                       temp_speed(ID,T2,S); temp_speed(ID,T2,S+1) }1 :- chosen(ID,T,A,_,_,_,_,T2), A != wait, temp_speed(ID,T,S), max_speed(ID,MS), S-1 < MS, S+1 <= 4. 
                                                  temp_speed(ID,T2,S)  :- chosen(ID,T,A,_,_,_,_,T2), A != wait, temp_speed(ID,T,S), max_speed(ID,MS), S-1 < MS, S+1 > 4.

% after waiting, you have to start with speed 1/4
                                                  temp_speed(ID,T2,4)  :- chosen(ID,T,wait,_,_,_,_,T2).

% you have to take a turn with inverse speed >= 3 
:- position(ID,_,T,Dir1), temp_speed(ID,T,S), T2 = T + S, position(ID,_,T2,Dir2), Dir1 != Dir2, S < 3.

% you can only arrive at your goal if your inverse speed was 4 before
:- reached(ID,T2), temp_speed(ID,T1,S), T2 = T1 + S, S < 4.

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
:- position(ID,(X,Y),T,_), end(ID,(EX,EY),_), max_speed(ID,MS), global(MaxTime), T + (|X-EX| + |Y-EY|)*MS > MaxTime.

% the arrival times should be minimized
reached_earlier(ID,T) :- reached(ID,T), reached(ID,T0), T0 < T.
arrival(ID,T) :- reached(ID,T), not reached_earlier(ID,T).

#minimize { T@2,ID : arrival(ID,T) }.