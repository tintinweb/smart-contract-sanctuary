/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract Context {
    constructor() {}
    
    event Minted(address _sender, uint256 _amount);
    
    function buy(uint256 amount) public {
        emit Minted(msg.sender, amount);
    }
}