/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract MyFirstContract {
 
    uint256 number;
 
 
    function setNumber(uint256 _num) public {
        number = _num;
    }
 
 
    function getNumber() public view returns (uint256){
        return number;
    }
}