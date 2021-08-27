// SPDX-License-Identifier: MIT
// 3A
// Create a token based on ERC20 which is buyable. Following features should present;
// 1. Anyone can get the token by paying against ether
// 2. Add fallback payable method to Issue token based on Ether received. Say 1 Ether = 100 tokens.
// 3. There should be an additional method to adjust the price that allows the owner to adjust the price.

// 3B  
// Please complete the ERC20 token with the following extensions;
// 1. Capped Token: The minting token should not be exceeded from the Capped limit.
// 2. TimeBound Token: The token will not be transferred until the given time exceed. For example Wages payment will be due after 30 days.
// 3. should be deployed by using truffle or hardhat on any Ethereum test network
// Note:  project should be share as a GitHub public repository

// 3C
// 1. Owner can transfer the ownership of the Token Contract.
// 2. Owner can approve or delegate anybody to manage the pricing of tokens.
// 3. Update pricing method to allow owner and approver to change the price of the token
// 3. Add the ability that Token Holder can return the Token and get back the Ether based on the current price.
//-------------------------------------------------------------------------------------------------------

pragma solidity ^0.8.0;

import "./ERC20TheToken.sol";

contract TheToken is ERC20{
    
    uint public rateBuy;           // rate of token = Ether
    uint public fundRais;       //sum of ethers collecting during token sale
    uint private maxSupply;
    mapping (address => bool) internal priceSetter;
    
    
    constructor(){
        maxSupply = 500000 *10**decimals;
        rateBuy = 100;                     // 1 ether = 100 WET 
    }
    
    modifier isAuthorizer () {
       require(msg.sender == owner() || priceSetter[msg.sender],"caller is not authorizer"); 
        _;
    }
    
    fallback()external payable{   }
    
    receive() external payable{   }
    
    function maxSupplyCap()public view returns(uint){
        return maxSupply;
    }
    
    function minting(address account, uint _mint)public  returns(bool){
        require(account != address(0),"account should not be zeor address");
        require(totalSupply() + (_mint*10**18) <= maxSupplyCap(),"TokenCaped: Cap exceeded");
        mint(account,_mint);
        return true;
    }
    
    
    function setRateSetter(address _priceSetter)public onlyOwner(){
        priceSetter[_priceSetter] = true;
    }
    
    function delRateSetter(address _priceSetter)public onlyOwner(){
        priceSetter[_priceSetter] = false;
    }
    
    
    function setRate(uint _newRate) public isAuthorizer returns(uint newRate){
        require(_newRate > 0,"Rate must not be Zero");
        rateBuy = _newRate;
        return rateBuy;
    }
    
    function buyToken(address account) public payable returns(uint FundsRais){
        uint tokensAllocation = msg.value * rateBuy;
        fundRais = fundRais + msg.value;
        
        require(account != address(0), "address must not be Zero");
        require(msg.value > 0,"minimum purchase must not be Zero ether");
        
        buyTokens(account,tokensAllocation);
        return fundRais;
    }
    
    function tokenBuyBack(address _seller, uint _tokenReturn, uint _rateSale)public payable returns(bool){
        address seller = _seller;
       uint etherReturn = (_tokenReturn * _rateSale)/(1**decimals);
        
        require (msg.sender == seller && seller !=address(0),"Seller must be valid account holder");
        require (_tokenReturn <= balanceOf(seller),"Seller token balance is not sufficient");
        require (etherReturn <= fundRais,"No liquidity for this token");

        _transfer(seller,owner(),_tokenReturn);
        fundRais = fundRais - etherReturn;
        payable(seller).transfer(etherReturn);
        
        emit Transfer(seller, owner(),_tokenReturn);
        return true;
    }
}