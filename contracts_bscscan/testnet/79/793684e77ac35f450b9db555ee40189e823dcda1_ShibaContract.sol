/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

pragma solidity ^0.4.25;

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
        ///priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // Mainnet BNB/USD
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

contract ShibaContract{
    
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
 
    
  uint MIN_DEPOSIT     = 5 ;
  uint START_AT        = 22442985;
  address buyTokenAddr = 0x698B1095Bc53d76b51849706500B9D865E71967A; // Testnet
  address referer      = 0x0000000000000000000000000000000000000000; // Testnet
  uint public tokenPrice      = 14;
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
  
  function register() internal {
      
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
    }
  }
  
  constructor() public {
    tariffs.push(Tariff(300 * 28800, 300));
    tariffs.push(Tariff(35 * 28800, 157));
    tariffs.push(Tariff(30 * 28800, 159));
    tariffs.push(Tariff(25 * 28800, 152));
    tariffs.push(Tariff(18 * 28800, 146));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function buyTokenWithBNB() external payable {
        BEP20 token = BEP20(buyTokenAddr);
        uint tariff = 0;
        require(msg.value >= MIN_DEPOSIT);
        require(tariff < tariffs.length);
    	if(investors[msg.sender].registered){
    		require(investors[msg.sender].deposits[0].tariff == tariff);
    	}
		register();
		uint tokenVal = (msg.value * priceOfBNB*10000) /(tokenPrice*100000000) ;
		investors[msg.sender].invested += tokenVal;
		totalInvested += tokenVal;
		investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.number));
		token.transfer(msg.sender, tokenVal);
		emit DepositAt(msg.sender, tariff, tokenVal);
  } 
  
   function buyTokenWithBUSD(uint busdAmount) external {
        BEP20 sendtoken    = BEP20(buyTokenAddr);
        BEP20 receiveToken = BEP20(0x72478b6F67364e73ebE93e979A8be3901EA9E5A0);///Testnet
        uint tariff = 0;
        require(tariff < tariffs.length);
    	uint tokenVal = (busdAmount* 10000) / tokenPrice ; 
    	require(sendtoken.balanceOf(address(this)) >= tokenVal, "Insufficient contract balance");
    	require(receiveToken.balanceOf(msg.sender) >= busdAmount, "Insufficient user balance");
		register();
		receiveToken.transferFrom(msg.sender, contractAddr, busdAmount);
		investors[msg.sender].invested += tokenVal;
		totalInvested += tokenVal;
	    investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.number));
		sendtoken.transfer(msg.sender, tokenVal);
		emit DepositAt(msg.sender, tariff, tokenVal);
	
  } 
   
  function myTotalInvestment() public view returns (uint) {
     Investor storage investor = investors[msg.sender];
	 uint amount = investor.invested;
	 return amount;
    
  }
  function tokenInBNB(uint amount) public view returns (uint) {
        uint tokenVal = (amount * priceOfBNB*10000) /(tokenPrice*100000000*1000000000000000000) ;
        return (tokenVal);
  }
  function tokenInBUSD(uint amount) public view returns (uint) {
        uint tokenVal = (amount * 10000) /(tokenPrice*1000000000000000000) ;
        return (tokenVal);
  }
    // Set buy price 
    // Upto 4 decimals
    function setBuyPrice(uint _price) public {
      require(msg.sender == owner, "Only owner");
      tokenPrice = _price;
    }
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 _token = BEP20(tokenAddress);
        _token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
}