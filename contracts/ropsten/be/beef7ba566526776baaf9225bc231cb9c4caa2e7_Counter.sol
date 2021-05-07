/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0; 
//below compatible with this version between 0.7.0 and 0.9.0 

contract Counter {
    // public means everyone can easily read the content of the variable
    // in public ethereum there is no concept of private
    uint count; 
    
    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }
    
    // Function to increment count by 1 
    function inc() public {
        count += 1;
    }
    
    // Function to decrement count by 1 
    function dec() public {
        count -= 1;
    }
}