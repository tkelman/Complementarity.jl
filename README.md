# Complementarity.jl

[![Complementarity](http://pkg.julialang.org/badges/Complementarity_0.4.svg)](http://pkg.julialang.org/?pkg=Complementarity)
[![Complementarity](http://pkg.julialang.org/badges/Complementarity_0.5.svg)](http://pkg.julialang.org/?pkg=Complementarity)


[![Build Status](https://travis-ci.org/chkwon/Complementarity.jl.svg?branch=master)](https://travis-ci.org/chkwon/Complementarity.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/pcb5nb5tsstueq1f?svg=true)](https://ci.appveyor.com/project/chkwon/complementarity-jl)
[![Coverage Status](https://coveralls.io/repos/github/chkwon/Complementarity.jl/badge.svg?branch=master)](https://coveralls.io/github/chkwon/Complementarity.jl?branch=master)


This package provides a modeling and computational interface for solving [Mixed Complementarity Problems](https://en.wikipedia.org/wiki/Mixed_complementarity_problem) (MCP): modeling by [JuMP.jl](https://github.com/JuliaOpt/JuMP.jl) and computing by [PATHSolver.jl](https://github.com/chkwon/PATHSolver.jl). Note that MCP is more general than [Linear Complementarity Problems](https://en.wikipedia.org/wiki/Linear_complementarity_problem) (LCP) and [Nonlinear Complementarity Problems](https://en.wikipedia.org/wiki/Nonlinear_complementarity_problem) (NCP). 

While the PATH Solver is the only available algorithm at this moment, this package aims to provide a few more algorithms for solving complementarity problems, perhaps specialized for solving LCP and NCP. It may also connect with the [VariationalInequality.jl](https://github.com/chkwon/VariationalInequality.jl) package.

The form of MCP is as follows:
```
lb ≤ x ≤ ub ⟂ F(x)
```
which means
- `x = lb`, then `F(x) ≥ 0`
- `lb < x < ub`, then `F(x) = 0`
- `x = ub`, then `F(x) ≤ 0`

When there is no upper bound `ub`, and the lower bound `lb=0`, then it is a regular Nonlinear Complementarity Problem (NCP) of the form:
```
0 ≤ x ⟂ F(x) ≥ 0
```
which means
```
F(x)' x = 0, F(x) ≥ 0, x ≥ 0
```
When `F(x)` is a linear operator such as `F(x) = M x + q` with matrix `M` and vector `q`, then it is a Linear Complementarity Problem (LCP). All these problems are solved by the [PATH Solver](http://pages.cs.wisc.edu/%7Eferris/path.html) which is wrapped by the [PATHSolver.jl](https://github.com/chkwon/PATHSolver.jl) package.

This package `Complementarity.jl` extends the modeling language from [JuMP.jl](https://github.com/JuliaOpt/JuMP.jl) to model complementarity problems.

# Installation

```julia
Pkg.add("Complementarity")
```

This will automatically install `PATHSolver.jl` as well.

# License

Without a license, the PATH Solver can solve problem instances up to with up to 300 variables and 2000 non-zeros. For information regarding license, visit the [PATHSolver.jl](https://github.com/chkwon/PATHSolver.jl) page and the [license page](http://pages.cs.wisc.edu/~ferris/path/LICENSE) of the PATH Solver.


# Example 1

```julia
using Complementarity, JuMP

m = MCPModel()

M = [0  0 -1 -1 ;
     0  0  1 -2 ;
     1 -1  2 -2 ;
     1  2 -2  4 ]

q = [2; 2; -2; -6]

lb = zeros(4)
ub = Inf*ones(4)

items = 1:4

# @variable(m, lb[i] <= x[i in items] <= ub[i])
@variable(m, x[i in items] >= 0)
@NLexpression(m, F[i in items], sum{M[i,j]*x[j], j in items} + q[i])
complements(m, F, x)

PATHSolver.path_options(
                "convergence_tolerance 1e-2",
                "output no",
                "time_limit 3600"
                )

solveMCP(m)

z = getvalue(x)
````
The result should be `[2.8, 0.0, 0.8, 1.2]`.

```julia
m = MCPModel()
```
This line prepares a JuMP Model, just same as in [JuMP.jl](https://github.com/JuliaOpt/JuMP.jl).

```julia
@variable(m, x[i in items] >= 0)
```
Defining variables is exactly same as in JuMP.jl. Lower and upper bounds on the variables in the MCP model should be provided here.

```julia
@NLexpression(m, F[i in items], sum{M[i,j]*x[j], j in items} + q[i])
```
This is to define expressions for `F` in MCP. Even when the expression is linear or quadratic, you should use the nonlinear version `@NLexpression`.

```julia
complements(m, F, x)
```
This function matches each element of `F` and the complementing element of `x`.

```julia
PATHSolver.path_options(   
                "convergence_tolerance 100",
                "output no",
                "time_limit 3600"      )
```
This adjusts options of the PATH Solver. See the [list of options](http://www.cs.wisc.edu/~ferris/path/options.pdf).

```julia
solveMCP(m)
```
This solves the MCP and stores the solution inside `m`, which can be accessed by `getvalue(x)` as in JuMP.


# Example 2

This is a translation of [`transmcp.gms`](http://www.gams.com/modlib/libhtml/transmcp.htm) originally written in GAMS.

```julia
using Complementarity, JuMP

plants = ["seattle", "san-diego"]
markets = ["new-york", "chicago", "topeka"]

capacity = [350, 600]
a = Dict(zip(plants, capacity))

demand = [325, 300, 275]
b = Dict(zip(markets, demand))

elasticity = [1.5, 1.2, 2.0]
esub = Dict(zip(markets, elasticity))

distance = [ 2.5 1.7 1.8 ;
             2.5 1.8 1.4  ]
d = Dict()
for i in 1:length(plants), j in 1:length(markets)
    d[plants[i], markets[j]] = distance[i,j]
end

f = 90

m = MCPModel()
@variable(m, w[i in plants] >= 0)
@variable(m, p[j in markets] >= 0)
@variable(m, x[i in plants, j in markets] >= 0)

@NLexpression(m, c[i in plants, j in markets], f * d[i,j] / 1000)

@NLexpression(m, profit[i in plants, j in markets],    w[i] + c[i,j] - p[j])
@NLexpression(m, supply[i in plants],                  a[i] - sum{x[i,j], j in markets})
@NLexpression(m, fxdemand[j in markets],               sum{x[i,j], i in plants} - b[j])

complements(m, profit, x)
complements(m, supply, w)
complements(m, fxdemand, p)

PATHSolver.path_options(
                "convergence_tolerance 1e-8",
                "output yes",
                "time_limit 3600"
                )

status = solveMCP(m)

@show getvalue(x)
@show getvalue(w)
@show getvalue(p)
@show status
```

The result is
```julia
getvalue(x) = x: 2 dimensions:
[  seattle,:]
  [  seattle,new-york] = 49.99999533220467
  [  seattle, chicago] = 300.0
  [  seattle,  topeka] = 0.0
[san-diego,:]
  [san-diego,new-york] = 275.00000466779534
  [san-diego, chicago] = 0.0
  [san-diego,  topeka] = 275.0

getvalue(w) = w: 1 dimensions:
[  seattle] = 0.0
[san-diego] = 0.0

getvalue(p) = p: 1 dimensions:
[new-york] = 0.22499999999999992
[ chicago] = 0.15299999999999955
[  topeka] = 0.126

status = :Solved
```

# Status Symbols
```julia
status =
    [ :Solved,              # 1 - solved
      :StationaryPoint,     # 2 - stationary point found
      :MajorIterLimit,      # 3 - major iteration limit
      :MinorIterLimit,      # 4 - cumulative minor iteration limit
      :TimeLimit,           # 5 - time limit
      :Interrupt,           # 6 - user interrupt
      :BoundError,          # 7 - bound error (lb is not less than ub)
      :DominaError,         # 8 - domain error (could not find a starting point)
      :InternalError        # 9 - internal error
     ]
 ```
