"""
Executes value iteration on a given problem instance, calculates the optimal policy and returns its expected contribution together with some metrics about the state space.
"""
function value_iteration(T::Int64, I::Array{Tuple{Float64,Float64}}, IA::Array{Int64}, P_C::Float64, P_R::Float64, α::Float64)
    @debug "Initializing..."
    pre_decision_nodes = Dict(t => PreDecisionNode[] for t = 0:T)
    post_decision_nodes = Dict(t => PostDecisionNode[] for t = 0:T-1) # we don't make decisions in T, therefore T-1
    counter = Counter(0,0)

    # Initialize customer request states with advance customers
    r_t = fill(0, length(I))
    # first and last location are start and end depot and therefore don't have a request state (signalized by -1)
    r_t[1] = -1
    r_t[end] = -1
    for i in IA
        r_t[i] = 1
    end

    # Initialize start node
    start_node = PreDecisionNode(
        PreDecisionState(r_t, 1, 0),
        0, # Initialize t with 0
        0, # Initialize expected contribution with 0
        []
    )
    push!(getindex(pre_decision_nodes, 0), start_node)

    # Build up the state tree
    @debug "Building up the state tree..."
    build_state_tree!(start_node, T, I, P_C, P_R, α, pre_decision_nodes, post_decision_nodes, counter)

    # Determine the policy by doing backward induction
    @debug "Determining the policy..."
    determine_policy!(pre_decision_nodes, post_decision_nodes, T, P_C, P_R)

    # Return result
    return ValueIteration(start_node.contribution_expected, counter.pre_decision_states, counter.post_decision_states)
end

"""
Builds up the state tree given a Pre-Decision State.
"""
function build_state_tree!(node::PreDecisionNode, T::Int64, I::Array{Tuple{Float64,Float64}}, P_C::Float64, P_R::Float64, α::Float64, pre_decision_nodes::Dict{Int64,Array{PreDecisionNode,1}}, post_decision_nodes::Dict{Int64,Array{PostDecisionNode,1}}, counter::Counter)
    # Exit if time has elapsed
    if node.t == T
        return
    end

    # 1. Determine all feasible decisions
    @debug "[t = $(node.t), PreDecisionNode] Determining feasible decisions"
    X_t = decisions(node.s_t.r_t, node.s_t.δ_t, node.s_t.m_t, node.t, T, I)

    # 2. Create edges connected Post-decision nodes for all decisions
    @debug "[t = $(node.t), PreDecisionNode] Transitioning to Post-decision nodes"
    for x_t in X_t
        # Determine Post-decision node using transition function
        post_decision_node = transition(node.s_t,x_t,node.t,I,T)

        push!(
            node.edges,
            DecisionEdge(
                post_decision_node,
                node.t,
                x_t,
                # calculate contribution of this decision
                contribution(node.s_t.r_t, x_t, node.t, node.s_t.δ_t, T, I, P_C, P_R)
            )
        )
        counter.post_decision_states += 1

        # Add new node to dictionary for backward induction
        push!(getindex(post_decision_nodes, post_decision_node.t), post_decision_node)
    end

    if length(node.edges) == 0
        @debug "[t = $(node.t), PreDecisionNode] No DecisionEdges available. Reached end node."
        return
    end

    # 3. Call build_state_tree! on all new Post-decision nodes
    for edge in node.edges
        build_state_tree!(edge.node, T, I, P_C, P_R, α, pre_decision_nodes, post_decision_nodes, counter)
    end
end

"""
Builds up the state tree given a Post-Decision State.
"""
function build_state_tree!(node::PostDecisionNode, T::Int64, I::Array{Tuple{Float64,Float64}}, P_C::Float64, P_R::Float64, α::Float64, pre_decision_nodes::Dict{Int64,Array{PreDecisionNode,1}}, post_decision_nodes::Dict{Int64,Array{PostDecisionNode,1}}, counter::Counter)
    # 1. Determine exogenous influences
    @debug "[t = $(node.t), PostDecisionNode] Determining exogenous influences"
    W_t = exogenous(node.sx_t.rx_t)

    Ω = 0.0

    # 2. Create edges connected Pre-decision nodes for all exogenous influences
    @debug "[t = $(node.t), PostDecisionNode] Transitioning to Pre-decision nodes"
    for w_t in W_t
        # Determine Pre-decision node using transition function
        pre_decision_node = transition(node.sx_t,w_t,node.t)

        push!(
            node.edges,
            RandomEdge(
                pre_decision_node,
                node.t,
                w_t,
                probability(node.sx_t.rx_t, w_t, α)
            )
        )
        counter.pre_decision_states += 1

        Ω += probability(node.sx_t.rx_t, w_t, α)

        # Add new node to dictionary for backward induction
        push!(getindex(pre_decision_nodes, pre_decision_node.t), pre_decision_node)
    end

    if length(node.edges) == 0
        error("[t = $(node.t), PostDecisionNode] No RandomEdges available.")
    end

    if !isapprox(Ω, 1.0, atol = 0.0000001)
        error("[t = $(node.t), PostDecisionNode] Error in probability calculation. Ω = $(Ω)")
    end

    # 3. Call build_state_tree! on all new Pre-decision nodes
    for edge in node.edges
        build_state_tree!(edge.node, T, I, P_C, P_R, α, pre_decision_nodes, post_decision_nodes, counter)
    end
end

"""
Determines the policy for a given state tree.
"""
function determine_policy!(pre_decision_nodes::Dict{Int64,Array{PreDecisionNode,1}}, post_decision_nodes::Dict{Int64,Array{PostDecisionNode,1}}, T::Int64, P_C::Float64, P_R::Float64)
    # Evaluate expected contribution of every Pre- and Post-decision state in every timestep T-1 down to 0
    # As at T no decision can be made anymore the expected contribution in these last states is 0
    for t in T-1:-1:0
        # Post-decision states
        for post_decision_node in getindex(post_decision_nodes, t)
            contribution_expected = 0.0

            # Expected contribution is the expected value of the expected contributions of following nodes
            for random_edge in post_decision_node.edges
                contribution_expected += random_edge.ω * random_edge.node.contribution_expected
            end

            post_decision_node.contribution_expected = contribution_expected
        end

        # Pre-decision states -> Could be a preliminary end node
        for pre_decision_node in getindex(pre_decision_nodes, t)
            contribution_expected = 0.0

            # Expected contribution is obtained by the edge that maximizes the decision contribution + expected contribution of following nodes
            for decision_edge in pre_decision_node.edges
                contribution_expected = max(contribution_expected, decision_edge.contribution + decision_edge.node.contribution_expected)
            end

            pre_decision_node.contribution_expected = contribution_expected
        end
    end
end

"""
Transitions to a Post-Decision State.
"""
function transition(s_t::PreDecisionState, x_t::Decision, t::Int64, I::Array{Tuple{Float64,Float64}}, T::Int64)
    # See Equation 4.4
    rx_t = copy(s_t.r_t)
    for i in 2:length(rx_t) - 1
        if (s_t.r_t[i] != 0) & ((i == x_t.m_t) | (dist(I, x_t.m_t, i) + dist(I, i, length(I)) > T - t - s_t.δ_t))
            rx_t[i] = 4
        elseif (s_t.r_t[i] in [1, 3]) & (x_t.c_t[i] == 1)
            rx_t[i] = 2
        elseif (s_t.r_t[i] in [1, 2]) & (x_t.c_t[i] == 0)
            rx_t[i] = 3
        end
    end

    # See Equation 4.5
    mx_t = ifelse(s_t.δ_t > 0, s_t.m_t, x_t.m_t)

    # See Equation 4.6
    δx_t = ifelse(s_t.δ_t > 0, s_t.δ_t, dist(I, s_t.m_t, x_t.m_t))

    return PostDecisionNode(
        PostDecisionState(rx_t, mx_t, δx_t),
        t,
        0, # Initialize expected contribution with 0
        []
    )
end

"""
Transitions to a Pre-Decision State.
"""
function transition(sx_t::PostDecisionState, w_t::Array{Int64}, t::Int64)
    # Equation 4.7
    r_tpp = copy(sx_t.rx_t)
    for i in 2:length(r_tpp) - 1
        if (sx_t.rx_t[i] == 0) && (w_t[i] == 1)
            r_tpp[i] = 1
        end
    end

    return PreDecisionNode(
        PreDecisionState(r_tpp, sx_t.mx_t, sx_t.δx_t - 1),
        t + 1, # advance time
        0, # Initialize expected contribution with 0
        []
    )
end

"""
Determines all feasible decisions.
"""
function decisions(r_t::Array{Int64}, δ_t::Int64, m_t::Int64, t::Int64, T::Int64, I::Array{Tuple{Float64,Float64},1})
    # Initialize
    X_t = Decision[]

    # No decision can be made if vehicle has arrived at end depot
    if (δ_t == 0) & (m_t == length(I))
        return X_t
    end

    # Get decidable customer locations
    D_t = findall(r_ti -> r_ti in 1:3, r_t)
    # Filter for customer locations that can be visited in the remaining time available
    filter!(d_t -> (dist(I, m_t, d_t) + dist(I, d_t, length(I))) <= (T - t - δ_t), D_t)
    @debug "Decidable customer locations" D_t

    # Feasible customer request decisions X_t
    for no_of_acceptations in 1:length(D_t)
        # Permutations of accepting (no_of_acceptations) customers and canceling (length(D_t) - no_of_acceptations) customers
        perms = unique(permutations(vcat(fill(1, no_of_acceptations), fill(0, length(D_t) - no_of_acceptations))))

        for perm in perms
            c_t = fill(0, length(r_t))
            # first and last location are start and end depot and therefore don't have to make a decision here (signalized by -1)
            c_t[1] = -1
            c_t[end] = -1
            j = 1
            for i in D_t
                c_t[i] = perm[j]
                j += 1
            end

            # Destination can only be changed if δ_t = 0
            if δ_t == 0
                # Every accepted customer request is a feasible new destination
                M_t = findall(c -> c == 1, c_t)
                # If there is no feasible new destination left the end depot is the next destination
                if isempty(M_t)
                    push!(X_t, Decision(c_t, length(c_t)))
                else
                    for m_t = findall(c -> c == 1, c_t)
                        push!(X_t, Decision(c_t, m_t))
                    end
                end
            else
                # No decision on new destination can be made ⟹ destination m_t remains
                push!(X_t, Decision(c_t, m_t))
            end
        end
    end
    @debug "Feasible decisions X_t:" X_t

    # If no decision is possible due to missing customer requests
    if length(X_t) == 0
        # Default customer request decision
        c_t = fill(0, length(r_t))
        # first and last location are start and end depot and therefore don't have to make a decision here (signalized by -1)
        c_t[1] = -1
        c_t[end] = -1

        # Add default decision if still driving
        if δ_t != 0
            @debug "[t = $(t), δ_t = $(δ_t), m_t = $(m_t)] Adding default decision"
            push!(X_t, Decision(c_t, m_t))
        # Add decision to drive to end depot if the time has come
        elseif dist(I, m_t, length(I)) == (T - t)
            @debug "[t = $(t), δ_t = $(δ_t), m_t = $(m_t)] Adding decision to drive to end depot"
            push!(X_t, Decision(c_t, length(I)))
        # Otherwise a preliminary end node has been reached
        else
            @debug("[t = $(t), δ_t = $(δ_t), m_t = $(m_t)] No decision can be made")
        end
    end

    return X_t
end

"""
Calculates the contribution of a decision.
"""
function contribution(r_t::Array{Int64}, x_t::Decision, t::Int64, δ_t::Int64, T::Int64, I::Array{Tuple{Float64,Float64}}, P_C::Float64, P_R::Float64)
    contribution = 0.0

    # Equation 4.8
    # Sum contributions of every customer request decision
    for i in 1:length(r_t) - 1
        # Destination is being visited --> +1
        if (r_t[i] in 1:3) & (x_t.m_t == i)
            contribution += 1
        # Request has been canceled --> -P_C
        elseif (r_t[i] in [1,2]) & (x_t.c_t[i] == 0)
            contribution -= P_C
        # Request has been reactivated --> -P_R
        elseif (r_t[i] == 3) & (x_t.c_t[i] == 1)
            contribution -= P_R
        # Unanswered Request has been finally canceled --> -P_C
        elseif (r_t[i] == 1) & (dist(I, x_t.m_t, i) + dist(I, i, length(I)) > T - t - δ_t)
            contribution -= P_C
        end
    end

    return contribution
end

"""
Calculates all possible outcomes of the random variable `W_t` that describes the exougenous influence.
"""
function exogenous(rx_t::Array{Int64})
    # Initialize
    W_t = Array{Int64,1}[]

    # Find customer locations that have not requested yet
    I_tinit = findall(rx_ti -> rx_ti == 0, rx_t)

    # Construct all possible outcomes of the random variable W_t
    for no_of_requests in 0:length(I_tinit)
        # Permutations of (no_of_requests) customers requesting and (length(I_tinit) - no_of_requests) customers not requesting
        perms = unique(permutations(vcat(fill(1, no_of_requests), fill(0, length(I_tinit) - no_of_requests))))

        for perm in perms
            w_t = fill(0, length(rx_t))
            # first and last location are start and end depot and therefore don't make requests (signalized by -1)
            w_t[1] = -1
            w_t[end] = -1
            j = 1
            for i in I_tinit
                w_t[i] = perm[j]
                j += 1
            end

            push!(W_t, w_t)
        end
    end

    @debug "Exogenous influence W_t:" W_t
    return W_t
end

"""
Calculates the probability of an outcome of the random variable `W_t`.
"""
function probability(rx_t::Array{Int64}, w_t::Array{Int64}, α::Float64)
    ω = 1

    for i_tinit in findall(rx_ti -> rx_ti == 0, rx_t)
        p = ifelse(w_t[i_tinit] == 1, α, (1 - α))
        ω *= p
    end

    return ω
end

"""
Calculates the (rounded) Euclidean distance between two geographical locations `i` and `j` given a set `I` of locations.
"""
dist(I::Array{Tuple{Float64,Float64}}, i::Int64, j::Int64) = ceil(sqrt((I[i][1] - I[j][1])^2 + (I[i][2] - I[j][2])^2))
