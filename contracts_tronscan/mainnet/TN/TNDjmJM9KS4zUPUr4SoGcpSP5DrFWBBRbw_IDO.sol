//SourceUnit: gmoney.sol

// SPDX-License-Identifier: none
pragma solidity ^0.6.12;

interface TRC20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract IDO {
    
    address public owner = msg.sender;
    address public priceOwner = address(0);
    uint usdPrice = 0;
    uint buyPrice = 0;
    uint startTime;
    uint stopTime;
    
    struct Buyer{
        uint[] purchase;
        uint[] time;
        uint[] buyPrice;
    }
    
    mapping(address => Buyer) buyer;
    
    event TokensBought(address, uint);
    event TransferOwnership(address);
    
    // Buy Tokens
    function buyToken(address tokenAddr) public payable returns (bool) {
        require(usdPrice != 0, "Invalid or zero usd price");
        require(buyPrice != 0, "Invalid or zero buy price");
        
        uint amount = msg.value * usdPrice * 1000000000;
        uint tokens;
        TRC20 token = TRC20(tokenAddr);
        
        tokens = amount / buyPrice / 10;
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
        require(msg.sender == owner, "Only owner");
        buyPrice = value;
    }
    
    // Set USD price of TRON
    // Insert value with three decimal places //
    function tronPrice(uint value) public {
        require(msg.sender == owner, "Only owner");
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
    
    // Tokens for TRX
    function tokenForOneTrx(uint amt) public view returns(uint) {
        require(usdPrice != 0, "Invalid or zero usd price");
        
        uint price = buyPrice;
        amt = amt * 1000000;
        uint amount = amt * usdPrice * 1000000000;
        uint tokens;
        tokens = amount / price / 10;
        
        return tokens;
    }
    
    // View current USD Price
    function currentPrice() public view returns(uint) {
        return usdPrice;
    }
    
    // Withdraw TRX only by Owner
    function withdrawalToAddress(address payable to,uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
    }
    
    // Withdraw tokens
    function withdrawTokens(address payable to, address tokenAddr, uint amount) public {
        require(msg.sender == owner);
        TRC20 token = TRC20(tokenAddr);
        token.transfer(to, amount);
    }
    
    // Transfer Ownership
    function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
    }
}