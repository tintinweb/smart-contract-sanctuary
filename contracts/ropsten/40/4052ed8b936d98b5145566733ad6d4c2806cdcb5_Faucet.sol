/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: GPL-3.0
// Smart contract: faucet
pragma solidity ^0.7.4;
contract Faucet
{
    
    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public
    {
        // Limit withdrawal amount
        require(withdraw_amount <= 100000000000000000);
        
        // Send the amount to the address that requested it
        msg.sender.transfer(withdraw_amount);
    }
    
    // receive function: be called when the call data is empty
    // call data == input data of smart contract
    // receive() is implicitly payable.
    receive() external payable {}
    
    // fallback function: be called when no other function matches
    // If receive() does not exist and the call data is empty, fallback() will be invoked as well.
    // If fallback() is not payable, TXs not matching any function which send value will revert.
    fallback () external payable {}
}