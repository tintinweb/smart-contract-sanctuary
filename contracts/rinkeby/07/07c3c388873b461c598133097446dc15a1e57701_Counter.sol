/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Counter {
    
    uint public count;
    
    function get() public view returns (uint) {
        return count;
    }
    
    function inc() public {
        count += 1;
    }
    
}