/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT; 

pragma solidity ^0.8.0; // .0 is a minor change, means from 0.8.0+

contract MyContract {

    string _message; // Save in Blockchain permanently, GAS will be charged.

    constructor(string memory message) {
        _message = message;
    }


    function PrintHelloWorld() public view returns(string memory) {
        return _message;
    }

}

// When deploy, GAS will be deducted, check ETHER left.
// After deployed, message will be written and cannot be deleted.
// because there are only one function, no update or delete function provided.

// Block Deployed address can be used to search at etherscan.io

// Try to change Environment to "Injected Web3"
// Connect to MetaMask
// Initial Message before deploy
// Deploy