/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract connectingUI {
    
    uint public x;
    function getValue() public view returns(uint) {
        return x;
    }
    function setValue(uint _x) public {
        x = _x;
    } 
    function getBlockNumber() public view returns(uint) {
        return block.number;
    }

}