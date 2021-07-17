/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Gut3hot {
    address private owner;
    
    address private tokenX;
    address private tokenY;
    
    uint256 private price;
    uint256 private minTokenYHoldAmount;
    
    uint256 private minBNB;
    uint256 private maxBNB;
    
    uint256 private startDate;
    bool private paused = false;
    bool private ended = false;
        
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
        
    constructor(address _tokenX, address _tokenY, uint256 _price, uint256 _minTokenYHoldAmount, uint256 _startDate, uint256 _minBNB, uint256 _maxBNB) {
        require(_startDate > block.timestamp, "_startDate has to be greater than block.timestamp");
        
        owner = msg.sender;
        
        tokenX = _tokenX;
        tokenY = _tokenY;
        price = _price;
        minTokenYHoldAmount = _minTokenYHoldAmount;
        startDate = _startDate;
        minBNB = _minBNB;
        maxBNB = _maxBNB;
    }
    
    //////////
    // Getters
    function calculateBNBToTokenX(uint256 _amount) public view returns(uint256) {
        uint256 tokens = _amount / price;
        
        return(tokens);
    }
    
    function getOwner() external view returns(address) {
        return(owner);
    }
    
    function getTokenX() external view returns(address) {
        return(tokenX);
    }
    
    function getTokenY() external view returns(address) {
        return(tokenY);
    }
    
    function getPrice() external view returns(uint256) {
        return(price);
    }
    
    function getMinTokenYHoldAmount() external view returns(uint256) {
        return(minTokenYHoldAmount);
    }
    
    function getMinBNB() external view returns(uint256) {
        return(minBNB);
    }
    
    function getMaxBNB() external view returns(uint256) {
        return(maxBNB);
    }
    
    function getStartDate() external view returns(uint256) {
        return(startDate);
    }
    
    function isPaused() external view returns(bool) {
        return(paused);
    }
    
    function isEnded() external view returns(bool) {
        return(ended);
    }
    
    /////////////
    // Buy tokens
    
    receive() external payable {
        buy();
    }
    
    function buy() public payable {
        require(block.timestamp > startDate, "Sale hasn't started yet");
        require(!paused, "Paused");
        require(!ended, "Ended");
        require(IERC20(tokenY).balanceOf(msg.sender) >= minTokenYHoldAmount, "msg.sender doesn't hold enough Token Y");
        require(msg.value < minBNB, "msg.value is less than minBNB");
        require(msg.value > maxBNB, "msg.value is great than maxBNB");
        
        uint256 amount = calculateBNBToTokenX(msg.value);
        
        IERC20(tokenX).transfer(msg.sender, amount);
    }
    
    //////////////////
    // Owner functions
    
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    function withdrawBNB(uint256 _amount, address _receiver) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }
    
    function setTokenX(address _tokenX) external onlyOwner {   
        tokenX = _tokenX;
    }
    
    function setTokenY(address _tokenY) external onlyOwner {   
        tokenY = _tokenY;
    }
    
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    
    function setMinTokenYHoldAmount(uint256 _minTokenYHoldAmount) external onlyOwner {
        minTokenYHoldAmount = _minTokenYHoldAmount;
    }
    
    function setMinBNB(uint256 _minBNB) external onlyOwner {
        minBNB = _minBNB;
    }
    
    function setMaxBNB(uint256 _maxBNB) external onlyOwner {
        maxBNB = _maxBNB;
    }
    
    function setPause() external onlyOwner {
       if(paused) {
           paused = false;
       } else {
           paused = true;
       }
    }
    
    function endSale(address _receiver) external onlyOwner {
        IERC20(tokenX).transfer(_receiver, IERC20(tokenX).balanceOf(address(this)));
        
        ended = true;
        paused = true;
    }
    
    function reset(address _tokenX, address _tokenY, uint256 _price, uint256 _minTokenYHoldAmount, uint256 _startDate, uint256 _minBNB, uint256 _maxBNB) external onlyOwner
    {
        require(_startDate > block.timestamp, "_startDate has to be greater than block.timestamp");
        require(ended, "end the sale first");
        
        ended = false;
        paused = false;
        tokenX = _tokenX;
        tokenY = _tokenY;
        price = _price;
        minTokenYHoldAmount = _minTokenYHoldAmount;
        startDate = _startDate;
        minBNB = _minBNB;
        maxBNB = _maxBNB;
    }
}