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

// contract Interaction {
//     address SWUtilsAddr = 0x64DC2863476c004B77100935C6C77F574ddfc8f3;

//     function setSWUtilsAddr(address _counter) public payable {
//        SWUtilsAddr = _counter;
//     }

//     function trimA(string memory str) external view returns (string memory) {
//         return ISWUtils(SWUtilsAddr).trim(str);
//     }
// }

library Base62Library {
    address internal constant SWUtilsAddr = 0x64DC2863476c004B77100935C6C77F574ddfc8f3;

    string internal constant __B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    //string internal constant _B80 = "[email protected]#$%^&*()_+-=[]{}";
    function _radix62(uint val) internal pure returns (uint ) { //Return Max root63 Integer (Restituisce il Massimo Intero nella Radice di 62 del Numero)
        for (uint i = 1; i <= 43; i++) {    //i = 32 is 2,2726578844967513453552415636275e+57. uint256 is 2^256 >62^42(i=42)
            if (val < (62**i)) { return uint(i); }
        }
        return uint(32);
    }
    function toBase(uint val) public pure returns (string memory) {      //MAX: 9'007'199'254'740'990; Javascript Limit See -> https://docs.ethers.io/v5/api/utils/bignumber/#BigNumber--notes-safenumbers
        uint r = _radix62(val);
        bytes memory res = new bytes(r);
        if (val == 0) { return "0"; }
        //else if (val >= 9007199254740990) { return "FfGNdXsE6"; } //No Error. It is a Javascript Limit -> https://docs.ethers.io/v5/api/utils/bignumber/#BigNumber--notes-safenumbers
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
    function fromBase(string memory val) public pure returns (uint) {    //MAX: 'XZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ' = 114446419277628420313129508056336604247695182258782022769131114106314177904639
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
// 1b: 0-                     61
// 2b: 0-                  3'843
// 3b: 0-                238'327
// 4b: 0-             14'776'335
// 5b: 0-            916'132'831
// 6b: 0-         56'800'235'583
// 7b: 0-      3'521'614'606'207
// 8b: 0-    218'340'105'584'895
//         9'007'199'254'740'990;   https://docs.ethers.io/v5/api/utils/bignumber/#BigNumber--notes-safenumbers
// 9b: 0- 13'537'086'546'263'551
//10b: 0-839'299'365'868'340'223 -> MAX: 839'299'365'868'340'200
//
// external: function is part of the contract interface, which means it can be called from other contracts and via transactions. External functions are sometimes more efficient when they receive large arrays of data. Use external if you expect that the function will only ever be called externally. For external functions, the compiler doesn't need to allow internal calls, and so it allows arguments to be read directly from calldata, saving the copying step, which will save more gas. Also note that external functions cannot be inherited by other contracts!
// public: function can either be called internally or externally. For public state variables, an automatic getter function is generated.
// internal: function or state variables can only be accessed internally (i.e. from within the current contract or contracts deriving from it), without using this.
// private: function or state variable is only visible for the contract they are defined in and not in derived contracts.
//https://ethfiddle.com/