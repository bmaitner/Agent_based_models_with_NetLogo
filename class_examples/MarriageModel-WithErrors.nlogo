; Define global variables
globals 
 [
   initial-population
   max-age
   birth-rate
   social-network-age-range
   social-network-angle-range
   min-marriage-age
 ]
 
; Define patch variables (none)

; Define turtle variables. 
turtles-own [
  sex                     ; a string, "M" or "F"
  social-network          ; an agentset
  is-married?             ; a boolean variable, true or false
  my-spouses-social-angle ; a float
  ]  

to setup
  ca
  reset-ticks
  
  ; Initialize global variables
  set initial-population 1000
  set max-age max-pxcor   ; Age is equal to X coordinate.
  set social-network-age-range 3
  set social-network-angle-range 20
  set min-marriage-age 16
  set birth-rate 16

  ;  Create initial population
  crt initial-population
   [  
     ; set the age
     set xcor random (max-age + 1)
     
     ; set the sex
     ifelse (random-float 1.0 < 0.5)
       [set sex "M"]
       [set sex "F"]
     
     ; set the social angle
     set ycor random-float 360.0
     
     ; set marital status with a 10% probability of being married
     ifelse (xcor >= min-marriage-age) and (random-float 1.0 < 0.1)
      [
        set is-married? true
        set color green
      ]
      [
        set is-married? false
        set color red
      ]

   ]
   
  ; Clear the test output file, write column headings
  if (file-exists? "TestOutput.csv") [carefully [file-delete "TestOutput.csv"] [print error-message]]
  file-open "TestOutput.csv"
      file-type "tick,"
      file-type "id,"
      file-type "age,"
      file-type "is-married?,"
      file-type "socialNetCount,"
      file-type "marriedFrac,"
      file-type "socialPress"
  file-close

end

;  This is the master schedule
to go
   ; Stop when 200 years have been simulated
   if ticks >= 200   
   [
     file-close
     stop
   ]

   ; Ageing and death
   ask turtles [age-and-die]
   
   ; Childbirth
   reproduce
   
   ; Marriage
   ; First, open the test output file that is written to in "marry"
   file-open "TestOutput.csv"
   ask turtles [marry]
   file-close
   
   ; Update the output
   output

   tick
  
end

; Ageing and death submodel
to age-and-die

 let new-age xcor + 1
 ifelse (new-age > 60)
   [die]
   [set xcor new-age]

end

; Marriage submodel
to marry

 ; Write to the output file for testing the code
 ; Print a carriage return first because we don't know which "type" statement is
 ; the last on a line.
 ; Then print out what tick we're on, the turtle ID, its age and marital status
 file-print " "
 file-type ticks          file-type ","
 file-type who            file-type ","
 file-type xcor           file-type ","
 file-type is-married?    file-type ","

 ; First exclude married and underage individuals
 if is-married? [stop]
 if xcor < min-marriage-age [stop]
 
 ; Identify the social network
  set social-network other turtles with
    [ 
      xcor > ([xcor] of myself - social-network-age-range) and
      xcor < ([xcor] of myself + social-network-age-range) and
      ycor > ([ycor] of myself - social-network-angle-range) and
      ycor < ([ycor] of myself + social-network-angle-range)
     ]

  ; Test output:   
    file-type count social-network      file-type ","
  
  ; Evaluate the married fraction of social network
   let married-fraction (count social-network with [is-married?]) / (count social-network)

  ; Evaluate social pressure
   let Z -5.4925 + (10.985 * married-fraction)
   let social-pressure (exp Z) / (1 + exp Z)

 ; Test output:   
      file-type married-fraction          file-type "," 
      file-type social-pressure           file-type ","

   ; Now, decide whether to try to marry
   if random-float 1.0 > married-fraction [stop]

  
   ; Identify a partner if there is one
   let potential-partners social-network with
    [ 
      sex != [sex] of myself and
      xcor >= min-marriage-age and
      is-married? = false
    ]
    
    let my-spouse one-of potential-partners
    if my-spouse = nobody [stop]
    
    ; Reset marriage status of self and new spouse
    set is-married? true
    set color green
    
    ask my-spouse 
     [
       set is-married? true
       set color green
     ]
     
    ; Get spouse's social angle (for childbirth)
    set my-spouses-social-angle [ycor] of my-spouse

  
end

; Childbirth submodel - THIS IS AN OBSERVER PROCEDURE, not a turtle procedure
to reproduce

 ; First, identify reproductive females
 let moms turtles with [(sex = "F") and (is-married?) and (xcor < 40)]

 ; Now figure out how many moms give birth 
 let number-of-births birth-rate
 if number-of-births > count moms [set number-of-births count moms]
 
 ; Pick which moms have babies and create the kids
 ask n-of number-of-births moms  
   [
     hatch 1
       [
         set xcor 0
         set is-married? false
         set color red
         ifelse (random-float 1.0 < 0.5)
          [set sex "M"]
          [set sex "F"]

         ; The babies get a social angle between their parents'
         let angle-difference ([my-spouses-social-angle] of myself) - ([ycor] of myself)
         set ycor [ycor] of myself + random-float angle-difference
       ]
    ]
    
end

to output

   ; Histogram this year's marriage distribution
   set-current-plot "Number of Married People"
   histogram [xcor] of turtles with [is-married?]
 
end


; A test procedure executed from a turtle agent-monitor.
; It makes the social network visible by labeling members by sex
; Note that this causes a runtime error if used before the
; first time step because social-network is not initialized.
; The calling turtle, which should be near the center of the network,
; has its label set to "me"
to tag-network
  set label "me"
  ask social-network 
   [
     set label sex
   ]
  
end 
@#$#@#$#@
GRAPHICS-WINDOW
377
10
622
1014
-1
-1
2.705
1
10
1
1
1
0
0
1
1
0
60
0
359
1
1
1
ticks
30.0

BUTTON
11
10
74
43
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
84
10
147
43
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

BUTTON
155
10
218
43
step
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

PLOT
1
53
299
267
Number of Married People
Age
Number married
15.0
60.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

@#$#@#$#@
# MARRIAGE AGE MODEL
Model formulated and implemented by S. F. Railsback

This model is loosely based on the marriage age model of:   
Billari, F. C., A. Prskawetz, B. Aparicio Diaz, and T. Fent. 2007. The "wedding-ring": an agent-based marriage model based on social interactions. Demographic Research 17:59-82. Available on-line at: www.demographic-research.org/Volumes/Vol17/3/

However, this model is different from the model of Billari et al. in many important ways and should not be compared to, or treated as equivalent to, their model.

This NetLogo implementation intentionally includes some programming errors as a software testing exercise!! This program is completely independent of the software used by Billari et al.

#MODEL DESCRIPTION (ODD FORMAT)

## PURPOSE
This model addresses social norms in the age at which people marry. These norms can be described by a graph showing what percent of people are married at each age. The model specifically explores the role of social networks (peer groups) in influencing marriage age. If we assume people are more likely to get married when more members of their social network are married, does that explain the typical distribution of age-at-marriage?

The model could also be modified to investigate the effect of alternative social networks on marriage ages. If people are more affected by their younger, older, or closer peers, how does that affect when they marry? If people know of more or fewer potential marriage partners, how does it affect the age-at-marriage distribution?

## ENTITIES, STATE VARIABLES, AND SCALES
The objects in this model represent people. People have two state variables to describe their location within a social network (described in the following paragraph). People also have variables for their age, sex, and marriage status. 

This model does not use geographic space, but instead represents a social network as a two-dimensional space, wrapped in one dimension so it acts like a cylinder. A person's social location (where they are in a circle of individuals, with people closer on the circle being more closely linked socially) is described via their angle (real numbers between 0 and 360 degrees) on the cylinder's surface. The NetLogo implementation represents this "social angle" as the Y coordinate of a world with max-ycor set to 360, so turtle Y coordinates range from -0.5 to 359.5. The X axis represents age, so an individual's X coordinate is equal to their age (0-60, in years). A person's close social network (people close in both social connection and age) is therefore its neighborhood on the social space. 

The model runs at a one-year time step. Simulations run for 200 years.

## PROCESS OVERVIEW AND SCHEDULING
The model includes the following actions executed each time step.

Aging and death: The age of all individuals is incremented. Individuals exceeding age 60 die. 

Childbirth: Married females with age less than 40 may have children, which are placed randomly in the social neighborhood between their parents. Childbirth happens at a rate that keeps the population stable in the long term. Childbirth is scheduled before marriage so women do not have children the same year they marry.

Marriage: Marriagable individuals (those still single and age 16 or higher) decide whether to try to marry, which depends on "social pressure". Social pressure is a non-linear function of the fraction of the social network that is married. If they decide to marry, they randomly identify a partner (if there is one) within their social network. If a partner is found, the two marry (their marriage status changes from false to true).

Output: The marriage-at-age distribution is represented via a histogram showing the number of people married at each age, for the current population.

## DESIGN CONCEPTS
_Emergence_: The model's primary output is the "age-at-marriage" distribution, which emerges from marriage decisions by individuals. These decisions are determined by (a) the social network and (b) the shape of the social pressure function. 

_Adaptive behavior_: The key individual decision is whether to marry each year. This decision is a deterministic function of (a) the fraction of the individual's social network who are already married, and (b) the availability of potential mates in the individual's social region. Individuals adapt their behavior in response to the fraction of peers who are married: as this fraction increases, they are more likely to marry. However, individuals do not adapt their social network in any way (e.g., by expanding the network with age or by being more linked to people of their own marital status). 

_Fitness_: Conformity with the marital status of social peers is an implicit fitness measure: the adaptive behavior acts to give individuals a marriage status more like that of their social peers.

_Learning_, _Prediction_: The individual behaviors are not based on expected future state and do not change; no learning or prediction are represented.

_Interaction_: Direct interaction occurs when an individual identifies a marriage partner. The individual "marries" the partner, converting the partner's status from single to married. Indirect interaction occurs as competition for partners: for examples, more males in a social region would decrease the availability of females for each other, affecting the behavior and marital status of the other males.

_Sensing_: Individuals are assumed simply to know the marital status of all individuals in their social network, and to know the sex and marital status of all potential marriage partners.

_Stochasticity_: Stochastic functions are used to initialize individual locations, age, sex, and marital status, and to set the location and sex of children born during the simulation. Whether a single individual marries is a stochastic function of its social pressure. 

_Collectives_: Collectives are not represented. Each individual has a social network of other individuals that it treats as social peers and potential partners, but these networks have no behaviors or characteristics of their own.

_Observation_: The key model output used by Bellari et al. for comparison to data is the "age-at-marriage" curve. This curve cannot be produced via the simple summary statistical reporters in NetLogo, so instead we use a histogram of number married vs. age.

## INITIALIZATION
The population of 1000 individuals is initialized with age selected randomly with equal probability of ages 0 to 60. Initial marriage status (for individuals of marriagable age) is assigned randomly with a probability of being married equal to 0.1. (This unrealistic assumption helps determine the extent to which patterns of marriage age produced by the model are an artifact of initial conditions.)

Initial social angle is set randomly to a value between 0.0 and 360.0.

## INPUT DATA
No time-series inputs are used.

## SUBMODELS

###Partner search and marriage: 
The fundamental behavioral assumption of this model is that people's efforts to marry increase as the fraction of their social network that is married increases. This assumption is implemented through the following steps.

a. Identify the social network. An individual's social network is defined as the other individuals within a rectangular area on the social space (the NetLogo world). The social network's size is defined by two parameters, which are (in this version) the same for all individuals. In the x (age) dimension, the social network ranges +/- social-network-age-range from the individual's age. In the Y (social angle) dimension, the social network ranges +/- social-network-angle-range from the individual's angle. Default values of social-network-age-range and social-network-angle-range are 3 years and 20 degrees. Hence the social network of an individual with age 21 and social angle 280 deg. includes any individuals with ages between 18 and 24 and social anges 260 and 300.

b. Evaluate the married fraction in the social network. This is simply the fraction of all people in the social network who are already married (including people married within the current time step).

c. Evaluate "social pressure". Social pressure is a variable describing the effect of the married fraction of the social network on a single person's effort to marry. The relationship between the married fraction of the social network and "social pressure" is represented as a logistic curve. Logistic curves are useful for representing many nonlinear relations that are common in natural and human systems: at both low and high levels of the independent (X) variable, there is little change in the dependent (Y) variable, but the relationship can be steep at intermediate levels. The value of the dependent variable Y ranges between 0 and 1.0.

An equation for the logistic function is: Y = exp(Z)/(1 + exp(Z))   
where: Z = a + bX  
and "a" and "b" are parameters defining how wide and steep the relationship is. 

One way to define "a" and "b" is to think about X values at which the value of Y is 0.1 and 0.9; call these "x01" and "x09". Now:

 b = -4.394 / (x01 - x09)
 a = -2.197 - [(b) (x01)]

Here we use the assumption of Bellari et al. that social pressure (Y) has a value of 0.1 when the married fraction (X) is 0.3, and has a value of 0.9 when the married fraction is 0.7. Hence:
  x01 = 0.3 and x09 is 0.7
  a = -5.4925
  b = 10.985

To explore shapes of this relationship, we recommend users implement these equations in a spreadsheet and play with values of x01 and x09. 

d. Decide whether to marry. This is simply a stochastic function of social pressure. A uniform random number between zero and one is drawn, and if it is less than the social pressure the individual looks for a marriage partner. 

e. Identify a partner. Partners are selected by randomly identifying a single individual of the opposite sex within the social network. If no such partners exist, the individual remains unmarried. If a partner is found, then both individuals are immediate assumed married and no longer available for selection by other single individuals. 

###Childbirth: 
Childbirth rates are imposed to maintain a stable population size. Potential mothers are any female that is married (including newlyweds married in the current time step) and has age less than 40. 

Each yearly time step, 16 potential mothers are randomly chosen to each produce one child. If there are fewer than 16 potential mothers in the population, then they all produce a child.

New children are given an age of 0 and a randomly selected sex. The social angle of new children is set to a random location uniformly distributed between those of the two parents.
@#$#@#$#@
default
true
0
Polygon -7566196 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7566196 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7566196 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7566196 true true 150 285 285 225 285 75 150 135
Polygon -7566196 true true 150 135 15 75 150 15 285 75
Polygon -7566196 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7566196 true true 96 182 108
Circle -7566196 true true 110 127 80
Circle -7566196 true true 110 75 80
Line -7566196 true 150 100 80 30
Line -7566196 true 150 100 220 30

butterfly
true
0
Polygon -7566196 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7566196 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7566196 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7566196 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7566196 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7566196 true true 47 195 58
Circle -7566196 true true 195 195 58

circle
false
0
Circle -7566196 true true 30 30 240

circle 2
false
0
Circle -7566196 true true 16 16 270
Circle -16777216 true false 46 46 210

cow
false
0
Polygon -7566196 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7566196 true true 73 210 86 251 62 249 48 208
Polygon -7566196 true true 25 114 16 195 9 204 23 213 25 200 39 123

face happy
false
0
Circle -7566196 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7566196 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7566196 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
true
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7566196 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7566196 true true 60 15 75 300
Polygon -7566196 true true 90 150 270 90 90 30
Line -7566196 true 75 135 90 135
Line -7566196 true 75 45 90 45

flower
false
0
Polygon -11352576 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7566196 true true 85 132 38
Circle -7566196 true true 130 147 38
Circle -7566196 true true 192 85 38
Circle -7566196 true true 85 40 38
Circle -7566196 true true 177 40 38
Circle -7566196 true true 177 132 38
Circle -7566196 true true 70 85 38
Circle -7566196 true true 130 25 38
Circle -7566196 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -11352576 true false 189 233 219 188 249 173 279 188 234 218
Polygon -11352576 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7566196 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7566196 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

largemouth
true
0
Polygon -7566196 true true 75 15 150 90 225 15 240 60 255 120 255 165 240 180 210 210 240 255 150 240 60 255 90 210 60 180 45 165 45 120 45 60
Polygon -7566196 true true 45 165 30 180 30 135 45 120
Circle -16777216 true false 60 60 30

leaf
false
0
Polygon -7566196 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7566196 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7566196 true 150 0 150 300

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

pentagon
false
0
Polygon -7566196 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7566196 true true 110 5 80
Polygon -7566196 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7566196 true true 127 79 172 94
Polygon -7566196 true true 195 90 240 150 225 180 165 105
Polygon -7566196 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7566196 true true 135 90 165 300
Polygon -7566196 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7566196 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7566196 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7566196 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7566196 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7566196 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7566196 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7566196 true true 30 30 270 270

square 2
false
0
Rectangle -7566196 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7566196 true true 60 270 150 0 240 270 15 105 285 105
Polygon -7566196 true true 75 120 105 210 195 210 225 120 150 75

target
false
0
Circle -7566196 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7566196 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7566196 true true 120 120 60

tree
false
0
Circle -7566196 true true 118 3 94
Rectangle -6524078 true false 120 195 180 300
Circle -7566196 true true 65 21 108
Circle -7566196 true true 116 41 127
Circle -7566196 true true 45 90 120
Circle -7566196 true true 104 74 152

triangle
false
0
Polygon -7566196 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7566196 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7566196 true true 4 45 195 187
Polygon -7566196 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7566196 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7566196 false true 24 174 42
Circle -7566196 false true 144 174 42
Circle -7566196 false true 234 174 42

turtle
true
0
Polygon -11352576 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -11352576 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -11352576 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -11352576 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -11352576 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7566196 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7566196 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7566196 true 150 285 150 15
Line -7566196 true 15 150 285 150
Circle -7566196 true true 120 120 60
Line -7566196 true 216 40 79 269
Line -7566196 true 40 84 269 221
Line -7566196 true 40 216 269 79
Line -7566196 true 84 40 221 269

x
false
0
Polygon -7566196 true true 270 75 225 30 30 225 75 270
Polygon -7566196 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0RC2
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
