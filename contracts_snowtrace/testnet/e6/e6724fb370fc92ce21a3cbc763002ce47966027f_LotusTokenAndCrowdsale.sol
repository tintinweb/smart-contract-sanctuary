/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.20;


contract LotusTokenAndCrowdsale {


    mapping (address => uint) balances;
    
    address tokenFundsAddress;
    address beneficiary;
    uint amountRaised;

    
    uint constant private TOKEN_PRICE_IN_WEI = 3 * 1 ether;

    
    event TransferLotus(address indexed from, address indexed to, uint value);
    event FundsRaised(address indexed from, uint fundsReceivedInWei, uint tokensIssued);
    event AVAXFundsWithdran(address indexed recipient, uint fundsWithdrawnInWei);
    
   
    constructor(uint initialSupply) public {
        
        balances[msg.sender] = initialSupply;
        
      
        tokenFundsAddress = msg.sender;
        
       
        beneficiary = tokenFundsAddress;
    }
    

    function sendTokens(address receiver, uint amount) public {
        
        if (balances[msg.sender] < amount) return;
        
       
        balances[msg.sender] -= amount;
        
      
        balances[receiver] += amount;

        emit TransferLotus(msg.sender, receiver, amount);
    }
    
    function getBalance(address addr) public view returns (uint) {
        return balances[addr];
    }

    function buyTokensWithAvax() public payable {
     
        uint numTokens = msg.value / TOKEN_PRICE_IN_WEI;
        
    
        balances[tokenFundsAddress] -= numTokens;
        
      
        balances[msg.sender] += numTokens;
        
    
        amountRaised += msg.value;

        emit FundsRaised(msg.sender, msg.value, numTokens);
    }
    
    function withdrawRaisedFunds() public {
        
 
        if (msg.sender != beneficiary)
            return;
        
 
        beneficiary.transfer(amountRaised);
        
        emit AVAXFundsWithdran(beneficiary, amountRaised);
        
    }
}