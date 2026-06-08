% define possible transitions for every cell type

transition(32800,s,move_forward,s).
transition(32800,n,move_forward,n).

transition(1025,e,move_forward,e).
transition(1025,w,move_forward,w).

transition(4608,e,move_forward,s).
transition(4608,n,move_forward,w).

transition(16386,n,move_forward,e).
transition(16386,w,move_forward,s).

transition(72,s,move_forward,e).
transition(72,w,move_forward,n).

transition(2064,s,move_forward,w).
transition(2064,e,move_forward,n).

transition(37408,n,move_forward,n).
transition(37408,n,move_left,w).
transition(37408,s,move_forward,s).
transition(37408,e,move_forward,s).

transition(17411,w,move_forward,w).
transition(17411,w,move_left,s).
transition(17411,n,move_forward,e).
transition(17411,e,move_forward,e).

transition(32872,s,move_forward,s).
transition(32872,s,move_left,e).
transition(32872,n,move_forward,n).
transition(32872,w,move_forward,n).

transition(3089,e,move_forward,e).
transition(3089,e,move_left,n).
transition(3089,s,move_forward,w).
transition(3089,w,move_forward,w).

transition(49186,n,move_forward,n).
transition(49186,n,move_right,e).
transition(49186,s,move_forward,s).
transition(49186,w,move_forward,s).

transition(1097,w,move_forward,w).
transition(1097,w,move_right,n).
transition(1097,s,move_forward,e).
transition(1097,e,move_forward,e).

transition(34864,s,move_forward,s).
transition(34864,s,move_right,w).
transition(34864,n,move_forward,n).
transition(34864,e,move_forward,n).

transition(5633,e,move_forward,e).
transition(5633,e,move_right,s).
transition(5633,n,move_forward,w).
transition(5633,w,move_forward,w).

transition(33825,e,move_forward,e).
transition(33825,s,move_forward,s).
transition(33825,n,move_forward,n).
transition(33825,w,move_forward,w).

transition(38433,e,move_forward,e).
transition(38433,s,move_forward,s).
transition(38433,n,move_forward,n).
transition(38433,w,move_forward,w).
transition(38433,n,move_left,w).
transition(38433,e,move_right,s).

transition(50211,e,move_forward,e).
transition(50211,s,move_forward,s).
transition(50211,n,move_forward,n).
transition(50211,w,move_forward,w).
transition(50211,n,move_right,e).
transition(50211,w,move_left,s).

transition(33897,e,move_forward,e).
transition(33897,s,move_forward,s).
transition(33897,n,move_forward,n).
transition(33897,w,move_forward,w).
transition(33897,s,move_left,e).
transition(33897,w,move_right,n).

transition(35889,e,move_forward,e).
transition(35889,s,move_forward,s).
transition(35889,n,move_forward,n).
transition(35889,w,move_forward,w).
transition(35889,s,move_right,w).
transition(35889,e,move_left,n).

transition(38505,e,move_forward,e).
transition(38505,s,move_forward,s).
transition(38505,n,move_forward,n).
transition(38505,w,move_forward,w).
transition(38505,s,move_left,e).
transition(38505,w,move_right,n).
transition(38505,n,move_left,w).
transition(38505,e,move_right,s).

transition(52275,e,move_forward,e).
transition(52275,s,move_forward,s).
transition(52275,n,move_forward,n).
transition(52275,w,move_forward,w).
transition(52275,s,move_right,w).
transition(52275,e,move_left,n).
transition(52275,n,move_right,e).
transition(52275,w,move_left,s).

transition(20994,n,move_right,e).
transition(20994,n,move_left,w).
transition(20994,w,move_forward,s).
transition(20994,e,move_forward,s).

transition(16458,w,move_right,n).
transition(16458,w,move_left,s).
transition(16458,n,move_forward,e).
transition(16458,s,move_forward,e).

transition(2136,s,move_right,w).
transition(2136,s,move_left,e).
transition(2136,e,move_forward,n).
transition(2136,w,move_forward,n).

transition(6672,e,move_right,s).
transition(6672,e,move_left,n).
transition(6672,n,move_forward,w).
transition(6672,s,move_forward,w).