// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "./SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingMP {
  using SafeMath for uint256;

  address private _owner;
  uint256 constant public PERCENT_DIVIDER = 10**18;
  uint256 private _percentPer;
  uint256 private _accrualPeriod;
  uint256 private _start_time;
  uint256 public totalInvested;
  uint256 public totalWithdrawn;

  IERC20 constant public token = IERC20(0xC4C1356302A96624e10F7BE12560A08bb1671bf5);// Token MetaPad

  struct InvestPlan {
    string title;
    uint min_amount;
    uint max_amount;
    uint percent;
    uint term;
  }

  struct Deposit {
    uint256 investplan;
		uint256 amount;
    uint256 withdrawn;
    uint256 percent;
    uint256 percentPer;
    uint256 accrualPeriod;
    uint256 term;
		uint256 timestamp;
    uint256 tw;
    uint256 status;
	}

  struct User {
		Deposit[] deposits;
	}

  InvestPlan[] public InvestPlans;
  mapping (address => User) internal users;

  constructor(
    uint256 percentPer,
    uint256 accrualPeriod,
    uint256 start_time,
    address owner){
    _percentPer = percentPer;
    _accrualPeriod = accrualPeriod;
    _start_time = start_time;
    _owner = owner;
    InvestPlans.push(InvestPlan({title: "Bronze", min_amount: 10000*10**18, max_amount: 24999*10**18, percent: 0, term: 30*60}));
    InvestPlans.push(InvestPlan({title: "Bronze", min_amount: 10000*10**18, max_amount: 24999*10**18, percent: 46, term: 60*60}));
    InvestPlans.push(InvestPlan({title: "Silver", min_amount: 25000*10**18, max_amount: 74999*10**18, percent: 0, term: 30*60}));
    InvestPlans.push(InvestPlan({title: "Silver", min_amount: 25000*10**18, max_amount: 74999*10**18, percent: 46, term: 60*60}));
    InvestPlans.push(InvestPlan({title: "Gold", min_amount: 75000*10**18, max_amount: 149999*10**18, percent: 0, term: 30*60}));
    InvestPlans.push(InvestPlan({title: "Gold", min_amount: 75000*10**18, max_amount: 149999*10**18, percent: 46, term: 60*60}));
    InvestPlans.push(InvestPlan({title: "Platinum", min_amount: 150000*10**18, max_amount: 0, percent: 0, term: 30*60}));
    InvestPlans.push(InvestPlan({title: "Platinum", min_amount: 150000*10**18, max_amount: 0, percent: 46, term: 60*60}));
  }

  function invest(uint256 id,uint256 amount) public{
    require(getStartTime() <= block.timestamp,"The time has not come yet");
    uint256 count;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count++;
        }
      }
    }
    require(count == 0,"Only one deposit");
    amount = amount * 10**18;
    require(amount >= InvestPlans[id].min_amount,"The amount of tokens is less than the minimum deposit amount");
    if(InvestPlans[id].max_amount > 0){
      require(amount <= InvestPlans[id].max_amount,"The number of tokens is greater than the maximum deposit amount");
    }
    require(token.balanceOf(msg.sender) >= amount,"You have the required amount");
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");
    require(token.transferFrom(msg.sender, address(this),amount),"Error transferFrom");
    User storage user = users[msg.sender];
    user.deposits.push(Deposit(id,amount,0,InvestPlans[id].percent,getPercentPer(),getAccrualPeriod(),InvestPlans[id].term,block.timestamp,block.timestamp,1));
    totalInvested = totalInvested.add(amount);
  }

  function _calcDividends(uint256 periods, uint256 i,address userAddress) public view returns(uint256) {
    uint256 dividends = (users[userAddress].deposits[i].amount).mul(periods).mul(users[userAddress].deposits[i].percent.mul(PERCENT_DIVIDER).div((users[userAddress].deposits[i].percentPer.div(users[userAddress].deposits[i].accrualPeriod))) / 100).div(PERCENT_DIVIDER);
    return dividends;
  }

  function withdrawn(uint256 id) public {
    uint256 time = block.timestamp;
		uint256 dividends;
    uint256 periods;
    uint256 count;
    uint256 idDep;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count++;
          idDep = i;
        }
      }
    }
    require(count > 0,"You have no deposit");
    if((users[msg.sender].deposits[idDep].tw).add(users[msg.sender].deposits[idDep].accrualPeriod) <= time){
      uint256 interval;
      uint256 timeClose = (users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term);
      if(timeClose < time){
        interval = timeClose.sub(users[msg.sender].deposits[idDep].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[idDep].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[idDep].accrualPeriod)).div(users[msg.sender].deposits[idDep].accrualPeriod);
      dividends = dividends.add(_calcDividends(periods,idDep,msg.sender));
    }
    if(dividends > 0){
      require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
      require(token.transfer(msg.sender, dividends),"Error transfer");
      User storage user = users[msg.sender];
      user.deposits[idDep].withdrawn = (user.deposits[idDep].withdrawn).add(dividends);
      user.deposits[idDep].tw = (user.deposits[idDep].tw).add(periods.mul(users[msg.sender].deposits[idDep].accrualPeriod));
      totalWithdrawn = totalWithdrawn.add(dividends);
    }
	}

  function close(uint256 id) public {
    uint256 time = block.timestamp;
    uint256 dividends;
    uint256 periods;
    uint256 count;
    uint256 idDep;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count.add(1);
          idDep = i;
        }
      }
    }
    require((users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term) <= time,"The time has not come yet");
    require(count > 0,"You have no deposit");
    if((users[msg.sender].deposits[idDep].tw).add(users[msg.sender].deposits[idDep].accrualPeriod) <= time){
      uint256 interval;
      uint256 timeClose = (users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term);
      if(timeClose < time){
        interval = timeClose.sub(users[msg.sender].deposits[idDep].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[idDep].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[idDep].accrualPeriod)).div(users[msg.sender].deposits[idDep].accrualPeriod);
      dividends = dividends.add(_calcDividends(periods,idDep,msg.sender));
    }
    dividends = dividends.add(users[msg.sender].deposits[idDep].amount);
    if(dividends > 0){
      require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
      require(token.transfer(msg.sender, dividends),"Error transfer");
      User storage user = users[msg.sender];
      user.deposits[idDep].withdrawn = (user.deposits[idDep].withdrawn).add(dividends);
      user.deposits[idDep].tw = (user.deposits[idDep].tw).add(periods.mul(users[msg.sender].deposits[idDep].accrualPeriod));
      user.deposits[idDep].status = 0;
      totalWithdrawn = totalWithdrawn.add(dividends);
    }
	}

  function reinvest(uint256 id) public {
    uint256 time = block.timestamp;
    uint256 dividends;
    uint256 periods;
    uint256 count;
    uint256 idDep;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count.add(1);
          idDep = i;
        }
      }
    }
    require((users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term) <= time,"The time has not come yet");
    require(count > 0,"You have no deposit");
    if((users[msg.sender].deposits[idDep].tw).add(users[msg.sender].deposits[idDep].accrualPeriod) <= time){
      uint256 interval;
      uint256 timeClose = (users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term);
      if(timeClose < time){
        interval = timeClose.sub(users[msg.sender].deposits[idDep].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[idDep].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[idDep].accrualPeriod)).div(users[msg.sender].deposits[idDep].accrualPeriod);
      dividends = dividends.add(_calcDividends(periods,idDep,msg.sender));
    }
    User storage user = users[msg.sender];
    if(dividends > 0){
      require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
      require(token.transfer(msg.sender, dividends),"Error transfer");
      user.deposits[idDep].withdrawn = (user.deposits[idDep].withdrawn).add(dividends);
      user.deposits[idDep].tw = (user.deposits[idDep].tw).add(periods.mul(users[msg.sender].deposits[idDep].accrualPeriod));
      user.deposits[idDep].status = 0;
      totalWithdrawn = totalWithdrawn.add(dividends);
    }
    user.deposits.push(Deposit(id,user.deposits[idDep].amount,0,InvestPlans[id].percent,_percentPer,getAccrualPeriod(),InvestPlans[id].term.mul(60*60*24),block.timestamp,block.timestamp,1));
	}

  function getUserDividends(address userAddress) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
          uint256 interval;
          uint256 timeClose = (users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term);
          if(timeClose < time){
            interval = timeClose.sub(users[userAddress].deposits[i].tw);
          }else{
            interval = time.sub(users[userAddress].deposits[i].tw);
          }
          uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
          dividends = dividends.add(_calcDividends(periods,i,userAddress));
        }
      }
		}
		return dividends;
	}

  function getUserDividendsTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if(users[userAddress].deposits[i].status == 1){
          if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
            uint256 interval;
            uint256 timeClose = (users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term);
            if(timeClose < time){
              interval = timeClose.sub(users[userAddress].deposits[i].tw);
            }else{
              interval = time.sub(users[userAddress].deposits[i].tw);
            }
            uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
            dividends = dividends.add(_calcDividends(periods,i,userAddress));
          }
        }
      }
		}
		return dividends;
	}

  function getUserDividendsDeposit(address userAddress, uint256 i) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
    if(users[userAddress].deposits[i].status == 1){
      if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
        uint256 interval;
        uint256 timeClose = (users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term);
        if(timeClose < time){
          interval = timeClose.sub(users[userAddress].deposits[i].tw);
        }else{
          interval = time.sub(users[userAddress].deposits[i].tw);
        }
        uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
        dividends = dividends.add(_calcDividends(periods,i,userAddress));
      }
    }
		return dividends;
	}

  function getUserUnstakedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 time = block.timestamp;
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if((users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term) < time){
          if(users[userAddress].deposits[i].status == 1){
            amount = amount.add(users[userAddress].deposits[i].amount);
          }
        }
      }
		}
		return amount;
	}

  function getUserActiveInvestedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if(users[userAddress].deposits[i].status == 1){
			    amount = amount.add(users[userAddress].deposits[i].amount);
        }
      }
		}
		return amount;
	}

  function getUserTotalInvestedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
			  amount = amount.add(users[userAddress].deposits[i].amount);
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

  function getUserDepositInfo(address userAddress, uint256 index) public view returns(Deposit memory) {
    Deposit memory deposit = users[userAddress].deposits[index];
    return deposit;
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

  function setPercentPer(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _percentPer = x;
  }

  function setAccrualPeriod(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _accrualPeriod = x;
  }

  function setStartTime(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _start_time = x;
  }

  function getTokenBalance() public {
    require(msg.sender == _owner,"Only owner");
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
  function getPercentPer() public view returns(uint256) {
		return _percentPer;
	}

  function getAccrualPeriod() public view returns(uint256) {
		return _accrualPeriod;
	}

  function getStartTime() public view returns(uint256) {
    return _start_time;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}