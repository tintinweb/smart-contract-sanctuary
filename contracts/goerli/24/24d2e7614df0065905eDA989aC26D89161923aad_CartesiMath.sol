// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CartesiMath
/// @author Felipe Argento
pragma solidity ^0.8.0;

library CartesiMath {
    // mapping values are packed as bytes3 each
    // see test/TestCartesiMath.ts for decimal values
    bytes constant log2tableTimes1M =
        hex"0000000F4240182F421E8480236E082771822AD63A2DC6C0305E8532B04834C96736B3C23876D73A187A3B9D4A3D09003E5EA63FA0C540D17741F28843057D440BA745062945F60246DC1047B917488DC7495ABA4A207C4ADF8A4B98544C4B404CF8AA4DA0E64E44434EE3054F7D6D5013B750A61A5134C851BFF05247BD52CC58534DE753CC8D54486954C19C55384255AC75561E50568DE956FB575766B057D00758376F589CFA5900BA5962BC59C3135A21CA5A7EF15ADA945B34BF5B8D805BE4DF5C3AEA5C8FA95CE3265D356C5D86835DD6735E25455E73005EBFAD5F0B525F55F75F9FA25FE85A60302460770860BD0A61023061467F6189FD61CCAE620E98624FBF62902762CFD5630ECD634D12638AA963C7966403DC643F7F647A8264B4E864EEB56527EC6560906598A365D029660724663D9766738566A8F066DDDA6712476746386779AF67ACAF67DF3A6811526842FA68743268A4FC68D55C6905536934E169640A6992CF69C13169EF326A1CD46A4A186A76FF6AA38C6ACFC0";

    /// @notice Approximates log2 * 1M
    /// @param _num number to take log2 * 1M of
    /// @return approximate log2 times 1M
    function log2ApproxTimes1M(uint256 _num) public pure returns (uint256) {
        require(_num > 0, "Number cannot be zero");
        uint256 leading = 0;

        if (_num == 1) return 0;

        while (_num > 128) {
            _num = _num >> 1;
            leading += 1;
        }
        return (leading * uint256(1000000)) + (getLog2TableTimes1M(_num));
    }

    /// @notice navigates log2tableTimes1M
    /// @param _num number to take log2 of
    /// @return result after table look-up
    function getLog2TableTimes1M(uint256 _num) public pure returns (uint256) {
        bytes3 result = 0;
        for (uint8 i = 0; i < 3; i++) {
            bytes3 tempResult = log2tableTimes1M[(_num - 1) * 3 + i];
            result = result | (tempResult >> (i * 8));
        }

        return uint256(uint24(result));
    }

    /// @notice get floor of log2 of number
    /// @param _num number to take floor(log2) of
    /// @return floor(log2) of _num
   function getLog2Floor(uint256 _num) public pure returns (uint8) {
       require(_num != 0, "log of zero is undefined");

       return uint8(255 - clz(_num));
    }

    /// @notice checks if a number is Power of 2
    /// @param _num number to check
    /// @return true if number is power of 2, false if not
    function isPowerOf2(uint256 _num) public pure returns (bool) {
        if (_num == 0) return false;

        return _num & (_num - 1) == 0;
    }

    /// @notice count trailing zeros
    /// @param _num number you want the ctz of
    /// @dev this a binary search implementation
    function ctz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) { n = n + 128; _num = _num >> 128; }
        if (_num & 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF == 0) { n = n + 64; _num = _num >> 64; }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF == 0) { n = n + 32; _num = _num >> 32; }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000FFFF == 0) { n = n + 16; _num = _num >> 16; }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000000000FF == 0) { n = n +  8; _num = _num >>  8; }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000000F == 0) { n = n +  4; _num = _num >>  4; }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000003 == 0) { n = n +  2; _num = _num >>  2; }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000001 == 0) { n = n +  1; }

        return n;
    }

    /// @notice count leading zeros
    /// @param _num number you want the clz of
    /// @dev this a binary search implementation
    function clz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 == 0) { n = n + 128; _num = _num << 128; }
        if (_num & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 == 0) { n = n + 64; _num = _num << 64; }
        if (_num & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 == 0) { n = n + 32; _num = _num << 32; }
        if (_num & 0xFFFF000000000000000000000000000000000000000000000000000000000000 == 0) { n = n + 16; _num = _num << 16; }
        if (_num & 0xFF00000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  8; _num = _num <<  8; }
        if (_num & 0xF000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  4; _num = _num <<  4; }
        if (_num & 0xC000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  2; _num = _num <<  2; }
        if (_num & 0x8000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  1; }

        return n;
    }
}

