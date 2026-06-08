# Purpose

There were several goals of the experiment:
1. To perform a test run of benchmarking
2. To collect initial information about paths
3. To observe the relationship between solving and grounding times
4. To uncover any relationship between the global time and the max. path length

There are 14 levels, each with ten environments.

For now, we set a 300-second timeout limit. Because of this Test 05 was unattainable.

# Results

<details>
<summary>Experiment 0.0 (Global: 200)</summary>
  
```
* Train 0:      2 paths (min: 30, max:  32)  Total:   8.001 (Solve:   0.006)
* Train 1:    191 paths (min: 20, max:  88)  Total:   4.205 (Solve:   0.048)
* Train 2:      2 paths (min: 30, max:  32)  Total:   8.287 (Solve:   0.005)
* Train 3:      2 paths (min: 30, max:  32)  Total:   8.053 (Solve:   0.005)
* Train 4:      2 paths (min: 30, max:  32)  Total:   1.554 (Solve:   0.002)
* Train 5:      2 paths (min: 30, max:  32)  Total:   8.241 (Solve:   0.007)
```
</details>

<details>
<summary>Experiment 0.3 (Global: 200)</summary>

```
* Train 0:  20660 paths (min: 26, max: 140)  Total:  17.787 (Solve:   7.712)
* Train 1:   2676 paths (min: 30, max: 102)  Total:   2.834 (Solve:   0.500)
* Train 2:  40280 paths (min: 30, max: 140)  Total:  23.015 (Solve:  14.323)
* Train 3: 638932 paths (min: 16, max: 142)  Total: 168.009 (Solve: 163.487)
* Train 4:  14179 paths (min: 18, max: 102)  Total:   5.326 (Solve:   3.051)
* Train 5: 764919 paths (min: 18, max: 156)  Total: 276.158 (Solve: 266.074)
```
</details>

<details>
<summary>Experiment 0.6 (Global: 228)</summary>


```
* Train 0:      1 path  (min: 35, max:  35)  Total:  12.528 (Solve:   0.000)
* Train 1:      2 paths (min: 35, max:  37)  Total:   2.535 (Solve:   0.002)
* Train 2:      6 paths (min: 23, max:  35)  Total:   1.507 (Solve:   0.002)
* Train 3:    246 paths (min: 23, max: 101)  Total:   4.348 (Solve:   0.064)
* Train 4:      2 paths (min: 35, max:  37)  Total:   2.832 (Solve:   0.002)
* Train 5:      2 paths (min: 33, max:  37)  Total:  12.537 (Solve:   0.010)
```
</details>

# Takeaways

## Environment classification

We end up with three types of environments:
1. directionally-fixed
2. directionally-preferred (experiments 0.0 and 0.6)
3. directionally-accessible (experiment 0.3)

In directionally-preferred environments, when a train faces the preferred direction of the environment, there exists for each switch only a single direction the train can exit through -- no choice can change that (_Hypothesis: as a consequence, it can only reach its goal from one direction_). Because of this, trains end up with a prescribed path that has very little room for variation. That's why many of the trains have a limited number of paths in these environments, usually 1 or 2. When a train faces against the preferred direction of the environment, the number of possibilities grows, particularly when there are multiple opportunities for the train to switch to the preferred direction. This leads also to paths that are significantly larger in length, sometimes over 80% of the the global value (e.g. experiment 1.3, not shown here).

In short, the determining factor for the number of paths (as well as the length of the longest path) has more to do with the starting direction of a train than how far away it is from its goal. *This should be obvious in the extreme example of a train starting adjacent to its goal but facing away from it.*

## Grounding vs. Solving time

```
{ path(Z,C,C',T) : edge(C,C') } = 1 :- start(Z,_,S,_), T = S..h, not finished(Z,T-1), Z=z.
```

In directionally-preferred environments, solving is negligible and almost the entire time is spent on grounding. However, in directionally-accessible environments, the majority of the time is spent on solving (as much as 97%).

This is presumably because directionally-preferred environments prescribe most of the path, due to the lack of choices, and therefore there is less solving to perform.
