// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "RandomV1.sol";

library HatchLayer {
    
    struct HatchParameters {
        uint32 opacity;
        int32 spacing;
        uint32 color;
        uint32[16] palette;
        RandomV1.PRNG prng;
    }

    function getParameters(RandomV1.PRNG memory prng) external pure returns(
        HatchParameters memory hatch) {                
        hatch.spacing = 5;
        hatch.opacity = 80;
        hatch.palette[0] = 0xFF0088DC;
        hatch.palette[1] = 0xFFB31942;
        hatch.palette[2] = 0xFFEB618F;
        hatch.palette[3] = 0xFF6A0F8E;
        hatch.palette[4] = 0xFF4FBF26;
        hatch.palette[5] = 0xFF6F4E37;
        hatch.palette[6] = 0xFFFF9966;
        hatch.palette[7] = 0xFFBED9DB;
        hatch.palette[8] = 0xFF998E80;
        hatch.palette[9] = 0xFFFFB884;
        hatch.palette[10] = 0xFF2E4347;
        hatch.palette[11] = 0xFF0A837F;
        hatch.palette[12] = 0xFF076461;
        hatch.palette[13] = 0xFF394240;
        hatch.palette[14] = 0xFFFAF4B1;
        hatch.palette[15] = 0xFFFFFFFF;
        int32 hatchColor = RandomV1.next(prng, 16);
        hatch.color = hatch.palette[uint32(hatchColor)];
        hatch.prng = prng;
    }
}