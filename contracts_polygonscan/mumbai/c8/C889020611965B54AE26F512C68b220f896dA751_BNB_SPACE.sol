/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

pragma solidity 0.5.8;

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

contract BNB_SPACE {
	using SafeMath for uint256;
	
	uint256[] public REFERRAL_PERCENTS = [40, 20, 7, 5];
	uint256 constant public FEE = 40;
	uint256 constant public PERCENT_STEP = 10;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TIME_TO_START = 47 * 60 * 60;
	uint256 constant public PLAN3_REFUNDTIME = 1 days;

	uint256 public totalStaked;
	uint256 public totalUsers;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 cashback;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[4] levels;
		uint256 bonus;
		uint256 totalBonus;
		bool[4] inPlan;
		uint256 lastPlan3_Indx;
	}

	mapping (address => User) internal users;
	
	uint256 public startTime;
	uint256 public createTime;
	address payable public owner;
	address payable public adv_1;
	address payable public adv_2;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 cashbackPercent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable _adv1, address payable _adv2) public {
		require(!isContract(msg.sender));
		owner = msg.sender;
		adv_1 = _adv1;
		adv_2 = _adv2;
		createTime = block.timestamp;
		startTime = createTime.add(TIME_TO_START);
        plans.push(Plan( 13, 100,   0));
        plans.push(Plan( 13,  90, 100));
        plans.push(Plan( 13,  80, 200));
        plans.push(Plan(100,  10,   0));
	}
	
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }	

	function checkDeposit(address usr, uint8 plan, uint256 amount) internal view returns (bool) {
		if ( (plan == 0 && amount >= 0.05 ether) ||
		     (plan == 1 && amount >= 1 ether)    || 
		     (plan == 2 && amount >= 5 ether)    ||  
		     (plan == 3 && amount == 50 ether && users[usr].inPlan[2] && !users[usr].inPlan[3])) {
		    return true;
		} else {
		    return false;
		}
	}

	function invest(address referrer, uint8 plan) public payable {
        require(block.timestamp > startTime, "Contract not launched yet");	    
        require(checkDeposit(msg.sender, plan, msg.value), "Invalid Plan Number or Plan Requirements");

		uint256 fee = msg.value.mul(FEE).div(PERCENTS_DIVIDER);
		owner.transfer(fee);
		adv_1.transfer(fee);
		adv_2.transfer(fee);
		
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && msg.sender != owner) {
			if (users[referrer].deposits.length == 0) {
				referrer = owner;
			}
			user.referrer = referrer;
			
			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		
		if (!user.inPlan[plan]) {
		    user.inPlan[plan] = true;
		    if (plan == 3) {
		        user.lastPlan3_Indx = user.deposits.length;
		    }
		}
		
		(uint256 percent, uint256 cashbackPercent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));
		
		if (cashbackPercent != 0) {
		    uint256 cb = msg.value.mul(cashbackPercent).div(PERCENTS_DIVIDER);
		    msg.sender.transfer(cb);
		}

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, cashbackPercent, msg.value, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 totalDividends = getUserDividends(msg.sender).add(getUserReferralBonus(msg.sender));
		require(totalDividends > 0, "There is no dividends");
        user.bonus = 0;
		user.checkpoint = block.timestamp;
		msg.sender.transfer(totalDividends);
		emit Withdrawn(msg.sender, totalDividends);
	}
	
	function refund() public {
		User storage user = users[msg.sender];
		uint256 indx = user.lastPlan3_Indx;
		require(user.inPlan[3]);
		require(block.timestamp > user.deposits[indx].start + PLAN3_REFUNDTIME);
        uint256 refundAmount = user.deposits[indx].amount;
        require(refundAmount > 0, "Refund amount = 0");
		uint256 totalDividends = refundAmount.add(getUserDividends(msg.sender)).add(getUserReferralBonus(msg.sender));
        user.deposits[indx].amount = 0;
        user.deposits[indx].finish = block.timestamp;
        user.bonus = 0;
		user.checkpoint = block.timestamp;
		msg.sender.transfer(totalDividends);
		emit Withdrawn(msg.sender, totalDividends);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 cashback) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		cashback = plans[plan].cashback;
	}

	function getDailyPercent(uint8 plan) public view returns (uint256) {
		if (plan == 0) {
		    uint256 elapsedDays = minZero(block.timestamp, startTime).div(TIME_STEP);
		    uint256 percent_add = minVal(40, PERCENT_STEP.mul(elapsedDays));
			return plans[plan].percent.add(percent_add);
		} else {
			return plans[plan].percent;
		}
    }
    
	function getCashbackPercent(uint8 plan) public view returns (uint256) {
		    uint256 elapsedDays = minZero(block.timestamp, startTime).div(TIME_STEP);
		    uint256 percent_add;
		    if (plan == 1) {
		        percent_add = minVal(200, elapsedDays.mul(50));
		    } else 
		    if (plan == 2) {
		        percent_add = minVal(400, elapsedDays.mul(100));
		    } else {
		        percent_add = 0;
		    }
			return plans[plan].cashback.add(percent_add);
    }    

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint cashback, uint256 profit, uint256 finish) {
		percent = getDailyPercent(plan);
		cashback = getCashbackPercent(plan);
	    profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalAmount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}
		return totalAmount;
	}
	
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a.sub(b); 
        } else {
           return 0;    
        }    
    }   
    
    function minVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }	

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3]);
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
	
	function getUserInPlan(address userAddress) public view returns(bool plan0, bool plan1, bool plan2, bool plan3) {
		return (users[userAddress].inPlan[0], users[userAddress].inPlan[1], users[userAddress].inPlan[2], users[userAddress].inPlan[3]);
	}	

	function getUserPlan3RefundTime(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
	    if (user.inPlan[3]) {
		    return minZero(user.deposits[user.lastPlan3_Indx].start + PLAN3_REFUNDTIME, block.timestamp);
	    } else {
	        return 0;
	    }
	}
	
	function getContractLaunchTime() public view returns(uint256) {
		return minZero(startTime, block.timestamp);
	}	

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}
}