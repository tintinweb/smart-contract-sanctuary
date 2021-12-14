/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract SolitityTest{

    constructor() public {

    }

    function getResult(uint a, uint b) public view returns(string memory ) {
      uint result = a + b;
      return integerToString(result); 
    }

    function integerToString(uint _i) internal pure returns (string memory) {

      if (_i == 0) {
         return "0";

      }
      uint j = _i;
      uint len;

      while (j != 0) {
         len++;
         j = j/10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len - 1;

      while (_i != 0) { // while 循环
         bstr[k--] = byte(uint8(48 + _i % 10));
         _i /= 10;
      }
      return string(bstr);
   }
}