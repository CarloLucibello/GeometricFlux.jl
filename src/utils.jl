## Inverse operation of scatter

function gather(input::AbstractArray{T,N}, index::AbstractArray{<:Integer,N}, dims::Integer;
                out::AbstractArray{T,N}=similar(index, T)) where {T,N}
    @assert dims <= N "Specified dimensions must lower or equal to the rank of input matrix."

    @inbounds for x = CartesianIndices(out)
        tup = collect(Tuple(x))
        tup[dims] = index[x]
        out[x] = input[tup...]
    end
    return out
end

function gather(input::Matrix{T}, index::Array{Int}) where T
    out = Array{T}(undef, size(input,1), size(index)...)
    @inbounds for ind = CartesianIndices(index)
        out[:, ind] = input[:, index[ind]]
    end
    return out
end

gather(input::Fill{T,2,<:Any}, index::Array{Int}) where T = gather(Matrix(input), index)

function gather_indices(X::Array{T}) where T
    Y = DefaultDict{T,Vector{CartesianIndex}}(CartesianIndex[])
    @inbounds for (ind, val) = pairs(X)
        push!(Y[val], ind)
    end
    Y
end

"""
    save_div(x, y)

Savely divde `x` by `y`. If `y` is zero, return `x` directly.
"""
save_div(x, y) = ifelse(iszero(y), x, x/y)



## Indexing

function range_indecies(idx::Tuple)
    x = Vector{Any}(undef, length(idx))
    for (i,n) in enumerate(idx)
        x[i] = 1:n
    end
    x
end

replace_last_index!(idx::Vector, x) = (idx[end] = x; idx)

function assign!(A::AbstractArray, B::AbstractArray{T,N}; last_dim=1:size(B,N)) where {T,N}
    A_dims, B_dims = size(A), size(B)
    @assert A_dims[1:end-1] == B_dims[1:end-1] "Inconsistent dimensions with $(A_dims[1:end-1]) and $(B_dims[1:end-1])"
    A_dims = replace_last_index!(range_indecies(A_dims), last_dim)
    B_dims = range_indecies(B_dims)
    A_idxs = CartesianIndices(Tuple(A_dims))
    B_idxs = CartesianIndices(Tuple(B_dims))
    for (Aidx, Bidx) = zip(A_idxs, B_idxs)
        A[Aidx] = B[Bidx]
    end
    A
end



## Top-k pooling

function topk_index(y::AbstractVector, k::Integer)
    v = nlargest(k, y)
    return collect(1:length(y))[y .>= v[end]]
end

topk_index(y::Adjoint, k::Integer) = topk_index(y', k)



## Get feature with defaults

get_feature(::Nothing, i::Integer) = zeros(0)
get_feature(A::AbstractMatrix, i::Integer) = (i ≤ size(A,2)) ? view(A, :, i) : zeros(0)
