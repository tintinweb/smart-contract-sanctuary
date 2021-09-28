/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test2 {
    function thisIsATest(uint256 money) public pure returns(uint256) {
       return money + 7;
    }
      function isItReally(bool maybe) public pure returns(string memory) {
        if(maybe){
          return 'Yes, it really is';
        } else {
          return 'mashed potatoes and gravy.';
        }
    }
}