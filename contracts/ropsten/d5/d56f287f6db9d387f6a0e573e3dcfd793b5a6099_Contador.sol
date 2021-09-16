/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract Contador {
    
    uint256 count;
    
    function setCount(uint256 _count) public {
        count = _count;
    }
    
    function incrementCount() public {
        count += 1;
    }
    
    function getCount() public view returns(uint256) {
        return count;
    }
    
    function getNumber() public pure returns(uint256) {
        return 34;
    }
    
}