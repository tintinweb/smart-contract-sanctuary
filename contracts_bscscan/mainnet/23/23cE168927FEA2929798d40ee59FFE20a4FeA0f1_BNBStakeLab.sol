/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

pragma solidity >=0.8.0;

contract BNBStakeLab {
	using SafeMath for uint256;
	
	struct Plan {
        uint256 time;
        uint256 percent;
    }

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
		address referrer;
		uint256 checkpoint;
		uint256 refBonus;
		uint256 refEarned;
		uint256[3] levels;
	}
	
	uint256[] public REFERRAL_PERCENTS = [50, 25, 5];
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	address payable public owner;
    uint256 public start_ts;
	uint256 public totalStaked;
	
	mapping (address => User) public users;
    Plan[] internal plans;
    
    event Deposited(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);

	constructor() {
		start_ts = block.timestamp;
		owner = payable(msg.sender);

        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
	}

	function invest(uint8 plan, address referrer) public payable {
 		require(msg.value >= 0.05 ether, "Minimum deposit amount is 0.05 BNB");
        require(plan < 6, "Invalid plan");
        
        owner.transfer(msg.value.mul(10).div(100));
        
		User storage user = users[msg.sender];
		
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].refBonus = users[upline].refBonus.add(amount);
					users[upline].refEarned = users[upline].refEarned.add(amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(msg.value);
		emit Deposited(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	
	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		
		if (referralBonus > 0) {
			user.refBonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		require(totalAmount >= 0.05 ether, "Minimum withdraw amount is 0.05 BNB");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
        
		user.checkpoint = block.timestamp;

		payable(msg.sender).transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
    function getUserDeposit(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}
	
	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	function getUserDepositsLength(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].refBonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserReferralEarned(address userAddress) public view returns(uint256) {
		return users[userAddress].refEarned;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return getUserReferralEarned(userAddress).sub(getUserReferralBonus(userAddress));
	}
	
	function getUserLevels(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getOwner() public view returns(address) {
		return owner;
	}

	function getTotalStaked() public view returns(uint256) {
		return totalStaked;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
        
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    uint256 profit;
		    uint256 from;
		    uint256 to;
		 
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					profit = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					
					if (from < to) {
					    profit = profit.mul(to.sub(from)).div(TIME_STEP);
					}
					
				} else if (block.timestamp > user.deposits[i].finish) {
				    profit = user.deposits[i].profit;
				}
			}
			
			if(profit > 0) {              
    			totalAmount = totalAmount.add(profit);
			}
		}

		return totalAmount;
	}

	function getPercent(uint8 plan) internal view returns (uint256) {
		return (block.timestamp > start_ts) ? plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(start_ts)).div(TIME_STEP)) : plans[plan].percent;
    }

	function getResult(uint8 plan, uint256 deposit) internal view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
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