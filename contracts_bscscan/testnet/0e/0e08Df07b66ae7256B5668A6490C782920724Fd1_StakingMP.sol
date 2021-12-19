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
    address owner){
    _percentPer = percentPer;
    _accrualPeriod = accrualPeriod;
    _owner = owner;
    InvestPlans.push(InvestPlan({title: "Bronze", min_amount: 10000, max_amount: 24999, percent: 0, term: 30}));
    InvestPlans.push(InvestPlan({title: "Bronze", min_amount: 10000, max_amount: 24999, percent: 46, term: 180}));
    InvestPlans.push(InvestPlan({title: "Silver", min_amount: 25000, max_amount: 74999, percent: 0, term: 30}));
    InvestPlans.push(InvestPlan({title: "Silver", min_amount: 25000, max_amount: 74999, percent: 46, term: 180}));
    InvestPlans.push(InvestPlan({title: "Gold", min_amount: 75000, max_amount: 149999, percent: 0, term: 30}));
    InvestPlans.push(InvestPlan({title: "Gold", min_amount: 75000, max_amount: 149999, percent: 46, term: 180}));
    InvestPlans.push(InvestPlan({title: "Platinum", min_amount: 150000, max_amount: 0, percent: 0, term: 30}));
    InvestPlans.push(InvestPlan({title: "Platinum", min_amount: 150000, max_amount: 0, percent: 46, term: 180}));
  }

  function invest(uint256 id,uint256 amount) public{
    require(amount >= InvestPlans[id].min_amount,"The amount of tokens is less than the minimum deposit amount");
    if(InvestPlans[id].max_amount > 0){
      require(amount <= InvestPlans[id].max_amount,"The number of tokens is greater than the maximum deposit amount");
    }
    require(token.balanceOf(msg.sender) >= amount,"You have the required amount");
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");
    require(token.transferFrom(msg.sender, address(this),amount),"Error transferFrom");
    User storage user = users[msg.sender];
    user.deposits.push(Deposit(id,amount,0,InvestPlans[id].percent,_percentPer,getAccrualPeriod(),InvestPlans[id].term.mul(60*60*24),block.timestamp,block.timestamp,1));
    totalInvested = totalInvested.add(amount);
  }

  function _calcDividents(uint256 periods, uint256 i,address userAddress) private view returns(uint256) {
    uint256 dividends = (users[userAddress].deposits[i].amount).mul(periods).mul(users[userAddress].deposits[i].percent.mul(PERCENT_DIVIDER).div((users[userAddress].deposits[i].percentPer.div(users[userAddress].deposits[i].accrualPeriod))) / 100).div(PERCENT_DIVIDER);
    return dividends;
  }

  function withdrawn() public {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].status == 1){
        if((users[msg.sender].deposits[i].tw).add(users[msg.sender].deposits[i].accrualPeriod) < time){
          uint256 interval;
          if(time.add(users[msg.sender].deposits[i].term) < time){
            interval = time.add(users[msg.sender].deposits[i].term).sub(users[msg.sender].deposits[i].tw);
          }else{
            interval = time.sub(users[msg.sender].deposits[i].tw);
          }
          uint256 periods = (interval.sub(interval % users[msg.sender].deposits[i].accrualPeriod)).div(users[msg.sender].deposits[i].accrualPeriod);
          dividends = dividends.add(_calcDividents(periods,i,msg.sender));
        }
      }
		}
    require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
    if(dividends > 0){
      require(token.transfer(msg.sender, dividends),"Error transfer");
      User storage user = users[msg.sender];
      for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
        if(users[msg.sender].deposits[i].status == 1){
          if((users[msg.sender].deposits[i].tw).add(users[msg.sender].deposits[i].accrualPeriod) < time){
            uint256 interval;
            if(time.add(users[msg.sender].deposits[i].term) < time){
              interval = time.add(users[msg.sender].deposits[i].term).sub(users[msg.sender].deposits[i].tw);
            }else{
              interval = time.sub(users[msg.sender].deposits[i].tw);
            }
            uint256 periods = (interval.sub(interval % users[msg.sender].deposits[i].accrualPeriod)).div(users[msg.sender].deposits[i].accrualPeriod);
            uint256 amount = _calcDividents(periods,i,msg.sender);
            user.deposits[i].withdrawn = (user.deposits[i].withdrawn).add(amount);
            user.deposits[i].tw = (user.deposits[i].tw).add(periods.mul(users[msg.sender].deposits[i].accrualPeriod));
          }
        }
      }
      totalWithdrawn = totalWithdrawn.add(dividends);
    }
	}

  function close(uint256 id) public {
    require(users[msg.sender].deposits[id].amount > 0,"No deposit exists");
    require(users[msg.sender].deposits[id].status == 1,"Deposit closed");
    require((users[msg.sender].deposits[id].timestamp).add(users[msg.sender].deposits[id].term) <= block.timestamp,"The minimum deposit period has not yet been crossed");
    uint256 time = block.timestamp;
    uint256 dividends;
    uint256 periods;
    if((users[msg.sender].deposits[id].tw).add(users[msg.sender].deposits[id].accrualPeriod) < time){
      uint256 interval;
      if(time.add(users[msg.sender].deposits[id].term) < time){
        interval = time.add(users[msg.sender].deposits[id].term).sub(users[msg.sender].deposits[id].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[id].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[id].accrualPeriod)).div(users[msg.sender].deposits[id].accrualPeriod);
      dividends = _calcDividents(periods,id,msg.sender);
    }
    dividends = dividends.add(users[msg.sender].deposits[id].amount);
    require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
    require(token.transfer(msg.sender, dividends),"Error transfer");
    User storage user = users[msg.sender];
    user.deposits[id].withdrawn = (user.deposits[id].withdrawn).add(dividends);
    user.deposits[id].tw = (user.deposits[id].withdrawn).add(periods.mul(users[msg.sender].deposits[id].accrualPeriod));
    user.deposits[id].status = 0;
    totalWithdrawn = totalWithdrawn.add(dividends);
	}

  function getUserDividends(address userAddress) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
          uint256 interval;
          if(time.add(users[msg.sender].deposits[i].term) < time){
            interval = time.add(users[msg.sender].deposits[i].term).sub(users[userAddress].deposits[i].tw);
          }else{
            interval = time.sub(users[userAddress].deposits[i].tw);
          }
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
      users[userAddress].deposits[index].investplan,
      users[userAddress].deposits[index].amount,
      users[userAddress].deposits[index].term,
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

  function setPercentPer(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _percentPer = x;
  }

  function setAccrualPeriod(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _accrualPeriod = x;
  }

  function getTokenBalance() public {
        require(msg.sender == _owner,"Only owner");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

  function getAccrualPeriod() public view returns(uint256) {
		return _accrualPeriod;
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