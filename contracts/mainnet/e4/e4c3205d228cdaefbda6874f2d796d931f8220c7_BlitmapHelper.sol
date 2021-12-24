// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @author fishboy
// @title A helper class for some more Blitmap related things
// Credit to the Blitmap contract for several methods here: https://etherscan.io/address/0x8d04a8c79ceb0889bdd12acdf3fa9d207ed3ff63#code
library BlitmapHelper {

    function uintToHexDigit(uint8 d) public pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint a) public pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }
        
        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }
    
    function byteToUint(bytes1 b) public pure returns (uint) {
        return uint(uint8(b));
    }
    
    function byteToHexString(bytes1 b) public pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function getColorToUse(uint8 a, uint8 b) public pure returns (uint256) {
        if (a == 0 && b == 0) {
            return 0;
        } else if (a == 1 && b == 0) {
           return 1;
        } else if (a == 0 && b == 1) {
            return 2;
        } else {
            return 3;
        }
    }

    function getBit(bytes1 b, uint8 loc) internal pure returns (uint8) {
        return uint8(b) >> loc & 1;
    }

    function getColorsAsHex(bytes memory tokenData) public pure returns (string[4] memory) {
        return [
            string(abi.encodePacked("#", byteToHexString(tokenData[0]), byteToHexString(tokenData[1]), byteToHexString(tokenData[2]))),
            string(abi.encodePacked("#", byteToHexString(tokenData[3]), byteToHexString(tokenData[4]), byteToHexString(tokenData[5]))),
            string(abi.encodePacked("#", byteToHexString(tokenData[6]), byteToHexString(tokenData[7]), byteToHexString(tokenData[8]))),
            string(abi.encodePacked("#", byteToHexString(tokenData[9]), byteToHexString(tokenData[10]), byteToHexString(tokenData[11])))
        ];
    }
}