// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "KintsugiLayer.sol";
import "ParticleSetV1.sol";
import "GraphicsV1.sol";
import "ProcessingV1.sol";
import "GeometryV1.sol";

library KintsugiDraw {

    struct Draw {
        uint32[16384] result;
        KintsugiLayer.KintsugiParameters p;
        int64[4096] noiseTable;
        TypesV1.Chunk2D chunk;
    }

    uint16 internal constant NOISE_TABLE_SIZE = 4095;
    uint16 internal constant PARTICLE_COUNT = 5000;
    uint16 internal constant FRAME_COUNT = 400;
    
    function draw(Draw memory f) external pure returns(uint32[16384] memory buffer) {
        f.p.iteration = 0;
        f.p.frame = 0;

        while (f.p.frame < FRAME_COUNT) {
            f.p.frame++;

            if (f.p.iteration >= f.p.layers) {
                break;
            }

            bool dead = true;
            {
                for (uint256 i = 0; i < f.p.layers; i++) {
                    ParticleSetV1.ParticleSet2D memory particleSet = f.p.particleSets[i];
                    update(
                        f.noiseTable,
                        particleSet,
                        PARTICLE_COUNT,
                        f.chunk.width,
                        f.chunk.height
                    );
                    if (!particleSet.dead) {
                        dead = false;
                    }
                    draw(particleSet, PARTICLE_COUNT, f.result, f.chunk);
                }
            }

            if (dead) {
                f.p.iteration++;
            }
        }

        return f.result;
    }

    function update(
        int64[NOISE_TABLE_SIZE + 1] memory noiseTable,
        ParticleSetV1.ParticleSet2D memory set,
        uint16 particleCount,
        uint256 width,
        uint256 height
    ) internal pure {
        set.dead = true;
        for (uint16 i = 0; i < particleCount; i++) {
            ParticleV1.Particle2D memory p = set.particles[i];
            if (p.dead) {
                continue;
            }
            set.dead = false;
            ParticleV1.update(noiseTable, p, width, height);
        }
    }

    function draw(
        ParticleSetV1.ParticleSet2D memory set,
        uint16 particleCount,
        uint32[16384] memory result,
        TypesV1.Chunk2D memory chunk
    ) internal pure {
        if (set.dead) {
            return;
        }

        for (uint256 i = 0; i < particleCount; i++) {
            ParticleV1.Particle2D memory p = set.particles[i];
            if (p.dead) {
                continue;
            }
            step(p, result, chunk);
        }
    }

    function step(
        ParticleV1.Particle2D memory p,
        uint32[16384] memory result,
        TypesV1.Chunk2D memory chunk
    ) internal pure {
        if (p.frames < 40) {
            return;
        }

        uint32 dark = GraphicsV1.setOpacity(0xFFF4BB29, 10);

        TypesV1.Point2D memory v0 = TypesV1.Point2D(int32(p.x), int32(p.y));
        TypesV1.Point2D memory v1 = TypesV1.Point2D(int32(p.px), int32(p.py));

        ProcessingV1.line(
            result,
            GeometryV1.Line2D(
                TypesV1.Point2D(v0.x, v0.y - 2),
                TypesV1.Point2D(v1.x, v1.y - 2),
                dark,
                chunk
            )
        );
        ProcessingV1.line(
            result,
            GeometryV1.Line2D(
                TypesV1.Point2D(v0.x, v0.y + 2),
                TypesV1.Point2D(v1.x, v1.y + 2),
                dark,
                chunk
            )
        );

        uint32 bright = GraphicsV1.setOpacity(0xFFD5B983, 10);

        ProcessingV1.line(
            result,
            GeometryV1.Line2D(
                TypesV1.Point2D(v0.x, v0.y - 1),
                TypesV1.Point2D(v1.x, v1.y - 1),
                bright,
                chunk
            )
        );
        ProcessingV1.line(
            result,
            GeometryV1.Line2D(
                TypesV1.Point2D(v0.x, v0.y),
                TypesV1.Point2D(v1.x, v1.y),
                bright,
                chunk
            )
        );
        ProcessingV1.line(
            result,
            GeometryV1.Line2D(
                TypesV1.Point2D(v0.x, v0.y + 1),
                TypesV1.Point2D(v1.x, v1.y + 1),
                bright,
                chunk
            )
        );
    }
}