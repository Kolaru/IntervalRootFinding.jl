using IntervalArithmetic
using IntervalRootFinding

##
# Available strategies
##

f(x) = sin(x)
contractor = Newton(f, cos)

# A search takes a starting region, a contractor and a tolerance as argument
search = BreadthFirstSearch(-10..10, contractor, 1e-10)

# This is needed to avoid the data being discarded at the end of the loop use
# `local tree` instead inside a function (may work only in 0.7)
global endtree
for (k, tree) in enumerate(search)
    println("Tree at iteration $k")
    println(tree)  # The tree has custom printing
    global endtree = tree
end

rts = data(endtree)  # Use `data` to only get the leafs marked as `:final`
println("Final $(length(rts)) roots: $rts")

# The second available type of root search is depth first
search = DepthFirstSearch(-10..10, contractor, 1e-10)
for tree in search
    global endtree = tree
end  # Go to the end of the iteration

# Since the index of each node is printed and indices are attributed in the
# order nodes are processed, comparing this tree with the preceding show the
# difference between breadth first and depth first searches.
println(endtree)


##
# Custom strategy
##

# Define custom BBSearch that store empty intervals rather than discarding it
# Functions of the interface must be explicitely imported (?)
import IntervalRootFinding

struct MySearch{R <: Region, C <: Contractor, T <: Real} <: BreadthFirstBBSearch{Root{R}}
    initial::Root{R}
    contractor::C
    tol::T
end

# This must be implemented, other functions needed are already implemented for
# Root (bisect function) or the general fallback match this case (root_element function)
function IntervalRootFinding.process(search::MySearch, r::Root)
    contracted_root = search.contractor(r, search.tol)
    status = root_status(contracted_root)

    # We only store the unrefined intervals so the final intervals cover all
    # the initial region
    unrefined_root = Root(r.interval, status)
    status == :unique && return :store, unrefined_root
    status == :empty && return :store, unrefined_root # Store largest known empty intervals
    status == :unkown && diam(contracted_root) < search.tol && return :store, unrefined_root
    return :bisect, unrefined_root  # Always bisect the original interval to bypass [NaN, NaN]
end

search = MySearch(Root(-10..10, :unkown), contractor, 1e-10)
for tree in search
    global endtree = tree
end  # Go to the end of the iteration
println(endtree)
