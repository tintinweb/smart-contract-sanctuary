/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11 <0.9.0;

library SWUtils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function trim(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory res = new bytes(strBytes.length);
        uint i1 = 0;
        for(uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] != " ") {
                res[i1] = strBytes[i2];
                i1++;
            }
        }
        bytes memory res2 = new bytes(i1);
        for(uint i3 = 0; i3 < i1; i3++) { res2[i3] = res[i3]; }
        return string(res2);
    }
    function substring(string memory str, uint begin, uint end) internal pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for(uint i = 0; i <= (end - begin); i++){
            a[i] = bytes(str)[i+begin-1];
        }
        return string(a);    
    }
}

library Base62Library {
    using SWUtils for *;
    string internal constant __B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    function _radix62(uint val) internal pure returns (uint ) {
        for (uint i = 1; i <= 43; i++) {
            if (val < (62**i)) { return uint(i); }
        }
        return uint(32);
    }
    function toBase(uint val) public pure returns (string memory) {
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
    function toDec(string memory val) public pure returns (uint) { return fromBase(val); }
    function fromBase(string memory val) internal pure returns (uint) {
        val = val.trim();
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

contract _Base62 {
    using Base62Library for *;
    function toBase(uint val) public pure returns (string memory) { return val.toBase(); }
    function toDec(string memory val) public pure returns (uint) { return val.toDec(); }
    function fromBase(string memory val) public pure returns (uint)  { return val.fromBase(); }
}