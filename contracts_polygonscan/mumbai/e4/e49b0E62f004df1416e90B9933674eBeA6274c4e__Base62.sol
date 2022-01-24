/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11 <0.9.0;
contract _Base62 {
    string internal constant __B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    function toBase(uint val) public pure returns (string memory) { return _toBase(val); }
    function _toBase(uint val) public pure returns (string memory) {
        uint r = _radix(val);
        bytes memory res = new bytes(r);
        if (val == 0) { return "0"; }
        else if (val >= 839299365868340200) { return "10000000000"; }
        else {
            bytes memory strBytes = bytes(__B62);
            for (uint i = 0; i < r; i++) {
                res[r - (i + 1)] = strBytes[(val % 62)];
            }
        }
        return string(res);
    }
    function _radix(uint val) internal pure returns (uint ) {
        for (uint i = 1; i <= 32; i++) {
            if (val < (62**i)) { return uint(i); }
        }
        return uint(32);
    }
    function toDec(string memory val) public pure returns (uint) { return _fromBase(val); }
    function fromBase(string memory val) public pure returns (uint)  { return _fromBase(val); }
    function _fromBase(string memory val) internal pure returns (uint) {
        val = trim(val);
        bytes memory valB = bytes(val);
        uint res = 0;
        for (uint i = 0; i < valB.length; i++) {
            bytes memory strBytes = bytes(__B62);
            for (uint i2 = 0; i2 < strBytes.length; i2++) {
                if(strBytes[i2] == valB[i]) {
                    res = (res * 62) + i2;
                }
            }
            int ix = indexOf(valB[i]);
            if(ix >= 0) { res = (res * 62) + uint(ix); }
         }
         return res;
    }
    function indexOf(bytes1 searchVal) public pure returns (int) {  //internal
        bytes memory strBytes = bytes(__B62);
        for (uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] == searchVal) { return int(i2); }
        }
        return -1;
    }
    function trim(string memory str) public pure returns (string memory) {  //internal
        bytes memory strBytes = bytes(str);
        bytes memory res = new bytes(strBytes.length);
        uint i1 = 0;
        for(uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] != " ") {
                res[i1] = strBytes[i2];
                i1++;
            }
        }
        return string(res);
    }
}