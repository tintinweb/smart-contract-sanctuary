/**
 *Submitted for verification at BscScan.com on 2021-07-09
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

contract Launchpad {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint priceOfBNB = priceConsumerV3.getThePrice();
    
    address public owner = msg.sender;
    uint startTime = 0;
    address contractAddr = address(this);
    address tokenAddr = 0x2C14479B25eCAF9c553164A95F1E1221Ca18f929;
    
    struct Buyer{
        uint[] bought;
        uint[] buyAt;
        uint[] claimed;
        uint[] claimLeft;
        uint[] buyPrice;
        uint[] halfOfBuy;
    }
    
    struct Claim{
        bool[] firstClaim;
        bool[] secondClaim;
        bool[] thirdClaim;
        bool[] fourthClaim;
        bool[] fifthClaim;
        uint[] show;
        uint[] showDates;
    }
    
    mapping(address => Buyer) buyer;
    mapping(address => Claim) claim;
    
    uint tokenR1 = 125000 * 10**18;
    uint tokenR2 = 125000 * 10**18;
    uint tokenR3 = 350000 * 10**18;
    
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    event Received(address, uint);
    
    // Presale: 3 Rounds //
    // Seed Round : 50% + 10% weekly
    // Private Round : 80% + 10% weekly
    // Public Round : No vesting
    
    function buyToken() public payable returns (bool) {
        
        uint amount = msg.value * priceOfBNB / 10000;
        uint buyPrice;
        
        BEP20 token = BEP20(tokenAddr);
        require(token.balanceOf(contractAddr) > 0, "Not enough balance on contract");
        require(msg.value > 0, "Zero value");
        require(startTime != 0, "Start time not set");
        
        uint tokens;
        
        if(block.timestamp - startTime <= 60 minutes){
            buyPrice = 11;
        }
        
        if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
            buyPrice = 16;
        }
        
        if(block.timestamp - startTime > 120 minutes){
            buyPrice = 19;
        }
        
        tokens = amount / buyPrice / 100;
        
        if(buyPrice == 11){
            require(tokenR1 >= tokens, "Round 1 tokens sold");
            buyer[msg.sender].bought.push(tokens);
            uint t = block.timestamp;
            uint tokensToSend = tokens / 2;
            uint weeklyTokens = (tokens - tokensToSend) / 5;
            token.transfer(msg.sender, tokensToSend);
            buyer[msg.sender].buyAt.push(t);
            buyer[msg.sender].claimed.push(0);
            uint claimLeft = tokens - tokensToSend;
            buyer[msg.sender].claimLeft.push(claimLeft);
            buyer[msg.sender].halfOfBuy.push(claimLeft);
            buyer[msg.sender].buyPrice.push(buyPrice);
            claim[msg.sender].firstClaim.push(false);
            claim[msg.sender].secondClaim.push(false);
            claim[msg.sender].thirdClaim.push(false);
            claim[msg.sender].fourthClaim.push(false);
            claim[msg.sender].fifthClaim.push(false);
            claim[msg.sender].show.push(tokensToSend);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].showDates.push(t);
            claim[msg.sender].showDates.push(t + 3600);
            claim[msg.sender].showDates.push(t + 7200);
            claim[msg.sender].showDates.push(t + 10800);
            claim[msg.sender].showDates.push(t + 14400);
            claim[msg.sender].showDates.push(t + 18000);
            tokenR1 -= tokens;
        }
        
        if(buyPrice == 16){
            require(tokenR2 >= tokens, "Round 2 tokens sold");
            buyer[msg.sender].bought.push(tokens);
            uint tokensToSend = tokens * 80 / 100;
            uint t = block.timestamp;
            uint weeklyTokens = (tokens - tokensToSend) / 2;
            token.transfer(msg.sender, tokensToSend);
            buyer[msg.sender].buyAt.push(t);
            buyer[msg.sender].claimed.push(0);
            uint claimLeft = tokens - tokensToSend;
            buyer[msg.sender].claimLeft.push(claimLeft);
            buyer[msg.sender].halfOfBuy.push(claimLeft);
            buyer[msg.sender].buyPrice.push(buyPrice);
            claim[msg.sender].firstClaim.push(false);
            claim[msg.sender].secondClaim.push(false);
            claim[msg.sender].thirdClaim.push(false);
            claim[msg.sender].fourthClaim.push(false);
            claim[msg.sender].fifthClaim.push(false);
            claim[msg.sender].show.push(tokensToSend);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].show.push(weeklyTokens);
            claim[msg.sender].showDates.push(t);
            claim[msg.sender].showDates.push(t + 3600);
            claim[msg.sender].showDates.push(t + 7200);
            tokenR2 -= tokens;
        }
        
        if(buyPrice == 19){
            require(tokenR3 >= tokens, "Round 3 tokens sold");
            token.transfer(msg.sender, tokens);
            uint t = block.timestamp;
            buyer[msg.sender].bought.push(tokens);
            buyer[msg.sender].buyAt.push(t);
            buyer[msg.sender].claimed.push(0);
            buyer[msg.sender].claimed.push(tokens);
            buyer[msg.sender].claimLeft.push(0);
            buyer[msg.sender].halfOfBuy.push(0);
            buyer[msg.sender].buyPrice.push(buyPrice);
            claim[msg.sender].firstClaim.push(false);
            claim[msg.sender].secondClaim.push(false);
            claim[msg.sender].thirdClaim.push(false);
            claim[msg.sender].fourthClaim.push(false);
            claim[msg.sender].fifthClaim.push(false);
            claim[msg.sender].show.push(tokens);
            claim[msg.sender].showDates.push(t);
            tokenR3 -= tokens;
        }
        
        emit TokensBought(msg.sender, tokens);
        return true;
    }
    
    // Claim tokens weekly //
    
    function firstWeekClaim() public returns (bool) {
        
        BEP20 token = BEP20(tokenAddr);
        
        for(uint a = 0; a < buyer[msg.sender].buyPrice.length; a++){
            
            if(buyer[msg.sender].buyPrice[a] == 11){
            
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint firstClaim = buyer[msg.sender].halfOfBuy[i] / 5;
                    require(timediff >= 60 minutes, "Claim time not reached");
                    require(claim[msg.sender].firstClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, firstClaim);
                    buyer[msg.sender].claimed[i] += firstClaim;
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - firstClaim;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].firstClaim[i] = true;
                } 
            }
        
            if(buyer[msg.sender].buyPrice[a] == 16){
                
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint firstClaim = buyer[msg.sender].halfOfBuy[i] / 2;
                    require(timediff >= 60 minutes, "Claim time not reached");
                    require(claim[msg.sender].firstClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, firstClaim);
                    buyer[msg.sender].claimed[i] += firstClaim;
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - firstClaim;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].firstClaim[i] = true;
                }
            }
        }
        
        return true;
    }
    
    function secondWeekClaim() public returns (bool) {
        
        BEP20 token = BEP20(tokenAddr);
        
        for(uint a = 0; a < buyer[msg.sender].buyPrice.length; a++){
            
            if(buyer[msg.sender].buyPrice[a] == 11){
            
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint secondClaim = buyer[msg.sender].halfOfBuy[i] / 5;
                    require(timediff >= 120 minutes, "Claim time not reached");
                    require(claim[msg.sender].secondClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, secondClaim);
                    buyer[msg.sender].claimed[i] += secondClaim;
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - secondClaim;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].secondClaim[i] = true;
                }
            }
            
            if(buyer[msg.sender].buyPrice[a] == 16){
                
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint secondClaim = buyer[msg.sender].halfOfBuy[i] / 2;
                    require(timediff >= 120 minutes, "Claim time not reached");
                    require(claim[msg.sender].secondClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, secondClaim);
                    buyer[msg.sender].claimed[i] += secondClaim;
                    uint furtherClaimLeft = 0;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].secondClaim[i] = true;
                }
            }
        }
        
        return true;
    }
    
    function thirdWeekClaim() public returns (bool) {
        
        BEP20 token = BEP20(tokenAddr);
        
        for(uint a = 0; a < buyer[msg.sender].buyPrice.length; a++){
            
            if(buyer[msg.sender].buyPrice[a] == 11){
            
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint thirdClaim = buyer[msg.sender].halfOfBuy[i] / 5;
                    require(timediff >= 180 minutes, "Claim time not reached");
                    require(claim[msg.sender].thirdClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, thirdClaim);
                    buyer[msg.sender].claimed[i] += thirdClaim;
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - thirdClaim;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].thirdClaim[i] = true;
                }
            }
        }
        
        return true;
    }
    
    function fourthWeekClaim() public returns (bool) {
        
        BEP20 token = BEP20(tokenAddr); 
        
        for(uint a = 0; a < buyer[msg.sender].buyPrice.length; a++){
            
            if(buyer[msg.sender].buyPrice[a] == 11){
            
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint fourthClaim = buyer[msg.sender].halfOfBuy[i] / 5;
                    require(timediff >= 240 minutes, "Claim time not reached");
                    require(claim[msg.sender].fourthClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, fourthClaim);
                    buyer[msg.sender].claimed[i] += fourthClaim;
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - fourthClaim;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].fourthClaim[i] = true;
                }
            }
        }
        
        return true;
    }
    
    function fifthWeekClaim() public returns (bool) {
        
        BEP20 token = BEP20(tokenAddr);
        
        for(uint a = 0; a < buyer[msg.sender].buyPrice.length; a++){
            
            if(buyer[msg.sender].buyPrice[a] == 11){
            
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint fifthClaim = buyer[msg.sender].halfOfBuy[i] / 5;
                    require(timediff >= 300 minutes, "Claim time not reached");
                    require(claim[msg.sender].fifthClaim[i] == false, "Already Claimed");
                    token.transfer(msg.sender, fifthClaim);
                    buyer[msg.sender].claimed[i] += fifthClaim;
                    uint furtherClaimLeft = 0;
                    buyer[msg.sender].claimLeft[i] = furtherClaimLeft;
                    claim[msg.sender].fifthClaim[i] = true;
                }
            }
        }
        
        return true;
    }
    
    // Set Start Time
    function setStartTime() public returns (bool) {
        require(msg.sender == owner, "Only Owner");
        startTime = block.timestamp;
        return true;
    }
        
    // View Buy Price
    function viewPrice() public view returns(uint){
        
        uint price;
        
        if(startTime == 0){
            price = 0;
        }
        
        else{
            
            if(block.timestamp - startTime <= 60 minutes){
            price = 11;
            }
            
            if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
                price = 16;
            }
            
            if(block.timestamp - startTime > 120 minutes){
                price = 19;
            }
        }
        
        return price;
    }
    
    // Show Buyer Details
    function userDetails(address user) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory tokensBought = new uint[](buyer[user].bought.length);
        uint[] memory buyAt = new uint[](buyer[user].bought.length);
        uint[] memory claimed = new uint[](buyer[user].bought.length);
        uint[] memory claimLeft = new uint[](buyer[user].bought.length);
        uint[] memory buyPrice = new uint[](buyer[user].bought.length);
        
        for(uint i = 0; i < buyer[user].bought.length; i++){
            tokensBought[i] = buyer[user].bought[i];
            buyAt[i] = buyer[user].buyAt[i];
            claimed[i] = buyer[user].claimed[i];
            claimLeft[i] = buyer[user].claimLeft[i];
            buyPrice[i] = buyer[user].buyPrice[i];
        }
        
        return(tokensBought, buyAt, claimed, claimLeft, buyPrice);
    }
    
    // Show Claim Details
    function claimDetails(address user) public view returns (uint[] memory, uint[] memory) {
        uint a;
        
        for(uint i = 0; i < buyer[user].bought.length; i++){
            
            if(buyer[user].buyPrice[i] == 11){
                a = 6;
            }
            else if(buyer[user].buyPrice[i] == 16){
                a = 3;
            }
            else if(buyer[user].buyPrice[i] == 19){
                a = 1;
            }
        }
        
        uint[] memory tokens = new uint[](a);
        uint[] memory dates = new uint[](a);
        
        for(a = 0; a < buyer[user].bought.length; a++){
            tokens[a] = claim[user].show[a];
        }
        
        return(tokens, dates);
    }
    
    // Show Cap limit
    function capLimit() public view returns (uint) {
        uint caplimit;
        if(startTime == 0){
            caplimit = 0;
        }
        
        else{
            
            if(block.timestamp - startTime <= 60 minutes){
                caplimit = 125000;
            }
            
            if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
                caplimit = 125000;
            }
            
            if(block.timestamp - startTime > 120 minutes){
                caplimit = 350000;
            }
        }
        return caplimit;
    }
    
    // Show Round Name
    function roundName() public view returns (string memory) {
        string memory round;
        if(startTime == 0){
            round = "Not Active";
        }
        
        else{
            
            if(block.timestamp - startTime <= 60 minutes){
                round = "Seed";
            }
            
            if(block.timestamp - startTime > 60 minutes && block.timestamp - startTime <= 120 minutes){
                round = "Private";
            }
            
            if(block.timestamp - startTime > 120 minutes){
                round = "Public";
            }
        }
        return round;
    }
    
    // Show USD Price of BNB
    function usdPrice(uint value) external view returns(uint) {
        uint Amount = value * priceOfBNB;
        return Amount/100000000;
    }
    
    // Ownership transfer
    function transferOwnership(address user) public returns (bool) {
        require(msg.sender == owner, "Only Owner");
        owner = user;
        emit OwnershipTransferred(user);
        return true;
    }
    
    // Owner BNB Withdraw
    function withdrawBNB(address payable to, uint amount) public returns (bool) {
        require(msg.sender == owner, "Only Owner");
        to.transfer(amount);
        return true;
    }
    
    // Owner Token Withdraw
    function withdrawToken(address tokenAddress, address payable to, uint amount) public returns (bool) {
        require(msg.sender == owner, "Only Owner");
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
}