/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

/* 
* Simple implementation of a crowd sale. You send Ether, this contract sends you tokens.
* Token price is fixed to be 1 GBT = 1 ETH.
* 
* This contract is for educational purposes ONLY. For security audited / more functional 
* crowdsale contracts, check out OpenZepplin's github repository:
*
* https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/crowdsale
* 
*/
contract GBTokenAndCrowdsale {

    /* This creates an array with all balances */
    mapping (address => uint) balances;
    
    /* Address of the wallet holding the token funds when they are first created */
    address tokenFundsAddress;
    
    /* Approved address of the account that will receive the raised Ether funds */
    address beneficiary;
    
    /* Keep track of ETH funds raised */
    uint amountRaised;

    /* Price of a GBT token, in 'wei' denomination */
    uint constant private TOKEN_PRICE_IN_WEI = 1 * 1 ether;

    /* This generates a public event on the blockchain that will notify listening clients */
    event TransferGB(address indexed from, address indexed to, uint value);
    event FundsRaised(address indexed from, uint fundsReceivedInWei, uint tokensIssued);
    event ETHFundsWithdrawn(address indexed recipient, uint fundsWithdrawnInWei);
    
    /* Initialize the contract, this is the "constructor" */
    constructor(uint initialSupply) public {
        // give all tokens to the creator of the contract
        balances[msg.sender] = initialSupply;
        
        // store a reference to this contract creator's address, 
        // so we can debit tokens from this address each time we distribute tokens to
        // a crowdsale participant
        tokenFundsAddress = msg.sender;
        
        // the beneficiary for the crowd sale (the one who will receive the raised ETH)
        // should be the same as the account holding the tokens to be given away
        beneficiary = tokenFundsAddress;
    }
    
    /* Send tokens from the message sender's account to the specified account */
    function sendTokens(address receiver, uint amount) public {
        // if sender does not have enough money
        if (balances[msg.sender] < amount) return;
        
        // take funds out of sender's account
        balances[msg.sender] -= amount;
        
        // add those funds to receipient's account
        balances[receiver] += amount;

        emit TransferGB(msg.sender, receiver, amount);
    }
    
    function getBalance(address addr) public view returns (uint) {
        return balances[addr];
    }

    function buyTokensWithEther() public payable {
        // calculate # of tokens to give based on 
        // amount of Ether received and the token's fixed price
        uint numTokens = msg.value / TOKEN_PRICE_IN_WEI;
        
        // take funds out of our token holdings
        balances[tokenFundsAddress] -= numTokens;
        
        // deposit those tokens into the buyer's account
        balances[msg.sender] += numTokens;
        
        // update our tracker of total ETH raised
        // during this crowdsale
        amountRaised += msg.value;

        emit FundsRaised(msg.sender, msg.value, numTokens);
    }
    
    function withdrawRaisedFunds() public {
        
        // verify that the account requesting the funds
        // is the approved beneficiary
        if (msg.sender != beneficiary)
            return;
        
        // transfer ETH from this contract's balance
        // to the rightful recipient
        beneficiary.transfer(amountRaised);
        
        emit ETHFundsWithdrawn(beneficiary, amountRaised);
        
    }
}