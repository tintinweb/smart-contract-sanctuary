/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Transfer {
    
    event MATICReceived(address from_, uint256 amount_);
    event MATICSent(address to_, uint256 amount_);
    
    constructor() {}
    
    receive() external payable {
        emit MATICReceived(msg.sender, msg.value);
    }
    
    function sendMATIC(uint256 amount, address to) external {
        require(address(this).balance > amount);
        (bool success, ) = to.call{value: amount}("");
        require(success);
        emit MATICSent(to, amount);
    }
}