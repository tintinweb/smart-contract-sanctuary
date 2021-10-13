/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.9;

contract SingleConstant {
    uint256 internal foo;
    
    function getFoo() external view returns (uint256) {
        return foo;
    }
    
    function getFoo(uint256 newFoo) external {
        foo = newFoo;
    }
}