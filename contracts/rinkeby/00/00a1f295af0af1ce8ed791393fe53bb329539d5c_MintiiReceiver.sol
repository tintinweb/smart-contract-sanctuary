/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "./StandardToken.sol";


contract MintiiReceiver {
    
    
    address[] tokenAddresses;
    
    event ReceivedToken(address TokenAddress, uint256 amount);
    
    function receiveTokens(uint256 amount) public{
        
        emit ReceivedToken(msg.sender, amount);
    }
    
}