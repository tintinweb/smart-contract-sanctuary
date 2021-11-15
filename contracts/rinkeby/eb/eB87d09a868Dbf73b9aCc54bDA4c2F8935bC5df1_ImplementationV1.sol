// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImplementationV1  {
    uint256 public num;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function incrementByTwo() public {
        num += 2;
    }
}

