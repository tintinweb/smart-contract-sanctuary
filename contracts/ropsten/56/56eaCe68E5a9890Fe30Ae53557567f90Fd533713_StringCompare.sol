pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

contract StringCompare {
 
 function  comPare(string memory a, string memory b) public pure returns  (bool) {
     
    return keccak256(bytes(a)) == keccak256(bytes(b)); 
    }
 
 
 function conCat(string memory a, string memory  b) public pure returns (string memory){
     
     string memory sp = " ";
     
     
    return string(abi.encodePacked(a,sp, b));
 }
}

