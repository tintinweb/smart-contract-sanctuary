/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT                                                 
pragma solidity ^0.8.0;                                                         
                                                                                
                                                                                
contract Faucet {                                                               
                                                                                
    receive() external payable {}                                               
                                                                                
    fallback() external payable {}                                              
                                                                                
    function getBalance() public view returns (uint) {                          
        return address(this).balance;                                           
    }                                                                           
                                                                                
    function sendViaTransfer(address payable _to) public payable {              
        _to.transfer(address(this).balance);                                    
    }                                                                           
}