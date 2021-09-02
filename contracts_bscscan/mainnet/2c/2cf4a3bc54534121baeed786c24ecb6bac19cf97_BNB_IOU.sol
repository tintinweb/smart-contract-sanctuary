/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

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

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
  function owner() public view returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BNB_IOU is Ownable {
  using SafeMath for uint256;

  uint256 constant public MIN_AMOUNT = 0.02 ether;
  uint256[] public REFERRAL_PERCENTS = [50];
  uint256 constant public PERCENT_STEP = 3;
  uint256 constant public PERCENTS_DIVIDER = 1000;
  uint256 constant public TIME_STEP = 1 days;
  uint256 constant public PENALTY_STEP = 500;
  uint256 constant public DEV_FEE = 60;
  uint256 constant public CONTRACT_FEE = 60;
  uint256 constant public MAX_CASHBACK = 80;

  uint256 public totalStaked;
  uint256 public totalCashback;
  uint256 public totalRefBonus;

  struct Plan {
    uint256 time;
    uint256 percent;
  }

  Plan[] internal plans;
  uint256[] internal cashbacks;

  struct Deposit {
    uint8 plan;
	uint256 percent;
	uint256 amount;
	uint256 profit;
	uint256 cashback;
	uint256 start;
	uint256 finish;
  }

  struct User {
    Deposit[] deposits;
	uint256 checkpoint;
	address referrer;
	uint256[1] levels;
	uint256 bonus;
	uint256 cashbackBonus;
	uint256 totalBonus;
	uint256 totalCashback;
  }

  mapping (address => User) internal users;

  uint256 private preUNIX;
  uint256 public startUNIX;
  address payable public dev;
  address payable public pro;

  event Newbie(address user);
  event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 cashback, uint256 start, uint256 finish);
  event Withdrawn(address indexed user, uint256 amount);
  event ForceWithdrawn(address indexed user, uint256 amount, uint256 penaltyAmount);
  event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
  event Cashback(address indexed user, uint256 amount);
  event Prestake(address indexed user);
  event Gift(address indexed user);
  
  constructor(address payable _dev, address payable _pro, uint256 preDate, uint256 startDate) public {
	require(!isContract(_dev));

	dev = _dev;
	pro = _pro;
	preUNIX = preDate;
	startUNIX = startDate;

    plans.push(Plan(14, 80));
    plans.push(Plan(21, 65));
    plans.push(Plan(28, 55));
	plans.push(Plan(35, 45));
    plans.push(Plan(14, 80));
    plans.push(Plan(21, 65));
    plans.push(Plan(28, 55));
	plans.push(Plan(35, 45));

    cashbacks.push(10);  // 1.0% base cashback for plan 1 
    cashbacks.push(15);  // 1.5% base cashback for plan 2
    cashbacks.push(20);  // 2.0% base cashback for plan 3
    cashbacks.push(25);  // 2.5% base cashback for plan 4
    cashbacks.push(30);  // 3.0% base cashback for plan 5
    cashbacks.push(35);  // 3.5% base cashback for plan 6
    cashbacks.push(40);  // 4.0% base cashback for plan 7
    cashbacks.push(50);  // 5.0% base cashback for plan 8
  }

  function invest(address referrer, uint8 plan) public payable {
    require(block.timestamp >= preUNIX, "Cannot stake yet");
    require(msg.value >= MIN_AMOUNT);
    require(plan < 8, "Invalid plan");

    dev.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
    pro.transfer(msg.value.mul(CONTRACT_FEE).div(PERCENTS_DIVIDER));

	User storage user = users[msg.sender];
	
	if (user.referrer == address(0)) {
      if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
	    user.referrer = referrer;
	  }

	  address upline = user.referrer;
      for (uint256 i = 0; i < 1; i++) {
	    if (upline != address(0)) {
	      users[upline].levels[i] = users[upline].levels[i].add(1);
		  upline = users[upline].referrer;
	    } else {
	      break;
	    }
      }
	}
	uint256 refsamount;

	if (user.referrer != address(0)) {
      address upline = user.referrer;
	  for (uint256 i = 0; i < 1; i++) {
	    if (upline != address(0)) {
		  uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
		  users[upline].bonus = users[upline].bonus.add(amount);
		  users[upline].totalBonus = users[upline].totalBonus.add(amount);
		  totalRefBonus = totalRefBonus.add(amount);
		  emit RefBonus(upline, msg.sender, i, amount);
		  upline = users[upline].referrer;
		} else {
		  uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
		  refsamount = refsamount.add(amount);
		}
	  }
	  if (refsamount > 0){
	    dev.transfer(refsamount.div(1));
	  }
	} else {
	  uint256 refsbkp = 60;
	  uint256 amount = msg.value.mul(refsbkp).div(PERCENTS_DIVIDER);
	  dev.transfer(amount.div(1));
    }

    bool firstOrSecondStake = false;
      
	if (user.deposits.length == 0) {
	  firstOrSecondStake = true;
	  user.checkpoint = block.timestamp;
	  emit Newbie(msg.sender);
	} else if (user.deposits.length == 1) {
	  firstOrSecondStake = true;
	}
	  
	(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
	  
	// PRE STAKE REWARDS ---
	// contract daily percent boost (plans 1-4)
	uint256 percentBoost = 0;
	// contract cashback percent boost (plans 5-8)
	uint256 cashbackBoost = 0;
	    
	if(block.timestamp >= preUNIX && block.timestamp < startUNIX && firstOrSecondStake) {
	    
	    if(plan == 0) { // extra daily return
	      if (msg.value >= 25 ether) { 
	        percentBoost = 15; // 1.5% daily boost
	      } else if (msg.value >= 2.5 ether) { 
	      	percentBoost = 8; // 0.8% daily boost
	      } else if (msg.value >= 1.2 ether) {
	        percentBoost = 7; // 0.7% daily boost  
	      } else if (msg.value >= 0.25 ether) {
	        percentBoost = 6; // 0.6% daily boost   
	      } else {
	        percentBoost = 5; // 0.5% daily boost 
	      }
	    } else if (plan == 1) { // extra daily return
	      if (msg.value >= 25 ether) { 
	        percentBoost = 20; // 2% daily boost
	      } else if (msg.value >= 2.5 ether) { 
	      	percentBoost = 10; // 1% daily boost
	      } else if (msg.value >= 1.2 ether) { 
	        percentBoost = 9; // 0.9% daily boost  
	      } else if (msg.value >= 0.25 ether) { 
	        percentBoost = 8; // 0.8% daily boost   
	      } else { // 10-99 ether = bronze reward
	        percentBoost = 7; // 0.7% daily boost 
	      }
	    } else if (plan == 2) { // extra daily return
	      if (msg.value >= 25 ether) { 
	        percentBoost = 30; // 3% daily boost
	      } else if (msg.value >= 2.5 ether) { 
	      	percentBoost = 11; // 1.1% daily boost
	      } else if (msg.value >= 1.2 ether) { 
	        percentBoost = 10; // 1% daily boost  
	      } else if (msg.value >= 0.25 ether) { 
	        percentBoost = 9; // 0.9% daily boost   
	      } else { // 10-99 ether = bronze reward
	        percentBoost = 8; // 0.8% daily boost 
	      }
	    } else if (plan == 3) { // extra daily return
	      if (msg.value >= 25 ether) {
	        percentBoost = 40; // 4% daily boost
	      } else if (msg.value >= 2.5 ether) { 
	      	percentBoost = 16; // 1.6% daily boost
	      } else if (msg.value >= 1.2 ether) {
	        percentBoost = 14; // 1.4% daily boost  
	      } else if (msg.value >= 0.25 ether) { 
	        percentBoost = 12; // 1.2% daily boost   
	      } else { 
	        percentBoost = 10; // 1% daily boost 
	      }
	    } else if (plan == 4) { // extra cashback
	      if (msg.value >= 25 ether) { 
	        cashbackBoost = 15; // 1.5% cashback boost
	      } else if (msg.value >= 2.5 ether) { 
	      	cashbackBoost = 10; // 1.0% cashback boost
	      } else if (msg.value >= 1.2 ether) {
	        cashbackBoost = 9; // 0.9% cashback boost
	      } else if (msg.value >= 0.25 ether) { 
	        cashbackBoost = 8; // 0.8% cashback boost
	      } else { 
	        cashbackBoost = 7; // 0.7% cashback boost
	      }
	    } else if (plan == 5) { // extra cashback
	      if (msg.value >= 25 ether) { 
	        cashbackBoost = 25; // 2.5% cashback boost
	      } else if (msg.value >= 2.5 ether) { 
	      	cashbackBoost = 20; // 2.0% cashback boost
	      } else if (msg.value >= 1.2 ether) { 
	        cashbackBoost = 18; // 1.8% cashback boost
	      } else if (msg.value >= 0.25 ether) {
	        cashbackBoost = 16; // 1.6% cashback boost
	      } else { 
	        cashbackBoost = 14; // 1.4% cashback boost
	      }
	    } else if (plan == 6) { // extra cashback
	      if (msg.value >= 25 ether) { 
	        cashbackBoost = 35; // 3.5% cashback boost
	      } else if (msg.value >= 2.5 ether) { 
	      	cashbackBoost = 30; // 3.0% cashback boost
	      } else if (msg.value >= 1.2 ether) { 
	        cashbackBoost = 28; // 2.8% cashback boost
	      } else if (msg.value >= 0.25 ether) { 
	        cashbackBoost = 26; // 2.6% cashback boost
	      } else {
	        cashbackBoost = 24; // 2.4% cashback boost
	      }
	    } else { // plan == 7, extra cashback
	      if (msg.value >= 25 ether) { 
	        cashbackBoost = 50; // 5.0% cashback boost
	      } else if (msg.value >= 2.5 ether) { 
	      	cashbackBoost = 45; // 4.5% cashback boost
	      } else if (msg.value >= 1.2 ether) {
	        cashbackBoost = 40; // 4.0% cashback boost
	      } else if (msg.value >= 0.25 ether) { 
	        cashbackBoost = 38; // 3.8% cashback boost
	      } else { 
	        cashbackBoost = 36; // 3.6% cashback boost
	      }   
	    }
	  }
	  
	// ADD PRESTAKE REWARD (1)
	// percent boost = bigger daily rewards
	percent = percent.add(percentBoost);
	  
	// INSTANT CASHBACK
	// base cashback + 1% for each deposit >= 0.15 BNB
	if(msg.value >= 0.15 ether) {
	  user.cashbackBonus = user.cashbackBonus + 10;
	}
    uint256 cashbackPct = cashbacks[plan].add(user.cashbackBonus);
    // max cashback = 8%
    if (cashbackPct > MAX_CASHBACK) {
      cashbackPct = MAX_CASHBACK;
    }
    
    // ADD PRESTAKE REWARD (2)
    // cashback boost = bigger cashback rewards
    cashbackPct = cashbackPct.add(cashbackBoost);
    uint256 cashback = msg.value.mul(cashbackPct).div(PERCENTS_DIVIDER);
    user.totalCashback = user.totalCashback.add(cashback);
    
    // send cashback to user
    msg.sender.transfer(cashback);
    emit Cashback(msg.sender, cashback);
    
    if(percentBoost > 0 || cashbackBoost > 0) {
      // Prestake reward!
      emit Prestake(msg.sender);
    }
    
	user.deposits.push(Deposit(plan, percent, msg.value, profit, cashback, block.timestamp, finish));
    emit NewDeposit(msg.sender, plan, percent, msg.value, profit, cashback, block.timestamp, finish);
	
	totalStaked = totalStaked.add(msg.value);
	totalCashback = totalCashback.add(cashback);
  }
  
  function withdraw() public {
    User storage user = users[msg.sender];
	uint256 totalAmount = getUserDividends(msg.sender);

	uint256 referralBonus = getUserReferralBonus(msg.sender);
	
	if (referralBonus > 0) {
	  user.bonus = 0;
	  totalAmount = totalAmount.add(referralBonus);
	}
	  
	require(totalAmount > 0, "User has no dividends");

	uint256 contractBalance = address(this).balance;
	  
	if (contractBalance < totalAmount) {
	  totalAmount = contractBalance;
	}

	user.checkpoint = block.timestamp;
	// transfer rewards
	msg.sender.transfer(totalAmount);
	emit Withdrawn(msg.sender, totalAmount);
  }

  function forceWithdraw(uint256 index) public {
    User storage user = users[msg.sender];

    require(index < user.deposits.length);
    require(user.deposits[index].plan >= 4 && user.deposits[index].plan < 8, 'force withdraw not valid');
    require(user.deposits[index].finish > block.timestamp, 'you can not force withdraw');

    uint256 depositAmount = user.deposits[index].amount;
    uint256 penaltyAmount = depositAmount.mul(PENALTY_STEP).div(PERCENTS_DIVIDER);

    msg.sender.transfer(depositAmount.sub(penaltyAmount));
    
    user.deposits[index] = user.deposits[user.deposits.length - 1];
    user.deposits.pop();
    
    emit ForceWithdrawn(msg.sender, depositAmount, penaltyAmount);
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 cashback) {
    time = plans[plan].time;
	percent = getPercent(plan);
	cashback = cashbacks[plan];
  }

  function getPercent(uint8 plan) public view returns (uint256) {
    if (block.timestamp > startUNIX) {
	  return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
	} else {
	  return plans[plan].percent;
	}
  }

  function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
    percent = getPercent(plan);

	if (plan < 4) {
	  profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
	} else if (plan < 8) {
	  for (uint256 i = 0; i < plans[plan].time; i++) {
	    profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
	  }
	}

	finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
  }

  function getUserDividends(address userAddress) public view returns (uint256) {
    User storage user = users[userAddress];

	uint256 totalAmount;

	for (uint256 i = 0; i < user.deposits.length; i++) {
	  if (user.checkpoint < user.deposits[i].finish) {
	    if (user.deposits[i].plan < 4) {
		  uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
		  uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
		  uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
		  if (from < to) {
		    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
		  }
		} else if (block.timestamp > user.deposits[i].finish) {
		  totalAmount = totalAmount.add(user.deposits[i].profit);
		}
	  }
	}

	return totalAmount;
  }

  function getUserCheckpoint(address userAddress) public view returns(uint256) {
    return users[userAddress].checkpoint;
  }

  function getUserReferrer(address userAddress) public view returns(address) {
    return users[userAddress].referrer;
  }
  
  function getUserTotalCashback(address userAddress) public view returns(uint256) {
    return users[userAddress].totalCashback;
  }
  
  function getUserCashbackBonus (address userAddress) public view returns(uint256) { 
    return users[userAddress].cashbackBonus;
  }


  function getUserReferralBonus(address userAddress) public view returns(uint256) {
    return users[userAddress].bonus;
  }

  function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
    return users[userAddress].totalBonus;
  }

  function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
    return users[userAddress].totalBonus.sub(users[userAddress].bonus);
  }

  function getUserAvailable(address userAddress) public view returns(uint256) {
    return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
  }

  function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
    return users[userAddress].deposits.length; 
  }

  function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
    for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
	  amount = amount.add(users[userAddress].deposits[i].amount);
	}
  }

  function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 cashback, uint256 start, uint256 finish) {
    User storage user = users[userAddress];

	plan = user.deposits[index].plan;
	percent = user.deposits[index].percent;
	amount = user.deposits[index].amount;
	profit = user.deposits[index].profit;
	cashback = user.deposits[index].cashback;
	start = user.deposits[index].start;
	finish = user.deposits[index].finish;
  }

  function getBaseCashback(uint8 plan) public view returns (uint256) {
    return cashbacks[plan];
  }

  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}