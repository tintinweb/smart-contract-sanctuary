/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.1;


contract Storage {

    uint count = 0;
    
    event Increment(uint value);
    
    
    function getCount() view public returns(uint) {
        return count;
    }
    
    function increment() public {
        count = count + 1;
        emit Increment(count);
        
    }

}