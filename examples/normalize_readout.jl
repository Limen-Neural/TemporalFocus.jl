# SPDX-License-Identifier: MIT OR Apache-2.0
# Run: julia --project=. examples/normalize_readout.jl

using TemporalFocus

# Spike-derived attention weights before normalization.
weights_l1 = Float32[2, 2, 4]
weights_max = Float32[2, 6, 3]

println("Raw L1 weights:  ", weights_l1)
normalize_l1!(weights_l1)
println("After normalize_l1!: ", weights_l1, "  (sum = ", sum(weights_l1), ")")

println("Raw max weights: ", weights_max)
normalize_max!(weights_max)
println("After normalize_max!: ", weights_max, "  (max = ", maximum(weights_max), ")")

# Zero vectors are left unchanged (no division by zero).
zeros_vec = Float32[0, 0, 0]
normalize_l1!(zeros_vec)
normalize_max!(zeros_vec)
println("Zero vector after both norms: ", zeros_vec)
