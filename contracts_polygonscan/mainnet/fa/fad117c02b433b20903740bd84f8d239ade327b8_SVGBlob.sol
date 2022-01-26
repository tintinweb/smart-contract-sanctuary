// SPDX-License-Identifier: MIT
/// @title A library used to construct ERC721 token URIs and SVG blob paths
/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░##################################################░░
░░##################################################░░
░░#######WXOdodOXW##################################░░
░░######Nd'     'dN##################NXK00KXNW######░░
░░#####Wd.       .xW#############W0d:'......':d0W###░░
░░#####Wo         dW############Kc.            .oX##░░
░░######Kc.     .lX############X:               .dW#░░
░░#######W0dcccd0W#############0,                oW#░░
░░#############################X:               ,0##░░
░░######WXOxdooodxk0KXW########Nc              ,OW##░░
░░####Xx;.          ..,:codxxkxl.            .cK####░░
░░##Nk'                                     'kN#####░░
░░#Nd.                                    .lX#######░░
░░#k.                                    ;OW########░░
░░Wl                                   .dN##########░░
░░Wl                                 .cKW###########░░
░░#x.                               ,kN#############░░
░░#Xc                             .dX###############░░
░░##Xc                          .lKW################░░
░░###Xo.                      .lKW##################░░
░░####W0c.                ..,dKW####################░░
░░######WKd;.          .;oOXN#######################░░
░░#########WXOxolllodx0XW###########################░░
░░##################################################░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
>>>          inspired by blobshape.js              <<<
*/

pragma solidity 0.8.11;

import {Utils} from "./Utils.sol";

library SVGBlob {
    /** 
        generates pseudo random blob path shapes

        @param size size of created blob
        @param growth  scale ratio of generated blob
        @param edges number of points to generate the blob path (min: 3, max 7)
        @param seed number used to generate deterministic random shapes 
        @param curveMethod index of curve function (default: Q)
                [0 => Q]
                [1 => S]
                [2 => T]
                [3 => L]
        @return path 
    */
    function generateBlobPath(
        uint32 size,
        uint32 growth,
        uint32 edges,
        uint32 seed,
        uint16 curveMethod
    ) public view returns (string memory) {
        return
            _createSvgPath(
                _createPoints(size, growth, edges, seed),
                curveMethod
            );
    }

    /**
        shorthand for a simple blobs
     */
    function blob() public view returns (string memory) {
        return
            generateBlobPath(
                100,
                3,
                3,
                uint32(Utils.randomWithTimestamp(1, 1000)),
                0
            );
    }

    /** 
        retrieves center theta point
        @param value point ratio multiplicator
        @param min  min result value
        @param max max result value
        @return radius theta point distance
    */
    function _getThetaPoint(
        uint32 value,
        uint32 min,
        uint32 max
    ) internal pure returns (uint32 radius) {
        radius = min + ((value * (max - min)) / 1000);
        if (radius > max) {
            radius = radius - min;
        } else if (radius < min) {
            radius = radius + min;
        }
    }

    /** 
        retrieves trigonometry table lookups for a given ratio
        @param count trigonometry angle ratio (from 3 to 7);
        @return array of trigonometry table lookup
    */
    function _divide(uint32 count) internal pure returns (uint32[2][7] memory) {
        uint32[2] memory R1 = [uint32(2000), uint32(1000)];

        if (count <= 3) {
            return [
                R1,
                [uint32(500), uint32(1866)],
                [uint32(500), uint32(134)],
                R1,
                R1,
                R1,
                R1
            ];
        }
        if (count == 4)
            return [
                R1,
                [uint32(1000), uint32(2000)],
                [uint32(0), uint32(2224)],
                [uint32(1000), uint32(0)],
                R1,
                R1,
                R1
            ];

        if (count == 5)
            return [
                R1,
                [uint32(1309), uint32(1951)],
                [uint32(191), uint32(1587)],
                [uint32(191), uint32(412)],
                [uint32(1309), uint32(49)],
                R1,
                R1
            ];

        if (count == 6)
            return [
                R1,
                [uint32(1500), uint32(1866)],
                [uint32(500), uint32(1870)],
                [uint32(0), uint32(2220)],
                [uint32(500), uint32(134)],
                [uint32(1500), uint32(134)],
                R1
            ];

        return [
            R1,
            [uint32(1623), uint32(1781)],
            [uint32(777), uint32(1975)],
            [uint32(99), uint32(1434)],
            [uint32(99), uint32(566)],
            [uint32(777), uint32(25)],
            [uint32(1623), uint32(218)]
        ];
    }

    /**
        calculate point coordinates
        @param origin theta point of blob shape
        @param radius distance from theta to requested point
        @param T trigonometry table
        @return single array of coordinates X and Y
    */
    function _getCoordinates(
        uint32 origin,
        uint32 radius,
        uint32[2] memory T
    ) internal pure returns (uint32[2] memory) {
        uint32 rx = T[0];
        uint32 ry = T[1];

        uint32 x = rx >= 1000
            ? origin + ((radius * (rx - 1000)) / 1000)
            : origin - ((radius * (1000 - rx)) / 1000);
        uint32 y = ry >= 1000
            ? origin + ((radius * (ry - 1000)) / 1000)
            : origin - ((radius * (1000 - ry)) / 1000);

        return [x, y];
    }

    /**
        generate array of points to form a blob
        @param size size of generated blob
        @param minGrowth min scaling of generated blob
        @param edgesCount number of points forming the blob
        @param seed used for generating pseudo random shape
        @return array[@param edgesCount] of array[2] coordinates X and Y
    */
    function _createPoints(
        uint32 size,
        uint32 minGrowth,
        uint32 edgesCount,
        uint32 seed
    ) internal view returns (uint32[2][] memory) {
        uint32 outerRad = size / 2;
        uint32 innerRad = (minGrowth * outerRad) / 10;
        uint32 edges = edgesCount < 3 || edgesCount > 7
            ? uint32(Utils.random(seed, 2)) + 3
            : edgesCount;

        uint32[2][7] memory slices = _divide(edges);
        uint32[2] memory p;
        uint32[2][] memory destPoints = new uint32[2][](edges);

        for (uint32 i = 0; i < edges; i++) {
            uint32 O = _getThetaPoint(
                uint32(Utils.random(i + seed, 1000)) + 1,
                innerRad,
                outerRad
            );
            p = _getCoordinates(outerRad, O, slices[i]);
            destPoints[i][0] = p[0];
            destPoints[i][1] = p[1];
        }
        return destPoints;
    }

    /** 
        generates svg curve path along givent points
        @param points array of coordinates
        @return svg formatted curve path
     */
    function _createSvgPath(uint32[2][] memory points, uint16 curveMethodId)
        internal
        pure
        returns (string memory)
    {
        string memory svgPath = "";
        string[4] memory methods = ["Q", "S", "T", "L"];
        uint16 methodId = curveMethodId > 3 ? 3 : curveMethodId;
        string memory C = methods[methodId];
        uint32[2] memory p1;
        uint32[2] memory p2;
        uint32[2] memory mid = [
            (points[0][0] + points[1][0]) / 2,
            (points[0][1] + points[1][1]) / 2
        ];

        svgPath = string(
            abi.encodePacked(
                svgPath,
                "M",
                Utils.uint2str(mid[0]),
                ",",
                Utils.uint2str(mid[1])
            )
        );

        for (uint32 i = 0; i < points.length; i++) {
            p1 = points[(i + 1) % points.length];
            p2 = points[(i + 2) % points.length];
            mid = [(p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2];
            svgPath = string(
                abi.encodePacked(
                    svgPath,
                    C,
                    Utils.uint2str(p1[0]),
                    ",",
                    Utils.uint2str(p1[1]),
                    ",",
                    Utils.uint2str(mid[0]),
                    ",",
                    Utils.uint2str(mid[1])
                )
            );
        }
        svgPath = string(abi.encodePacked(svgPath, "Z"));
        return svgPath;
    }
}

// SPDX-License-Identifier: MIT
/// @title Utils library for RNG and uint string interpolation
/**
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
*/

pragma solidity 0.8.11;

library Utils {
    /**
        @param v uint number to convert ty bytes32
        @return ret bytes32 string interpolatable format
    */
    function uintToBytes(uint256 v) public pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint256(ret) / (2**8));
                ret |= bytes32(((v % 10) + 48) * 2**(8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
        @param nonce uint number to use as random seed
        @param max max number to generate
        @return randomnumber uint256 random number generated
    */
    function random(uint256 nonce, uint256 max) public view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(msg.sender, nonce))
        ) % max;
        return randomnumber;
    }

    /**
        generates random numbers every time timestamp of block execution changes
        @param nonce uint number to use as random seed
        @param max max number to generate
        @return randomnumber uint256 random number generated
    */
    function randomWithTimestamp(uint256 nonce, uint256 max)
        public
        view
        returns (uint256)
    {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % max;
        return randomnumber;
    }

    function getIndexAt(uint256 a, uint8 n) internal pure returns (uint256) {
        if (a & (1 << n) != 0) {
            return 1;
        }
        return 0;
    }

    function getWeightedIndex(uint256 i, uint256 max)
        internal
        pure
        returns (uint256)
    {
        return ((i % (max + 1)) + 1) % ((i % max) + 1);
    }

    function getBytesParams(uint256 targetId)
        internal
        pure
        returns (string memory bytesParams)
    {
        for (uint8 i = 0; i < 9; i++) {
            bytesParams = string(
                abi.encodePacked(
                    bytesParams,
                    "--b",
                    uint2str(i),
                    ":",
                    uint2str(getIndexAt(targetId, i)),
                    ";"
                )
            );
        }
        return bytesParams;
    }

    function getSvgCircles(uint256 nbC)
        internal
        pure
        returns (string memory circles)
    {
        for (uint16 j = 1; j <= nbC; j++) {
            circles = string(
                abi.encodePacked(
                    circles,
                    '<circle class="circle_',
                    Utils.uint2str(j),
                    '" cx="300" cy="',
                    Utils.uint2str(300 - (j * 20)),
                    '" r="',
                    Utils.uint2str(j * 20),
                    '" fill="url(#blobC_)" />'
                )
            );
        }

        return circles;
    }
}