/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: none

pragma solidity ^0.6.12;

interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract GOTido {
    
    address public owner = msg.sender;
    address public priceOwner = msg.sender;
    uint public usdPrice = 0;
    uint public buyPrice = 0;
    uint public startTime;
    uint public stopTime;
    address public tokenAddr;
    
    struct Buyer{
        uint[] purchase;
        uint[] time;
        uint[] buyPrice;
    }
    
    mapping(address => Buyer) buyer;
    
    event TokensBought(address, uint);
    event TransferOwnership(address);
    
    
    
  constructor(address tokenAddress) public {
    tokenAddr = tokenAddress;
  }
    
    // Buy Tokens
    function buyToken() public payable returns (bool) {
        require(usdPrice != 0, "Invalid or zero usd price");
        require(buyPrice != 0, "Invalid or zero buy price");
        require(msg.value >= 500000000000000000,"Min Limit 0.5 BNB");
        require(msg.value <= 1000000000000000000000,"Max Limit 1000 BNB");
        
        BEP20 token = BEP20(tokenAddr);
        
        uint tokens = (msg.value * usdPrice * 10) / buyPrice;
        token.transfer(msg.sender, tokens);
        
        buyer[msg.sender].purchase.push(tokens);
        buyer[msg.sender].time.push(block.timestamp);
        buyer[msg.sender].buyPrice.push(buyPrice);
        
        emit TokensBought(msg.sender, tokens);
        return true;
    }
    
    // Set token price
    // Insert value with three decimal places //
    function tokenPrice(uint value) public {
        require(msg.sender == priceOwner || msg.sender == owner, "Only Onwer Or priceOwner");
        buyPrice = value;
        
    }
    
    // Set USD price of BNB
    // Insert value with three decimal places //
    function bnbPrice(uint value) public {
        require(msg.sender == priceOwner || msg.sender == owner, "Only Onwer Or priceOwner");
        usdPrice = value;
    }
    
    // View Buyer Details
    function userDetails(address user) public view returns(uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory tokensBought = new uint[](buyer[user].purchase.length);
        uint[] memory timeBoughtAt = new uint[](buyer[user].purchase.length);
        uint[] memory priceBoughtAt = new uint[](buyer[user].purchase.length);
        
        for(uint i = 0; i < buyer[user].purchase.length; i++){
            tokensBought[i] = buyer[user].purchase[i];
            timeBoughtAt[i] = buyer[user].time[i];
            priceBoughtAt[i] = buyer[user].buyPrice[i];
        }
        
        return (tokensBought, timeBoughtAt, priceBoughtAt);
    }
    
    // Tokens for BNB
    function tokenForOneBnb(uint amt) public view returns(uint) {
        require(usdPrice != 0, "Invalid or zero usd price");
        
        uint tokens = (amt * usdPrice * 10) / buyPrice;
        
        return tokens;
    }
    
    function changePriceOwner(address newPriceOwner) external{
        require(msg.sender == owner,"Only Onwer");
        priceOwner = newPriceOwner;
    }
    
    // Withdraw BNB only by Owner
    function withdrawalToAddress(address payable to,uint amount) external {
        require(msg.sender == owner,"Only Onwer");
        to.transfer(amount);
    }
    
    // Withdraw tokens
    function withdrawTokens(address payable to, uint amount) public {
        require(msg.sender == owner,"Only Onwer");
        BEP20 token = BEP20(tokenAddr);
        token.transfer(to, amount);
    }
    
     // Withdraw Any tokens
    function withdrawAnyToken(address tokenAdr,address payable to, uint amount) public {
        require(msg.sender == owner,"Only Onwer");
        BEP20 token = BEP20(tokenAdr);
        token.transfer(to, amount);
    }
    
    // Transfer Ownership
    function transferOwnership(address to) external {
        require(msg.sender == owner,"Only Onwer");
        owner = to;
        emit TransferOwnership(owner);
    }
}