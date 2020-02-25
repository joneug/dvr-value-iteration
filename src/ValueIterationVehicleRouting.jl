"""
This module implements Value Iteration with backwards induction for the Service Vehicle Routing Problem.
"""
module ValueIterationVehicleRouting

using Combinatorics

export value_iteration, ValueIteration

include("types.jl")
include("valueiteration.jl")

end
