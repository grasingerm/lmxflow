# lbxflow
Modelling complex flow using lattice Boltzmann method

## lattice Boltzmann method
Lattice Boltzmann method is a computational technique that streams and
collides "psuedo particles", or particle frequency distributions, on a lattice
to approximate hydrodynamics.

## Dependencies
* YAML
* PyPlot (if plotting or animation is used)

## TODO list
* [x] verify Newtonian Poiseuille flow
* [x] debug BCs at inlet/outlet (bounceback, periodic)
* [x] implement MRT scheme for Bingham plastic flow
* [ ] implement free surface flow
* [x] clean up api
* [x] make an autosave feature
* [x] should be able to "catch" from exceptions and/or keyboard interrupt
* [ ] should be able to restart from interrupted model where left off
* [ ] parallelize streaming and collision steps, multiscale mapping, and BCs
* [ ] write user documentation
* [ ] clean up existing BCs / more general BCs
* [ ] break collision functions down into forcing method, constitutive eqn, etc.
* [x] develop post processing and animations
* [ ] implement HB-Bingham constitutive model used in Fluent
* [ ] consider "DSL" for mapping particle to macroscale and vice versa
* [ ] implement Jonas Latt BCs
* [ ] profile simulation steps to identify bottlenecks
* [ ] write some tests?
