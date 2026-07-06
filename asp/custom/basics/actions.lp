action(train(ID),A,T) :- chosen(ID,T,A,_,_,_,_,_).
action(train(ID),move_forward,Dep) :- start(ID,_,Dep,_), Dep > 0.
action(train(ID),wait,T) :- start(ID,_,Dep,_), Dep > 0, T = 0..Dep-1.