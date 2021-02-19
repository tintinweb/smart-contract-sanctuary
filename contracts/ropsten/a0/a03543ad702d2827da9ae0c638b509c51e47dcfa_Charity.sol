/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

contract Charity {
    
    address payable public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function donate() public payable {
        owner.transfer(msg.value);
    }
    
}