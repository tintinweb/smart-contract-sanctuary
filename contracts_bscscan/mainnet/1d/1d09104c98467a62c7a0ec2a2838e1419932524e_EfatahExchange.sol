/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EfatahExchange {
    using SafeMath for uint256;

    address payable private _owner;  
    address private _contractAddr;
    uint256 private bnbBuyRate = 1; 
    uint256 private bnbSellRate = 1; 
    IERC20 private efatahCoin;
    
    struct Transact { uint256 bnbRate;  uint256 bnbAmount;  uint256 tokenAmount; }
    mapping(address => Transact[]) public buyRecords;
    mapping(address => Transact[]) public sellRecords;
    address[] private clientAddrs; 

    modifier ownerOnly() {
        require(msg.sender == _owner);
        _;
    }

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event Received(address sender, uint256 amount);
    event Withdrawn(uint256 amount);

    constructor(address payable addr, address cAddr) {
        _owner = addr; 
        _contractAddr = cAddr;
        efatahCoin = IERC20(cAddr); 
    }
    
    
    function getInfo() public view returns (address ownerAddr, address contractAddr, uint256 buyRate, uint256 sellRate) {
        ownerAddr = _owner;
        contractAddr = _contractAddr;
        buyRate = bnbBuyRate;
        sellRate = bnbSellRate;
    }
    
    function getTokenBalance() public view returns (uint256 tokenBalance) { 
        tokenBalance = efatahCoin.balanceOf(msg.sender);
    }
    
    function getBuyAddresses() external view ownerOnly returns (address[] memory) {
        return clientAddrs;
    }
    
    function getBuyTransactions(address addr) external view ownerOnly returns (Transact[] memory) {
        return buyRecords[addr];
    }
    
    function getSellTransactions(address addr) external view ownerOnly returns (Transact[] memory) {
        return sellRecords[addr];
    }
     

    function setContractAddress(address cAddr) external ownerOnly {
        _contractAddr = cAddr;
        efatahCoin = IERC20(cAddr); 
    }

    function setOwner(address payable addr) external ownerOnly {
        _owner = addr;
    }
    
    
    function setBnbRate(uint256 buyRate, uint256 sellRate) external payable ownerOnly {
        bnbBuyRate = buyRate;
        bnbSellRate = sellRate;
    }  
    
     function buy() payable public { 
        uint256 efatahAmount = bnbBuyRate.div(msg.value);
        uint256 efatBalance = efatahCoin.balanceOf(address(this));
        require(msg.value > 0, "You need to send some BNB");
        require(efatahAmount <= efatBalance, "Not enough tokens in reserve");

        efatahCoin.transfer(msg.sender, efatahAmount);
        
        if(buyRecords[msg.sender].length == 0){
            clientAddrs.push(msg.sender);
        }
        
        buyRecords[msg.sender].push(Transact(bnbBuyRate, msg.value, efatahAmount));
        emit Bought(efatahAmount); 
    }

    function sell(uint256 eftAmt) payable public {
        require(eftAmt > 0, "You need to sell at least some tokens");
        uint256 bnbValue = bnbSellRate.mul(eftAmt);
        require(address(this).balance >= bnbValue, "Not enough BNB in reserve");
        
        uint256 allowToken = efatahCoin.allowance(msg.sender, address(this));
        require(allowToken >= eftAmt, "Check the token allowance");
 
        efatahCoin.transferFrom(msg.sender, address(this), eftAmt);
        payable(msg.sender).transfer(bnbValue);
        
        if(buyRecords[msg.sender].length == 0 && sellRecords[msg.sender].length == 0){
            clientAddrs.push(msg.sender);
        }
        
        sellRecords[msg.sender].push(Transact(bnbSellRate, bnbValue, eftAmt));
        emit Sold(bnbValue); 
    }

    
    //accept fallbacks
    fallback() external payable {}
    receive() external payable {
        _owner.transfer(msg.value);
        emit Received(msg.sender, msg.value);
    }

    //accidentally sent bnb to address
    function withdraw(uint256 amount) external payable ownerOnly {
        _owner.transfer(amount);
        emit Withdrawn(amount);
    }
    
    //accidentally sent token to address
    function withdrawToken(address contractAddress, uint256 amount) external payable ownerOnly {
        require(amount > 0, "Check the amount to withdraw");
        IERC20 coin = IERC20(contractAddress); 
        uint256 allowance = coin.allowance(address(this), msg.sender);
        require(allowance >= amount, "Check the token allowance"); 
        coin.transferFrom(address(this), msg.sender, amount); 
        emit Withdrawn(amount);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        //assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

}