/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.5;

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

contract TestSender {
    address private owner;
    
    address private presaleToken;
    address private houseToken;
    
    uint256 private price; // For 1 token
    uint256 private minHouseTokenHoldAmount;
    
    address private tokenA; //Token to receive
    address private tokenB; //Token to swap for Token A
    
    uint256 private pricetokenAtoB; //price of token A relative to B, for example A equals 10 B
    uint256 private minamountTokenA;
    uint256 private maxamountTokenA;
    
    uint256 private minBNB;
    uint256 private maxBNB;
    uint256 private startDate;

    bool private paused = false;
    bool private ended = false;
    bool public enabledWhitelistPurchase = false;

    mapping(address => bool) public whitelisted;
        
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
        
    constructor(address _presaleToken, address _houseToken, uint256 _price, uint256 _minHouseTokenHoldAmount, uint256 _startDate, uint256 _minBNB, uint256 _maxBNB) {
        require(_startDate >= block.timestamp, "_startDate has to be greater than block.timestamp");
        
        owner = msg.sender;
        
        presaleToken = _presaleToken;
        houseToken = _houseToken;
        price = _price;
        minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
        startDate = _startDate;
        minBNB = _minBNB;
        maxBNB = _maxBNB;
    }
    //////////
    // setters
    
    function settokenABvalues(address _tokenA, address _tokenB, uint256 _pricetokenAtoB, uint256 _mintokenA, uint256 _maxtokenA) external onlyOwner {
        tokenA = _tokenA;
        tokenB = _tokenB;
        pricetokenAtoB = _pricetokenAtoB; 
        minamountTokenA = _mintokenA;
        maxamountTokenA = _maxtokenA;
    }
    
    //////////
    // Getters
    function calculateBNBToPresaleToken(uint256 _amount) public view returns(uint256) {
        uint256 tokens = _amount / price * (10 ** uint256(IERC20(presaleToken).decimals()));

        return(tokens);
    }
    
    
    /////////calculate Token A to B price
    function calculateTokenAtoBprice(uint256 _amount) public view returns(uint256) {
        uint256 tokens = _amount * pricetokenAtoB;

        return(tokens);
    }
    
    function getOwner() external view returns(address) {
        return(owner);
    }
    
    function getPresaleToken() external view returns(address) {
        return(presaleToken);
    }
    
    function getHouseToken() external view returns(address) {
        return(houseToken);
    }
    
    function getPrice() external view returns(uint256) {
        return(price);
    }
    
    function getMinHouseTokenHoldAmount() external view returns(uint256) {
        return(minHouseTokenHoldAmount);
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
        if(enabledWhitelistPurchase)
            require(whitelisted[msg.sender],"Only whitelisted addresses can purchase tokens");
        require(IERC20(houseToken).balanceOf(msg.sender) >= minHouseTokenHoldAmount, "msg.sender doesn't hold enough house tokens");
        require(msg.value >= minBNB, "msg.value is less than minBNB");
        require(msg.value <= maxBNB, "msg.value is great than maxBNB");
        
        uint256 amount = calculateBNBToPresaleToken(msg.value);
        
        IERC20(presaleToken).transfer(msg.sender, amount);
    }
    
    ////////Token Swap Function
    function swaptokens() public payable {
        require(whitelisted[msg.sender],"Only whitelisted addresses can purchase tokens");
        //require(IERC20(houseToken).balanceOf(msg.sender) >= minHouseTokenHoldAmount, "msg.sender doesn't hold enough house tokens");
        require(msg.value >= minamountTokenA, "msg.value is less than minamountTokenA");
        require(msg.value <= maxamountTokenA, "msg.value is great than maxamountTokenA");
        
        uint256 amount = calculateTokenAtoBprice(msg.value);
        
        IERC20(tokenB).transfer(msg.sender, amount);
    }
    
    //////////////////
    // Owner functions
    
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    function withdrawBNB(uint256 _amount, address _receiver) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }
    
    function setPresaleToken(address _presaleToken, address _receiver) external onlyOwner {   
        uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
        if(contractBal > 0) IERC20(presaleToken).transfer(_receiver, contractBal);
        
        presaleToken = _presaleToken;
    }
    
    function setHouseToken(address _houseToken) external onlyOwner {   
        houseToken = _houseToken;
    }
    
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    
    function setMinHouseTokenHoldAmount(uint256 _minHouseTokenHoldAmount) external onlyOwner {
        minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
    }
    
    function setMinBNB(uint256 _minBNB) external onlyOwner {
        minBNB = _minBNB;
    }
    
    function setMaxBNB(uint256 _maxBNB) external onlyOwner {
        maxBNB = _maxBNB;
    }

    function whitelistSingleAddress(address wallet) external onlyOwner {
        whitelisted[wallet] = true;
    }

    function unWhitelistSingleAddress(address wallet) external onlyOwner {
        whitelisted[wallet] = false;
    }

    function whitelistMultipleAddresses(address[] calldata wallets) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++)
            whitelisted[wallets[i]] = true;
    }

    function unWhitelistMultipleAddresses(address[] calldata wallets) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++)
            whitelisted[wallets[i]] = false;
    }

    function setWhitelistPurchase(bool enable) external onlyOwner {
        enabledWhitelistPurchase = enable;
    }
    
    function setPause() external onlyOwner {
       if(paused) {
           paused = false;
       } else {
           paused = true;
       }
    }
    
    function endSale(address _receiver) external onlyOwner {
        uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
        if(contractBal > 0) IERC20(presaleToken).transfer(_receiver, contractBal);

        ended = true;
        paused = true;
    }
    
    function reset(address _presaleToken, address _houseToken, uint256 _price, uint256 _minHouseTokenHoldAmount, uint256 _startDate, uint256 _minBNB, uint256 _maxBNB) external onlyOwner
    {
        require(_startDate > block.timestamp, "_startDate has to be greater than block.timestamp");
        require(ended, "end the sale first");
        
        ended = false;
        paused = false;
        presaleToken = _presaleToken;
        houseToken = _houseToken;
        price = _price;
        minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
        startDate = _startDate;
        minBNB = _minBNB;
        maxBNB = _maxBNB;
    }
}