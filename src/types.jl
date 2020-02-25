"""
Composite Type holding the result of Value Iteration
"""
struct ValueIteration
    expected_contribution::Float64
    number_pre_decision_states::Int64
    number_post_decision_states::Int64
end

"""
Composite Type holding counters
"""
mutable struct Counter
    pre_decision_states::Int64
    post_decision_states::Int64
end

"""
Abstract Type for Information State
"""
abstract type AbstractState end

"""
Composite Type for Pre-Decision State
"""
mutable struct PreDecisionState <: AbstractState
    r_t::Array{Int64} # Request state of customers
    m_t::Int64        # Destination
    δ_t::Int64        # Remaining time needed to arrive at m
end

"""
Composite Type for Post-Decision State
"""
mutable struct PostDecisionState <: AbstractState
    rx_t::Array{Int64} # Request state of customers
    mx_t::Int64        # Destination
    δx_t::Int64        # Remaining time needed to arrive at m
end

"""
Composite Type for Decision Variable
"""
mutable struct Decision
    c_t::Array{Int64} # Customer request decision
    m_t::Int64       # Service vehicle movement decision
end

"""
Abstract Type for Edges connecting a node of state `FromState` to a node of state `ToState`.
"""
abstract type AbstractEdge{FromState <: AbstractState, ToState <: AbstractState} end
"""
Abstract Type for Nodes of state `CurrentState` (with following nodes of state `NextState`).
"""
abstract type AbstractNode{CurrentState <: AbstractState, NextState <: AbstractState} end

"""
Composite Type for Nodes containing a state of type `PreDecisionState`.
"""
mutable struct PreDecisionNode <: AbstractNode{PreDecisionState, PostDecisionState}
    s_t::PreDecisionState                                           # State of type S
    t::Int64                                                        # Time
    contribution_expected::Float64                                  # Expected contribution of following edges
    edges::Array{AbstractEdge{PreDecisionState, PostDecisionState}} # Following Edges
end

"""
Composite Type for Nodes containing a state of type `PostDecisionState`.
"""
mutable struct PostDecisionNode <: AbstractNode{PostDecisionState, PreDecisionState}
    sx_t::PostDecisionState                                         # State of type S
    t::Int64                                                        # Time
    contribution_expected::Float64                                  # Expected contribution of following edges
    edges::Array{AbstractEdge{PostDecisionState, PreDecisionState}} # Following Edges
end

"""
Composite Type for Edge connecting a PreDecisionState with a PostDecisionState.
"""
mutable struct DecisionEdge <: AbstractEdge{PreDecisionState, PostDecisionState}
    node::AbstractNode{PostDecisionState, PreDecisionState} # Following Node
    t::Int64                                                # Time
    x_t::Decision                                           # Decision
    contribution::Float64                                   # Contribution of edge
end

"""
Composite Type for Edge connecting a PostDecisionState with a PreDecisionState.
"""
mutable struct RandomEdge <: AbstractEdge{PostDecisionState, PreDecisionState}
    node::AbstractNode{PreDecisionState, PostDecisionState} # Following Node
    t::Int64                                                # Time
    w_t::Array{Int64}                                       # Random variables for customers requesting
    ω::Float64                                              # Probability of edge
end
