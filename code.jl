"""
Heuristic Search
"""

using DataStructures
using Random
import Plots
import JSON


N = 3

# puzzle_15 = UInt[11 3 1 7; 4 6 8 2; 15 9 10 13; 14 12 5 0]

function encode(a::Array{UInt, 2})::UInt
    s::UInt = 0
    for i = 1:N, j = 1:N
        p = N * (i - 1) + j
        s |= a[i, j] << 4(p - 1)
    end
    s
end

# encode(puzzle_15)

function getValue(s::UInt, i::Int, j::Int)::UInt
    p = N * (i - 1) + j
    (s >> 4(p - 1)) & 0xf
end

function decode(s::UInt)::Array{UInt, 2}
    [getValue(s, i, j) for i=1:N, j=1:N]
end

# decode(encode(puzzle_15)) == puzzle_15

function generate(s::UInt)::Vector{UInt}
    function findZero()
        for i=1:N, j = 1:N
            if getValue(s, i, j) == 0
                return i, j
            end
        end
    end
    x, y = findZero()
    ret = Vector{UInt}()
    for (δx, δy) in ((-1, 0), (1, 0), (0, -1), (0, 1))
        u, v = x + δx, y + δy
        if 1 <= u <= N && 1 <= v <= N
            val = getValue(s, u, v)
            ss = s
            p = N * (x - 1) + y
            #ss = ss & (0xffffffffffffffff ⊻ (0x000000000000000f << 4(p - 1)))
            ss = ss ⊻ (val << 4(p - 1))
            p = N * (u - 1) + v
            ss = ss & (0xffffffffffffffff ⊻ (0x000000000000000f << 4(p - 1)))
            #ss = ss ⊻ (0x0 << 4(p - 1))
            push!(ret, ss)
        end
    end
    ret
end

# generate(0xd5ce0a9f2864713b)

# over_puzzle_15 = UInt[1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 0]
# over_state_15 = encode(over_puzzle_15)

over_puzzle_8 = UInt[1 2 3; 4 5 6; 7 8 0]
over_state_8 = encode(over_puzzle_8)

isOver(s::UInt)::Bool = s == over_state_8

isOver(over_state_8)

function isConsistent(h::Function)::Bool
    if h == h1
        return false
    elseif h == h2
        return false
    elseif h == h3
        return true
    end
    return false
end

"""

"""
function A_star(puzzle::Array{UInt, 2}, h::Function)
    State = UInt
    Q = PriorityQueue{State, Int}()
    vis = Set{State}()
    dis = Dict{State, Int}()
    pre = Dict{State, State}()

    st = encode(puzzle)
    enqueue!(Q, st=>0)
    dis[st] = 0
    pre[st] = 0

    tot = 0
    while !isempty(Q)
        x = dequeue!(Q)
        d = dis[x]
        if isConsistent(h)
            push!(vis, x)
        end
        tot += 1
        # if tot % 1000000 == 0
        #     @show (tot, x, d)
        # end
        if isOver(x)
            println("Find the answer with ", d, " steps")
            println("Total visited: ", tot)
            return d, tot
        end
        for y in generate(x)
            if !(y == pre[x]) && !(y in vis)
                if haskey(Q, y)
                    if dis[y] > d + 1
                        pre[y] = x
                        dis[y] = d + 1
                        Q[y] = h(y) + d + 1
                    end
                else
                    pre[y] = x
                    dis[y] = d + 1
                    enqueue!(Q, y=>(h(y) + dis[y]))
                end
            end
        end
    end
    return nothing
end

"""

"""
function IDA_star(puzzle, h)
    function dfs(x, vis, dis, limit)
        push!(vis, x)
        tot += 1
        #@show (x, dis)
        if isOver(x)
            return true, dis
        end
        tmp = map(y->(h(y), y), generate(x))
        sort!(tmp)
        ret = (false, typemax(Int))
        for (hy, y) in tmp
            if !(y in vis)
                fy = hy + dis + 1
                if fy > limit
                    fy < ret[2] && (ret = (false, fy))
                else
                    flag, d = dfs(y, vis, dis + 1, limit)
                    if flag
                        return flag, d
                    else
                        d < ret[2] && (ret = (false, d))
                    end
                end
            end
        end
        pop!(vis, x)
        ret
    end
    tot = 0
    st = encode(puzzle)
    limit = 0
    while true
        ret = dfs(st, Set{UInt}(), 0, limit)
        if ret[1]
            println("Find the answer with ", ret[2], " steps")
            println("Total visited: ", tot)
            return ret[2], tot
        else
            println("Can't find answer with limit = ", limit)
            limit = ret[2]
        end
    end
end


# IDA_star(UInt[2 1 3; 6 7 4; 0 8 5], h1)
#
# A_star(UInt[2 1 3; 6 7 4; 0 8 5], h1)

function h1(s::UInt)::Int
    ret = 0
    for i = 1:N, j = 1:N
        val = getValue(s, i, j)
        if val == 0
            ret += abs(i - N) + abs(j - N)
        else
            x::Int, y::Int = div(val - 1, N) + 1, (val - 1) % N + 1
            ret += abs(i - x) + abs(j - y)
        end
    end
    ret
end

function h2(s::UInt)::Int
    ret = 0
    for i=1:N, j=1:N
        val = getValue(s, i, j)
        if val == 0
            ret += ceil(Int, sqrt((i - N)^2 + (j - N)^2))
        else
            x::Int, y::Int = div(val - 1, N) + 1, (val - 1) % N + 1
            ret += ceil(Int, sqrt((i - x)^2 + (j - y)^2))
        end
    end
    ret
end

function h3(s::UInt)::Int
    ret = 0
    for i=1:N, j=1:N
        val = getValue(s, i, j)
        if val == 0
            ret += max(abs(i - N), abs(j - N))
        else
            x::Int, y::Int = div(val - 1, N) + 1, (val - 1) % N + 1
            ret += max(abs(i - x), abs(j - y))
        end
    end
    ret
end

# h1(encode(over_puzzle_15))
# h1(over_state_8)

# @time IDA_star(UInt[1 2 3 4; 5 6 7 8; 9 10 15 11; 13 0 14 12], h1)
#
# @time IDA_star(puzzle_15, h1)
#
# puzzle = UInt64[0x0000000000000004 0x0000000000000006 0x0000000000000007;
#     0x0000000000000001 0x0000000000000000 0x0000000000000005;
#     0x0000000000000008 0x0000000000000003 0x0000000000000002]
#
# BFS(puzzle)
# IDA_star(puzzle, h1)
# A_star(puzzle, h1)


"""

"""
function BFS(puzzle)
    Q = Queue{Tuple{UInt, Int}}()
    vis = Set{UInt}()
    enqueue!(Q, (encode(puzzle), 0))
    push!(vis, encode(puzzle))
    tot = 0
    while !isempty(Q)
        x, dis = dequeue!(Q)
        tot += 1
        if isOver(x)
            println("Find the answer with ", dis, " steps")
            println("Total visited: ", tot)
            return dis, tot
        end
        for y in generate(x)
            if !(y in vis)
                enqueue!(Q, (y, dis + 1))
                push!(vis, y)
            end
        end
    end
    return nothing
end

"""

"""
data = let
    data = []
    num = 1
    while true
        puzzle = shuffle(UInt[1 2 3; 4 5 6; 7 8 0])
        b = BFS(puzzle)
        if b == nothing
            continue
        end
        push!(data, puzzle)
        num += 1
        @show num
        if num > 100
            break
        end
    end
    data
end

open("data.json", "w") do f
    s = JSON.json(data)
    print(f, s)
end

data = open("data.json", "r") do f
    s = readline(f)
    d = JSON.parse(s, inttype = UInt)
    map(t -> [t[1] t[2] t[3]], d)
end

"""

"""
Y = let
    global data
    Y = map(data) do puzzle
        b = BFS(puzzle)
        a, c = A_star(puzzle, h1), IDA_star(puzzle, h1)
        if a[1] != b[1] || c[1] != b[1]
            @show puzzle
        end
        b[2], a[2], c[2]
    end
    Y
end

open("result.json", "w") do f
    s = JSON.json(Y)
    print(f, s)
end

let
    y1 = [Y[i][1] for i=1:100]
    y2 = [Y[i][2] for i=1:100]
    y3 = [Y[i][3] for i=1:100]
    fig = Plots.plot(1:100, [y1, y2, y3], label=["BFS", "A*", "IDA*"])
    Plots.xlabel!("Sample")
    Plots.ylabel!("total")
    Plots.title!("Different Algorithms with h1")
    Plots.savefig(fig, "result.png")
    fig
end


Y2 = let
    global data
    map(data) do puzzle
        a, b, c = A_star(puzzle, h1), A_star(puzzle, h2), A_star(puzzle, h3)
        if a[1] != b[1] || c[1] != b[1] || a[1] != c[1]
            @show puzzle
        end
        a[2], b[2], c[2]
    end
end

let
    y1 = [Y2[i][1] for i=1:100]
    y2 = [Y2[i][2] for i=1:100]
    y3 = [Y2[i][3] for i=1:100]
    fig = Plots.plot(1:100, [y1, y2, y3], label=["h1", "h2", "h3"])
    Plots.xlabel!("Sample")
    Plots.ylabel!("total")
    Plots.title!("A* with h1, h2 and h3")
    Plots.savefig(fig, "A_star.png")
    fig
end

Y3 = let
    global data
    map(data) do puzzle
        a, b, c = IDA_star(puzzle, h1), IDA_star(puzzle, h2), IDA_star(puzzle, h3)
        if a[1] != b[1] || a[1] != c[1]
            @show puzzle
        end
        a[2], b[2], c[2]
    end
end

let
    y1 = [Y3[i][1] for i=1:100]
    y2 = [Y3[i][2] for i=1:100]
    y3 = [Y3[i][3] for i=1:100]
    fig = Plots.plot(1:100, [y1, y2, y3], label=["h1", "h2", "h3"])
    Plots.xlabel!("Sample")
    Plots.ylabel!("total")
    Plots.title!("IDA* with h1, h2 and h3")
    Plots.savefig(fig, "IDA_star.png")
    fig
end
