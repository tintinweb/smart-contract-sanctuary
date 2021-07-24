/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Faucet {
    receive() external payable {}

    function withdraw(uint256 withdraw_amount) public {
        // Check that withdraw request is not more than 0.1 ether
        require(withdraw_amount <= 0.1 ether);
        
        // Send the amount to the address that requested it
        payable(msg.sender).transfer(withdraw_amount);
    }
    
}