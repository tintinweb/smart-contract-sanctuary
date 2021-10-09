// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "TypesV1.sol";
import "RandomV1.sol";
import "Trig256.sol";
import "GraphicsV1.sol";

library WatercolorLayer {
    uint16 public constant MAX_POLYGONS = 40960;
    uint8 public constant NUM_SIDES = 10;

    struct WatercolorParameters {
        uint8 stackCount;        
        uint32[4] stackColors;        
        int64[4] r;
        uint32[16] palette;       
        TypesV1.Point2D[MAX_POLYGONS][4] basePoly;
        uint32[4] basePolyCount;
        RandomV1.PRNG prng;      
    }    

    struct StackList {
        TypesV1.Point2D[MAX_POLYGONS] stack1;
        TypesV1.Point2D[MAX_POLYGONS] stack2;
        TypesV1.Point2D[MAX_POLYGONS] stack3;
        TypesV1.Point2D[MAX_POLYGONS] stack4;        
        uint32 stack1Count;
        uint32 stack2Count;
        uint32 stack3Count;
        uint32 stack4Count;
        RandomV1.PRNG prng;
    }

    struct CreateBasePoly {
        int64 x;
        int64 y;
        int64 r;
    }

    struct CreatePolyStack {
        int64 r;
        TypesV1.Point2D[MAX_POLYGONS] basePoly;
        uint32 basePolyCount;
    }

    struct Subdivide {
        int32 depth;
        int64 variance;
        int64 vdiv;
        TypesV1.Point2D[MAX_POLYGONS] points;
        uint32 pointCount;
        int64 x1;
        int64 y1;
        int64 x2;
        int64 y2;
    }

    struct RPoly {
        uint32 count;
        TypesV1.Point2D[MAX_POLYGONS] points;
    }

    function getParameters(RandomV1.PRNG memory prng)
        external
        pure
        returns (WatercolorParameters memory watercolors)
    {
        uint8 stackCount = uint8(uint32(RandomV1.next(prng, 2, 5)));
        watercolors.stackCount = stackCount;

        watercolors.palette[0] = 0xFF0088DC;
        watercolors.palette[1] = 0xFFB31942;
        watercolors.palette[2] = 0xFFEB618F;
        watercolors.palette[3] = 0xFF6A0F8E;
        watercolors.palette[4] = 0xFF4FBF26;
        watercolors.palette[5] = 0xFF6F4E37;
        watercolors.palette[6] = 0xFFFF9966;
        watercolors.palette[7] = 0xFFBED9DB;
        watercolors.palette[8] = 0xFF998E80;
        watercolors.palette[9] = 0xFFFFB884;
        watercolors.palette[10] = 0xFF2E4347;
        watercolors.palette[11] = 0xFF0A837F;
        watercolors.palette[12] = 0xFF076461;
        watercolors.palette[13] = 0xFF394240;
        watercolors.palette[14] = 0xFFFAF4B1;   
        watercolors.palette[15] = 0xFFFFFFFF;   

        for (uint8 i = 0; i < watercolors.stackCount; i++) {
            RandomV1.next(prng);
            RandomV1.next(prng);

            int32 stackColorIndex = RandomV1.next(prng, 16);
            uint32 stackColor = watercolors.palette[uint32(stackColorIndex)];
            stackColor = GraphicsV1.setOpacity(stackColor, 4);
            watercolors.stackColors[i] = stackColor;

            int64 x = RandomV1.next(prng, 0, 1024 /* width */) * Fix64V1.ONE;
            int64 y = RandomV1.next(prng, 0, 1024 /* height */) * Fix64V1.ONE;
            watercolors.r[i] = RandomV1.next(prng, 341 /* width / 3 */, 1024 /* width */) * Fix64V1.ONE;

            (TypesV1.Point2D[MAX_POLYGONS] memory basePoly, uint32 basePolyCount)
             = createBasePoly(
                CreateBasePoly(x, y, watercolors.r[i]),                
                prng
            );

            watercolors.basePoly[i] = basePoly;
            watercolors.basePolyCount[i] = basePolyCount;            
        }

        watercolors.prng = prng;
    }

    function buildStackList(RandomV1.PRNG memory prng, WatercolorParameters memory p)
    external pure returns(StackList memory stackList) {
        require(p.stackCount > 0 && p.stackCount < 5, "invalid stack count");

        for (uint8 i = 0; i < p.stackCount; i++) {
            
            (TypesV1.Point2D[MAX_POLYGONS] memory stack, uint32 vertexCount)
             = createPolyStack(CreatePolyStack(p.r[i],
                p.basePoly[i],
                p.basePolyCount[i]),
                prng
            );
            
            if(i == 0) {
                stackList.stack1 = stack;
                stackList.stack1Count = vertexCount;
            } else if (i == 1) {
                stackList.stack2 = stack;
                stackList.stack2Count = vertexCount;
            } else if (i == 2) {
                stackList.stack3 = stack;    
                stackList.stack3Count = vertexCount;
            } else if (i == 3) {
                stackList.stack4 = stack;    
                stackList.stack4Count = vertexCount;
            }
        }        

        stackList.prng = prng;
    }

    function createPolyStack(
        CreatePolyStack memory f,        
        RandomV1.PRNG memory prng
    ) private pure returns (
        TypesV1.Point2D[MAX_POLYGONS] memory stack,
        uint32 vertexCount) {
        
        int32 variance = RandomV1.next(
            prng,
            int32(Fix64V1.div(f.r, 10 * Fix64V1.ONE) >> 32),
            int32(Fix64V1.div(f.r, 4 * Fix64V1.ONE) >> 32)
        );            

        (TypesV1.Point2D[MAX_POLYGONS] memory poly, uint32 polyCount) = deform(
            prng,
            f.basePoly,
            f.basePolyCount,
            5,                  // depth
            variance,           // variance
            4 * Fix64V1.ONE     // vdiv
        );

        require(polyCount == MAX_POLYGONS, "invalid algorithm");
        stack = poly;
        vertexCount = polyCount;
    }    

    function createBasePoly(CreateBasePoly memory f, RandomV1.PRNG memory prng) private pure returns (TypesV1.Point2D[MAX_POLYGONS] memory stack,
        uint32 vertexCount) {
        RPoly memory rPoly = rpoly(f);        
        require(rPoly.count == 10, "invalid algorithm");
        
        (TypesV1.Point2D[MAX_POLYGONS] memory basePoly, uint32 basePolyCount) = deform(prng, rPoly.points, rPoly.count, 5, 15, 2 * Fix64V1.ONE);
        require(basePolyCount == 640, "invalid algorithm");

        return (basePoly, basePolyCount);
    }

    function rpoly(CreateBasePoly memory f)
        private
        pure
        returns (RPoly memory _rpoly)
    {
        int64 angle = Fix64V1.div(
            Fix64V1.TWO_PI,
            int8(NUM_SIDES) * Fix64V1.ONE
        );

        for (int64 a = 0; a < Fix64V1.TWO_PI; a += angle) {
            int64 sx = Fix64V1.add(f.x, Fix64V1.mul(Trig256.cos(a), f.r));
            int64 sy = Fix64V1.add(f.y, Fix64V1.mul(Trig256.sin(a), f.r));
            _rpoly.points[_rpoly.count++] = TypesV1.Point2D(int32(sx >> 32), int32(sy >> 32));
        }
    }    

    function deform(
        RandomV1.PRNG memory prng,
        TypesV1.Point2D[MAX_POLYGONS] memory points,
        uint32 pointCount,
        int32 depth,
        int32 variance,
        int64 vdiv
    ) private pure returns(TypesV1.Point2D[MAX_POLYGONS] memory newPoints, uint32 newPointCount) {

        if (pointCount < 2) {
            return (newPoints, 0);
        }

        newPointCount = 0;
        for (uint32 i = 0; i < pointCount; i++) {

            int32 sx1 = int32(points[i].x);
            int32 sy1 = int32(points[i].y);
            int32 sx2 = int32(points[(i + 1) % pointCount].x);
            int32 sy2 = int32(points[(i + 1) % pointCount].y);

            newPoints[newPointCount++] = TypesV1.Point2D(sx1, sy1);

            newPointCount = subdivide(
                Subdivide(depth, variance * Fix64V1.ONE, vdiv, newPoints, newPointCount, sx1 * Fix64V1.ONE,
                sy1 * Fix64V1.ONE,
                sx2 * Fix64V1.ONE,
                sy2 * Fix64V1.ONE),
                prng                
            );
        }

        return (newPoints, newPointCount);
    }

    function subdivide(
        Subdivide memory f,
        RandomV1.PRNG memory prng
    ) private pure returns (uint32) {
        while (true) {
            if (f.depth >= 0) {

                (int64 nx) = subdivide_midpoint(f, prng, f.x1, f.x2);
                (int64 ny) = subdivide_midpoint(f, prng, f.y1, f.y2);

                int32 vardiv2 = int32(Fix64V1.div(f.variance, f.vdiv) >> 32);
                int64 variance2 = RandomV1.next(prng, vardiv2) * Fix64V1.ONE;
                
                f.pointCount = subdivide(Subdivide(                    
                    f.depth - 1,
                    variance2,
                    f.vdiv,
                    f.points,
                    f.pointCount,
                    f.x1, f.y1, nx, ny
                ), prng);
                
                uint32 pi = f.pointCount++;
                f.points[pi] = TypesV1.Point2D(int32(nx >> 32), int32(ny >> 32));
                f.x1 = nx;
                f.y1 = ny;
                f.depth = f.depth - 1;

                int32 vardiv = int32(Fix64V1.div(f.variance, f.vdiv) >> 32);
                f.variance = RandomV1.next(prng, vardiv) * Fix64V1.ONE;
                continue;
            }

            break;
        }

        return f.pointCount;
    }

    function subdivide_midpoint(
        Subdivide memory f,
        RandomV1.PRNG memory prng,
        int64 t1,
        int64 t2
    ) private pure returns (int64) {
        int64 mid = Fix64V1.div(Fix64V1.add(t1, t2), Fix64V1.TWO);
        int64 g = RandomV1.nextGaussian(prng);
        int64 n = Fix64V1.add(mid, Fix64V1.mul(g, f.variance));
        return n;
    }
}