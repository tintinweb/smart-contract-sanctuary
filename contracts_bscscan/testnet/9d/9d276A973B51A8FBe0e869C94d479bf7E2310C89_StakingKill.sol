// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StakingKill {
  using SafeMath for uint256;

  address constant public OWNER = 0x786926965a11942f11Ff954d8E068189f1D883fE;
  uint256 constant public PERCENT_DIVIDER = 10**18;

  uint256 private _minTerm;
  uint256 private _percent;
  uint256 private _percentPer;
  uint256 private _minDeposit;
  uint256 private _accrualPeriod;

  uint256 public totalInvested;
  uint256 public totalWithdrawn;

  IERC20 constant public token = IERC20(0xa4D82AeAC2F2fA115763442d5764e5D400eafaE9);// Token MemeKiller

  constructor(uint256 minTerm,uint256 percent,uint256 percentPer,uint256 minDeposit,uint256 accrualPeriod) public {
    _minTerm = minTerm;
    _percent = percent;
    _percentPer = percentPer;
    _minDeposit = minDeposit.mul(10**18);
    _accrualPeriod = accrualPeriod;
  }

  struct Deposit {
		uint256 amount;
    uint256 withdrawn;
    uint256 percent;
    uint256 percentPer;
    uint256 accrualPeriod;
    uint256 minTerm;
		uint256 timestamp;
    uint256 tw;
    uint256 status;
	}

  struct User {
		Deposit[] deposits;
	}

  mapping (address => User) internal users;

  event NewUser(address user);
  event NewDeposit(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);

  function invest(uint256 amount) public{
    require(amount >= getMinDeposit(),"The amount of tokens is less than the minimum deposit amount");
    require(token.balanceOf(msg.sender) >= amount,"You have the required amount");
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");
    require(token.transferFrom(msg.sender, address(this),amount),"Error transferFrom");
    User storage user = users[msg.sender];
    if (user.deposits.length == 0) {
			emit NewUser(msg.sender);
		}
    user.deposits.push(Deposit(amount,0,getPercent(),getPercentPer(),getAccrualPeriod(),getMinTerm(),block.timestamp,block.timestamp,1));
    totalInvested = totalInvested.add(amount);
    emit NewDeposit(msg.sender, amount);
  }

  function withdrawn() public {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].status == 1){
        if((users[msg.sender].deposits[i].tw).add(users[msg.sender].deposits[i].accrualPeriod) < time){
          uint256 interval = time.sub(users[msg.sender].deposits[i].tw);
          uint256 periods = (interval.sub(interval % users[msg.sender].deposits[i].accrualPeriod)).div(users[msg.sender].deposits[i].accrualPeriod);
          dividends = dividends.add(_calcDividents(periods,i,msg.sender));
        }
      }
		}
    if(dividends > 0){
      require(token.transfer(msg.sender, dividends),"Error transfer");
      User storage user = users[msg.sender];
      for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
        if(users[msg.sender].deposits[i].status == 1){
          if((users[msg.sender].deposits[i].tw).add(users[msg.sender].deposits[i].accrualPeriod) < time){
            uint256 interval = time.sub(users[msg.sender].deposits[i].tw);
            uint256 periods = (interval.sub(interval % users[msg.sender].deposits[i].accrualPeriod)).div(users[msg.sender].deposits[i].accrualPeriod);
            uint256 amount = _calcDividents(periods,i,msg.sender);
            user.deposits[i].withdrawn = (user.deposits[i].withdrawn).add(amount);
            user.deposits[i].tw = (user.deposits[i].tw).add(periods.mul(users[msg.sender].deposits[i].accrualPeriod));
          }
        }
      }
      totalWithdrawn = totalWithdrawn.add(dividends);
      emit Withdrawn(msg.sender, dividends);
    }
	}

  function close(uint256 id) public {
    require(users[msg.sender].deposits[id].amount > 0,"No deposit exists");
    require(users[msg.sender].deposits[id].status == 1,"Deposit closed");
    require((users[msg.sender].deposits[id].timestamp).add(users[msg.sender].deposits[id].minTerm) <= block.timestamp,"The minimum deposit period has not yet been crossed");
    uint256 time = block.timestamp;
    uint256 interval = time.sub(users[msg.sender].deposits[id].tw);
    uint256 periods = (interval.sub(interval % users[msg.sender].deposits[id].accrualPeriod)).div(users[msg.sender].deposits[id].accrualPeriod);
    uint256 dividends = _calcDividents(periods,id,msg.sender);
    dividends = dividends.add(users[msg.sender].deposits[id].amount);
    require(token.transfer(msg.sender, dividends),"Error transfer");
    User storage user = users[msg.sender];
    user.deposits[id].withdrawn = (user.deposits[id].withdrawn).add(dividends);
    user.deposits[id].tw = (user.deposits[id].withdrawn).add(periods.mul(users[msg.sender].deposits[id].accrualPeriod));
    user.deposits[id].status = 0;
    totalWithdrawn = totalWithdrawn.add(dividends);
    emit Withdrawn(msg.sender, dividends);
	}

  function _calcDividents(uint256 periods, uint256 i,address userAddress) private view returns(uint256) {
    uint256 dividends = (users[userAddress].deposits[i].amount).mul(periods).mul(users[userAddress].deposits[i].percent / getPercentPer().div(users[userAddress].deposits[i].accrualPeriod) / 100);
    return dividends;
  }

  function testCalcDividends(uint256 amount, uint256 percent, uint256 accrualPeriod, uint256 periods) public view returns(uint256) {
    uint256 dividends = (amount).mul(periods).mul(percent.mul(PERCENT_DIVIDER).div((getPercentPer().div(accrualPeriod))) / 100).div(PERCENT_DIVIDER);
    return dividends;
  }

  function getUserDividends(address userAddress) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
          uint256 interval = time.sub(users[userAddress].deposits[i].tw);
          uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
          dividends = dividends.add(_calcDividents(periods,i,userAddress));
        }
      }
		}
		return dividends;
	}

  function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
		return amount;
	}

  function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
		return (
      users[userAddress].deposits[index].amount,
      users[userAddress].deposits[index].minTerm,
      users[userAddress].deposits[index].accrualPeriod,
      users[userAddress].deposits[index].timestamp,
      users[userAddress].deposits[index].tw,
      users[userAddress].deposits[index].status);
	}

  function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].withdrawn);
		}
		return amount;
	}

  function getUserTotalActiveDeposits(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        amount = amount.add(users[userAddress].deposits[i].amount);
      }
		}
		return amount;
	}

  function getUserCountDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

  function getUserCountActiveDeposits(address userAddress) public view returns(uint256) {
		uint256 count;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        count = count.add(1);
      }
		}
		return count;
	}

  function setMinTerm(uint256 x) public{
    require(msg.sender == OWNER,"Only owner");
    _minTerm = x;
  }

  function setPercent(uint256 x) public{
    require(msg.sender == OWNER,"Only owner");
    _percent = x;
  }

  function setPercentPer(uint256 x) public{
    require(msg.sender == OWNER,"Only owner");
    _percentPer = x;
  }

  function setMinDeposit(uint256 x) public{
    require(msg.sender == OWNER,"Only owner");
    _minDeposit = x;
  }

  function setAccrualPeriod(uint256 x) public{
    require(msg.sender == OWNER,"Only owner");
    _accrualPeriod = x;
  }

  function getMinTerm() public view returns(uint256) {
		return _minTerm;
	}

  function getPercent() public view returns(uint256) {
		return _percent;
	}

  function getPercentPer() public view returns(uint256) {
		return _percentPer;
	}

  function getMinDeposit() public view returns(uint256) {
		return _minDeposit;
	}

  function getAccrualPeriod() public view returns(uint256) {
		return _accrualPeriod;
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

