/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: box.sol

contract Box {
    uint256 public value;

    event ValueSet(uint256 _value);

    function retreive() public view returns(uint256) {
        return value;
    } 


    function setValue(uint256 _value) public {
        emit ValueSet(_value);
        value = _value;
    }












}