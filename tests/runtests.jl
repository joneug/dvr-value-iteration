include("../src/types.jl")
include("../src/valueiteration.jl")
using Test

# To enable debug logs:
# ENV["JULIA_DEBUG"] = "all"
# ENV["JULIA_DEBUG"] = ""

state = PreDecisionState([-1,1,0,2,3,1,-1], 1, 0)
node = transition(
    state, # s_t::PreDecisionState
    Decision([-1,1,0,0,1,0,-1],2), # x_t::Decision
    0, # t::Int64
    [(1.0,1.0),(2.0,2.0),(3.0,3.0),(5.0,5.0),(6.0,6.0),(100.00,100.00),(4.0,4.0)], # I::Array{Tuple{Float64,Float64}}
    10 # T::Int64
)
@testset "transition to Post-Decision State" begin
    @test node.sx_t.rx_t == [-1,4,0,3,2,4,-1]
    @test node.sx_t.mx_t == 2
    @test node.sx_t.δx_t == 2
    @test node.t == 0
    @test node.contribution_expected == 0
    @test node.edges == []
    @test state.r_t == [-1,1,0,2,3,1,-1]
    @test state.m_t == 1
    @test state.δ_t == 0
end

state = PostDecisionState([-1,4,0,3,2,4,-1], 2, 4)
node = transition(
    state, # sx_t::PostDecisionState
    [-1,0,1,0,1,0,-1], # w_t::Array{Int64},
    0 # t::Int64
)
@testset "transition to Pre-Decision State" begin
    @test node.s_t.r_t == [-1,4,1,3,2,4,-1]
    @test node.s_t.m_t == 2
    @test node.s_t.δ_t == 3
    @test node.t == 1
    @test node.contribution_expected == 0
    @test node.edges == []
    @test state.rx_t == [-1,4,0,3,2,4,-1]
    @test state.mx_t == 2
    @test state.δx_t == 4
end

@testset "distance between locations" begin
    @test dist([(1.0,1.0),(2.0,2.0)], 1, 2) == 2
    @test dist([(4.2,5.1),(1.0,2.0)], 1, 2) == 5
end
