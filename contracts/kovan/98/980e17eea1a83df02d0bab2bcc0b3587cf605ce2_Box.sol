/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Box {
    uint256 public value;
    
    function setValue(uint256 _value) public payable {
        require(msg.value >= 0.1 ether);
        value = _value;
    }
}