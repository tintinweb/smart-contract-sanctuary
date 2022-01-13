// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract LepaGetVIP{

    event Registered(address from);
    
    constructor() {
    }

    /* Dont accept eth or any token*/  
    receive() external payable {
        revert("The contract does not accept payment or transfer.");
    }

    function register() public{
        emit Registered(msg.sender);
    }

}