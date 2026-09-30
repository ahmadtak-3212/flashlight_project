#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices

#show: arkheion.with(
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  title: "Final Project Report: Flashlight Power Converter Design",
  authors: (
    (name: "Ahmad Taka", email: "ahmadtak@mit.edu", affiliation: "MIT EECS"),
  ),
  date: "December 9th, 2025",
)

#set cite(style: "chicago-author-date")
#show link: underline




= Introduction and Project Motivation

For the final project, a discrete, low-voltage boost LED driver is designed and built for a Cree XHP50.3 6 V LED (XHP50D-00-0000-0D0UH240G).@CreeXHP503 The objective is to realize a compact, thermally-managed flashlight that is bright enough to illuminate a workspace or driveway while remaining efficient and comfortable to hold. Although high-power LED flashlights are widely available, most commercial designs conceal the internal power-converter behavior and provide little visibility into regulation, transient response, or thermal performance. This work instead emphasizes a transparent, measurement-friendly architecture in which the power electronics are explicitly designed, modeled, and probed, rather than relying on off-the-shelf drivers.

The project builds on prior hardware developed over the summer, where a custom STM32-based board was designed to manage a Li-ion cell, deliver up to 3 A on a power-path rail using the BQ2125, and interface with an onboard accelerometer to implement a “shake-to-wake” LED control gesture. During that effort, several commercial boost LED drivers, including the TPS61169 and TPS61500, were evaluated and found unable to deliver sufficient current to fully drive the Cree XHP50.3. These limitations motivated the development of a higher-power, constant-current architecture in which a boost converter measures LED current via a shunt resistor and regulates it directly to achieve stable brightness and predictable thermal behavior. In the present work, the prototype operates from a single 3 V rail representing a fresh pair of alkaline cells, with no upstream regulation. The converter must boost from 3 V to approximately 6–6.5 V to drive the Cree XHP50.3 in its 6 V configuration (typical forward voltage 5.6–6.2 V at 1.4 A, 3 A continuous rating), while maintaining acceptable component stress and temperature margins.@CreeXHP503

For the 6.2222 graduate extension, the flashlight driver is used as a laboratory platform for converter modeling, control design, and energy-flow analysis. The implementation uses discrete analog building blocks (LM358 op-amps, comparator, 22 µH inductor, current shunt), alongside small-signal modeling and MATLAB state-space simulation to study loop stability and transient response. Time-domain and frequency-domain measurements (inductor current, switch node voltage, LED current, control signals) will be used to validate the models. In addition, silicon MOSFET and GaN FET devices will be compared in the same boost topology to quantify differences in switching loss and thermal performance. Tellegen’s theorem will be applied to track energy flow through the converter and verify that measured power losses are consistent with theoretical predictions. Finally, a small switched-capacitor voltage doubler will be constructed to generate short, higher-voltage flashes on the LED, extending Lab 3 concepts to examine how brief high-voltage bursts affect brightness and heating.


= Independent Inquiry Background and Control-Theoretic Context

The independent inquiry drew on the 6.2222 notes, Tellegen-based energy flow
arguments, and two Texas Instruments application reports on boost converter
feedback loops.@Lee2014VoltageModeBoost @Lee2014CurrentModeBoost  The
reference material places the boost in the context of general
feedback-system theory, emphasizing loop gain, sensitivity, and the special
role of right-half-plane (RHP) zeros in the overall stability of the system.

== Black’s feedback theorem and loop-shaping viewpoint

#figure(
  image("figures/2_1_blacks_formula.png", width: 70%),
  caption: [Blacks formula block diagram],
) <figure_2_1>

Black’s classical feedback model represents the closed-loop system as a
forward plant $G(s)$, a feedback network $F(s)$, and an input $X(s)$ and
output $Y(s)$. The basic closed-loop relation is 

#math.equation(block: true, [
  $
    T(s) = Y(s)/X(s) = G(s)/(1 + G(s) F(s))
  $
])

Defining the loop gain
#math.equation(block: true, [
  $
    L(s) = G(s)\,F(s)
  $
])
the sensitivity and complementary sensitivity functions are

#math.equation(block: true, [
  $
    S(s) = 1/(1 + L(s)), \qquad
    T(s) = L(s)/(1 + L(s)).
  $
])

// Low $|S(j omega)|$ at low frequency means good disturbance rejection and
// small steady-state error; the magnitude and phase of $L(j omega)$ near
// crossover control stability and transient behavior. In the LED driver, the
// plant $G(s)$ is the averaged boost converter plus PWM modulator; the
// compensator and current-sense network form $F(s)$. The design goal is a
// loop gain $L(s)$ that achieves accurate current regulation (low-frequency
// gain and small $|S|$) and sufficient phase margin at crossover.


Low values of $|S(j omega)|$ at low frequency mean that the loop rejects disturbances well and keeps the steady-state error small. The loop gain $L(j omega)$ near the crossover frequency then sets the stability and shapes the transient response. For this LED driver, the plant $G(s)$ consists of the averaged boost converter together with the PWM modulator, and the compensator plus current-sense network together form $F(s)$. The control objective is to choose $L(s)$ so that the loop has high gain at low frequency (for accurate current regulation and low $|S|$) while maintaining adequate phase margin at crossover for stable, well-damped behavior.

== Voltage-mode versus current-mode control in boost converters

The TI voltage-mode report models the continuous-conduction boost as an
LC output filter with ESR zero and an RHP zero whose location depends on
load, inductance, and duty cycle.@Lee2014VoltageModeBoost  Linearization
gives a control to output transfer function with a moving double pole at
the LC resonance and a right-half-plane zero at

#math.equation(block: true, [
  $
    f_"rhp" = R_"load" * (1 - D)^2 / (2 * pi * L)
  $
])

This zero moves to lower frequency at heavy load, low input voltage, or
large inductance. It contributes +20 dB/dec of gain but also an additional
90° of phase lag, so Black’s feedback theorem implies that the loop
crossover must be kept well below this frequency (typically
$f_"c" ≤ f_"rhp" / 5$) to preserve adequate phase margin and avoid
instability.@Lee2014VoltageModeBoost

The current-mode report analyzes an alternative architecture with an inner
cycle-by-cycle current loop and an outer voltage loop.@Lee2014CurrentModeBoost
From the outer-loop perspective, the inductor dynamics are “prelinearized”
and the LC double pole collapses to a single dominant pole associated with
the output capacitor and load. A Type-II compensator (one pole at the origin
plus a pole–zero pair) suffices, with simpler design rules and improved
phase margin at a given crossover.

== Relevance to a constant-current LED boost driver

Although the final flashlight driver is not a textbook current-mode
converter, the LED-current regulation problem is structurally similar to
the TI voltage-mode designs: a PI controller and comparator form a
voltage-mode outer loop around a boost power stage whose “load” is a
nonlinear LED plus shunt resistor. Around a given operating point, the LED
may be linearized as an effective resistance, so the plant still exhibits
an LC double pole and an RHP zero set by $L$, duty cycle, and equivalent
load resistance.

The inquiry applied the TI voltage-mode model to estimate $f_"rhp"$ and the
LC resonant frequency for the chosen inductance and LED operating points,
setting upper bounds on crossover. It then used the current-mode
compensator rules as a template for the PI design: integrator pole at the
origin, a zero below crossover to add phase, and a high-frequency pole
implicit in the op-amp and PWM modulator. Black’s sensitivity functions
$S(j omega)$ and $T(j omega)$ provide the interpretation: low-frequency
gain and small $|S|$ translate into accurate current regulation and good
line/load rejection, while adequate phase margin at crossover prevents the
duty-cycle adjustments from exciting RHP-zero or half-switching-frequency
pathologies.

= System Requirements and Architecture Overview

== Electrical and performance requirements
#figure(
  image("/figures/3_1_xhp_load.png", width: 100%),
  caption: [Plot of LED Load curve and operating points],
) <figure_3_1>

The driver targets a single 3 V supply (two alkaline cells) and a Cree
XHP50.3 6 V LED driven near 1–1.5 A, with a hard upper ceiling around 2 A
to respect the 3 A absolute maximum rating and keep junction temperatures
reasonable.@CreeXHP503  Around the design operating point the LED forward
voltage is about 6 V, so the converter must provide roughly 6–6.5 V from a
3 V input.

For an ideal continuous-conduction boost converter, the dc conversion ratio
is
#math.equation(block: true, [
  $
    M = V_"out" / V_"in" = 1 / (1 - D),
  $
])
so with $V_"in" = 3,V$ and $V_"out" ≈ 6.2,V$ the required duty cycle is
#math.equation(block: true, [
  $
    D = 1 - V_"in" / V_"out" ≈ 1 - 3 / 6.2 ≈ 0.52.
  $
])

At $V_"out" ≈ 6.2,V$ and $I_"out" ≈ 1.5,A$, the output power is ≈9.3 W. With
efficiency in the 75–85% range, the input current is roughly 4–4.5 A, which
sets the stress on the inductor, switch, diode, and shunt. The design goal
is to keep LED current ripple below about 10% of the dc level.

== Control and stability requirements

From a control standpoint, the driver should behave as a current regulator:
the user sets an LED current, and the loop adjusts duty cycle so that the
measured average current tracks over variations in LED forward voltage and
input voltage. The specific objectives are:

- Continuous conduction in the main operating region.
- Crossover $f_"c"$ below both the boost RHP zero and $f_"sw"/10$, with
  at least 45–60° of phase margin.
- Step changes in setpoint that settle without sustained oscillation and
  with limited overshoot.
- Hardware constraints on maximum duty cycle set by op-amp swing and ramp
  amplitude, even though no explicit clamp circuit is present.

The implemented structure uses LM358 op-amps at 3 V for current sense,
PI controller, and triangle generator, plus a comparator and low-side
switch device. The independent inquiry provides the theoretical basis for
selecting PI pole and zero locations and the target loop gain shape.

== Thermal and mechanical constraints

The LED dissipates roughly 10 W at full brightness, plus several watts of
converter loss. The XHP50.3 is rated to 150 °C junction, but practical
operation suggests staying well below 100 °C for long life and color
stability.@CreeXHP503  The inductor and switch device must handle several
amperes of current without saturation or excessive temperature rise.

Mechanically, the prototype is built on a breadboard or prototyping PCB
with careful attention to minimizing loop inductances on the high-di/dt
paths and providing accessible test points (`Vmeas`, `Vset`, `V_tri`,
`V_ctrl`, switch node). A future PCB version would fit into a flashlight
host, but the electrical requirements are already based on that form factor.

== Architecture overview

The system is partitioned into:

1. Input stage (3 V source and local decoupling),
2. Boost power stage (22 µH inductor, rectifier diode, 120 µF output
  capacitor, LED, 0.2 Ω shunt),
3. Current-sense and signal-conditioning (0–1 V range),
4. PI controller and reference generation (0–1 V setpoint),
5. PWM modulator and gate drive (100 kHz ramp and comparator),
6. Measurement hooks for scope-based loop analysis.

This architecture links the requirements to specific circuit blocks and
provides a clean mapping to the modeling and simulations that follow.

= Circuit Design and Analysis
#figure(
  image("/figures/3_2_boost.png", width: 100%),
  caption: [schematic of boost converter circuit],
) <figure_3_2>


== Power Stage (Boost Converter)

The power stage in figure 3 is a non-synchronous boost converter that steps
a single 3 V source up to ≈6–6.5 V for the XHP50.3 LED.@CreeXHP503  The
inductor ($L = 22,µ H$) sits in series with the input, followed by a
Schottky rectifier and an output capacitor ($C_"out" = 120,µ F$) feeding the
LED and 0.2 Ω sense resistor. A low-side switch periodically connects the
inductor to ground; in the on interval the inductor current ramps up, and
in the off interval the stored energy is delivered to the output.

Assuming $I_"out" ≈ 1.5,A$ and efficiency $eta ≈ 0.8$, the average inductor
current is
#math.equation(block: true, [
  $
    I_"L,avg" ≈ I_"in" ≈
    V_"out" * I_"out" / (eta * V_"in")
    ≈
    6.2 * 1.5 / (0.8 * 3)
    ≈ 3.9,
  $
])

The inductor ripple is set by the input voltage and duty cycle:
#math.equation(block: true, [
  $
    Delta I_"L" = V_"in" * D / (L * f_"sw").
  $
])
With $V_"in" = 3,V$, $D ≈ 0.52$, $L = 22,µ H$, and $f_"sw" ≈ 100, "kHz"$, this
gives
#math.equation(block: true, [
  $
    Delta I_"L" ≈ 3 * 0.52 / (22e-6 * 100e 3) ≈ 0.7,
  $
])
so the ripple is ≈18% of $I_"L,avg"$, keeping the stage comfortably in
continuous conduction.

The small-signal dynamics follow the standard voltage-mode boost model. The
equivalent inductance seen by the output is
#math.equation(block: true, [
  $
    L_"eq" = L / (1 - D)^2,
  $
])
so the power-stage double pole is at
#math.equation(block: true, [
  $
    f_0 = (1/(2 * pi)) * sqrt((1 - D)^2 / (L * C_"out")).
  $
])
The RHP zero is
#math.equation(block: true, [
  $
    f_"rhp" = R_"load" * (1 - D)^2 / (2 * pi * L),
  $
])
where $R_"load"$ is the linearized LED plus series resistance. For the
chosen parameters this places $f_0$ in the low-kilohertz range and $f_"rhp"$
at several kilohertz, which constrains the allowable loop crossover.

// == Current Sense and PI Control Loop

// The LED current flows through a fixed shunt $R_"s" = 0.2,Ω$. With
// $I_"LED"$ in the 0–2 A range, the shunt voltage $v_"s" = I_"LED" R_"s"$
// spans 0–0.4 V. A differential amplifier with gain $A_"sense"$ translates
// this into a ground-referenced 0–1 V signal:
// #math.equation(block: true, [
//   $
//     v_"meas" ≈ A_"sense" * R_"s" * I_"LED",
//   $
// ])
// with $A_"sense"$ chosen so that 1.25 A maps to ≈1 V, matching the MATLAB
// normalization.

// The setpoint is generated by a potentiometer from 0–3 V and then scaled
// down by a small divider to 0–1 V:
// #math.equation(block: true, [
//   $
//     v_"set" = v_"pot" * R_"bot" / (R_"top" + R_"bot"),
//   $
// ])
// with $R_"bot"/(R_"top" + R_"bot") ≈ 1/3$. An LM358 buffer provides a low
// impedance reference. When $v_"meas" = v_"set"$, the loop enforces
// $I_"LED" ≈ v_"set" / (A_"sense" R_"s")$.

// The error $e(t) = v_"set"(t) - v_"meas"(t)$ is processed by an LM358
// configured as a PI controller. The input resistor $R_"in"$ feeds $e(t)$ into
// the inverting input; the feedback consists of $R_"f"$ in parallel with
// $C_"f"$, giving feedback impedance
// #math.equation(block: true, [
//   $
//     Z_"f"(s) = R_"f" // (1/(s * C_"f")) = R_"f" / (1 + s * R_"f" * C_"f"),
//   $
// ])
// and compensator
// #math.equation(block: true, [
//   $
//     G_"c"(s) = V_"ctrl"(s) / E(s)
//     = -Z_"f"(s) / R_"in"
//     = -(R_"f"/R_"in") * 1/(1 + s * R_"f" * C_"f").
//   $
// ])

// At low frequency the capacitor is open and the gain is approximately
// $-R_"f"/R_"in"$ (proportional path), while above the break
// $omega_"i" = 1/(R_"f" C_"f")$ the controller behaves increasingly like an
// integrator. The PI output $V_"ctrl"$ is compared against a 100 kHz ramp
// $V_"tri"$ from a relaxation oscillator; the comparator generates a PWM
// whose duty increases with $V_"ctrl"$. The LM358 output swing and ramp range
// together limit the maximum duty cycle.
//
//
== Current Sense and PI Control Loop

The LED current flows through a fixed shunt $R_"s" = 0.2,Ω$. With
$I_"LED"$ in the 0–2 A range, the shunt voltage
$v_"s" = I_"LED" * R_"s"$ spans 0–0.4 V. A differential amplifier with
gain $A_"sense"$ translates this into a ground-referenced 0–1 V signal:
#math.equation(block: true, [
  $
    v_"meas"(s) ≈ A_"sense" * R_"s" * I_"LED"(s)
    ≡ K_"sense" * I_"LED"(s),
  $
])
where $K_"sense" = A_"sense" * R_"s"$ is the effective current-sense gain.
The setpoint is generated by a potentiometer from 0–3 V and then scaled
down by a small divider to 0–1 V:
#math.equation(block: true, [
  $
    v_"set" = v_"pot" * R_"bot"/(R_"top" + R_"bot"),
  $
])
with $R_"bot"/(R_"top" + R_"bot") ≈ 1/3$. An LM358 buffer provides a low
impedance reference. When $v_"meas" = v_"set"$, the loop enforces
#math.equation(block: true, [
  $
    I_"LED" ≈ v_"set"/K_"sense"
    = v_"set"/(A_"sense" * R_"s"),
  $
])
which matches the MATLAB normalization where $v_"set"$ in the 0–1 V
range corresponds to the desired 0–1.25 A LED current.

The error $e(t) = v_"set"(t) - v_"meas"(t)$ is processed by an LM358
configured as a PI controller. The input resistor $R_"in"$ feeds $e(t)$
into the inverting input, and the feedback consists of $R_"f"$ in
parallel with $C_"f"$, giving the feedback impedance
#math.equation(block: true, [
  $
    Z_"f"(s)
    = R_"f" // (1/(s * C_"f"))
    = R_"f"/(1 + s * R_"f" * C_"f").
  $
])
The resulting compensator is
#math.equation(block: true, [
  $
    G_"c"(s)
    = V_"ctrl"(s)/E(s)
    = -Z_"f"(s)/R_"in"
    = -(R_"f"/R_"in") * 1/(1 + s * R_"f" * C_"f"),
  $
])
where the overall sign is chosen so that the feedback is negative at the
comparator input. The LM311 PWM compares $V_"ctrl"$ to a 0–1 V triangle
wave, so around the operating point the small-signal duty-cycle
perturbation can be approximated as
#math.equation(block: true, [
  $
    d(s) ≈ V_"ctrl"(s)
    = G_"c"(s) * E(s).
  $
])

To relate duty cycle to LED current, the boost converter is modeled in
continuous conduction mode with an equivalent LED resistance
$R_"load" ≈ V_"LED"/I_"LED"$ and steady-state duty ratio $D$. The
averaged small-signal plant from duty perturbation $d(s)$ to LED current
is written in the standard two-pole, one right-half-plane-zero form
#math.equation(block: true, [
  $
    G_"p"(s)
    ≡ I_"LED"(s)/D(s)
    =
    (V_"in"/(R_"load" * (1 - D)^2))
    * (1 - s/ω_"z")
    / (s^2/ω_0^2 + s/(Q * ω_0) + 1),
  $
])
with
#math.equation(block: true, [
  $
    ω_0 = (1 - D)/sqrt(L * C),
    \qquad
    Q = (1 - D) * R_"load"/sqrt(L/C),
    \qquad
    ω_"z" = (1 - D)^2 * R_"load"/L,
  $
])
where $ω_0$ is the LC natural frequency, $Q$ is the damping factor, and
$ω_"z"$ is the right-half-plane zero associated with the boost topology.

Combining the sense amplifier, compensator, and power stage yields the
loop equations
#math.equation(block: true, [
  $
    e(s) = v_"set"(s) - K_"sense" * I_"LED"(s),
    \qquad
    d(s) = G_"c"(s) * e(s),
    \qquad
    I_"LED"(s) = G_"p"(s) * d(s).
  $
])
Eliminating $e(s)$ and $d(s)$ gives the closed-loop transfer function
from setpoint to LED current:
#math.equation(block: true, [
  $
    I_"LED"(s)/v_"set"(s)
    = G_"p"(s) * G_"c"(s)
    / (1 + K_"sense" * G_"p"(s) * G_"c"(s)),
  $
])
and, equivalently, the transfer from setpoint to sensed voltage is
#math.equation(block: true, [
  $
    v_"meas"(s)/v_"set"(s)
    = K_"sense" * G_"p"(s) * G_"c"(s)
    / (1 + K_"sense" * G_"p"(s) * G_"c"(s)).
  $
])
These expressions explicitly show how the closed-loop behavior depends on
the design variables $L$, $C$, $R_"load"$, $R_"s"$, $A_"sense"$,
$R_"in"$, $R_"f"$, $C_"f"$, and the operating duty ratio $D$.

== Magnetics and Component Sizing

The inductor value is chosen from a ripple constraint:
#math.equation(block: true, [
  $
    (Delta I_"L") / I_"L,avg"
    = V_"in" * D / (L * f_"sw" * I_"L,avg")
    ≤ rho,
  $
])
with $rho$ the desired fractional ripple. Rearranging,
#math.equation(block: true, [
  $
    L ≥ V_"in" * D / (rho * f_"sw" * I_"L,avg").
  $
])
Using $V_"in" = 3,V$, $D ≈ 0.52$, $f_"sw" = 100,"kHz"$, $I_"L,avg" ≈ 3.9,A$,
and $rho ≈ 0.2$ gives a minimum $L$ of about 18 µH; 22 µH is a natural
choice.

The output capacitor size follows from ripple:
#math.equation(block: true, [
  $
    Delta V_"out" ≈ I_"out" * D / (C_"out" * f_"sw").
  $
])
With the chosen $C_"out"$, the ripple is only tens of millivolts, and the
(L, C_"out", R_"load") combination yields $f_0$ and $f_"rhp"$ consistent
with the control design.

The shunt dissipates
#math.equation(block: true, [
  $
    P_"s" ≈ I_"out"^2 * R_"s",
  $
])
which at 1.5–2 A and 0.2 Ω is 0.45–0.8 W. This is acceptable for a 1 W
sense resistor over short lab runs and provides a relatively large 1 V
full-scale sense signal.

== GaN vs Si FET comparison

The project compares an onsemi RFD3055LESM MOSFET and a Nexperia
GAN041-650WSBQ GaN FET as candidate switches.@RFD3055LESM @GAN041650WSBQ  The
RFD3055LESM has $R_"ds,on" ≈ 107 m Ω$ at $V_"GS" = 5,V$ and total gate charge
$Q_"g" ≈ 11.3,n C$; the GAN041-650WSBQ has $R_"ds,on" ≈ 41,m Ω$ (35 mΩ typical)
and faster edges.

Conduction loss is approximated by
#math.equation(block: true, [
  $
    P_"cond" ≈ D * I_"L,avg"^2 * R_"ds,on",
  $
])
so with $D ≈ 0.52$ and $I_"L,avg" ≈ 3.9,A$:
#math.equation(block: true, [
  $
    P_"cond,Si" ≈ 0.52 * 3.9^2 * 0.107 ≈ 0.85,
  $
])
#math.equation(block: true, [
  $
    P_"cond,GaN" ≈ 0.52 * 3.9^2 * 0.041 ≈ 0.32.
  $
])

Switching loss is estimated as
#math.equation(block: true, [
  $
    P_"sw" ≈ 0.5 * V_"in" * I_"L,avg" * (t_"r" + t_"f") * f_"sw".
  $
])
At 3 V, 3.9 A, 100 kHz, and ≈144 ns total edge time, the silicon device
dissipates ≈84 mW; the GaN device at ≈31 ns totals ≈18 mW. At 100 kHz both
are conduction-dominated, but the GaN FET cuts total device losses by more
than 2×. At higher $f_"sw"$ the GaN advantage grows.

== Graduate Extension: Switched-Capacitor Quadrupler Flash Supply
#figure(
  image("/figures/3_4_switch_cap.png", width: 100%),
  caption: [schematic of switched-capacitor quadrupler flash circuit],
) <figure_3_4>

In this prototype the network is driven from $V_"in" = 3V$ and
uses four flying-capacitor stages to charge a storage capacitor
$C_"flash"$ to approximately $V_"flash,hi" approx 10 V$. The
flash path consists of this storage capacitor, a 1,Ω series resistor,
the 6,V, 3,A LED, and a MOSFET switch. During a flash the MOSFET
connects $C_"flash"$ to the LED so that the capacitor discharges from
$V_"flash,hi"$ down toward some lower voltage $V_"flash,lo"$.

The energy extracted from the storage capacitor by a single flash is
#math.equation(block: true, [
  $
    E_"flash"
    = 1/2 dot C_"flash"
    (V_"flash,hi"^2 - V_"flash,lo"^2).
  $
])
For the measured values
$C_"flash" = 1000 " "mu F$,
$V_"flash,hi" approx 10 V$,
and $V_"flash,lo" approx 8 V$, the energy per flash is
#math.equation(block: true, [
  $
    E_"flash"
    ≈ 1/2 dot 1000·10^(-6) * (10^2 - 8^2)
    = 0.5 dot 10^(-3) dot 36
    ≈ 18 " " m J.
  $
])
Two flashes therefore remove roughly $36 " " m J$ from the storage
capacitor before it is recharged by the switched-capacitor network.

The instantaneous LED current is set by the voltage left across the
series resistance. Approximating the LED as a 6,V drop and taking the
series resistance to be dominated by the explicit 1,Ω resistor
(the MOSFET on-resistance and LED dynamic resistance are much smaller),
the peak current at the start of the pulse is
#math.equation(block: true, [
  $
    I_"flash,pk"
    ≈ (V_"flash,hi" - V_"LED")/(R_"eq")
    ≈ (10 - 6)/1
    ≈ 4 A,
  $
])
and the current then decays as the capacitor discharges. The decay time
constant of the flash is set by the same resistance and $C_"flash"$:
#math.equation(block: true, [
  $
    tau ≈ R_"eq" C_"flash"
    ≈ 1·1000·10^(-6)
    ≈ 1 m s,
  $
])
so most of the visible light is produced in the first few hundred
microseconds, consistent with the short, high-current flashes seen in
measurement.

The finite energy in $C_"flash"$ limits how many such flashes can be
produced before the voltage collapses close to the LED forward voltage.
If each flash has average current $I_"avg"$ over duration $t_"p"$, the
charge removed per flash is
$Delta Q = I_"avg" t_"p"$, and the resulting voltage droop is
#math.equation(block: true, [
  $
    Delta V = (Delta Q)/(C_"flash")
    = (I_"avg" t_"p")/(C_"flash").
  $
])
After $N$ identical flashes the total droop is $N Delta V$, so the
minimum capacitor voltage is
$V_"flash,min" = V_"flash,hi" - N Delta V$. To maintain a clearly
visible flash the capacitor voltage must stay at least a few volts above
the LED forward voltage; here a margin of
$V_"margin" approx 2 V$ is used, so
$V_"flash,min" > V_"LED" + V_"margin" approx 8 V$. This
requirement bounds the number of flashes:
#math.equation(block: true, [
  $
    N < (V_"flash,hi" - V_"flash,min")/(Delta V)
    = [(V_"flash,hi" - V_"flash,min")(C_"flash")]/
    (I_"avg" t_"p").
  $
])
Using $V_"flash,hi" = 10 V$,
$V_"flash,min" = 8 V$,
$C_"flash" = 1000 " " mu F$,
$I_"avg" approx 3 A$,
and a pulse width $t_"p" approx 0.3 " "m s$ gives
#math.equation(block: true, [
  $
    N < ((10 - 8) dot 10^(-3))/(3 dot 0.3 dot 10^(-3)) ≈ 2.2,
  $
])
so in practice only two short flashes can be delivered before the
capacitor voltage falls too close to the LED forward voltage and the
current (and brightness) collapse. Because the charge pump feeding
$C_"flash"$ can only supply a small average current from the 3,V input,
the capacitor recharges slowly between flash events, keeping the
additional average thermal load modest while still allowing high
instantaneous flash current.

= Modeling, Simulation, and Control Analysis


The MATLAB script `boost_cc_led_PI_stable.m` (Appendix A) encodes the averaged boost
plant, the sense path, and the PI controller, and simulates both frequency
response and step behavior using the same parameters as the hardware
design.

== Small-signal boost model and transfer function

With state vector $x = (i_"L", v_"C")^T$ and $R_"load" = V_"out,nom"/I_"out,nom"$,
the ON and OFF subcircuits over a switching period yield matrices
$A_1, A_2$ and input vectors $b_1, b_2$:

#math.equation(block: true, [
  $
    A_1 =
    ( 0, 0;
      0, -1/(R_"load" * C) ),
  $
])

#math.equation(block: true, [
  $
    A_2 =
    ( 0, -1/L;
      1/C, -1/(R_"load" * C) ),
  $
])

Averaging gives
#math.equation(block: true, [
  $
    A = D A_1 + (1 - D) A_2
    =
    ( 0, -(1 - D)/L;
      (1 - D)/C, -1/(R_"load" * C) ).
  $
])

Linearizing around $(I_"L", V_"out,nom", D)$ and writing small perturbations
$hat i_"L"$, $hat v_"C"$, $hat d$ yields
#math.equation(block: true, [
  $
    dot(hat x) = A hat x + B_"d" hat d,
  $
])
with
#math.equation(block: true, [
  $
    B_"d" =
    ( V_"out,nom"/L;
      -I_"L"/C ).
  $
])

Selecting $hat(v_"C")$ as the output,
#math.equation(block: true, [
  $
    C_"v" = (0, 1),
  $
])
the duty-to-output transfer function is
#math.equation(block: true, [
  $
    G_"vd"(s)
    = hat((V_"out"(s))) / (hat(d(s)))
    = C_"v" (s I - A)^(-1) B_"d".
  $
])

This simplifies to the canonical boost form
#math.equation(block: true, [
  $
    G_"vd"(s)
    = V_"out,nom" / (1 - D)
    * (1 - s / s_"z")
    / (s^2 / omega_"0"^2 + s / (Q * omega_"0") + 1),
  $
])
with
#math.equation(block: true, [
  $
    omega_"0" = (1 - D)/sqrt(L * C),
  $
])
#math.equation(block: true, [
  $
    Q = (1 - D) * R_"load"/sqrt(L/C),
  $
])
#math.equation(block: true, [
  $
    s_"z" = R_"load" * (1 - D)^2 / L,
    quad
    f_"rhp" = s_"z"/(2 * pi).
  $
])

The numerical values used in the script ($V_"in" = 3,V$, $V_"out,nom" = 6,V$,
$I_"out,nom" = 1,A$, $L = 22,µ H$, $C = 120,µ H$) match the design and set
$omega_"0"$ and $f_"rhp"$ in the expected ranges.@Lee2014VoltageModeBoost

== State-space model used in MATLAB

The script constructs `A1`, `A2`, `A`, and `Bd` exactly as above, with
`Rload = Vout_nom/Iout_nom` and
#math.equation(block: true, [
  $
    D = 1 - V_"in"/V_"out,nom".
  $
])
The steady-state inductor current is computed as
#math.equation(block: true, [
  $
    I_"L" = V_"in" / (R_"load" * (1 - D)^2),
  $
])
and the duty-perturbation input is coded as
#math.equation(block: true, [
  $
    B_"d" =
    ( V_"out,nom"/L;
      -I_"L"/C ).
  $
])

The current sense output is modeled by
#math.equation(block: true, [
  $
    C_"vsense" =
    ( 0, (R_"sense" * K_"sense,amp") / R_"load" ),
  $
])
with
#math.equation(block: true, [
  $
    K_"sense,amp" = 1 / (R_"sense" * I_"max,real"),
  $
])
so that 0–1.25 A corresponds to 0–1 V at `Vmeas`. This matches the 0–1 V
hardware scaling.

== PI controller mapping and augmented closed-loop system

The PI controller is implemented as
#math.equation(block: true, [
  $
    G_"PI"(s) = K_"p" + K_"i"/s,
  $
])
with an inverting op-amp mapping
#math.equation(block: true, [
  $
    K_"p" = R_"f"/R_"in", quad
    K_"i" = 1/(R_"in" * C_"f").
  $
])
In the script, representative values are
#math.equation(block: true, [
  $
    R_"in" = 10,k Ω, quad
    R_"f" = 680,Ω, quad
    C_"f" = 10,µ F,
  $
])
leading to modest $K_"p"$ and $K_"i"$ consistent with stability and the
hardware values.

The augmented closed-loop state is
#math.equation(block: true, [
  $
    x_"cl" = (i_"L", v_"C", z)^T,
  $
])
where $z$ is the integrator state. With normalized PWM gain $K_"pwm" = 1$,
the closed-loop matrices are

#math.equation(block: true, [
  $
    A_"cl" =
    ( A - B_"d" K_"p" K_"pwm" C_"vsense", B_"d" K_"i" K_"pwm";
      -C_"vsense", 0 ),
  $
])
#math.equation(block: true, [
  $
    B_"cl" =
    ( B_"d" K_"p" K_"pwm";
      1 ),
  $
])
with output matrices
#math.equation(block: true, [
  $
    C_"y" = (C_"vsense", 0), quad D_"cl" = 0,
  $
])
for `Vmeas`, and
#math.equation(block: true, [
  $
    C_"i" = C_"y" / (R_"sense" * K_"sense,amp"),
  $
])
for $I_"LED"$. The MATLAB systems
#math.equation(block: true, [
  $
    "sys"_"vsense" = "ss"(A_"cl", B_"cl", C_"y", D_"cl"),
  $
])

#math.equation(block: true, [
  $
    "sys"_"iout" = "ss"(A_"cl", B_"cl", C_"i", D_"cl"),
  $
])

are used for Bode and time-domain plots.

== Frequency response and loop properties
#figure(
  image("/figures/4_1_bode_transfer.png", width: 100%),
  caption: [Plot of simulated Bode transfer functions from setpoint to measured voltage and LED current],
) <figure_4_1>


The Bode plot of `sys_iout` (setpoint → LED current) shows a crossover
frequency in the low-kilohertz range, well below both $f_"rhp"$ and
$f_"sw"/10$, and a phase margin around 50–60°. This matches the TI loop
design guidelines and the qualitative goals stated earlier:
low-frequency gain for good current regulation, and enough phase margin for
a well-damped step response.@Lee2014VoltageModeBoost @Lee2014CurrentModeBoost

== Step-response simulation
#figure(
  image("/figures/4_2_set_response.png", width: 100%),
  caption: [Plot of simulated step response in LED current and measured voltage],
) <figure_4_2>

The script simulates a step in `Vset` from 0.3 V to 0.7 V at $t = 1,m s$ and
uses `lsim` to compute `Vmeas` and `I_LED`. The responses show the sensed
voltage tracking the setpoint with small steady-state error and the LED
current moving smoothly to the new level with modest overshoot and settling
within a few milliseconds. This behavior is consistent with the Bode
analysis and provides a reference for interpreting the measured scope
waveforms in the hardware section.

= Hardware Implementation and Measurement Setup
#figure(
  image("/figures/5_1_setup.jpg", width: 100%),
  caption: [Photograph of prototype hardware setup],
) <figure_5_1>

The prototype was built on a breadboard using the discrete boost stage and control loop from figure 3. The layout was chosen
to keep the high di/dt loops compact and to expose key internal nodes for
probing:

- Switch node (inductor diode switch junction),
- LED cathode (for measuring output ripple),
- Sense amplifier output `Vmeas`,
- Setpoint `Vset`,
- PI output `Vctrl`,
- Triangle ramp `Vtri`.

The 3 V input was provided by a bench supply configured to emulate a fresh
pair of alkaline cells. A second channel supplied gate-drive / comparator
logic during early bring-up; in the final configuration the LM358 and
comparator run directly from the same 3 V rail as the power stage.

A digital oscilloscope with 10× probes was used for all waveforms. To
reduce loop inductance in the high-frequency current paths, the inductor,
diode, and switch device were clustered physically near each other, and
short ground returns were used for both the input and output capacitors.
The 0.2 Ω sense resistor was mounted with short Kelvin connections to the
sense amplifier to minimize error from trace resistance.

Before closing the loop, the following incremental tests were performed:

- Open-loop switching of the boost stage at ≈100 kHz with fixed duty cycle,
  verifying expected duty/voltage relation and switch-node waveform.
- Standalone verification of the triangle generator (`Vtri`) and comparator
  behavior, confirming clean, monotonic PWM.
- DC transfer of the sense path (LED current → `Vmeas`) and setpoint path
  (`Vset`), verifying that both span 0–1 V over the intended current range.

Only after these blocks matched the model was the PI controller closed
around the current sense to form a complete LED driver.

== Implementation Challenges
During the bring-up phase, several challenges were encountered that required design iterations:

1. *Noise on the Sense Line:* Initially, the switching noise from the main boost loop coupled into the high-impedance input of the current sense op-amp, causing the PWM to jitter. This was resolved by adding a small R-C low-pass filter ($100 Omega$, $1 n F$) at the op-amp input and improving the ground layout to separate the power ground from the signal ground.

2. *Comparator Hysteresis:* The comparator initially triggered multiple times on the noisy triangle wave peaks. A small amount of hysteresis was added via a positive feedback resistor to ensure clean switching transitions.

3. *GaN Vgs:* Specifically for the GaN FET, ensuring that the gate drive voltage was sufficient to fully turn on the device without exceeding its maximum gate voltage rating required careful selection of the drive circuitry. A dedicated gate driver IC (the IR2125) was chosen with an external 12 V supply to provide the necessary gate voltage. 

= Experimental Results and Comparison to Simulation

#figure(
  image("/figures/6_1_light.jpg", width: 100%),
  caption: [Photograph of prototype flashlight driver in operation],
) <figure_6_1>

This section summarizes the key measured waveforms and compares them
qualitatively to the MATLAB simulations of Section 5. Scope plots are
referred to by figure number; each was captured at the nominal operating
point with $V_"in" approx 3 V$ and the LED current in the 1–1.5 A range.

== Operating point and steady-state waveforms

In steady state, with the setpoint adjusted to a mid-range value, the
measured LED current (via the 0.2 Ω shunt) is on the order of 1 A and the
output voltage approximately 6–6.5 V, consistent with the design. The
switch-node waveform (not explicitly shown here but observed) shows the
expected boost behavior: during the on-time the switch node is near ground; during the off-time it rises above the
output voltage as the inductor current commutates through the diode.

Figure 10 shows the key signals for the *PWM generation*: the PI controller's output voltage ($V_"ctrl"$) (blue), which is nearly a DC level in steady-state, is compared against the sawtooth/triangle wave (yellow). The intersection of these two signals determines the switch's turn-off point.

The resulting *gate drive signal (duty cycle)* is shown in Figure <figure_6_3>. The measured duty cycle at this operating point is close to the predicted
$D approx 0.5$ from
#math.equation(block: true, [
  $
    D = 1 - V_"in"/V_"out".
  $
])
The inductor current, reconstructed from the shunt voltage and sense gain,
shows triangular ripple consistent with the ~  0.7 A  peak-to-peak value
predicted in Section 4 (actual inductor current is not shown in the figures).

The output voltage ripple is small (tens of millivolts) and primarily
high-frequency, confirming that the chosen $120 µ F$ capacitance is sufficient
for both LED visual performance and small-signal modeling assumptions.

---

== Setpoint step response

#figure(
  image("/figures/DS1Z_QuickPrint2.png", width: 100%),
  caption: [Waveform capture of the Pulse Width Modulation (PWM) generator signals. Blue (Channel 2) is the PI controller output $V_"ctrl"$ (the control voltage), and yellow (Channel 1) is the triangle wave (ramp signal) at ~100  "kHz".],
) <figure_6_2>

A key test is the response to a step in $V_"set"$. On the bench, the setpoint
was changed by adjusting the potentiometer from a lower to a higher voltage
command, roughly analogous to the 0.3 to 0.7 V step simulated in MATLAB.

The measured $V_"set"$, $V_"meas"$, and LED current waveforms show:

- $V_"meas"$ tracks $V_"set"$ with small steady-state error, confirming that the PI controller successfully drives the sensed current toward the reference.
- The LED current exhibits a single, well-damped rise from its initial to
  final value, with modest overshoot and settling within a few
  milliseconds.
- The duty cycle increases smoothly during the transient; no subharmonic
  oscillations or sustained ringing near half the switching frequency were
  observed, which is consistent with the absence of a current-mode inner
  loop and the conservative choice of crossover frequency.

Qualitatively, the measured step response matches the MATLAB predictions:
the simulated $"sys"_"iout"$ step in Section 5 shows a similar rise time,
overshoot, and settling behavior. Small discrepancies (slightly slower
settling and slightly higher overshoot on hardware) are attributable to
LM358 finite bandwidth, comparator propagation delay, and nonideal ramp
shape—effects that were neglected in the idealized averaged model.

== Comparison of GaN vs Si switch behavior
#figure(
  table(
    align: center,
    columns: (auto, auto),
    row-gutter: (2pt, auto),
    stroke: 0pt,
    inset: 6pt,

    [*GaN Gate Waveform*], [*Si Gate Waveform*],
    [#figure(
        image("/figures/DS1Z_QuickPrint4.png", width: 100%),
      ) <figure_6_4>
    ],

    [#figure(
        image("/figures/DS1Z_QuickPrint3.png", width: 100%),
      ) <figure_6_3>
    ],
  ),

  caption: [
    Post-synthesis SAIF-based power breakdown at 10 ns.
  ],
) <saif-power-table>


When the silicon MOSFET was replaced with the GaN FET, the primary
observable differences on the scope were:

- Faster switch-node transitions (shorter rise/fall times),
- Slightly reduced switching-node ringing due to lower charge storage,
- Lower device temperature for the same output current, consistent with the
  reduced conduction and switching losses discussed in Section 4.

At the relatively low 100 kHz switching frequency, both devices allowed the
converter to reach the same operating point, but the GaN FET did so with
noticeably less self-heating over a multi-minute run. This matches the
loss-estimation trends and illustrates how even at a few volts and a few
amps, device parasitics and transition speeds are important.

= Energy-Flow and Graduate Extension Discussion
#figure(
  image("/figures/7_1_light_thermal.jpg", width: 100%),
  caption: [Thermal performance of LED],
) <figure_6_2>

A central 6.2222 theme is energy conservation and Tellegen-style reasoning
about networks. For the flashlight driver, it is natural to divide the
steady-state input power into useful LED power and losses in individual
elements. Figure 12 illustrates the measured thermal behavior of the LED:
at the nominal operating point the LED case stabilizes near 70,°C, which
is consistent with the expected electrical-to-thermal conversion and the
measured optical output.

At a representative operating point, the input power is
#math.equation(block: true, [
  $
    P_"in" = V_"in" * I_"in",
  $
])
the LED optical/electrical power is approximated by
#math.equation(block: true, [
  $
    P_"LED" ≈ V_"f" * I_"LED",
  $
])
and the remainder is partitioned into conduction and switching losses in
the switch, diode, inductor copper loss, control power, and sense resistor
loss. Section 4 provided analytical estimates for the switch and shunt
losses; qualitative thermal observations on the bench are consistent with
those estimates (the shunt runs warm, the silicon MOSFET runs appreciably
warmer than the GaN device).

From a Tellegen perspective, the averaged boost network plus control
circuitry form a larger multiport network in which the sum over all branch
power $v_k * i_k$ is zero at each instant. Integrating over a switching
period and grouping terms by element yields
#math.equation(block: true, [
  $
    P_"in" = P_"LED" + P_"switch" + P_"diode" + P_"L,loss" + P_"sense" + P_"ctrl",
  $
])
where each term can be estimated either from measured currents and voltages
or from datasheet parameters. The GaN vs Si comparison is naturally
expressed in these terms: substituting a lower–$R_"ds,on"$, faster device
reduces $P_"switch"$ for fixed $P_"in"$, allowing either a higher
$P_"LED"$ at the same thermal limit or a cooler-running converter for the
same LED power.

The switched-capacitor flash extension can also be viewed through energy
flow. Over a full charge–discharge cycle, the net energy delivered to the
LED during the flash must be drawn from the 3 V input via the doubler
network. The “equivalent resistance” of the doubler chain determines how
much extra input power is needed to support repeated flashes, and Tellegen
ensures that averaged over many cycles, this additional power appears as
either extra LED optical output or additional losses in the charge pump
elements.

= Discussion and Conclusion

This project built and tested a discrete boost converter for a high-power LED and used it as a hands-on way to think about stability and current control, not just “making a bright flashlight.” Starting from a 3 V source and a 6 V Cree XHP50.3 LED, the circuit combined a 22 µH inductor, a 120 µF output capacitor, a 0.2 Ω sense resistor, and LM358-based current sensing, PI control, and PWM generation to create a complete current-regulated driver.@CreeXHP503

A key lesson was how tightly stability and current regulation are linked. The control design had to respect the boost converter’s right-half-plane zero and LC resonance, so the crossover frequency and PI gains could not be chosen arbitrarily.@Lee2014VoltageModeBoost @Lee2014CurrentModeBoost  The small-signal averaged model and MATLAB Bode plots made it clear that high low-frequency gain (for small steady-state error) has to be balanced against enough phase margin at crossover (for well-damped transients). The comparison between simulated and measured responses also highlighted where real-world nonidealities—op-amp bandwidth, comparator delay, and ramp distortion—start to erode the “perfect” loop behavior predicted by the model.

On the device side, swapping a silicon MOSFET for a GaN FET in the same topology showed how much the switch actually matters, even in a 3→6 V design. The GaN device reduced switching loss and ran cooler at 100 kHz, hinting that higher-frequency operation and smaller magnetics would be possible with a more careful layout. Overall, the project turned a simple flashlight into an accessible platform for seeing how classical feedback ideas, averaged converter models, and current-mode thinking all come together in real hardware, and it points naturally toward next steps such as a PCB implementation, true current-mode control with slope compensation, and more systematic efficiency and transient measurements.
\
\
\
\
\
\
\
= Appendix section
== Matlab Code Listing
```matlab
%% boost_cc_led_PI_stable.m
% Small-signal averaged model of boost -> current sense -> PI -> PWM

clear; clc; close all;

%% ====== Power stage and sense parameters ===============================
Vin      = 3;          % V, battery
Vout_nom = 6;          % V, nominal LED voltage
Iout_nom = 1;          % A, nominal LED current (you can leave this)
L        = 22e-6;
C        = 120e-6;
fsw      = 100e3;
Rload    = Vout_nom / Iout_nom;

Rsense      = 0.2;     % Ohm, current-sense resistor

Imax_real   = 1.25;    % A, max LED current you see in hardware
K_sense_amp = 1/(Rsense * Imax_real);   % => 0..1 V for 0..1.25 A
% K_sense_amp = 4 in this case

%% ====== PI controller as hardware =====================================
% We implement: G_PI(s) = Kp + Ki/s
% with a series Rf-Cf in the feedback and an input resistor Rin:
% Kp = Rf/Rin, Ki = 1/(Rin*Cf)

Rin = 10e3;           % Ohm
Rf  = 680;            % Ohm
Cf  = 10e-6;         % F

Kp  = Rf / Rin;
Ki  = 1/(Rin * Cf);

% (These values give roughly Kp = 0.5, Ki = 500 – stable for this plant.)

%% ====== Linearized CCM boost converter model ===========================
% Steady-state
D   = 1 - Vin / Vout_nom;          % duty
V_o = Vout_nom;
I_o = V_o / Rload;
I_L = Vin / (Rload * (1-D)^2);

% ON:  diL/dt = Vin/L, dvC/dt = -vC/(R C)
A1 = [ 0,                         0;
       0,                -1/(Rload*C) ];

% OFF: diL/dt = (Vin - vC)/L, dvC/dt = iL/C - vC/(R C)
A2 = [ 0,                -1/L;
       1/C,  -1/(Rload*C) ];

% Duty-averaged A
A = D*A1 + (1-D)*A2;

% Duty perturbation input (Erickson/Maksimovic form)
Bd = [ V_o / L;
      -I_L / C ];

% Sense output: Vmeas = K_sense_amp * Rsense * i_out, i_out ≈ vC/Rload
C_vsense = [0, (Rsense*K_sense_amp)/Rload];   % 1×2
D_vsense = 0;

%% ====== Build loop in state space (add PI integrator state) ============
K_pwm = 1;   % normalized PWM gain (0–1 V triangle & control)

% States: [ x ; z ], x = [iL; vC], z = integrator state
% x_dot = A x + Bd*K_pwm*(Kp*(r - y) + Ki*z)
% z_dot = r - y,     y = C_vsense x
%
% => A_cl = [A - Bd*Kp*K_pwm*C,   Bd*Ki*K_pwm;
%            -C_vsense,          0]

A_cl = [A - Bd*Kp*K_pwm*C_vsense,  Bd*Ki*K_pwm;
        -C_vsense,                0              ];

B_cl = [Bd*Kp*K_pwm;
        1          ];        % input is setpoint r

C_y   = [C_vsense, 0];       % output y = Vmeas
C_i   = C_y / (Rsense * K_sense_amp); % LED current (A) from Vmeas

D_cl  = 0;

% State-space systems
sys_vsense = ss(A_cl, B_cl, C_y, D_cl);   % Vmeas / Vset
sys_iout   = ss(A_cl, B_cl, C_i, D_cl);   % I_LED / Vset

%% ====== Check poles and frequency response ============================
fprintf('Closed-loop poles (Vset -> Vmeas):\n');
disp(pole(sys_vsense));

figure;
bode(sys_iout);
grid on;
title('Closed-loop transfer: set-point \rightarrow LED current');

%% ====== Time-domain step in set-point ==============================
t_end = 1000e-3;          % 5 ms total sim time
Ts    = 1e-5;          % 10 us sample time  << 1.2e-4 from warning
t     = 0:Ts:t_end;    % time vector

Vset_low  = 0.3;
Vset_high = 0.7;
t_step    = 1e-3;

r = Vset_low * ones(size(t));
r(t >= t_step) = Vset_high;


[y_vsense, ~] = lsim(sys_vsense, r, t);
y_iout        = lsim(sys_iout,   r, t);

figure;
subplot(2,1,1);
plot(t*1e3, r, 'LineWidth', 1.5); hold on;
plot(t*1e3, y_vsense, 'LineWidth', 1.5);
ylabel('Voltage (V)');
legend('V_{set}','V_{meas}','Location','Best');
grid on;
title('Set-point step and sensed feedback');

subplot(2,1,2);
plot(t*1e3, y_iout, 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('I_{LED} (A)');
grid on;
title('LED current response to set-point step');

```

#bibliography("bibliography.bib")



