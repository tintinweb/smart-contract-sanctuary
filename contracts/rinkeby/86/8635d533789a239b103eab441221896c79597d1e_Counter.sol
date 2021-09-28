/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.1;

contract Counter {
    uint count = 0;
    
    event Increment(uint value);
    event Decrement(uint value);
    
    /*
    constructor() public {
        count = 0;    
    }
    */
    
    function increment() public {
        count += 1;
        // we allow to be subscribed in blockchain to this event
        emit Increment(count);
    }
    
    function decrement() public {
        count -= 1;
        // we allow to be subscribed in blockchain to this event
        emit Decrement(count);
    }
    
    function getcount() view public returns (uint) {
        return count;
    }
}