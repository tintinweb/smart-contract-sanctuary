/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract num {
    uint256 number;
    function changeNumber(uint256 _num) public {
        number = _num;
        
    }
    function getNumber() public view returns (uint256) {
        return number;
    }
    function addNumber(uint256 _num1, uint256 _num2) public pure returns (uint256) {
        return _num1 + _num2;
    }
}