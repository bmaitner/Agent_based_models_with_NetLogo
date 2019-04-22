globals
[
  month
  year
;  survival-prob     ; Probability of a bird surviving one month MOVED TO SLIDER
  fecundity         ; Number of offspring of either sex
  scouting-distance ; Distance over which birds scout
  scouting-survival ; Probability of surviving a scouting trip
  
  group-sizes       ; A list of group sizes by patch, for output
  foray-ages        ; A list of ages at which birds foray
  non-alpha-ages    ; A list of ages at which birds *consider* forays
  foray-months       ; A list of months at which birds foray
]

turtles-own
[
  is-alpha?
  is-female?
  age-in-months
]


to setup
  
  clear-all
  reset-ticks
  
  ; Set parameters and globals
  set month 0
  set year 1
;  set survival-prob 0.99  MOVED TO SLIDER
  set fecundity 2
  set scouting-distance 5
  set scouting-survival 0.8
  
  set group-sizes []  ; An empty list
  set foray-ages []  ; An empty list
  set non-alpha-ages []  ; An empty list
  set foray-months []  ; An empty list
  
  ; Shade the patches
  ask patches
  [
    ifelse (remainder pxcor 2) = 0.0
    [ set pcolor 8]
    [ set pcolor 9]
  ]
  
  ; Create birds
  ask patches
  [
    sprout 4
    [
      set is-alpha? false
      set is-female? false
      set color blue
      set shape "circle"
      set size 0.1
      setxy (pxcor - 0.4 + random-float 0.8) (pycor - random-float 0.4)
      set age-in-months 1 + random 24
    ]
    
    ask n-of 2 turtles-here 
    [
      set is-female? true
      set color pink
    ]
    
    ask max-one-of (turtles-here with [is-female?]) [age-in-months] [become-alpha]
    
    ask max-one-of (turtles-here with [not is-female?]) [age-in-months] [become-alpha]
    
  ]
  
  ; Open test output file
  ; First, delete it instead of appending to it

;  if (file-exists? "HoopoeModel-Test.csv") 
;  [carefully [file-delete "HoopoeModel-Test.csv"] 
;    [print error-message]]
;  file-open "HoopoeModel-Test.csv"
  
end


to go
  
  tick
  
  if year = 22 and month = 12 
  [
    file-close
    stop
  ]
  
  update-date-and-ages
  
  if month = 1 [clear-drawing] ; Remove move traces each year
  
  ask patches [promote-alphas]
  
  ask turtles with [(age-in-months > 12) and (not is-alpha?)] [scout]
  
  if (month = 12) [ask turtles with [is-female? and is-alpha?] [reproduce]]
  
  ask turtles [do-mortality]
  
  if year > 2 [update-output]
  
end


to update-date-and-ages
  
  set month month + 1
  if month > 12 
  [
    set month 1
    set year year + 1
  ]
  
  ask turtles [set age-in-months age-in-months + 1]
  
end


to promote-alphas  ; a patch procedure
  
  let adult-females turtles-here with [is-female? and age-in-months > 12]
  let adult-males turtles-here with [(not is-female?) and age-in-months > 12]
  
  if (any? adult-females) and (not any? adult-females with [is-alpha?])
  [
    ask max-one-of adult-females [age-in-months] [become-alpha]
  ]
  
  if (any? adult-males) and (not any? adult-males with [is-alpha?])
  [
    ask max-one-of adult-males [age-in-months] [become-alpha]
  ]
  
end


to scout  ; a turtle procedure
  
  ; Record age for output
  set non-alpha-ages lput age-in-months non-alpha-ages
  
  ; Test output
 ;  file-type (word who "," month "," is-alpha? "," is-female? "," age-in-months "," I-should-scout-direct ",")
 ;  ask other turtles-here
 ;  [file-type (word is-alpha? "," is-female? "," age-in-months ",")]
 ;  file-print count turtles-here

  ; First decide whether to scout
  if not I-should-scout [stop]
  
  ; Then do it
  ; Record age of forayers for output
  set foray-ages lput age-in-months foray-ages
  set foray-months lput month foray-months
  
  
  ; First remember where home is
  let start-x xcor
  let start-y ycor
  
  ; Choose positive or negative X direction
  let step 1
  if random-bernoulli 0.5 [set step -1]
  
  ; Then go
  repeat scouting-distance
  [
    setxy (xcor + step) ycor
    if not any? (other turtles-here) with [(is-female? = [is-female?] of myself) and is-alpha?]
    [
      ; Go back and draw a line to here
      let new-x xcor
      let new-y ycor
      setxy start-x start-y
      pen-down
      setxy new-x new-y
      
      become-alpha
      pen-up
      set shape "square"
      stop ; End the "repeat" loop
    ]
  ]
  
  ; Go home if did not become alpha
  if not is-alpha? [setxy start-x start-y]
  
  ; Incur mortality
  if (not random-bernoulli scouting-survival) [die]
  
end


to-report I-should-scout  ; a turtle reporter, returns a boolean
  ; This trait assumes the decision depends on whethere there are any 
  ; older non-alphas, using a "rule of thumb". See "Submodels" on the Info tab.
  ifelse any? (other turtles-here) with 
   [
     (is-female? = [is-female?] of myself) and
     (not is-alpha?) and
     (age-in-months > [age-in-months] of myself)]
    [ifelse random-bernoulli scout-prob 
      [report true]
      [report false]
    ]
    [report false]
  
end


to reproduce  ; a turtle procedure only executed by female alphas
  
  ; Cannot reproduce if there is no male alpha
  if not any? turtles-here with [(not is-female?) and is-alpha?] [stop]
  
  hatch fecundity
  [
    set age-in-months 0
    set is-alpha? false
    set is-female? false
    set color blue
    set shape "circle"
    set size 0.1
    setxy (pxcor - 0.4 + random-float 0.8) (pycor - random-float 0.4)
    if random-bernoulli 0.5 
    [
      set is-female? true
      set color pink
    ]
  ]

end


to do-mortality  ; a turtle procedure
  
  if (not random-bernoulli survival-prob) [die]

end


to become-alpha  ; turtle procedure done any time a bird becomes alpha
  
  set is-alpha? true
  set size 0.2
  setxy (pxcor - 0.4 + random-float 0.8) (pycor + random-float 0.4)

end


to update-output
  
  ; Histogram group sizes, using data only from month 12 and years 3 and higher
  if month = 12 and year > 2 
  [
    set-current-plot "Group Size Histogram"
    ask patches  ; Put current group sizes on a permanent list of all values
                 ; to make this a cumulative histogram over the whole run
    [
      set group-sizes lput (count turtles-here with [age-in-months > 12]) group-sizes
    ]
  
    histogram group-sizes
  ]
  
  set-current-plot "Foray Month Histogram"
  histogram foray-months
  
  set-current-plot "Ages"
  set-current-plot-pen "Non-alphas"
  ifelse length non-alpha-ages > 0
  [plot mean non-alpha-ages]
  [plot 0]
  set-current-plot-pen "Forayers"
  ifelse length foray-ages > 0
  [plot mean foray-ages]
  [plot 0]
;  histogram foray-ages
 ; show count turtles with [is-alpha?]
  
end


to-report random-bernoulli [probability-true]

  ; First, do some defensive programming to make sure "probability-true"
  ; has a sensible value

  if (probability-true < 0.0 or probability-true > 1.0) 
    [ 
      type "Warning in random-bernoulli: probability-true equals "
      print probability-true
    ]

  if-else random-float 1.0 < probability-true
  [report true]
  [report false]

end
@#$#@#$#@
GRAPHICS-WINDOW
14
10
774
71
12
0
30.0
1
10
1
1
1
0
1
0
1
-12
12
0
0
0
0
1
ticks
30.0

BUTTON
16
99
79
132
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

MONITOR
15
144
72
189
Year
year
0
1
11

MONITOR
76
143
133
188
Month
month
0
1
11

BUTTON
89
99
152
132
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
15
194
98
239
NIL
count turtles
17
1
11

BUTTON
158
99
221
132
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

PLOT
14
251
271
432
Group Size Histogram
Number of birds
Number of groups
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
287
257
541
419
Ages
Tick
Mean age (mo.)
0.0
200.0
0.0
10.0
true
true
"" ""
PENS
"Non-alphas" 1.0 0 -16777216 true "" ""
"Forayers" 1.0 0 -2674135 true "" ""

PLOT
258
92
458
242
Foray Month Histogram
Month
Number forays
0.0
12.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

MONITOR
139
143
206
188
Vacancies
(count patches * 2) - count turtles with [is-alpha?]
0
1
11

SLIDER
493
95
665
128
survival-prob
survival-prob
0.9
1
0.993
.001
1
NIL
HORIZONTAL

SLIDER
492
131
664
164
scout-prob
scout-prob
0
1.00
0.5
.001
1
NIL
HORIZONTAL

@#$#@#$#@
#Woodhoopoe Model
This is the simplified Woodhoopoe model from Section 19.4.3 of _Agent-based and Individual-based Modeling: A Practical Introduction_. The key adaptive trait of scouting for vacant territories is the simple version described in Section 20.5 for an exercise in model calibration. 

An error in the book text describing the scouting trait is described below at "Submodels".

##Purpose
The purpose of the model is to illustrate how the dynamics of a population of group-living woodhoopoes, and the dynamics of its social groups, depend on the trait individuals use to decide when to leave their group. The model provides a laboratory for developing theory for the woodhoopoes’ scouting foray trait.

##Entities, state variables, and scales
The model entities are territories and birds. A territory represents both a collective—a social group of birds—and the space occupied by the group (territories can also be empty, though). Territories are represented as a one-dimensional row of 25 NetLogo patches, “wrapped” so that the two ends of the row are considered adjacent. The only state variables of territories are a coordinate for their position in the row and a list of the birds in them. Birds have state variables for their sex, age (in months), and whether they are alpha. The time step is one month. Simulations run for 22 years, with results from the initial two “warm-up” years ignored.

##Process overview and scheduling
The following actions are executed in the given order once per time step. The order in which the birds and territories execute an action is always randomized and state variables are updated immediately, after each action. 

  1.	Date and ages are updated. The current year and month are advanced by one month, and the age of all birds is increased by one month.

  2.	Territories fill vacant alpha positions. If a territory lacks an alpha but has a subordinate adult (age > 12 months) of the right sex, the oldest subordinate becomes the new alpha. 

  3.	Birds undertake scouting forays. Subordinate adults decide whether to scout for a new territory with a vacant alpha position, using the scouting decision submodel described below. Birds that do scout choose randomly (with equal probability) between the two directions they can look (left or right along the row of territories). Scouting birds can explore up to five territories in their chosen direction. Of those five territories, the bird occupies the one that is closest to its starting territory and has no alpha of its sex. If no such territory exists, the bird stays at its starting territory. All birds that scout (including those that find and occupy a new territory) are then subjected to predation mortality, a stochastic event with the probability of survival 0.8.

  4.	Alpha females reproduce. In the 12th month of every year, alpha females that have an alpha male in their territory produce two offspring. The offspring have their age set to zero months and their sex chosen randomly with equal probability of male and female.

  5.	Birds experience mortality. All birds are subject to stochastic mortality with a monthly survival probability of 0.99.

  6.	Output is produced. 

##Design concepts
This discussion of design concepts may help you design alternative theories for the scouting trait.

_Basic principles_: This model explores the “stay-or-leave” question: when should a subordinate individual leave a group that provides safety and group success but restricts opportunities for individual success? In ecology we can assume real individuals have traits for this decision that evolved because they provide “fitness”: success at reproducing. The trait we use in an ABM could explicitly consider fitness (e.g., select the behavior providing the highest expected probability of reproducing) but could instead just be a simple rule or “heuristic” that usually, but not always, increases fitness.

_Emergence_: The results we are interested in for theory testing are the three patterns described at the end of Section 19.4.2: a successful theory will cause the model to reproduce these patterns. All the patterns emerge from the trait for scouting. The group size distribution pattern may also depend strongly on other model processes such as the reproduction and survival rates. 

_Adaptation_: The only adaptive decision the woodhoopoes make is whether to undertake a scouting foray. You can consider several alternative traits for this decision that vary in how explicitly they represent the individuals’ objective of obtaining alpha status to reproduce. You should start with “null” traits in which the decision is random or always the same. You could consider an indirectly-objective-seeking trait such as a simple rule-of-thumb (e.g., “scout whenever age > X”), and a trait that explicitly represents the factors that affect an individual’s chance of meeting its objective.

_Objectives_: The subordinate birds have a clear objective: to become an alpha so they can reproduce. We also know, in this model, what processes affect the likelihood of reaching that objective. If the individual stays at its home territory, all the older birds of its sex must die for the individual to succeed to alpha. If the individual scouts, to succeed it must find a vacant alpha position and it must survive the predation risk of scouting.

_Learning_: The decision trait could change with the individual’s experience. For example, birds could learn things on unsuccessful scouting forays that they use in subsequent decisions. (If you try learning at all, we suggest you start with simpler traits without learning.)

_Prediction_: The decision objective is to attain alpha status, but attain it by when? If you design a decision trait that compares the relative probability of becoming alpha for leaving vs. for staying, the trait must specify a time horizon over which that probability applies. Evaluating these probabilities would require some kind of prediction over the time horizon.

_Sensing_: We assume that birds know nothing about other territories and can sense whether an alpha position is open in another territory only by scouting there. However, it is reasonable to assume that a bird can sense the age and status of the others in its own group.

_Collectives_: The social groups are collectives: their state affects the individual birds, and the behavior of individuals determines the state of the collectives. Because the model’s “territory” entities represent the social groups as well as their space, the model treats behaviors of the social groups (promoting alphas) as territory traits.

_Observation_: In addition to visual displays to observe individual behavior, the model’s software must produce outputs that allow you to test how well it reproduces the three characteristic patterns identified in Section 19.4.2. Hence, it must output the group size distribution illustrated in Figure 19 2, the mean age (over all months of the entire simulation) of subordinate adult birds that do vs. do not make scouting forays, and the total number of forays made by month.

##Initialization
Simulations start at January (month 1). Every territory starts with two male and two female birds, with ages chosen randomly from a uniform distribution of 1 to 24 months. The oldest of each sex becomes alpha. 

##Input
The model does not use any external input.

##Submodels
###Scouting decision
This submodel is executed by individual subordinate adult woodhoopoes to decide whether to search for a new territory where they would become an alpha individual. The decision has two simple steps:

  1. If there are no _older_ (not "other", as the book text says) subordinate adults of the same sex in the current territory, then do not scout.

  2. Otherwise, decide whether to scout via a random Bernoulli trial with probability of scouting equal to the parameter _scouting-prob_.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0RC2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Calibration" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <metric>month</metric>
    <metric>count turtles</metric>
    <metric>count patches with [count (turtles-here with [is-alpha?]) &lt; 2]</metric>
    <steppedValueSet variable="scout-prob" first="0" step="0.05" last="0.5"/>
    <steppedValueSet variable="survival-prob" first="0.95" step="0.0050" last="1"/>
  </experiment>
  <experiment name="Calibration2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <metric>month</metric>
    <metric>count turtles</metric>
    <metric>count patches with [count (turtles-here with [is-alpha?]) &lt; 2]</metric>
    <steppedValueSet variable="scout-prob" first="0.2" step="0.01" last="0.4"/>
    <steppedValueSet variable="survival-prob" first="0.975" step="0.0010" last="0.985"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
