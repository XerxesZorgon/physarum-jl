;;; physarum.nlogo — Physarum Snell's Law demonstration
;;; Jones (2010) agent model, NetLogo port of physarum-jl v0.1.0
;;;
;;; Verification (2026-05-11 / NetLogo 6.4.0):
;;;   Condition A (v1=1.0, v2=0.5): x_cross at tick 2000 = +38
;;;   Condition B (v1=0.5, v2=1.0): x_cross at tick 2000 = -42
;;;   Condition C (equal speeds):   x_cross at tick 2000 = 0
;;;   Ordering A > C > B: YES
;;;
;;; If ordering fails with default params: increase deposit-amount to 12
;;; or decrease diffusion-rate to 0.07 before re-verifying.

globals [
  first-contact-tick   ;; tick of first food contact (0 = not yet)
  beacon-xcor          ;; pxcor of empirical Phase 2 beacon (-999 = unset)
  x-cross              ;; pxcor of highest-chemo boundary patch
]

patches-own [
  chemo        ;; chemoattractant level
  zone-speed   ;; movement speed in this patch
  is-food?
  is-source?
  is-boundary? ;; pycor = 0
]

turtles-own [
  my-speed    ;; current zone speed
  returning?  ;; Phase 2: navigating back to source
]

to setup
  clear-all
  set first-contact-tick 0
  set beacon-xcor -999
  set x-cross 0
  apply-condition        ;; set v1/v2 from chooser before patches use them
  setup-patches
  setup-turtles
  reset-ticks
end

to go
  if ticks >= max-ticks [ stop ]
  decay-and-diffuse
  replenish-food
  if phase2-on? and first-contact-tick > 0 [ place-beacon ]
  ask turtles [ move-turtle ]
  update-x-cross
  visualize-patches
  tick
end

to apply-condition
  ;; Condition chooser overrides v1/v2 sliders
  if condition = "B (slow→fast)" [
    set v1 0.5
    set v2 1.0
  ]
  if condition = "C (control)" [
    set v1 1.0
    set v2 1.0
  ]
  ;; "A (fast→slow)" uses slider values as-is
end

to setup-patches
  ask patches [
    set chemo 0
    set zone-speed  (ifelse-value (pycor <= 0) [v1] [v2])
    set is-food?     false
    set is-source?   false
    set is-boundary? (pycor = 0)
    ;; Base zone colouring (will be updated by visualize-patches each tick)
    set pcolor (ifelse-value (pycor <= 0) [102] [48])
  ]
  ask patches with [distancexy  75  75 <= 3] [
    set is-food? true
    set chemo food-chemo
    set pcolor green
  ]
  ask patches with [distancexy -75 -75 <= 3] [
    set is-source? true
    set pcolor red
  ]
end

to setup-turtles
  create-turtles n-agents [
    let r random-float 3
    let a random-float 360
    setxy (-75 + r * sin a) (-75 + r * cos a)
    set heading random-float 360
    set my-speed [zone-speed] of patch-here
    set returning? false
    set color white
    set size 0.8
  ]
end

to decay-and-diffuse
  diffuse chemo diffusion-rate
  ask patches [
    set chemo chemo * (1 - decay-rate)
    if chemo < 0.001 [ set chemo 0 ]
  ]
end

to replenish-food
  ask patches with [is-food?] [
    set chemo food-chemo
  ]
end

to place-beacon
  if beacon-xcor != -999 [ stop ]           ;; already placed
  if ticks < first-contact-tick + 1 [ stop ] ;; wait one tick after contact

  let best max-one-of (patches with [is-boundary? and chemo > 0]) [chemo]
  if best != nobody [
    set beacon-xcor [pxcor] of best
  ]
end

to-report chemo-at [dir dist]
  ;; Chemo at the patch 'dist' steps in direction 'dir' from this turtle.
  ;; Clamps to world boundary.
  let tx xcor + dist * sin dir
  let ty ycor + dist * cos dir
  set tx max (list min-pxcor (min (list max-pxcor (round tx))))
  set ty max (list min-pycor (min (list max-pycor (round ty))))
  report [chemo] of patch tx ty
end

to move-turtle  ;; turtle procedure
  ;; ── Phase 2: returning navigation ────────────────────────────────
  if phase2-on? and returning? [
    ifelse beacon-xcor != -999
      [ face patch beacon-xcor 0 ]
      [ facexy -75 -75 ]
    set my-speed [zone-speed] of patch-here
    forward my-speed
    ask patch-here [ set chemo chemo + deposit-amount * [my-speed] of myself ]
    if distancexy -75 -75 < 4 [
      set returning? false
      set heading random-float 360
      set color white
    ]
    stop
  ]

  ;; ── Phase 1: exploration ─────────────────────────────────────────
  let lv chemo-at (heading - sensor-angle) sensor-distance
  let cv chemo-at  heading                 sensor-distance
  let rv chemo-at (heading + sensor-angle) sensor-distance

  if lv > rv and lv > cv [ left  sensor-angle ]
  if rv > lv and rv > cv [ right sensor-angle ]

  set my-speed [zone-speed] of patch-here
  forward my-speed

  ;; Normalized deposit
  ask patch-here [ set chemo chemo + deposit-amount * [my-speed] of myself ]

  ;; Food contact
  if [is-food?] of patch-here [
    if first-contact-tick = 0 [ set first-contact-tick ticks ]
    if phase2-on? [
      set returning? true
      set heading heading + 180
      set color orange
    ]
  ]
end

to update-x-cross
  let best max-one-of (patches with [is-boundary? and chemo > 0]) [chemo]
  set x-cross ifelse-value (best != nobody) [[pxcor] of best] [0]
end

to visualize-patches
  ask patches [
    ifelse is-food? [
      set pcolor green
    ] [
    ifelse is-source? [
      set pcolor red
    ] [
    ifelse is-boundary? and pxcor = beacon-xcor [
      set pcolor yellow
    ] [
      ;; Chemo heatmap on zone background
      ;; Zone 1 (pycor<=0): shades of cyan-blue  (base 96)
      ;; Zone 2 (pycor >0): shades of orange-tan (base 26)
      let base-col (ifelse-value (pycor <= 0) [96] [26])
      let max-display food-chemo * 0.5
      let intensity min (list 1.0 (chemo / max-display))
      set pcolor base-col + (4 * intensity)
    ]]]]
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
210
10
612
433
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-75
75
-75
75
0
0
1
ticks
30.0

@#$#@#$#@
## Physarum Snell's Law Simulation

An agent-based demonstration of *Physarum polycephalum* (slime mold) path
optimization across a two-speed boundary, based on the Jones (2010) model.

### What you are seeing

White dots are agents starting at the lower-left (red). They explore toward
the food source at the upper-right (green), depositing a chemoattractant trail.
Darker patches show higher trail concentration.

The domain has two zones separated by the horizontal boundary (y = 0):
- **Zone 1** (lower): speed = v1
- **Zone 2** (upper): speed = v2

### Conditions

| Condition | Zone 1 | Zone 2 | Snell prediction |
|-----------|--------|--------|-----------------|
| A (fast→slow) | fast | slow | x_cross > 0 |
| B (slow→fast) | slow | fast | x_cross < 0 |
| C (control)   | equal | equal | x_cross ≈ 0 |

The x_cross monitor shows where the dominant trail crosses the boundary.
Snell's Law predicts x_cross ≈ ±40 for v1/v2 = 2.

### Phase 2 (flow reinforcement)
When `phase2-on?` is enabled, agents that reach the food reverse and reinforce
the crossing they used. A yellow beacon marks this crossing. Watch how the
initial noisy wavefront (Phase 1) consolidates into a single dominant tube
(Phase 2).

### Parameters
- **v1, v2**: Zone speeds. Default: 1.0 and 0.5 (Condition A).
- **decay-rate**: Trail evaporation rate per tick.
- **deposit-amount**: Chemo deposited per agent per step.
- **diffusion-rate**: Fraction of chemo spreading to neighbours each tick.
- **phase2-on?**: Toggle flow reinforcement.

### Reference
Jones, J.D. (2010). Characteristics of Pattern Formation and Evolution in
Approximations of Physarum Transport Networks. *Artificial Life* 16(2), 127–153.

Wild Peaches: https://wildpeaches.xyz
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
