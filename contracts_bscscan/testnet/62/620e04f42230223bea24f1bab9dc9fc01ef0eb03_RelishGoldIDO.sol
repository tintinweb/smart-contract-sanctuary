/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.8;

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
       // priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // Mainnet BNB/USD
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // Testnet BNB/USD
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

contract RelishGoldIDO{
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfBNB = priceConsumerV3.getThePrice();
    
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint referrals_tier4;
   uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
   struct getReferralwalletAddress { 
    address referer; 
  }
  
  struct InvestorReferral {
  
    uint referralsAmt_tier1;
    uint referralsAmt_tier2;
    uint referralsAmt_tier3;
    uint referralsAmt_tier4;
    uint balanceRef;
  }

  address public buyTokenAddr = 0x3f5241b0f8949e123728a6246e655698F6398f42; 
  uint public tokenPrice         = 1;
  uint public tokenPriceDecimal  = 100;
  event OwnershipTransferred(address);
  
  address public owner = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public totalRefRewards;
  address public contractAddr = address(this);
  
  mapping (address => Investor) public investors;
  mapping (address => getReferralwalletAddress) public getReferralwalletAddresses;
  mapping (address => InvestorReferral) public investorreferrals;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  
  function register(address referer) internal {
      
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
      
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        
        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          
          if (i == 0) {
            investors[rec].referrals_tier1++;
          }
          if (i == 1) {
            investors[rec].referrals_tier2++;
          }
          if (i == 2) {
            investors[rec].referrals_tier3++;
          }
          
          rec = investors[rec].referer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      uint refRewardPercent = 0;
      if(i==0){
          refRewardPercent = 3;
      }
      else if(i==1){
          refRewardPercent = 1;
      }
      else if(i==2){
          refRewardPercent = 1;
      }
      uint a = amount * refRewardPercent / 100;
      
      if(i==0){
          investorreferrals[rec].referralsAmt_tier1 += a;
      }
      else if(i==1){
          investorreferrals[rec].referralsAmt_tier2 += a;
      }
      else if(i==2){
          investorreferrals[rec].referralsAmt_tier3 += a;
      }
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      BEP20 token = BEP20(buyTokenAddr);
      if(rec != address(0x0) ){
        token.transfer(rec, a);    
      }
      rec = investors[rec].referer;
    }
  }
  
  
  constructor() {
    tariffs.push(Tariff(300 * 28800, 300));
    tariffs.push(Tariff(35  * 28800, 157));
    tariffs.push(Tariff(30  * 28800, 159));
    tariffs.push(Tariff(25  * 28800, 152));
    tariffs.push(Tariff(18  * 28800, 146));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function buyTokenWithBNB(address referer) external payable {
        BEP20 token = BEP20(buyTokenAddr);
        uint tariff = 0;
        require(msg.value >= 0);
        require(tariff < tariffs.length);
      if(investors[msg.sender].registered){
        require(investors[msg.sender].deposits[0].tariff == tariff);
      }
  
    register(referer);
     
    uint tokenVal = (msg.value * priceOfBNB* 10**tokenPriceDecimal) /(tokenPrice*100000000) ;
    
    rewardReferers(tokenVal, investors[msg.sender].referer);
    
    investors[msg.sender].invested += tokenVal;
    totalInvested += tokenVal;
    
    investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.number));
    
    token.transfer(msg.sender, tokenVal);
    
    emit DepositAt(msg.sender, tariff, tokenVal);
  
  } 
 
  
    function myTariff() public view returns (uint) {
      
      uint tariff = investors[msg.sender].deposits[0].tariff;
      return tariff;
    
    }
    function usd_price() public view returns (uint) {
        return priceOfBNB;
    }
    
    function referralBalance() public view returns (uint) {
        Investor storage investor = investors[msg.sender];

        uint amount = investor.balanceRef;
        return amount;
    }
  
    function myTotalInvestment() public view returns (uint) {
        Investor storage investor = investors[msg.sender];
        uint amount = investor.invested;
        return amount;
    }

    function referralLevelBalance() public view returns (uint,uint,uint,uint) {
        InvestorReferral storage investorreferral = investorreferrals[msg.sender];
        uint levelOne = investorreferral.referralsAmt_tier1;
        uint levelTwo = investorreferral.referralsAmt_tier2;
        uint levelThree = investorreferral.referralsAmt_tier3;
        uint levelFour = investorreferral.referralsAmt_tier4;
        return (levelOne,levelTwo,levelThree,levelFour);
    }
    
    function referralLevelCount() public view returns (uint,uint,uint,uint) {
        Investor storage investor = investors[msg.sender];
        uint levelOneCnt = investor.referrals_tier1;
        uint levelTwoCnt = investor.referrals_tier2;
        uint levelThreeCnt = investor.referrals_tier3;
        uint levelFourCnt = investor.referrals_tier4;
        return (levelOneCnt,levelTwoCnt,levelThreeCnt,levelFourCnt);
    } 
    
    function tokenInBNB(uint amount) public view returns (uint) {
        uint tokenVal = (amount * priceOfBNB* 10**tokenPriceDecimal) /(tokenPrice*100000000*1000000000000000000) ;
        return (tokenVal);
    }

    function getTokenPrice() public view returns (uint,uint) {
        return (tokenPrice,tokenPriceDecimal);
    } 



    /*
    like tokenPrice = 0.0000000001
    setBuyPrice = 1 
    tokenPriceDecimal= 10
    */
    // Set buy price  
    function setBuyPrice(uint _price, uint _decimal) external {
      require(msg.sender == owner, "Only owner");
      tokenPrice        = _price;
      tokenPriceDecimal = _decimal;
    }
  
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 _token = BEP20(tokenAddress);
        _token.transfer(to, amount);
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address payable to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
    }

    // BNB Price Update
    // Only owner can call this function
    function bnbpriceChange() external {
        require(msg.sender == owner, "Only owner");
        priceOfBNB = priceConsumerV3.getThePrice();
    }
}