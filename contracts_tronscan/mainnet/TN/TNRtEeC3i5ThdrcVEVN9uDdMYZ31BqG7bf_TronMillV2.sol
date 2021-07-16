//SourceUnit: Contract_Updated.sol

 /*   TronMillV2 - NEXT GENERATION COMMUNITY PROGRAM, Safe and Secure.
 *


████████╗██████╗  ██████╗ ███╗   ██╗    ███╗   ███╗██╗██╗     ██╗         ██╗   ██╗██████╗     ██████╗ 
╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║    ████╗ ████║██║██║     ██║         ██║   ██║╚════██╗   ██╔═████╗
   ██║   ██████╔╝██║   ██║██╔██╗ ██║    ██╔████╔██║██║██║     ██║         ██║   ██║ █████╔╝   ██║██╔██║
   ██║   ██╔══██╗██║   ██║██║╚██╗██║    ██║╚██╔╝██║██║██║     ██║         ╚██╗ ██╔╝██╔═══╝    ████╔╝██║
   ██║   ██║  ██║╚██████╔╝██║ ╚████║    ██║ ╚═╝ ██║██║███████╗███████╗     ╚████╔╝ ███████╗██╗╚██████╔╝
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝╚══════╝╚══════╝      ╚═══╝  ╚══════╝╚═╝ ╚═════╝ 
                                                                                                       

 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.tronmill.site                                  │
 *   │                                                                       │
 *   │   Telegram Public Group: @Tr0nMill0fficial                            |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 */


pragma solidity 0.5.10;

contract TronMillV2 {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 200 trx;
	uint256 constant public INVEST_MAX_AMOUNT = 50000 trx;

	uint256[] public REFERRAL_PERCENTS = [50, 30, 10];
	uint256[] public PROJECT_FEE = [50, 50, 20, 20];
    address payable public feeOwner;
    address payable public feeDevTeam;
    address payable public feeMarketing;
    address payable public feeBlockchain;
    address payable public insuaranceFee;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
	uint256 public totalUsers;
	uint256 public totalRefBonus;
    uint256 public miniPeriod = 24 hours;

    struct Plan {
        uint256 time;
        uint256 percent;
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
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalDeposit;
		uint256 totalWithdrawn;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user0, uint256 amount0, uint256 amount1, uint256 amount2,  uint256 amount3);

	constructor(
	    address payable _feeOwner,
	    address payable _feeDevTeam, 
	    address payable _feeMarketing, 
	    address payable _feeBlockchain, 
	    address payable _insuaranceFee, 
	    uint256 _startDate
	    ) public {
        feeOwner = _feeOwner;
        feeDevTeam = _feeDevTeam;
        feeMarketing = _feeMarketing;
        feeBlockchain = _feeBlockchain;
		insuaranceFee = _insuaranceFee;
        if(_startDate == 0){
            startUNIX = block.timestamp;
        }else{
		    startUNIX = _startDate;
        }

        plans.push(Plan(14, 70));
        plans.push(Plan(21, 60));
        plans.push(Plan(28, 50));
        plans.push(Plan(14, 140));
        plans.push(Plan(21, 120));
        plans.push(Plan(28, 100));
	}

    function invest(address referrer, uint8 plan) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "invest amount error");
        _invest(referrer, plan, msg.value);
    }

	function _invest(address _referrer, uint8 _plan, uint256 _amount) internal {
        require(_plan < 6, "Invalid plan");

		uint256 fee0 = _amount.mul(PROJECT_FEE[0]).div(PERCENTS_DIVIDER);
		uint256 fee1 = _amount.mul(PROJECT_FEE[1]).div(PERCENTS_DIVIDER);
		uint256 fee2 = _amount.mul(PROJECT_FEE[2]).div(PERCENTS_DIVIDER);
		uint256 fee3 = _amount.mul(PROJECT_FEE[3]).div(PERCENTS_DIVIDER);
		feeOwner.transfer(fee0);
		feeDevTeam.transfer(fee1);
		feeMarketing.transfer(fee2);
		feeBlockchain.transfer(fee3);
		emit FeePayed(msg.sender, fee0, fee1, fee2, fee3);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[_referrer].deposits.length > 0 && _referrer != msg.sender) {
				user.referrer = _referrer;
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
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
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

		(uint256 percent, uint256 profit, uint256 finish) = getResultInvest(_plan, _amount);
		user.deposits.push(Deposit(_plan, percent, _amount, profit, block.timestamp, finish));
		user.totalDeposit = user.totalDeposit.add(_amount);
		totalStaked = totalStaked.add(_amount);
		emit NewDeposit(msg.sender, _plan, percent, _amount, profit, block.timestamp, finish);
	}
	
	function bonusReinvest(uint8 _plan) public payable {
	    
	    User storage user = users[msg.sender];
	    require(user.checkpoint.add(miniPeriod) < block.timestamp, "Withdrawal time is not reached");
	    
	    uint256 referralBonus = getUserReferralBonus(msg.sender);
		
		if (referralBonus > 0) {
			user.bonus = 0;
		}
		
		(uint256 percent, uint256 profit, uint256 finish) = getResultInvest(_plan, referralBonus);
		user.deposits.push(Deposit(_plan, percent, referralBonus, profit, block.timestamp, finish));
		user.totalDeposit = user.totalDeposit.add(referralBonus);
		totalStaked = totalStaked.add(referralBonus);
		emit NewDeposit(msg.sender, _plan, percent, referralBonus, profit, block.timestamp, finish);
	}
	
	function withdraw(uint8 _plan) public payable {
		User storage user = users[msg.sender];
        require(user.checkpoint.add(miniPeriod) < block.timestamp, "Withdrawal time is not reached");

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
        
		user.checkpoint = block.timestamp;
		uint256 reInvestAmount = totalAmount.mul(40).div(100);

		(uint256 percent, uint256 profit, uint256 finish) = getResultWithdraw(_plan, reInvestAmount);
		user.deposits.push(Deposit(_plan, percent, reInvestAmount, profit, block.timestamp, finish));
		user.totalDeposit = user.totalDeposit.add(reInvestAmount);
		totalStaked = totalStaked.add(reInvestAmount);

		uint256 withdrawAmount = totalAmount.sub(reInvestAmount);
		uint256 feeAmount = withdrawAmount.mul(5).div(100);
		uint256 realWithdraw = withdrawAmount.sub(feeAmount);
		insuaranceFee.transfer(feeAmount);
		user.totalWithdrawn = user.totalWithdrawn.add(realWithdraw);
		msg.sender.transfer(realWithdraw);
		emit Withdrawn(msg.sender, withdrawAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getTotalDeposit() public view returns(uint256) {
		return totalStaked;
	}

	function getTotalUsers() public view returns(uint256) {
		return totalUsers;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}


	function getPercentInvest(uint8 plan) public view returns (uint256) {
			return plans[plan].percent;
    }
    
    
	function getPercentWithdraw(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }


	function getResultInvest(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercentInvest(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}
	
	function getResultWithdraw(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercentWithdraw(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
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
				if (user.deposits[i].plan < 3) {
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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
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

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].totalDeposit;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalWithdrawn;
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

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}