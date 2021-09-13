/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract test {
    
    uint256 a;
    
    function set(uint256 _a) public {
        a = _a;
    }
    
    function get() public view returns(uint256) {
        return a;
    }
}