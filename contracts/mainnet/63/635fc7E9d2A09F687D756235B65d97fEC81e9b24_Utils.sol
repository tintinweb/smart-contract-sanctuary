// SPDX-License-Identifier: MIT
// Same version as openzeppelin 3.4
pragma solidity >=0.6.0 <0.8.0;

library Utils
{
    //---------------------------
    // Convert
    //

    function convertBlockHashToAddress(uint256 blockNumber) public view returns (address)
    {
        // https://docs.soliditylang.org/en/v0.7.6/types.html#address
        return address(uint160(bytes20(blockhash(blockNumber))));
    }

    function getBlockSeed() public view returns (bytes20)
    {
        address s = convertBlockHashToAddress(block.number);
        if( s == address(0) && block.number > 0 )
            s = convertBlockHashToAddress(block.number-1);
        return bytes20(s);
    }

    function convertBytesToHexString(bytes memory values) public pure returns (string memory)
    {
        bytes memory result = new bytes(values.length*2);
        for(uint8 i = 0; i < values.length; i++)
        {
            for(uint8 j = 0 ; j < 2; j++)
            {
                uint8 v = ( j == 0 ? uint8(values[i]>>4) : uint8(values[i] & 0x0f) );
                result[i*2+j] = v > 9 ? byte(55+v) : byte(48+v);
            }
        }
        return string(result);
    }

    function convertByteToHexString(byte b) public pure returns (string memory)
    {
        bytes memory result = new bytes(2);
        for(uint8 j = 0 ; j < 2; j++)
        {
            uint8 v = ( j == 0 ? uint8(b>>4) : uint8(b & 0x0f) );
            result[j] = v > 9 ? byte(55+v) : byte(48+v);
        }
        return string(result);
    }

    //---------------------------
    // Math
    //

    function clamp_uint256(uint256 value, uint256 min, uint256 max) public pure returns (uint256)
    {
        return value < min ? min : value > max ? max : value;
    }

    function min_uint256(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function max_uint256(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    function percent_uint256(uint256 value, uint256 percentage) public pure returns (uint256)
    {
        return value * percentage / 100;
    }

    //---------------------------
    // Pixels
    //
    function step_int(int min, int max, int stepCount, int stepIndex) public pure returns (int)
    {
        if( stepIndex <= 0 || stepCount <= 1 || min == max )
            return min;
        if( stepIndex >= stepCount - 1 )
            return max;
        int d = (max - min) / (stepCount - 1);
        return min + (d * stepIndex);
    }
    function step_uint8(uint8 min, uint8 max, uint8 stepCount, uint8 stepIndex) public pure returns (uint8)
    {
        int result = step_int( min, max, stepCount, stepIndex );
        return result < 0 ? 0 : result > 255 ? 255 : uint8(result);
    }

    function map_uint256(uint256 value, uint256 min, uint256 max) public pure returns (uint256)
    {
        return min + ((value * (max - min)) / 255);
    }

    function map_uint8(uint8 value, uint8 min, uint8 max) public pure returns (uint8)
    {
        return uint8(int(min) + ((int(value) * int(max - min)) / 255));
    }

    function rshift_bytes20(bytes20 buffer, uint256 bits) public pure returns (bytes20)
    {
        uint256 b = bits % (20*8);
        return (buffer >> b) | (buffer << (20*8-b));
    }

    function lshift_bytes20(bytes20 buffer, uint256 bits) public pure returns (bytes20)
    {
        uint256 b = bits % (20*8);
        return (buffer << b) | (buffer >> (20*8-b));
    }

    function sum_bytes20(bytes20 buffer) public pure returns (uint256)
    {
        uint256 sum = 0;
        for(uint8 i = 0 ; i < 20 ; ++i) {
            sum += uint8(buffer[i]);
        }
        return sum;
    }


    // HSV Conversion from
    // https://stackoverflow.com/a/14733008/360930
    function hsvToRgb(uint8 h, uint8 s, uint8 v) public pure returns (uint8, uint8, uint8)
    {
        if (s == 0) {
            return (v, v, v);
        }
        int region = h / 43;
        int remainder = (h - (region * 43)) * 6; 
        int p = (v * (255 - s)) >> 8;
        int q = (v * (255 - ((s * remainder) >> 8))) >> 8;
        int t = (v * (255 - ((s * (255 - remainder)) >> 8))) >> 8;
        if(region == 0) {
            return(v, uint8(t), uint8(p));
        } else if (region == 1) {
            return(uint8(q), v, uint8(p));
        } else if (region == 2) {
            return(uint8(p), v, uint8(t));
        } else if (region == 3) {
            return(uint8(p), uint8(q), v);
        } else if (region == 4) {
            return(uint8(t), uint8(p), v);
        }
        return(v, uint8(p), uint8(q));
    }

    function reduceColors(bytes20 s0, bytes20 s1, bytes20 s2, uint8 colorCount, uint256 offset) public pure returns (uint8[] memory)
    {
        uint8[] memory c3 = new uint8[](colorCount*3);
        uint256 sum0 = sum_bytes20(s0) + sum_bytes20(s1);
        uint256 sum2 = sum_bytes20(s2);
        bytes20 hues = lshift_bytes20(s2, sum2 + (offset*8));
        for(uint8 c = 0 ; c < colorCount ; c++) {
            uint8 h = uint8(hues[c]);
            uint8 s = map_uint8(uint8((uint256(uint8(hues[c+10])) + sum0*3) % 256), (64+(5-(colorCount/2))*30), 255);
            uint8 v = map_uint8(h|uint8((uint256(uint8(hues[c+10])) + sum0) % 256), (127+(5-(colorCount/2))*30), 255);
            h = uint8(map_uint256(h, sum2, sum2+map_uint8(uint8((sum2+sum0)%256),100,240))%256);
            // h = uint8(map_uint256(h, lh, lh+192)%256);
            (c3[c*3+0], c3[c*3+1], c3[c*3+2]) = hsvToRgb(h,s,v);
        }
        return (c3);
    }

    //
    // From truffle/Assert.sol
    // MIT Licence
    //
    uint8 constant ZERO = uint8(bytes1('0'));
    uint8 constant A = uint8(bytes1('a'));
    bytes1 constant MINUS = bytes1('-');
    function utoa(uint n) public pure returns (string memory)
    {
        return utoa(n, 10);
    }
    function utoa(uint n, uint8 radix) public pure returns (string memory) {
        if (n == 0 || radix < 2 || radix > 16)
            return '0';
        bytes memory bts = new bytes(256);
        uint i;
        while (n > 0) {
            bts[i++] = _utoa(uint8(uint(n % radix))); // Turn it to ascii.
            n /= radix;
        }
        // Reverse
        bytes memory rev = new bytes(i);
        for (uint j = 0; j < i; j++)
            rev[j] = bts[i - j - 1];
        return string(rev);
    }
    function _utoa(uint8 u) public pure returns (bytes1) {
        if (u < 10)
            return bytes1(u + ZERO);
        else if (u < 16)
            return bytes1(u - 10 + A);
        else
            return 0;
    }

}