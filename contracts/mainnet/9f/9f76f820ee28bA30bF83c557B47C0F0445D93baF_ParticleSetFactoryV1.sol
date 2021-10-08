// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "ParticleSetV1.sol";
import "ParticleV1.sol";
import "RandomV1.sol";

/*
    A noise-based particle simulator, built for generative art that uses flow fields.

    Based on techniques in Sighack's "Getting Creative with Perlin Noise Fields":
    See: https://github.com/sighack/perlin-noise-fields
    See: https://github.com/sighack/perlin-noise-fields/blob/master/LICENSE

    THIRD PARTY NOTICES:
    ====================

    MIT License

    Copyright (c) 2018 Manohar Vanga

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

library ParticleSetFactoryV1 {
    uint16 internal constant PARTICLE_TABLE_SIZE = 5000;

    struct CreateParticleSet2D {
        int32 seed;
        uint32 range;
        uint16 width;
        uint16 height;
        uint16 n;
        int64 forceScale;
        int64 noiseScale;
        uint8 lifetime;
    }

    function createSet(CreateParticleSet2D memory f, RandomV1.PRNG memory prng)
        external
        pure
        returns (ParticleSetV1.ParticleSet2D memory set, RandomV1.PRNG memory)
    {
        ParticleV1.Particle2D[PARTICLE_TABLE_SIZE] memory particles;

        for (uint16 i = 0; i < f.n; i++) {  

            int256 px = RandomV1.next(
                prng,
                -int32(f.range),
                int16(f.width) + int32(f.range)
            );

            int256 py = RandomV1.next(
                prng,
                -int32(f.range),
                int16(f.height) + int32(f.range)
            );

            ParticleV1.Particle2D memory particle = ParticleV1.Particle2D(
                int64(px),
                int64(py),
                0,
                0,
                int64(px),
                int64(py),
                0,
                false,
                TypesV1.Point2D(0, 0),
                f.lifetime,
                f.forceScale,
                f.noiseScale
            );
            particles[i] = particle;
        }

        set.particles = particles;
        return (set, prng);
    }
}