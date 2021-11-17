/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

contract Test {
    uint256 public number;
    
    function addNumber(uint256 _num) public {
        number = number + _num;
    }
}