/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Summator{
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        return c;
   }
}