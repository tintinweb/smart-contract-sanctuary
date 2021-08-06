/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }


    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

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

contract StakeAndBuy {
    
    /// Variables
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint priceOfBNB = priceConsumerV3.getThePrice();
    
    struct Buyer{
        uint totalTokensBought;
        uint[] tokensBought;
        uint[] buyTime;
    }
    
    struct Stake {
        bool staked;
        uint totalStaked;
        uint[] stakedAmounts;
        uint tier;
    }
    
    address public owner = msg.sender;
    address private stakeTokenAddr = 0x8691BB7E4f4d299716850bE908df9F8e002dED16;
    address private buyTokenAddr;
    address private contractAddr = address(this);
    mapping(address => Stake) public user;
    mapping(address => Buyer) public buyer;
    uint private buyPrice = 375;
    bool stakeStatus;
    bool public saleStatus;
    uint private maxPool = 100000 * 10**8; // in USD amount
    
    event Received(address, uint);
    event Staked(address, uint);
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets start and end time of stake 
     * 
     * Also sets default sale status to false
     * Sets token addresses for buy function
     */
    constructor(address buyTokenAddr_) {
        stakeStatus = true;
        saleStatus = false;
        buyTokenAddr = buyTokenAddr_;
    }
    
    /**
     * @dev Stake tokens on the contract
     * 
     * Requirements:
     * Minimum amount to stake is 650 tokens 
     * timestamp has to be between start and end time 
     */
    function stake(uint amount) public returns(bool) {
        
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
        
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        require(stakeStatus == true, "Staking disabled");
        require(amount >= 650 * 10**18, "Stake minimum 650 tokens");
        
        token.approve(contractAddr, amount);
        token.transferFrom(sender, contractAddr, amount);
        
        user[sender].staked = true;
        user[sender].totalStaked += amount;
        user[sender].stakedAmounts.push(amount);
        
        if(user[sender].totalStaked >= 650*10**18 && user[sender].totalStaked <= 3000*10**18) {
            user[sender].tier = 1;
        }
        
        else if(user[sender].totalStaked > 3000*10**18 && user[sender].totalStaked <= 10000*10**18) {
            user[sender].tier = 2;
        }
        
        else if(user[sender].totalStaked > 10000*10**18 && user[sender].totalStaked <= 30000*10**18) {
            user[sender].tier = 3;
        }
        
        else if(user[sender].totalStaked > 30000*18){
            user[sender].tier = 4;
        }
        
        emit Staked(sender, amount);
        return true;
    }
    
    /// Show Staking Details
    function stakingDetails(address addr) public view returns(bool, uint, uint[] memory){
        uint len = user[addr].stakedAmounts.length;
        bool staked = user[addr].staked;
        uint totalStake_ = user[addr].totalStaked;
        uint[] memory stakedAmount = new uint[](len);
        for(uint i = 0; i < len; i++){
            stakedAmount[i] = user[addr].stakedAmounts[i];
        }
        return (staked, totalStake_, stakedAmount);
    }
    
    /** 
     * @dev Change buy token address
     * 
     * Requirements:
     * Only owner can change the address
     */
    function changeBuyTokenAddress(address newAddr) public {
        require(msg.sender == owner, "Only owner");
        buyTokenAddr = newAddr;
        emit BuyTokenAddressChanged(newAddr);
    }
    
    /** 
     * @dev Change 'maxPool' size 
     * 
     * Requirements:
     * Only owner can call this function
     * Set amount according to 10**8 decimals(in USD)
     */
    function changeMaxPoolSize(uint amount) public {
        require(msg.sender == owner, "Only owner");
        maxPool = amount;
    }
    
    /**
     * @dev BUY TOKEN 
     * 
     * Requirements:
     * User has to stake first in order to buy
     * 'saleStatus' has to be true
     * 
     */
    function buyToken() public payable returns(bool) {
        
        address sender = msg.sender;
        uint amount = msg.value * priceOfBNB / 10000;
        uint usdAmount = msg.value * priceOfBNB;
        
        BEP20 token = BEP20(buyTokenAddr);
        
        require(maxPool >= usdAmount, "Pool limit reached");
        require(usdAmount >= 50*10**8 && usdAmount <= 500*10**8, "USD amount limit error");
        require(saleStatus == true, "Sale is not in progress");
        require(token.balanceOf(contractAddr) > 0, "Not enough balance on contract");
        require(msg.value > 0, "Zero value");
        
        uint tokens = amount / buyPrice / 10000;
        token.transfer(sender, tokens);
        
        maxPool = maxPool - usdAmount;
        
        buyer[sender].totalTokensBought += tokens;
        buyer[sender].tokensBought.push(tokens);
        buyer[sender].buyTime.push(block.timestamp);
        
        emit TokensBought(sender, tokens);
        return true;
    }
    
    /// Show Buyer Details
    function buyerDetails(address addr) public view returns(uint, uint[] memory, uint[] memory){
        uint len = buyer[addr].tokensBought.length;
        uint totalTokensBought = buyer[addr].totalTokensBought;
        uint[] memory tokensBought = new uint[](len);
        uint[] memory buyTime = new uint[](len);
        for(uint i = 0; i < len; i++){
            
        }
        return (totalTokensBought, tokensBought, buyTime);
    }
    
    /// User stake status 
    function userStakeStatus(address addr) public view returns (bool) {
        return user[addr].staked;
    }
    
    /** 
     * @dev Change sale status
     * 
     * Requirements:
     * Only owner can call this function
     */
    function setSaleStatus(bool status) public {
        require(msg.sender == owner, "Only owner");
        saleStatus = status;
    }
    
    /// Show USD Price of 'amount' number of BNB
    function usdPrice(uint amount) external view returns(uint) {
        uint bnbAmt = amount * priceOfBNB;
        return bnbAmt/100000000;
    }
    
    /** Owner Token Withdraw    
     * 
     * Requirements:
     * Only owner can call this function 
     */
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot withdraw to zero address");
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    /** Owner BNB Withdraw
     * 
     * Requirements:
     * Only owner can call this function
     */
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot withdraw to zero address");
        to.transfer(amount);
        return true;
    }
    
    /** 
     * @dev Ownership Transfer to "to" address
     * 
     * Requirements:
     * Only owner can call this function
     */
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    /// Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}