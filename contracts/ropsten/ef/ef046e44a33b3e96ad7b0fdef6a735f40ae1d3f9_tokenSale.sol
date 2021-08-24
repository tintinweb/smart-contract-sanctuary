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

//-------------------------------------------------------------------------------------------------------

pragma solidity ^0.8.0;

import "./IERC20_wapda.sol";
import "./ERC20wapdaToken.sol";


contract tokenSale is ERC20{
    
    // address payable owner; 
    uint public rate;           // rate of token = Ether
    uint public fundRais;       //sum of ethers collecting during token sale
    uint private maxSupply;
    
    constructor(){
        maxSupply = 50000000*10**18;
        rate = 100;                     // 1 ether = 100 WET 
    }
    
    fallback()external payable{
        buyToken(payable(owner));
    }
    receive() external payable{
        buyToken(payable(owner));
    }
    
    function maxSupplyCap()public view returns(uint){
        return maxSupply;
    }
    
    function minting(address account, uint _mint)public  returns(bool){
        require(account != address(0),"account should not be zeor ac");
        require(ERC20.totalSupply() + (_mint*10**18) <= maxSupplyCap(),"TokenCaped: Cap exceeded");
        ERC20.mint(account,_mint);
        return true;
    }
    
    function updateTokenRate(uint _newRate) public returns(uint newRate){
        require(owner == msg.sender,"unauthorized call");
        require(_newRate > 0,"rate must not be Zero");
        rate = _newRate;
        
        return rate;
    }
    
    function buyToken(address account) public payable returns(uint FundsRais){
        uint tokensAllocation = msg.value * rate;
        fundRais = fundRais + msg.value;
        
        require(account != address(0), "address must not be Zero");
        require(msg.value > 0,"minimum purchase must not be Zero ether");
        
        // ERC20 token = new ERC20();  // new instance of ERC20 token
        ERC20.buyTokens(account,tokensAllocation);
        payable(owner).transfer(msg.value);
        
        return fundRais;
    }
}