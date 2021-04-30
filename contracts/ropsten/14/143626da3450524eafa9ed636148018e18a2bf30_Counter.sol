/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Counter {
    uint public count; // everything stored in contract level is stored in a persist way.
    
    function get() public view returns (uint) {
        return count;
    }
    
    function inc() public {
        count += 1;
    }
    
    function dec() public {
        count -= 1;
    }
}