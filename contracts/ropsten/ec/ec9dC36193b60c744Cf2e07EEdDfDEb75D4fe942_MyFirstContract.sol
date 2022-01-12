// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;
 
contract MyFirstContract {
 
    uint256 number;
 
 
    function setNumber(uint256 _num) public {
        number = _num;
    }
 
 
    function getNumber() public view returns (uint256){
        return number;
    }
}