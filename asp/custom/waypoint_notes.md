# How to use intermediate stations in flatland

Intermediate stations are considered waypoints and look like this:

waypoint(Z, Ord, (X,Y), Dir, Arr, Dep)
Z:     Train ID
Ord:   Order of waypoint (1st, 2nd, 3rd), including start() and end()
(X,Y): Location
Dir:   Direction the train mus face (e.g. w)
Arr:   Earliest arrival time step
Dep:   Earliest departure time step