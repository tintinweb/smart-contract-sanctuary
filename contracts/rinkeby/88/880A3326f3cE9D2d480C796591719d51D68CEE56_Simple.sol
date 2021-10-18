/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Simple {
    event DoSomething(
        address sender,
        uint256 oldFoo,
        uint256 newFoo
    );
    
    uint256 public foo;
    
    function doSomething(uint256 bar) external {
        emit DoSomething(msg.sender, foo, bar);
        foo = bar;
    }
}