using SpikeAttention
using Test

@testset "SpikeAttention" begin
    @testset "Discrete Attention" begin
        q = SpikeTrain([
            SpikeEvent(1, 0.10f0, 1.0f0),
            SpikeEvent(2, 0.20f0, 1.0f0),
        ])
        k = SpikeTrain([
            SpikeEvent(1, 0.15f0, 1.0f0),
            SpikeEvent(1, 0.25f0, 1.0f0),
            SpikeEvent(3, 0.30f0, 1.0f0),
        ])
        v = Float32[
            1 0
            0 1
            1 1
        ]

        out = spike_attention_discrete(q, k, v)

        @test out == Float32[2, 0]
    end

    @testset "Temporal Attention" begin
        q = SpikeTrain([SpikeEvent(1, 0.10f0, 1.0f0)])
        k = SpikeTrain([SpikeEvent(1, 0.30f0, 1.0f0)])
        v = Float32[
            2 1
            0 3
        ]

        out = spike_attention_temporal(q, k, v; τ = 0.20f0)
        expected_weight = exp(-1.0f0)

        @test out ≈ expected_weight .* Float32[2, 1] atol = 1.0f-6
    end

    @testset "Continuous Attention" begin
        buffer_q = TemporalBuffer(0.30f0, [SpikeEvent(1, 0.50f0, 1.0f0)])
        buffer_k = TemporalBuffer(0.30f0, [
            SpikeEvent(1, 0.35f0, 1.0f0),
            SpikeEvent(1, 0.90f0, 1.0f0),
        ])
        v = Float32[
            1 2
            3 4
        ]

        out = spike_attention_continuous(buffer_q, buffer_k, v; τ = 0.15f0)

        @test out ≈ exp(-1.0f0) .* Float32[1, 2] atol = 1.0f-6
    end

    @testset "Normalization" begin
        l1 = Float32[2, 2, 4]
        maxn = Float32[2, 6, 3]

        @test normalize_l1!(l1) == Float32[0.25, 0.25, 0.5]
        @test normalize_max!(maxn) == Float32[1 / 3, 1, 0.5]
    end

    @testset "Buffer Pruning" begin
        buffer = TemporalBuffer(0.25f0, [
            SpikeEvent(1, 0.10f0, 1.0f0),
            SpikeEvent(2, 0.55f0, 1.0f0),
            SpikeEvent(3, 0.80f0, 1.0f0),
        ])

        prune!(buffer, 0.80f0)

        @test length(buffer.events) == 2
        @test [event.neuron_id for event in buffer.events] == [2, 3]
    end

    @testset "STDP Update" begin
        weights = zeros(Float32, 2, 2)
        pre = SpikeTrain([SpikeEvent(1, 0.10f0, 1.0f0)])
        post = SpikeTrain([SpikeEvent(2, 0.20f0, 0.5f0)])

        stdp_update!(weights, pre, post; τ = 0.10f0, η = 0.2f0)

        @test weights[1, 2] ≈ 0.2f0 * 0.5f0 * exp(-1.0f0) atol = 1.0f-6
        @test sum(weights) ≈ weights[1, 2] atol = 1.0f-6
    end
end
