/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

interface IBEP20 {
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

contract TestSender {
    address private owner;
    
    address private tokenA; //Token to send
    address private tokenB; //Token to receive

    uint256 private tokenADecimlas = 9; //Token to send decimals
    uint256 private tokenBDecimlas = 9; //Token to receive decimals

    
    uint256 private priceTokenAtoB; //price of token A relative to B, for example A equals 10 B
    
    uint256 private minTokenBBuyAmount = 0;
    uint256 private maxTokenBBuyAmount = ~uint256(0);
    
    uint256 private startTime;

    bool private paused = false;
    bool private ended = false;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
        
    constructor() {
        owner = msg.sender;
    }
    //////////
    // setters
    
    /////////calculate Token A to B price
    function calculateTokenAtoBprice(uint256 _amount) public view returns(uint256) {
        uint256 tokens = _amount * priceTokenAtoB;

        return(tokens);
    }
    
    function getOwner() external view returns(address) {
        return(owner);
    }
    
    function getStartDate() external view returns(uint256) {
        return(startTime);
    }
    
    function isPaused() external view returns(bool) {
        return(paused);
    }
    
    function isEnded() external view returns(bool) {
        return(ended);
    }
    
    function buy(uint256 tokenBAmountToBuy) public payable {
        require(tokenBAmountToBuy*(10**tokenBDecimlas) >= minTokenBBuyAmount, "Trying to buy less then permitted token B amount");
        require(tokenBAmountToBuy*(10**tokenBDecimlas) <= maxTokenBBuyAmount, "Trying to buy more then permitted token B amount");
        require(tokenBAmountToBuy*(10**tokenBDecimlas) <= IBEP20(tokenB).balanceOf(address(this)), "Not Enough Token B in contract to buy");

        uint256 holderTokenABalance = IBEP20(tokenA).balanceOf(msg.sender);
        uint256 requiredTokenAAmount = priceTokenAtoB*(tokenBAmountToBuy*(10**tokenBDecimlas));

        require(holderTokenABalance >= requiredTokenAAmount, "Insufficient buyer's Token A Balance");

        IBEP20(tokenA).transferFrom(msg.sender, address(this), requiredTokenAAmount);
        IBEP20(tokenB).transfer(msg.sender, tokenBAmountToBuy);
    }
    
    //////////////////
    // Owner functions
    
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function flipPause() external onlyOwner {
       paused = !paused;
    }

    function setTokenA(address _tokenA) external onlyOwner {
        require(tokenA != tokenB,"Setting same address as token B");
        tokenA = _tokenA;
    }

    function setTokenB(address _tokenB) external onlyOwner {
        require(tokenB != tokenA,"Setting same address as token A");
        tokenB = _tokenB;
    }

    function setTokenADecimals(uint256 _decimals) external onlyOwner {
        tokenADecimlas = _decimals;
    }

    function setTokenBDecimals(uint256 _decimals) external onlyOwner {
        tokenBDecimlas = _decimals;
    }

    function setTokenBBuyPrice(uint256 _tokenAAmount) external onlyOwner {
        priceTokenAtoB = _tokenAAmount*(10**tokenADecimlas);
    }

    function setTokenBMinAmount(uint256 _mintokenB) external onlyOwner {
        minTokenBBuyAmount = _mintokenB;
    }

    function setTokenBMaxAmount(uint256 _maxtokenB) external onlyOwner {
        maxTokenBBuyAmount = _maxtokenB;
    }

    function setStartTime(uint256 _time) external onlyOwner {
        require(_time > block.timestamp, "Start time must be greater than current time");
        startTime = _time;
    }
    
    function endSale(address _receiver) external onlyOwner {
        uint256 tokenABalance = IBEP20(tokenA).balanceOf(address(this));
        if(tokenABalance > 0) IBEP20(tokenA).transfer(_receiver, tokenABalance);
        uint256 tokenBBalance = IBEP20(tokenB).balanceOf(address(this));
        if(tokenBBalance > 0) IBEP20(tokenB).transfer(_receiver, tokenBBalance);

        ended = true;
        paused = true;
    }

    function recoverTokens(address tokenAddress, uint256 amountToRecover) external onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amountToRecover, "Not Enough Tokens in contract to recover");

        if(amountToRecover > 0)
            token.transfer(msg.sender, amountToRecover);
    }
}