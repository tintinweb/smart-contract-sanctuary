// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "TypesV1.sol";
import "GraphicsV1.sol";
import "ProcessingV1.sol";
import "HatchLayer.sol";

library HatchDraw {

    struct Draw {
        uint32[16384] result;
        HatchLayer.HatchParameters parameters;
        TypesV1.Chunk2D chunk;
    }

    function draw(Draw memory f) external pure returns (uint32[16384] memory buffer) {
        uint32 color = GraphicsV1.setOpacity(
            f.parameters.color,
            f.parameters.opacity
        );

        for (int32 i = f.parameters.spacing; i < 1024; i += f.parameters.spacing) {
            ProcessingV1.line(
                f.result,
                GeometryV1.Line2D(
                    TypesV1.Point2D(i, 0),
                    TypesV1.Point2D(0, i),
                    color,
                    f.chunk
                )
            );
            ProcessingV1.line(
                f.result,
                GeometryV1.Line2D(
                    TypesV1.Point2D(1024 - i - 3, 1024),
                    TypesV1.Point2D(1024, 1024 - i - 3),
                    color,
                    f.chunk
                )
            );
            ProcessingV1.line(
                f.result,
                GeometryV1.Line2D(
                    TypesV1.Point2D(i, 1024),
                    TypesV1.Point2D(0, 1024 - i),
                    color,
                    f.chunk
                )
            );
            ProcessingV1.line(
                f.result,
                GeometryV1.Line2D(
                    TypesV1.Point2D(i - 4, 0),
                    TypesV1.Point2D(1024, 1024 - i + 4),
                    color,
                    f.chunk
                )
            );
        }

        ProcessingV1.line(
            f.result,
            GeometryV1.Line2D(
                TypesV1.Point2D(1024 - 4, 1024),
                TypesV1.Point2D(1024, 1024 - 4),
                color,
                f.chunk
            )
        );
        ProcessingV1.line(
            f.result,
            GeometryV1.Line2D(
                TypesV1.Point2D(1024 - 3, 0),
                TypesV1.Point2D(1024, 3),
                color,
                f.chunk
            )
        );

        return f.result;
    }
}