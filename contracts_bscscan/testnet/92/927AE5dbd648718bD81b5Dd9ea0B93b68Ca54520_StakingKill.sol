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
  uint256 constant public PERCENTS_DIVIDER = 100;

  uint256 private _minTerm;
  uint256 private _percentYear;
  uint256 private _minDeposit;
  uint256 private _accrualPeriod;

  IERC20 constant public token = IERC20(0xa4D82AeAC2F2fA115763442d5764e5D400eafaE9);// Token MemeKiller

  constructor() public {
    _minTerm = 7 days;
    _percentYear = 125;
    _minDeposit = 50 ether;
    _accrualPeriod = 1 hours;
  }

  struct Deposit {
		uint256 amount;
    uint256 percentYear;
		uint256 timestamp;
    uint256 withdrawn;
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
    //uint256 allowance = token.allowance(msg.sender, address(this));
    //require(allowance >= amount, "Check the token allowance");
    require(token.transferFrom(msg.sender, address(this),amount));
    User storage user = users[msg.sender];
    if (user.deposits.length == 0) {
			emit NewUser(msg.sender);
		}
    user.deposits.push(Deposit(amount,getPercentYear(),block.timestamp,block.timestamp,1));
    emit NewDeposit(msg.sender, amount);
  }

  function withdrawn() public {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].status == 1){
        if((users[msg.sender].deposits[i].withdrawn).add(getAccrualPeriod()) < time){
          uint256 interval = time.sub(users[msg.sender].deposits[i].withdrawn);
          uint256 year = 365 days;
          uint256 percentPeriod = getPercentYear().div(year.div(getAccrualPeriod())).mul(PERCENTS_DIVIDER);
          uint256 periods = (interval.sub(interval % getAccrualPeriod())).sub(getAccrualPeriod());
          dividends = dividends.add(periods.mul(percentPeriod.div(PERCENTS_DIVIDER).div(100)));
        }
      }
		}
    require(token.transfer(msg.sender, dividends));
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].status == 1){
        if((users[msg.sender].deposits[i].withdrawn).add(getAccrualPeriod()) < time){
          uint256 interval = time.sub(users[msg.sender].deposits[i].withdrawn);
          uint256 periods = (interval.sub(interval % getAccrualPeriod())).sub(getAccrualPeriod());
          User storage user = users[msg.sender];
          user.deposits[i].withdrawn = (user.deposits[i].withdrawn).add(periods.mul(getAccrualPeriod()));
        }
      }
		}
		emit Withdrawn(msg.sender, dividends);
	}

  function close(uint256 id) public {
    require(users[msg.sender].deposits[id].amount > 0,"No deposit exists");
    require(users[msg.sender].deposits[id].status == 1,"Deposit closed");
    require((users[msg.sender].deposits[id].timestamp).add(getMinTerm()) <= block.timestamp,"The minimum deposit period has not yet been crossed");
    uint256 interval = block.timestamp.sub(users[msg.sender].deposits[id].withdrawn);
    uint256 year = 365 days;
    uint256 percentPeriod = getPercentYear().div(year.div(getAccrualPeriod())).mul(PERCENTS_DIVIDER);
    uint256 periods = (interval.sub(interval % getAccrualPeriod())).sub(getAccrualPeriod());
    uint256 dividends = periods.mul(percentPeriod.div(PERCENTS_DIVIDER).div(100));
    dividends = dividends.add(users[msg.sender].deposits[id].amount);
    require(token.transfer(msg.sender, dividends));
    User storage user = users[msg.sender];
    user.deposits[id].withdrawn = (user.deposits[id].withdrawn).add(periods.mul(getAccrualPeriod()));
    user.deposits[id].status = 0;
    emit Withdrawn(msg.sender, dividends);
	}

  function getUserDividends(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        uint256 interval = block.timestamp.sub(users[msg.sender].deposits[i].withdrawn);
        uint256 year = 365 days;
        uint256 percentPeriod = getPercentYear().div(year.div(getAccrualPeriod())).mul(PERCENTS_DIVIDER);
        uint256 periods = (interval.sub(interval % getAccrualPeriod())).sub(getAccrualPeriod());
        amount = amount.add(periods.mul(percentPeriod.div(PERCENTS_DIVIDER).div(100)));
      }
		}
		return amount;
	}

  function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
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

  function setPercentYear(uint256 x) public{
    require(msg.sender == OWNER,"Only owner");
    _percentYear = x;
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

  function getPercentYear() public view returns(uint256) {
		return _percentYear;
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

