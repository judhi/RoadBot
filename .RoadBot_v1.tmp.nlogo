; some of the codes inspired by https://netlogoweb.org/launch#https://netlogoweb.org/assets/modelslib/Sample%20Models/Social%20Science/Traffic%202%20Lanes.nlogo

globals [
  selected-car    ; the currently selected car
  lanes           ; a list of the y coordinates of different lanes
  number-of-lanes ; max num of total lanes
  lanes-to-east
  lanes-to-west
  cones-are-moving
  min-speed
]

breed [cones cone]
breed [cars car]

cars-own [
  speed         ; the current speed of the car
  top-speed     ; the maximum speed of the car (different for all cars)
  target-lane   ; the desired lane of the car
  patience      ; the driver's current level of patience
  obstacle   ; blocked by cone
  original-color
  facing
]

to setup
  clear-all
  set min-speed 0.07
  set number-of-lanes 4
  set lanes-to-east [-1 -3]
  set lanes-to-west [1 3]
  set cones-are-moving 0
  set-default-shape cars "car"
  draw-road
  draw-cones
  create-or-remove-cars-going-east
  create-or-remove-cars-going-west
  reset-ticks
end

to go
  ask cones [move-cones]
  ask cars [
    move-forward
  ]
  create-and-remove-cars
  ask cars with [ patience <= 0 ] [choose-new-lane]
  ask cars with [ ycor != target-lane ] [ move-to-target-lane ]
  ;ask cars with [ obstacle = 1 ] [change-to-right-lane]
  tick
end

; **************** road related codes *******************
to draw-road
  ask patches [
    ; the road is surrounded by green grass of varying shades
    set pcolor green - random-float 0.5
  ]
  set lanes n-values number-of-lanes [ n -> number-of-lanes - (n * 2) - 1 ]
  ask patches with [ abs pycor <= number-of-lanes ] [
    ; the road itself is varying shades of grey
    set pcolor grey - 2.5 + random-float 0.25
  ]
  let y (last lanes) - 1 ; start below the "lowest" lane
  while [ y <= first lanes + 1 ] [
    if not member? y lanes [
      ; draw lines on road patches that are not part of a lane
      ifelse abs y = number-of-lanes
        [ draw-line y yellow 0 ]  ; yellow for the sides of the road
        [ draw-line y white 0.6 ] ; dashed white between lanes
    ]
    set y y + 1 ; move up one patch
  ]
  create-turtles 1 [ ; temporary turtle to write label WEST and EAST
    setxy (min-pxcor + 1) 5
    set shape "square"
    set color green
    set label "WEST"
  ]
  create-turtles 1 [
    setxy (max-pxcor - 0.5) -5
    set shape "square"
    set color green
    set label "EAST"
  ]
end

to draw-line [ y line-color gap ]
  create-turtles 1 [ ; temporary turtle to draw line
    setxy (min-pxcor - 0.2) y
    hide-turtle
    set color line-color
    set heading 90

    repeat world-width [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

; **************** CONES related codes *******************
to draw-cones
  let xpos min-pxcor
  repeat world-width [
    create-cones 1 [
      setxy xpos 0
      set size 0.7
      set color yellow
      set shape "triangle"
      set heading 180
      set xpos ( xpos + 1 )
    ]
  ]
end

to move-cones ; this is to move cone up or down the line
  let target-divider-line 0
  if (pos = 1) [
    set target-divider-line 2
  ]
  if (pos = 0) [
    set target-divider-line 0
  ]
  if (pos = -1) [
    set target-divider-line -2
  ]
  facexy xcor target-divider-line
  let ycor1 precision ycor 3 ; to avoid floating point errors
  ifelse ( ycor1 != target-divider-line) [
    set color orange
    forward 0.0005
    set cones-are-moving 1
  ] [
    set color yellow
    set cones-are-moving 0
  ]
end
; ------------------------------------------------------------------


; **************** cars related codes *******************
to create-and-remove-cars
  let cars-heading-east cars with [heading = 90]
  let cars-heading-west cars with [heading = 270]
  ;set
  if count cars-heading-east > cars-going-east [ ; remove excess car(s) heading east, if any
    let n count cars-heading-east - cars-going-east
    ask n-of n cars-heading-east [ die ]
  ]
  if count cars-heading-west > cars-going-west [ ; remove excess car(s) heading east, if any
    let n count cars-heading-west - cars-going-west
    ask n-of n  cars-heading-west [ die ]
  ]
  if( count cars-heading-east < cars-going-east) and (random 2 = 1) [ ; create one car heading east, if needed
    create-cars 1 [
      let start-car-at [-1 -3]
      set shape one-of [ "car" "truck" ]
      ifelse (shape = "truck") [ set size 1 ] [ set size 0.9 ]
      if (min [ycor] of cones >= 0) [ set start-car-at [-1 -3] ]
      if (min [ycor] of cones < -0.05) [ set start-car-at [-3] ]
      if (min [ycor] of cones > 1.8) [ set start-car-at [1 -1 -3] ]
      setxy min-pxcor one-of start-car-at
      set lanes-to-east start-car-at
      set target-lane pycor
      let this-car self
      if any? cars-here with [ self != this-car ] [die]
      set color car-color
      set original-color color
      set heading 90
      set facing "east"
      set speed min-speed + random-float 0.05
      set top-speed speed + random-float 0.05
      set patience random max-patience
    ]
  ]
  if (count cars-heading-west < cars-going-west) and (random 2 = 1) [ ; create one car heading west, if needed
    create-cars 1 [
      set shape one-of [ "car-l" "truck-l" ]
      ifelse (shape = "truck") [ set size 1 ] [ set size 0.9 ]
      let start-car-at [1 3]
      if (max [ycor] of cones > 0.05) [ set start-car-at [3] ]
      if (max [ycor] of cones <= 0.05) [ set start-car-at [1 3] ]
      if (max [ycor] of cones < -1.8) [ set start-car-at [-1 1 3] ]
      setxy max-pxcor one-of start-car-at
      set lanes-to-west start-car-at
      set target-lane pycor
      let this-car self
      if any? cars-here with [ self != this-car ] [die]
      set color car-color
      set original-color color
      set heading 270
      set facing "west"
      set speed min-speed + random-float 0.05
      set top-speed speed + random-float 0.05
      set patience random max-patience
    ]
  ]
end

to create-or-remove-cars-going-east
  ; create cars
  let road-patches-east patches with [ member? pycor [-1 -3] ]
  if cars-going-east > count road-patches-east [
    set cars-going-east count road-patches-east - 10
  ]
  create-cars (cars-going-east - count cars with [ heading = 90 ]) [
    set shape one-of [ "car" "truck" ]
    ifelse (shape = "truck") [ set size 1 ] [ set size 0.9 ]
    set color car-color
    set original-color color
    move-to one-of free road-patches-east
    set target-lane pycor
    set heading 90
    set facing "east"
      set speed min-speed + random-float 0.05
      set top-speed speed + random-float 0.05
    set patience random max-patience
  ]
end

to create-or-remove-cars-going-west
  ; create cars
  let road-patches-west patches with [ member? pycor [1 3] ]
  if cars-going-west > count road-patches-west [
    set cars-going-west count road-patches-west
  ]
  create-cars (cars-going-west - count cars with [ heading = 270 ]) [
    set shape one-of [ "car-l" "truck-l" ]
    ifelse (shape = "truck-l") [ set size 1 ] [ set size 0.9 ]
    set heading 270
    set facing "west"
    set color car-color
    set original-color color
    move-to one-of free road-patches-west
    set target-lane pycor
      set speed min-speed + random-float 0.05
      set top-speed speed + random-float 0.05
    set patience random max-patience
  ]
end


to-report free [ road-patches ] ; turtle procedure
  let this-car self
  report road-patches with [
    not any? turtles-here with [ self != this-car ]
  ]
end

to move-forward                                    ; ############ MOVE FORWARD ####################
  ; check if there's any blocking car in front
  ; if so, slow-down, match the speed to the car in front

  ; check if there's any approaching obstacle (cones) in right front within 1 patch distance and angle 45 degree
  ; (use patch-right-and-ahead)
  ; if so, set obstacle = 1
  ifelse facing = "east" [set heading 90] [set heading 270]
  if (xcor > max-pxcor) or (xcor < min-pxcor) [ die ] ; disapear at the end of screen
  ; check for other car
  let blocking-cars other cars in-cone (1 + speed) 180 with [ y-distance <= 2 ]
  let blocking-car min-one-of blocking-cars [ distance myself ]
  ifelse blocking-car != nobody [
    ; match the speed of the car ahead of you and then slow
    ; down so you are driving a bit slower than that car.
    set obstacle 1
    set speed [ speed ] of blocking-car
    slow-down
  ] [
    set obstacle 0
    set patience max-patience
    speed-up
  ]
  forward speed
end

to change-to-any-lane
  ; make the car to change to any lane (right or left)
  ; reset the patience to max-patience after changing lane and speed up
  ; see original example
end

to change-to-right-lane
  ; make the car to change to left lane only when there's approaching obstacle/cone from the right side
  ; reset the patience to max-patience after changing lane and speed up
  ; see the original example
end

to slow-down
    set speed (speed - deceleration)
    if speed < 0 [ set speed 0.001 ]
    set patience patience - 1
    ifelse patience < 0 [
      set color red
      set patience -1
    ] [ set color original-color ]
end

to speed-up
  set speed speed + acceleration
  if (speed > top-speed) [ set speed top-speed ]
  ; add speed based on acceleration variable
end

to-report car-color
  report one-of [ blue cyan sky yellow] + 1.5 + random-float 1.0
end

to choose-new-lane ; turtle procedure
  ; Choose a new lane among those with the minimum
  ; distance to your current lane (i.e., your ycor).
  ifelse (heading = 270) [set lanes lanes-to-west] [set lanes lanes-to-east]
  let other-lanes remove ycor lanes
  if not empty? other-lanes [
    let min-dist min map [ y -> abs (y - ycor) ] other-lanes
    let closest-lanes filter [ y -> abs (y - ycor) = min-dist ] other-lanes
    set target-lane one-of closest-lanes
    set patience max-patience
  ]
end

to move-to-target-lane ; turtle procedure
  let current-heading heading
  if (target-lane < ycor) and (current-heading < 180) [set heading 150]
  if (target-lane > ycor) and (current-heading < 180) [set heading 60]
  if (target-lane < ycor) and (current-heading > 180) [set heading 230]
  if (target-lane > ycor) and (current-heading > 180) [set heading 300]
  forward 0.008
end

; *************************** buttons ***************


to west-plus
  if cars-going-west < 50 [
    set cars-going-west cars-going-west + 1
  ]
end

to west-minus
  if cars-going-west > 0 [
    set cars-going-west cars-going-west - 1
  ]
end

to east-plus
  if cars-going-east < 50 [
    set cars-going-east cars-going-east + 1
  ]
end

to east-minus
  if cars-going-east > 0 [
    set cars-going-east cars-going-east - 1
  ]
end

to-report x-distance
  report distancexy [ xcor ] of myself ycor
end

to-report y-distance
  report distancexy xcor [ ycor ] of myself
end
@#$#@#$#@
GRAPHICS-WINDOW
10
30
834
375
-1
-1
16.0
1
10
1
1
1
0
0
0
1
-25
25
-10
10
0
0
1
ticks
30.0

SLIDER
835
29
976
62
max-patience
max-patience
0
60
5.0
1
1
NIL
HORIZONTAL

SLIDER
835
62
975
95
deceleration
deceleration
0.01
0.1
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
835
95
974
128
acceleration
acceleration
0.001
0.01
0.002
0.001
1
NIL
HORIZONTAL

BUTTON
873
164
975
204
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
874
210
974
250
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
836
253
975
286
cars-going-east
cars-going-east
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
836
127
975
160
cars-going-west
cars-going-west
0
50
17.0
1
1
NIL
HORIZONTAL

SLIDER
836
160
869
252
pos
pos
-1
1
0.0
1
1
NIL
VERTICAL

BUTTON
840
297
895
330
West +
west-plus
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
841
332
896
365
West -
West-minus
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
901
297
960
330
East +
East-plus
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
901
333
960
366
East -
East-minus
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
13
383
344
533
Cars per Direction
Time
# cars
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"to East" 1.0 0 -955883 true "" "plot count cars with [facing = \"east\"]"
"to West" 1.0 0 -11033397 true "" "plot count cars with [facing = \"west\"]"

PLOT
359
383
689
533
Cars Changing Lane
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"to East" 1.0 0 -955883 true "" "plot count cars with [facing = \"east\"] with [target-lane != ycor]"
"to West" 1.0 0 -11033397 true "" "plot count cars with [facing = \"west\"] with [target-lane != ycor]"

PLOT
699
381
974
531
Car Speed
NIL
NIL
10.0
10.0
0.0
0.1
true
true
"" ""
PENS
"to East" 1.0 0 -2674135 true "" "plot mean [speed] of cars with [facing = \"east\"]"
"to West" 1.0 0 -7500403 true "" "plot mean [speed] of cars with [facing = \"west\"]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car-l
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

truck-l
false
0
Rectangle -7500403 true true 105 45 296 187
Polygon -7500403 true true 4 193 4 150 41 134 56 104 92 104 93 194
Rectangle -1 true false 105 60 105 105
Polygon -16777216 true false 62 112 48 141 81 141 82 112
Circle -16777216 true false 24 174 42
Rectangle -7500403 true true 86 185 119 194
Circle -16777216 true false 114 174 42
Circle -16777216 true false 234 174 42
Circle -7500403 false true 234 174 42
Circle -7500403 false true 114 174 42
Circle -7500403 false true 24 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
