/**
 *Submitted for verification at BscScan.com on 2021-08-25
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
    uint256 private efa_decimals = 100000000;//10^8; 8decimals
     
    modifier ownerOnly() {
        require(msg.sender == _owner);
        _;
    }

    event Bought(address addr, uint256 bnbAmount, uint256 efaAmt, uint256 bnbBuyRate);
    event Sold(address addr, uint256 bnbAmount, uint256 efaAmt, uint256 bnbSellRate);
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
        return(ownerAddr, contractAddr, buyRate, sellRate);
    }
     
    function getTokenBalance() external view returns (uint256) { 
        return efatahCoin.balanceOf(msg.sender);
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
        require(msg.value > 0, "You need to send some BNB");
        uint256 efatahAmount = msg.value.div(bnbBuyRate); 
        //convert to tokenDecimals
        efatahAmount =  efatahAmount.mul(efa_decimals);
        uint256 efatBalance = efatahCoin.balanceOf(address(this));
        require(efatahAmount <= efatBalance, "Not enough tokens in reserve");

        efatahCoin.transfer(msg.sender, efatahAmount);
        
        emit Bought(msg.sender, msg.value, efatahAmount, bnbBuyRate); 
    }

    function sell(uint256 eftAmt) payable public {
        require(eftAmt > 0, "You need to sell at least some tokens");
        uint256 bnbValue = bnbSellRate.mul(eftAmt);
        require(address(this).balance >= bnbValue, "Not enough BNB in reserve");
        
        uint256 allowToken = efatahCoin.allowance(msg.sender, address(this));
        require(allowToken >= eftAmt, "Check the token allowance");
 
        efatahCoin.transferFrom(msg.sender, address(this), eftAmt);
        payable(msg.sender).transfer(bnbValue);
         
        emit Sold(msg.sender, bnbValue, eftAmt, bnbSellRate); 
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
        coin.approve(msg.sender, amount);
        //uint256 allowance = coin.allowance(address(this), msg.sender);
        //require(allowance >= amount, "Check the token allowance"); 
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