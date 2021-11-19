/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Contract {
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        require(msg.sender == owner);
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}