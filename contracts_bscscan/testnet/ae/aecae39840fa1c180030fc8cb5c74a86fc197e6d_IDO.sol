/**
 *Submitted for verification at BscScan.com on 2021-07-08
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

contract IDO {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint priceOfBNB = priceConsumerV3.getThePrice();
    
    struct Buyer{
        address referer;
        uint tokensBought;
        bool registered;
    }
    
    struct Scratch{
        uint[] tokenAmt;
        uint[] buyAt;
        bool claimed;
    }
    
    address public owner = msg.sender;
    address private tokenAddr = 0xDFD7bD57a90793be53ae214b74b30e0ac7D1e962;
    address private contractAddr = address(this);
    uint buyPrice;
    mapping(address => Buyer) buyer;
    mapping(address => Scratch) scratch;
    uint startTime = 0;
    uint public claimAmount = 10 * 10000 * 10**18;
    
    event Received(address, uint);
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    
    // Set Start Time
    function setStartTime() public {
        require(msg.sender == owner);
        startTime = block.timestamp;
    }
    
    // BUY TOKEN & Referral Reward
    function buyToken(address referer) public payable returns(bool) {
        
        uint amount = msg.value * priceOfBNB / 10000;
        buyPrice = buyPrice;
        
        BEP20 token = BEP20(tokenAddr);
        
        require(startTime > 0, "Start time not defined");
        require(token.balanceOf(contractAddr) > 0, "Not enough balance on contract");
        require(msg.value > 0, "Zero value");
        
        uint tokens;
        uint bonus;
        uint bonusPercent;
        
        if(block.timestamp - startTime <= 60 minutes){
            buyPrice = 50;
            bonusPercent = 10;
        }
        
        if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
            buyPrice = 75;
            bonusPercent = 7;
        }
        
        if(block.timestamp - startTime > 120 minutes && block.timestamp - startTime <= 180 minutes){
            buyPrice = 95;
            bonusPercent = 5;
        }
        
        if(block.timestamp - startTime > 180 minutes && block.timestamp - startTime <= 240 minutes){
            buyPrice = 295;
            bonusPercent = 0;
        }
        
        if(block.timestamp - startTime > 240 minutes){
            buyPrice = 495;
            bonusPercent = 0;
        }
        
        tokens = amount / buyPrice / 100;
        token.transfer(msg.sender, tokens);
        
        if(bonusPercent == 0){
            bonus = 0;
        }
        else if(bonusPercent != 0){
            bonus = tokens * bonusPercent / 100;
            token.transfer(msg.sender, bonus);
        }
        
        refReward(referer, tokens);

        buyer[msg.sender].tokensBought += tokens;
        buyer[msg.sender].registered = true;
        
        scratch[msg.sender].tokenAmt.push(tokens);
        scratch[msg.sender].buyAt.push(block.timestamp);
        scratch[msg.sender].claimed = false;
        
        emit TokensBought(msg.sender, tokens);
        return true;
    }
    
    // Referral Reward
    function refReward(address _ref, uint _amt) internal {
        
        uint referralReward;
        BEP20 token = BEP20(tokenAddr);
        
        if(!buyer[_ref].registered){
            referralReward = 0;
        }
        else{
            referralReward = _amt * 5 / 100;
            token.transfer(_ref, referralReward);
        }
    }
    
    // View Buy Price
    function viewPrice() public view returns(uint){
        
        uint price;
        
        if(startTime == 0){
            price = 0;
        }
        
        else{
            
            if(block.timestamp - startTime <= 60 minutes){
            price = 50;
            }
            
            if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
                price = 75;
            }
            
            if(block.timestamp - startTime > 120 minutes && block.timestamp - startTime <= 180 minutes){
                price = 95;
            }
            
            if(block.timestamp - startTime > 180 minutes && block.timestamp - startTime <= 240 minutes){
                price = 295;
            }
            
            if(block.timestamp - startTime > 240 minutes){
                price = 495;
            }
        }
        
        return price;
    }
    
    // Claim Scratch Coupon tokens
    function claim() public returns (bool) {
        require(scratch[msg.sender].claimed == false, "User has already claimed tokens");
        require(claimAmount > 0, "All scratch tokens claimed");
        require(buyer[msg.sender].tokensBought > 20000000000000000000, "Not eligible for scratch");
        BEP20 token = BEP20(tokenAddr);
        token.transfer(msg.sender, 10000000000000000000);
        scratch[msg.sender].claimed = true;
        claimAmount -= 10000000000000000000;
        return true;
    }
    
    // Show Buyer Details
    function buyerDetails(address user) public view returns(bool, address, uint, uint[] memory, uint[] memory, bool){
        bool reg = buyer[user].registered;
        address referer = buyer[user].referer;
        uint totalTokensBought = buyer[user].tokensBought;
        uint[] memory tokensBought = new uint[](scratch[user].tokenAmt.length);
        uint[] memory buyTime = new uint[](scratch[user].tokenAmt.length);
        
        for(uint i = 0; i< scratch[user].tokenAmt.length; i++){
            tokensBought[i] = scratch[user].tokenAmt[i];
            buyTime[i] = scratch[user].buyAt[i];
        }
        
        bool claimStatus = scratch[user].claimed;
        
        return (reg, referer, totalTokensBought, tokensBought, buyTime, claimStatus);
    }
    
    // View Current Bonus
    function viewBonusPercent() public view returns (uint) {
        uint bonus;
        
        if(startTime == 0){
            bonus = 0;
        }
        
        else if(startTime != 0){
            if(block.timestamp - startTime <= 60 minutes){
                bonus = 10;
            }
            
            if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
                bonus = 7;
            }
            
            if(block.timestamp - startTime > 120 minutes && block.timestamp - startTime <= 180 minutes){
                bonus = 5;
            }
            
            if(block.timestamp - startTime > 180 minutes && block.timestamp - startTime <= 240 minutes){
                bonus = 0;
            }
            
            if(block.timestamp - startTime > 240 minutes){
                bonus = 0;
            }
        }
        
        return bonus;
    }
    
    // Show USD Price of 1 BNB
    function usdPrice(uint value) external view returns(uint) {
        uint Amount = value * priceOfBNB;
        return Amount/100000000;
    }
    
    // Owner Token Withdraw    
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer    
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner);
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}