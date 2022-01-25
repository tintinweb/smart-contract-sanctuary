/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

pragma solidity >=0.8.11 <0.9.0;
// SPDX-License-Identifier: UNLICENSED
interface ISWUtils {
    function toString(uint256 value) external pure returns (string memory);
    function trim(string memory str) external pure returns (string memory);
    function substring(string memory str, uint begin, uint end) external pure returns (string memory);
}
library Base62Library {
    address internal constant SWUtilsAddr = 0x64DC2863476c004B77100935C6C77F574ddfc8f3;
    string internal constant __B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    function _radix62(uint val) internal pure returns (uint ) {
        for (uint i = 1; i <= 43; i++) {
            if (val < (62**i)) { return uint(i); }
        }
        return uint(32);
    }
    function toBase(uint val) external pure returns (string memory) {
        uint r = _radix62(val);
        bytes memory res = new bytes(r);
        if (val == 0) { return "0"; }
        else {
            bytes memory strBytes = bytes(__B62);
            for (uint i = 0; i < r; i++) {
                res[r - (i + 1)] = strBytes[(val % 62)];
                val = (val / 62);
            }
        }
        return string(res);
    }
    function toDec(string memory val) external pure returns (uint) { return _fromBase(val); }
    function fromBase(string memory val) external pure returns (uint) { return _fromBase(val); }
    function _fromBase(string memory val) internal pure returns (uint) {
        val = ISWUtils(SWUtilsAddr).trim(val);
        bytes memory valB = bytes(val);
        uint res = 0;
        for (uint i = 0; i < valB.length; i++) {
            bytes memory strBytes = bytes(__B62);
            for (uint i2 = 0; i2 < strBytes.length; i2++) {
                if(strBytes[i2] == valB[i]) {
                    res = (res * 62) + i2;
                }
            }
         }
         return res;
    }
}