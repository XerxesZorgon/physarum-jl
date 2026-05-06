Write a program in Netlogo where turtles originate at the lower left corner of a grid, choose a direction of travel and then take a step. Step lengths are bounded by min-step and max-step, and the direction is  randomly chosen between 20 and 70 degrees. Subsequent step lengths are bounded as in the first step, and new random directions are selected within 25 degrees of the previous direction. Turtles generate yellow paths of where they have been. If a turtle crosses an existing path it dies at the intersection. The program ends when one turtle reaches the upper right corner.

Here's a NetLogo program that implements the requirements you've described:

```
globals [min-step max-step]

to setup
  clear-all
  set min-step 1
  set max-step 5
  setup-patches
  setup-turtles
  reset-ticks
end

to setup-patches
  ask patches [
    set pcolor white
  ]
  ask patch 0 0 [
    set pcolor green
  ]
  ask patch max-pxcor max-pycor [
    set pcolor red
  ]
end

to setup-turtles
  create-turtles 1 [
    setxy 0 0
    set color yellow
    set heading 0
  ]
end

to go
  ask turtles [
    let direction random-float 50 + 20
    let step-length random min-step max-step
    rt direction
    fd step-length
    ifelse (xcor >= max-pxcor) or (ycor >= max-pycor) [
      stop
    ] [
      let previous-direction heading
      let min-angle previous-direction - 25
      let max-angle previous-direction + 25
      set direction random-float (max-angle - min-angle) + min-angle
      set step-length random min-step max-step
      rt direction
      fd step-length
      ifelse pcolor = yellow [
        die
      ] [
        set pcolor yellow
      ]
    ]
  ]
  tick
end
```

Here's how the program works:

- In the `setup` procedure, we initialize the simulation by clearing the world, setting the minimum and maximum step lengths, and creating the patches and turtles.
- In the `setup-patches` procedure, we set the color of all patches to white, and then set the color of the patch at the lower left corner to green and the patch at the upper right corner to red.
- In the `setup-turtles` procedure, we create one turtle at the lower left corner of the world, set its color to yellow, and set its heading to 0 (which points in the positive x-direction).
- In the `go` procedure, we update the turtles' positions and headings. For each turtle, we first randomly choose a direction to move in between 20 and 70 degrees, and a step length between `min-step` and `max-step`. We then turn the turtle in that direction and move it forward by the step length. If the turtle has reached the upper right corner, we stop the simulation. Otherwise, we randomly choose a new direction to move in within 25 degrees of the turtle's previous direction, and a new step length between `min-step` and `max-step`. We then turn the turtle in the new direction and move it forward by the step length. If the turtle's new position overlaps with a yellow patch (indicating that it has already traveled through that spot), we kill the turtle. Otherwise, we set the color of the turtle's new patch to yellow to indicate its path.

Note that this program uses the `random-float` primitive to generate random directions within a range, and the `random` primitive with two arguments to generate random step lengths within a range. The `ifelse` primitive is used to test whether the turtle's new position overlaps with a yellow patch, and to either kill the turtle or set the color of the patch to yellow accordingly.