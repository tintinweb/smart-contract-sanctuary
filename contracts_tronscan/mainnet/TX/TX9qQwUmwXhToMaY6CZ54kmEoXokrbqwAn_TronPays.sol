//SourceUnit: TronPays.sol

pragma solidity ^0.4.25;

contract TronPays {
  using SafeMath for uint256;

  struct Investor {
    bool registered;
    address referrer;
    uint balanceRef;
    uint totalRef;
    uint totalDepositedByRefs;
    uint invested;
    uint paidAt;
    uint profit;
    uint withdrawn;
    uint level;
  }
  
  uint DAY = 1 days;
  uint MIN_DEPOSIT = 100 trx;
  uint START_AT = 1607763600;
  
  address public support = msg.sender;
  
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping (address => mapping (uint => uint)) public referrals;
  mapping (address => mapping (uint => uint)) public gained_profit;
  mapping (address => mapping (uint => uint)) public missed_profit;
  
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
          
          referrals[rec][i]++;
          
          rec = investors[rec].referrer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referrer) internal {
    address rec = referrer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      bool _missed_profit = false;
      address initialRec = rec;
      
      if (!investors[rec].registered || investors[rec].level <= i) {
        rec = support;
        _missed_profit = true;
      }
      
      uint a = amount * refRewards[i] / 10000;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      investors[rec].totalDepositedByRefs += amount;
      totalRefRewards += a;
      
      if (_missed_profit) {
        if (investors[initialRec].registered) {
          missed_profit[initialRec][i] += a;
        }
      } else {
        gained_profit[initialRec][i] += a;
      }
      
      rec = investors[initialRec].referrer;
    }
  }
  
  constructor() public {
	
    refRewards.push(1000);
    refRewards.push(500);
    refRewards.push(200);
    refRewards.push(100);
    refRewards.push(50);
    refRewards.push(50);
    refRewards.push(50);
    refRewards.push(25);
    refRewards.push(25);
    refRewards.push(12);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    return investor.paidAt > 0 ? investor.invested * (block.timestamp - investor.paidAt) * 4 / DAY / 10 : 0;
  }
  
  function addProfit() internal {
    Investor storage investor = investors[msg.sender];
    
    investor.profit += withdrawable(msg.sender);
    
    investor.paidAt = block.timestamp;
  }
  
  function deposit(address referrer) external payable {
    require(block.timestamp >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    
    Investor storage investor = investors[msg.sender];
    
    register(referrer);
    
    uint fee = msg.value / 10;
    investors[support].balanceRef += fee;
    investors[support].totalRef += fee;
    
    rewardReferers(msg.value, investor.referrer);
    
    addProfit();
    
    investor.invested += msg.value;
    totalInvested += msg.value;
    
    if (investor.invested >= 1312200 trx) {
      investor.level = 10;
    } else if (investor.invested >= 437400 trx) {
      investor.level = 9;
    } else if (investor.invested >= 145800 trx) {
      investor.level = 8;
    } else if (investor.invested >= 48600 trx) {
      investor.level = 7;
    } else if (investor.invested >= 16200 trx) {
      investor.level = 6;
    } else if (investor.invested >= 5400 trx) {
      investor.level = 5;
    } else if (investor.invested >= 1800 trx) {
      investor.level = 4;
    } else if (investor.invested >= 600 trx) {
      investor.level = 3;
    } else if (investor.invested >= 200 trx) {
      investor.level = 2;
    } else {
      investor.level = 1;
    }
    
    support.transfer(msg.value.mul(10).div(100));
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
    support.transfer(amount * 5 /100);
    emit Withdraw(msg.sender, amount);
  }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}