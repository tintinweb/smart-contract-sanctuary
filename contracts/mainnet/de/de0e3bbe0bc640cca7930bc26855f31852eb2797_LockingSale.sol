pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

import './Owned.sol';
import './CUB.sol';

contract LockingSale is Owned {
    
    ERCToken token;
    enum State {_OPEN, _CLOSE, _UNLOCKED}
    
    State saleState = State._CLOSE;
    
    mapping(address => uint256) public tokenAllocation;
    mapping(uint256 => address) public users;
    uint256 totalUsers;
    uint256 public totalTokens;
    
    event TokensAllocated(uint256 tokens, address purchaser);
    event TokensUnlocked();
    
    constructor(address payable _owner, address _tokenAddress) public{
        owner = _owner; 
        token = ERCToken(_tokenAddress);
    }
    
    function startSale() external onlyOwner{
        require(token.balanceOf(address(this)) > 0, "tokens: Insufficient token balance of the contract");
        require(saleState == State._CLOSE, "sale state: the sale is open already");
        
        totalTokens = token.balanceOf(address(this));
        saleState = State._OPEN; // open sale but tokens are locked
    }
    
    function endSale() external onlyOwner{
        require(saleState == State._OPEN, "sale state: sale is closed already");
        
        saleState = State._CLOSE;
        
        if(totalTokens > 0){
            token.transfer(owner, totalTokens);
            totalTokens = 0;
        }
        
        owner.transfer(address(this).balance); // send all collected funds to the owner
    }
    
    function unlockTokens() external onlyOwner{
        require(saleState == State._CLOSE, "sale state: sale is open");
        saleState = State._UNLOCKED;
        sendTokens();
        emit TokensUnlocked();
    }
    
    
    function sendTokens() internal{
        for(uint256 i = 1; i<= totalUsers; i++){
            address _to = users[i];
            token.transfer(_to, tokenAllocation[_to]); // transfer tokens to the users
            tokenAllocation[_to] = 0;
        }
        
    }
    
    // receive ethers
    fallback() external payable{
        purchase();
    }
    
    // receive ethers with data 
    receive() external payable{
        purchase();
    }
    
    function purchase() internal {
        require(saleState == State._OPEN, "sale state: sale is not open");
        require(msg.value >= 0.5 ether && msg.value <= 10 ether, "investment: purchase amount is not within limits");
        require(totalTokens >= calculateTokens(), "tokens: Insufficient token balance of the contract, try with lower amount");
        tokenAllocation[msg.sender] += calculateTokens();
        totalTokens -= calculateTokens();
        totalUsers++;
        users[totalUsers] = msg.sender;
        emit TokensAllocated(calculateTokens(), msg.sender);
    }
    function calculateTokens() internal returns(uint256 _tokens){
        /* Calculations
        
           1 eth = 2000 cub tokens 
           1 * 10^18 = 2000 * 10 ^ 18 
           cancelling 10^18 on b.sides 
           1 wei = 2000 cub parts
           
        */
        
        return msg.value * (2000); 
    }
}