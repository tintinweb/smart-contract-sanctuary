/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EfatahExchange {  

    using SafeMath for uint256;
    
    address payable private _owner;  
    address private _contractAddr; 
    IERC20 private efatahCoin;
    uint256 private efaBuyRateCheck = 830000000;   
     
    modifier ownerOnly() {
        require(msg.sender == _owner);
        _;
    }

    event sendTokenEvent(uint256 efa, uint256 bnb, uint256 balance, bool isTransferred);  
    event Received(address sender, uint256 amount);
    event Withdrawn(uint256 amount); 

    constructor(address payable addr, address cAddr) {
        _owner = addr; 
        _contractAddr = cAddr;
        efatahCoin = IERC20(cAddr); 
    }
    
    
    function getInfo() public view returns (address ownerAddr, address contractAddr, 
                    uint256 balanceToken, uint256 efaBuyMinCheck) { 
        return(_owner, _contractAddr, efatahCoin.balanceOf(msg.sender), efaBuyRateCheck);
    }
      
    function setContractAddress(address cAddr) external ownerOnly {
        _contractAddr = cAddr;
        efatahCoin = IERC20(cAddr); 
    }

    function setEfaMinCheck(uint256 minBuyCheck) external ownerOnly {
        efaBuyRateCheck = minBuyCheck; 
    }
    
    function setOwner(address payable addr) external ownerOnly {
        _owner = addr;
    }
    
     
    function buyToken(uint256 efa) payable public {  
         //require(msg.value.div(efa) >= efaBuyRateCheck, "BNB required");
         _owner.transfer(msg.value);
         uint256 tokenBalance = efatahCoin.balanceOf(address(this)); 
         bool ans = efatahCoin.transfer(msg.sender, efa);
         emit sendTokenEvent(efa, msg.value, tokenBalance, ans);
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
    function withdrawToken(address contractAddress, uint256 token) external payable ownerOnly {
        IERC20 coin = IERC20(contractAddress); 
        require(coin.balanceOf(address(this)) >= token, "Check the token to withdraw");
        coin.approve(msg.sender, token);
        //coin.allowance(address(this), msg.sender); 
        coin.transfer(msg.sender, token); 
         
        emit Withdrawn(token);
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}