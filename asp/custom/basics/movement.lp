% define coordinate change based on wait / direction after transition 

moving(move_forward).
moving(move_left).
moving(move_right).

delta(A,s,1,0)  :- moving(A).
delta(A,n,-1,0) :- moving(A).
delta(A,e,0,1)  :- moving(A).
delta(A,w,0,-1) :- moving(A).