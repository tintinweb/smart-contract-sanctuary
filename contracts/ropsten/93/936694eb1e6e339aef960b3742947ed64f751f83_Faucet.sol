/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

// Version of Solidity compiler this program was written for
pragma solidity ^0.6.0;

// Our first contract is a faucet!
contract Faucet {
    
    string message;
    
    // Accept any incoming amount
    receive () external payable {}
    
    function helloworld() public {
        require(true, "hello world this is cryptosinghs first contract");
    }
    
    function sendMessage(string memory _message) public {
        message = _message;
    }
    
    function getMessage() public returns(string memory){
        return message;
    }
    
    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 100000000000000000);

        // Send the amount to the address that requested it
        msg.sender.transfer(withdraw_amount);
    }
}