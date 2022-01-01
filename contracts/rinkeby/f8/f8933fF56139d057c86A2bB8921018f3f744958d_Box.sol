/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// File: Box.sol

contract Box {
    uint256 public value;
    event ValueChanged(uint256 newvalue);

    function store(uint256 newvalue) public {
        value = newvalue;
        emit ValueChanged(newvalue);    
    }

    function retrive() public view returns(uint256) {
        return value;
    }

}