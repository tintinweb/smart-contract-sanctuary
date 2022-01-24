/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// SPDX-License-Identifier: UNLICENSED
//1b62 0-        61
//2b62 0-     3'844
//3b62 0-   238'328
//4b62 0-14'776'336
pragma solidity >=0.8.11 <0.9.0;
contract _Base62 {
    string internal constant __B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    //string internal constant _B80 = "[email protected]#$%^&*()_+-=[]{}";
    function toBase(uint val) public pure returns (bytes32) { return _toBase(val); }
    function _toBase(uint val) public pure returns (bytes32) {
        bytes32 res = "";
        bytes memory strBytes = bytes(__B62);
        if (val == 0) { return strBytes[val]; }
        else {
            while (val != 0) {
                res = bytes32(bytes.concat(strBytes[(val % 62)], res));
                val = val/62;
            }
        }
        return res;
    }
    function toDec(string memory val) public pure returns (uint ) { return _fromBase(val); }
    function fromBase(string memory val) public pure returns (uint ) { return _fromBase(val); }
    function _fromBase(string memory val) internal pure returns (uint ) {
        val = trim(val);
        bytes memory valB = bytes(val);
        uint res = 0;
        for (uint i = 0; i < valB.length; i++) {
//-            res = (res * 62) + __B62.indexOf(val[i]);
         }
         return res;
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
        return string(res);
    }
}
//external: function is part of the contract interface, which means it can be called from other contracts and via transactions. External functions are sometimes more efficient when they receive large arrays of data. Use external if you expect that the function will only ever be called externally. For external functions, the compiler doesn't need to allow internal calls, and so it allows arguments to be read directly from calldata, saving the copying step, which will save more gas. Also note that external functions cannot be inherited by other contracts!
// public: function can either be called internally or externally. For public state variables, an automatic getter function is generated.
// internal: function or state variables can only be accessed internally (i.e. from within the current contract or contracts deriving from it), without using this.
// private: function or state variable is only visible for the contract they are defined in and not in derived contracts.

//indexOf
//.trim()
//https://ethfiddle.com/