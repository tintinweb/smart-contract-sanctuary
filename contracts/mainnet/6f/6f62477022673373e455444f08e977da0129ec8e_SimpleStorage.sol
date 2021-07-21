/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {

    // Declare state variables of the contract
    address public owner;
    
    mapping (address => string) public ids;
  
    constructor() {
        owner = msg.sender;
    }
    
    function frank(string calldata id) public payable {
        ids[msg.sender] = id;
    }
}