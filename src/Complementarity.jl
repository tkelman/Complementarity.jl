# isdefined(Base, :__precompile__) && __precompile__()

module Complementarity

# package code goes here

using JuMP

import PATHSolver, MathProgBase

export  MCPModel, MCPData, OneDimension,
        correspond, solveMCP

include("mcp.jl")

end # module
