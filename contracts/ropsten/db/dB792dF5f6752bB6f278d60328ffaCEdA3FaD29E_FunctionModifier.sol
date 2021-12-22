/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract FunctionModifier {
    address public owner;
    uint public x = 10;
    bool public locked;

    constructor() {
        //  set the transaction sender as the owner of the contract
        owner = msg.sender;
    }

    //  Restrict access 
    //  Modifier to check the caller is the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    //  Validate inputs
    //  This modifier checks that the address passed in is not the zero address
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    //  Guard against reentrancy hack
    //  This modifier prevents a function from being called while it is still executing.

    function decrement(uint i) public  {
        x -= i;

        if (i > 1) {
            decrement(i -1);
        }
    }
}