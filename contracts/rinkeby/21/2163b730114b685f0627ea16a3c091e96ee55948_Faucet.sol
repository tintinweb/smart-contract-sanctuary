/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT                                                 
pragma solidity ^0.8.0;                                                         
                                                                                
                                                                                
contract Faucet {                                                               
    event Deposit(address indexed from, uint amount);                           
    event Withdraw(address indexed to, uint amount);                            
                                                                                
    receive() external payable {                                                
        emit Deposit(msg.sender, msg.value);                                    
    }                                                                           
                                                                                
    fallback() external payable {                                               
        emit Deposit(msg.sender, msg.value);                                    
    }                                                                           
                                                                                
    function getBalance() public view returns (uint) {                          
        return address(this).balance;                                           
    }                                                                           
                                                                                
    function sendViaTransfer(address payable _to) public payable {              
        emit Deposit(msg.sender, msg.value);                                    
        _to.transfer(address(this).balance);                                    
    }                                                                           
}