/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;



// Contract declaration
contract SimpleStorage {
    // state variables
    uint256 public number;
    
    // constructor - executed ONLY once while contract is deployed
    constructor (uint _number) public {
        number = _number;
    }
    
    function increment() public {
        number++;
        // emit events
        emit Increment(number,msg.sender);
    }
    
    function decrement() public {
        number--;
        // emit events
        emit Decrement(number,msg.sender);
    }
    
    function getNumber() public view returns (uint) {
        return number;
    }
    
    
    // events
    event Increment(uint256 indexed number, address indexed caller);
    event Decrement(uint256 indexed number, address indexed caller);
}