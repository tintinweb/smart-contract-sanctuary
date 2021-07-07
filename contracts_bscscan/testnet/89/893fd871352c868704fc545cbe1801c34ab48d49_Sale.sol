/**
 *Submitted for verification at BscScan.com on 2021-07-07
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

contract Sale {
    
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
    }
    mapping(address => Buyer) buyer;
    
    uint tokenR1 = 125000 * 10**18;
    uint tokenR2 = 125000 * 10**18;
    uint tokenR3 = 350000 * 10**18;
    
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    
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
        
        if(block.timestamp - startTime <= 5 minutes){
            buyPrice = 11;
        }
        
        if(block.timestamp - startTime > 5 minutes && block.timestamp - startTime <= 10 minutes){
            buyPrice = 16;
        }
        
        if(block.timestamp - startTime > 10 minutes && block.timestamp - startTime <= 15 minutes){
            buyPrice = 19;
        }
        
        if(block.timestamp - startTime > 15 minutes){
            buyPrice = 22;
        }
        
        tokens = amount / buyPrice / 100;
        
        if(buyPrice == 11){
            require(tokenR1 >= tokens, "Round 1 tokens sold");
            buyer[msg.sender].bought.push(tokens);
            uint tokensToSend = tokens / 2;
            token.transfer(msg.sender, tokensToSend);
            buyer[msg.sender].buyAt.push(block.timestamp);
            uint claimLeft = tokens - tokensToSend;
            buyer[msg.sender].claimLeft.push(claimLeft);
            buyer[msg.sender].buyPrice.push(buyPrice);
            tokenR1 -= tokens;
        }
        
        if(buyPrice == 16){
            require(tokenR2 >= tokens, "Round 2 tokens sold");
            buyer[msg.sender].bought.push(tokens);
            uint tokensToSend = tokens * 80 / 100;
            token.transfer(msg.sender, tokensToSend);
            buyer[msg.sender].buyAt.push(block.timestamp);
            uint claimLeft = tokens - tokensToSend;
            buyer[msg.sender].claimLeft.push(claimLeft);
            buyer[msg.sender].buyPrice.push(buyPrice);
            tokenR2 -= tokens;
        }
        
        if(buyPrice == 19){
            require(tokenR3 >= tokens, "Round 3 tokens sold");
            token.transfer(msg.sender, tokens);
            tokenR3 -= tokens;
        }
        
        if(buyPrice == 22){
            token.transfer(msg.sender, tokens);
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
                    uint firstClaim = buyer[msg.sender].claimLeft[i] / 5;
                    require(timediff >= 5 minutes, "Claim time not reached");
                    token.transfer(msg.sender, firstClaim);
                    buyer[msg.sender].claimed.push(firstClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - firstClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
                } 
            }
        
            if(buyer[msg.sender].buyPrice[a] == 16){
                
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint firstClaim = buyer[msg.sender].claimLeft[i] / 2;
                    require(timediff >= 5 minutes, "Claim time not reached");
                    token.transfer(msg.sender, firstClaim);
                    buyer[msg.sender].claimed.push(firstClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - firstClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
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
                    uint secondClaim = buyer[msg.sender].claimLeft[i] / 5;
                    require(timediff >= 10 minutes, "Claim time not reached");
                    token.transfer(msg.sender, secondClaim);
                    buyer[msg.sender].claimed.push(secondClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - secondClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
                }
            }
            
            if(buyer[msg.sender].buyPrice[a] == 16){
                
                for(uint i = 0; i < buyer[msg.sender].bought.length; i++){
                    uint timediff = block.timestamp - buyer[msg.sender].buyAt[i];
                    uint secondClaim = buyer[msg.sender].claimLeft[i] / 2;
                    require(timediff >= 10 minutes, "Claim time not reached");
                    token.transfer(msg.sender, secondClaim);
                    buyer[msg.sender].claimed.push(secondClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - secondClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
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
                    uint thirdClaim = buyer[msg.sender].claimLeft[i] / 5;
                    require(timediff >= 15 minutes, "Claim time not reached");
                    token.transfer(msg.sender, thirdClaim);
                    buyer[msg.sender].claimed.push(thirdClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - thirdClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
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
                    uint fourthClaim = buyer[msg.sender].claimLeft[i] / 5;
                    require(timediff >= 15 minutes, "Claim time not reached");
                    token.transfer(msg.sender, fourthClaim);
                    buyer[msg.sender].claimed.push(fourthClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - fourthClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
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
                    uint fifthClaim = buyer[msg.sender].claimLeft[i] / 5;
                    require(timediff >= 15 minutes, "Claim time not reached");
                    token.transfer(msg.sender, fifthClaim);
                    buyer[msg.sender].claimed.push(fifthClaim);
                    uint furtherClaimLeft = buyer[msg.sender].claimLeft[i] - fifthClaim;
                    buyer[msg.sender].claimLeft.push(furtherClaimLeft);
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
            
            if(block.timestamp - startTime <= 5 minutes){
            price = 11;
            }
            
            if(block.timestamp - startTime > 5 minutes && block.timestamp - startTime <= 10 minutes){
                price = 16;
            }
            
            if(block.timestamp - startTime > 10 minutes && block.timestamp - startTime <= 15 minutes){
                price = 19;
            }
            
            if(block.timestamp - startTime > 15 minutes){
                price = 22;
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
        uint[] memory buyPrice = new uint[](buyer[user].buyPrice.length);
        
        for(uint i = 0; i < buyer[user].bought.length; i++){
            tokensBought[i] = buyer[user].bought[i];
            buyAt[i] = buyer[user].buyAt[i];
            claimed[i] = buyer[user].claimed[i];
            claimLeft[i] = buyer[user].claimLeft[i];
        }
        
        for(uint j = 0; j < buyer[user].buyPrice.length; j++){
            buyPrice[j] = buyer[user].buyPrice[j];
        }
        
        return(tokensBought, buyAt, claimed, claimLeft, buyPrice);
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
    
}