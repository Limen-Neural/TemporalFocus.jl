# SPDX-License-Identifier: MIT OR Apache-2.0

using TemporalFocus
using Test

@testset "TemporalFocus" begin
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
        @testset "Basic pruning" begin
            buffer = TemporalBuffer(0.25f0, [
                SpikeEvent(1, 0.10f0, 1.0f0),
                SpikeEvent(2, 0.55f0, 1.0f0),
                SpikeEvent(3, 0.80f0, 1.0f0),
            ])

            prune!(buffer, 0.80f0)

            @test length(buffer.events) == 2
            @test [event.neuron_id for event in buffer.events] == [2, 3]
        end

        @testset "Prune empty buffer" begin
            buffer = TemporalBuffer(0.25f0, SpikeEvent[])
            prune!(buffer, 1.0f0)
            @test isempty(buffer.events)
        end

        @testset "Prune removes all events" begin
            buffer = TemporalBuffer(0.10f0, [
                SpikeEvent(1, 0.10f0, 1.0f0),
                SpikeEvent(2, 0.20f0, 1.0f0),
            ])
            prune!(buffer, 10.0f0)
            @test isempty(buffer.events)
        end

        @testset "Prune keeps all events" begin
            events = [SpikeEvent(1, 0.90f0, 1.0f0), SpikeEvent(2, 0.95f0, 1.0f0)]
            buffer = TemporalBuffer(1.0f0, events)
            prune!(buffer, 1.0f0)
            @test length(buffer.events) == 2
        end
    end

    @testset "SpikeEvent constructor" begin
        @test SpikeEvent(1, 0.5).t isa Float32
        @test SpikeEvent(1, 0.5).value == 1.0f0
        @test SpikeEvent(1, 0.5, 2.0).value == 2.0f0
    end

    @testset "SpikeTrain constructor" begin
        @test isempty(SpikeTrain().events)
        @test SpikeTrain([SpikeEvent(1, 0.5f0)]).events[1].neuron_id == 1
    end

    @testset "TemporalBuffer constructor" begin
        buf = TemporalBuffer(1.0f0)
        @test buf.window == 1.0f0
        @test isempty(buf.events)
    end

    @testset "Discrete edge cases" begin
        @testset "Empty spike trains" begin
            q = SpikeTrain()
            k = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            out = spike_attention_discrete(q, k, v)
            @test out == Float32[0, 0]
        end

        @testset "Single neuron multiple coincidences" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.2f0, 1.0f0), SpikeEvent(1, 0.3f0, 1.0f0)])
            v = Float32[1; 2;;]
            out = spike_attention_discrete(q, k, v)
            @test out == Float32[2]
        end

        @testset "Non-unit spike values" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 2.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.2f0, 3.0f0)])
            v = Float32[1; 2;;]
            out = spike_attention_discrete(q, k, v)
            @test out == Float32[6]
        end

        @testset "Out of range source neuron ID throws" begin
            q = SpikeTrain([SpikeEvent(5, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.2f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            @test_throws ArgumentError spike_attention_discrete(q, k, v)
        end

        @testset "Out of range context neuron ID is ignored" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(5, 0.2f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            out = spike_attention_discrete(q, k, v)
            @test out == Float32[0, 0]
        end

        @testset "Larger readout matrix works" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.2f0, 1.0f0)])
            v = Float32[1 0 0; 0 1 0; 0 0 1]
            # readout has 3 rows but only 1 neuron → should work
            out = spike_attention_discrete(q, k, v)
            @test length(out) == 3
        end

        @testset "Dimension mismatch throws" begin
            @test_throws DimensionMismatch TemporalFocus._apply_readout(Float32[1, 2], Float32[1 0 0; 0 1 0; 0 0 1])
        end

        @testset "No coincidences" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(2, 0.2f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            out = spike_attention_discrete(q, k, v)
            @test out == Float32[0, 0]
        end
    end

    @testset "Temporal edge cases" begin
        @testset "tau zero throws" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.2f0, 1.0f0)])
            v = Float32[1; 2;;]
            @test_throws ArgumentError spike_attention_temporal(q, k, v; τ = 0.0f0)
        end

        @testset "tau zero throws even without coincidences" begin
            # τ is validated eagerly before the loop
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(2, 0.2f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            @test_throws ArgumentError spike_attention_temporal(q, k, v; τ = 0.0f0)
        end

        @testset "Negative tau throws" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.2f0, 1.0f0)])
            v = Float32[1; 2;;]
            @test_throws ArgumentError spike_attention_temporal(q, k, v; τ = -1.0f0)
        end

        @testset "Small tau decays faster" begin
            q = SpikeTrain([SpikeEvent(1, 0.10f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(1, 0.30f0, 1.0f0)])
            v = Float32[1; 2;;]
            out_small = spike_attention_temporal(q, k, v; τ = 0.05f0)
            out_large = spike_attention_temporal(q, k, v; τ = 1.0f0)
            @test abs(out_small[1]) < abs(out_large[1])
        end

        @testset "Empty context returns zero" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain()
            v = Float32[1; 2;;]
            out = spike_attention_temporal(q, k, v; τ = 1.0f0)
            @test out == Float32[0]
        end

        @testset "No coincidences returns zero" begin
            q = SpikeTrain([SpikeEvent(1, 0.1f0, 1.0f0)])
            k = SpikeTrain([SpikeEvent(2, 0.2f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            out = spike_attention_temporal(q, k, v; τ = 1.0f0)
            @test out == Float32[0, 0]
        end
    end

    @testset "Continuous edge cases" begin
        @testset "Empty buffers" begin
            bq = TemporalBuffer(0.3f0, SpikeEvent[])
            bk = TemporalBuffer(0.3f0, [SpikeEvent(1, 0.5f0, 1.0f0)])
            v = Float32[1; 2;;]
            out = spike_attention_continuous(bq, bk, v; τ = 0.15f0)
            @test out == Float32[0]
        end

        @testset "Events outside window" begin
            bq = TemporalBuffer(0.1f0, [SpikeEvent(1, 0.5f0, 1.0f0)])
            bk = TemporalBuffer(0.1f0, [SpikeEvent(1, 10.0f0, 1.0f0)])
            v = Float32[1; 2;;]
            out = spike_attention_continuous(bq, bk, v; τ = 0.15f0)
            @test out == Float32[0]
        end

        @testset "Different window sizes" begin
            bq = TemporalBuffer(0.5f0, [SpikeEvent(1, 0.5f0, 1.0f0)])
            bk = TemporalBuffer(0.1f0, [SpikeEvent(1, 0.55f0, 1.0f0)])
            v = Float32[1; 2;;]
            out = spike_attention_continuous(bq, bk, v; τ = 0.15f0)
            @test out[1] > 0
        end

        @testset "tau zero throws" begin
            bq = TemporalBuffer(0.3f0, [SpikeEvent(1, 0.5f0, 1.0f0)])
            bk = TemporalBuffer(0.3f0, [SpikeEvent(1, 0.5f0, 1.0f0)])
            v = Float32[1; 2;;]
            @test_throws ArgumentError spike_attention_continuous(bq, bk, v; τ = 0.0f0)
        end

        @testset "tau zero throws even without coincidences" begin
            # Different neuron_ids → no coincidences, but τ is still validated eagerly
            bq = TemporalBuffer(0.001f0, [SpikeEvent(1, 0.5f0, 1.0f0)])
            bk = TemporalBuffer(0.001f0, [SpikeEvent(2, 0.5f0, 1.0f0)])
            v = Float32[1 0; 0 1]
            @test_throws ArgumentError spike_attention_continuous(bq, bk, v; τ = 0.0f0)
        end
    end

    @testset "Normalization edge cases" begin
        @testset "All zeros" begin
            l1 = Float32[0, 0, 0]
            @test normalize_l1!(l1) == Float32[0, 0, 0]

            maxn = Float32[0, 0, 0]
            @test normalize_max!(maxn) == Float32[0, 0, 0]
        end

        @testset "Single element" begin
            l1 = Float32[5]
            @test normalize_l1!(l1) == Float32[1]

            maxn = Float32[5]
            @test normalize_max!(maxn) == Float32[1]
        end

        @testset "Already normalized" begin
            l1 = Float32[0.5, 0.5]
            @test normalize_l1!(l1) ≈ Float32[0.5, 0.5]

            maxn = Float32[0.5, 1.0]
            @test normalize_max!(maxn) ≈ Float32[0.5, 1.0]
        end

        @testset "Negative weights" begin
            # sum is 0, normalize_l1! returns unchanged
            l1 = Float32[-2, 3, -1]
            result = normalize_l1!(l1)
            @test result == Float32[-2, 3, -1]

            # sum is positive, normalizes
            l2 = Float32[-1, 3, 2]
            normalize_l1!(l2)
            @test sum(l2) ≈ 1.0f0
        end

        @testset "Idempotency" begin
            l1 = Float32[2, 2, 4]
            normalize_l1!(l1)
            l1_copy = copy(l1)
            normalize_l1!(l1)
            @test l1 ≈ l1_copy

            maxn = Float32[2, 6, 3]
            normalize_max!(maxn)
            maxn_copy = copy(maxn)
            normalize_max!(maxn)
            @test maxn ≈ maxn_copy
        end
    end

    @testset "Temporal weight" begin
        @testset "Symmetry" begin
            τ = 0.5f0
            @test temporal_weight(0.3f0, τ) ≈ temporal_weight(-0.3f0, τ)
        end

        @testset "Zero dt" begin
            @test temporal_weight(0.0f0, 1.0f0) ≈ 1.0f0
        end

        @testset "Large dt decays" begin
            @test temporal_weight(10.0f0, 1.0f0) < 0.001f0
        end

        @testset "Monotonic decay" begin
            τ = 1.0f0
            @test temporal_weight(0.1f0, τ) > temporal_weight(0.5f0, τ) > temporal_weight(1.0f0, τ)
        end
    end

end
