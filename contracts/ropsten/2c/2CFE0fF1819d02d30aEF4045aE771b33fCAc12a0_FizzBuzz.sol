/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later Or MIT

pragma solidity >=0.6.0 <=0.8.0;

contract FizzBuzz {
    uint private count;
    
    event Increment(
        address sender,
        uint count
    );
    
    constructor() public {
        count = 0;
    }
    
    function increment() external {
        count = count + 1;
        
        emit Increment(msg.sender, count);
    }
    
    function getFizzBuzz() external returns (string memory res) {
        if ( count % 3 == 0 && count % 5 == 0 ) {
            res = "FizzBuzz";
        } else if ( count % 3 == 0 ) {
            res = "Fizz";
        } else if ( count % 5 == 0 ) {
            res = "Buzz";
        }
        return res;
    }
}