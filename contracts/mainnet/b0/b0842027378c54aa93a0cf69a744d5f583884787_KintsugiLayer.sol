// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "ParticleSetV1.sol";
import "ParticleSetFactoryV1.sol";
import "RandomV1.sol";
import "LCG64.sol";

library KintsugiLayer {

    uint16 public constant PARTICLE_COUNT = 5000;
    uint8 public constant PARTICLE_RANGE = 65;
    uint8 public constant PARTICLE_LIFETIME = 100;
    int64 public constant PARTICLE_FORCE_SCALE = 15 * 4294967296; /* 15 * Fix64V1.ONE */
    int64 public constant PARTICLE_NOISE_SCALE = 42949673; /* 0.01 */

    struct KintsugiParameters {
        uint8 layers;        
        uint256 frame;
        uint256 iteration;
        ParticleSetV1.ParticleSet2D[4] particleSets;
    }

    function getParameters(RandomV1.PRNG memory prng, int32 seed) 
    external pure returns (KintsugiParameters memory kintsugi, RandomV1.PRNG memory) {
        kintsugi.layers = uint8(uint32(RandomV1.next(prng, 1, 5)));

        for (uint256 i = 0; i < kintsugi.layers; i++) {
            (ParticleSetV1.ParticleSet2D memory particleSet, RandomV1.PRNG memory p) = ParticleSetFactoryV1.createSet(
                ParticleSetFactoryV1.CreateParticleSet2D(
                    seed,
                    PARTICLE_RANGE,
                    1024,
                    1024,
                    PARTICLE_COUNT,                    
                    PARTICLE_FORCE_SCALE,
                    PARTICLE_NOISE_SCALE,
                    PARTICLE_LIFETIME                                        
                ),
                prng
            );
            prng = p;                
            kintsugi.particleSets[i] = particleSet;            
        }

        return (kintsugi, prng);
    }
}