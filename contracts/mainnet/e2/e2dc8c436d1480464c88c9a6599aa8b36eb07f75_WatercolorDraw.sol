// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "ProcessingV1.sol";
import "WatercolorLayer.sol";

library WatercolorDraw {
    uint16 public constant MAX_POLYGONS = 40960;
    
    struct Draw {
        uint32[16384] result;
        WatercolorLayer.WatercolorParameters p;
        WatercolorLayer.StackList stackList;
        TypesV1.Chunk2D chunk;
    }

    function draw(Draw memory f)
        external
        pure
        returns (uint32[16384] memory buffer)
    {
        for (uint8 s = 0; s < f.p.stackCount; s++) {
            
            TypesV1.Point2D[MAX_POLYGONS] memory stack;
            uint32 vertexCount;

            if (s == 0) {
                stack = f.stackList.stack1;
                vertexCount = f.stackList.stack1Count;
            } else if (s == 1) {
                stack = f.stackList.stack2;
                vertexCount = f.stackList.stack2Count;
            } else if (s == 2) {
                stack = f.stackList.stack3;
                vertexCount = f.stackList.stack3Count;
            } else if (s == 3) {
                stack = f.stackList.stack4;
                vertexCount = f.stackList.stack4Count;
            }

            uint32 fillColor = f.p.stackColors[s];

            require(vertexCount == MAX_POLYGONS, "invalid vertex count");
            
            ProcessingV1.polygon(
                    f.result,
                    GeometryV1.Polygon2D(
                        stack,
                        vertexCount,
                        fillColor,
                        fillColor,                            
                        f.chunk
                    )
                );
        }

        return f.result;
    }
}