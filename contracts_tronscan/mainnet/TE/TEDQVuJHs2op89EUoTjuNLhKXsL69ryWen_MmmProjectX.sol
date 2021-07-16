//SourceUnit: MmmProjectX.sol


pragma solidity 0.5.10;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MmmProjectX {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 50e6;
	uint256 constant public INVEST_MAX_AMOUNT = 10000e6;
	uint256 constant public WITHDRAW_MIN_AMOUNT = 100e6;

	uint256[] public REFERRAL_PERCENTS = [50, 30, 20, 10, 10, 30];
	uint256 public constant PROJECT_FEE = 50;
	uint256 public constant POOL_PERCENTS = 20;
	uint256 public constant INSUR_PERCENTS = 20;
	uint256 public constant REINVEST_PERCENTS = 250;
	uint256 public constant BACK_TO_CONTRACT_PERCENTS = 200;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public MAX_PERCENT = 155;
	uint256 constant public TIME_STEP = 1 days;

	mapping (uint8=>address) public poolDayTop;

	uint256[] public topBonusPercents = [300, 150, 150, 100, 50, 50, 50, 50, 50, 50];

	uint256 public poolAmount;
	uint256 public poolLastReward;

	uint256 public totalStaked;
	uint256 public totalUsers;
	uint256 public totalInsurance;
	uint256 public totalBack;
	uint256 public totalReinvest;

	address public usdtAddr;
	address payable public feeReceiver;
	address payable public insurReceiver;

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
		uint256[6] levels;
		uint256 bonus;
        uint256 totalBonus;
		uint256 dayDeposit;
        uint256 totalDeposit;
        uint256 totalWithdrawn;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 amount);

	constructor(
		address payable _feeReceiver, 
		address payable _insurReceiver,
		address _usdtAddr, 
		uint256 _startDate
	) 
		public 
	{
        feeReceiver = _feeReceiver;
		insurReceiver = _insurReceiver;
		usdtAddr = _usdtAddr;
        if(_startDate == 0){
            startUNIX = block.timestamp;
        }else{
		    startUNIX = _startDate;
        }

        plans.push(Plan(16, 80));
        plans.push(Plan(23, 70));
        plans.push(Plan(30, 60));
        plans.push(Plan(16, 100));
        plans.push(Plan(23, 90));
        plans.push(Plan(30, 80));
	}

    function invest(address _referrer, uint8 _plan, uint256 _amount) public {
        require(_plan < 6, "invalid plan");
        require(_amount >= INVEST_MIN_AMOUNT && _amount <= INVEST_MAX_AMOUNT, "invest amount error");
		ITRC20(usdtAddr).transferFrom(msg.sender, address(this), _amount);
		_updateTop(msg.sender, _amount);
        _invest(msg.sender, _referrer, _plan, _amount);
    }

	function _invest(address _user, address _referrer, uint8 _plan, uint256 _amount) internal {
		uint256 feeInvest = _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		ITRC20(usdtAddr).transfer(feeReceiver, feeInvest);
		emit FeePayed(_user, feeInvest);
		User storage user = users[_user];

		if (user.referrer == address(0)) {
			if (users[_referrer].deposits.length > 0 && _referrer != _user) {
				user.referrer = _referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 6; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 6; i++) {
				if (upline != address(0)) {
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, _user, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(_user);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(_plan, _amount);
		user.deposits.push(Deposit(_plan, percent, _amount, profit, block.timestamp, finish));
		user.totalDeposit = user.totalDeposit.add(_amount);
		totalStaked = totalStaked.add(_amount);
		emit NewDeposit(_user, _plan, percent, _amount, profit, block.timestamp, finish);
	}


    function _updateTop(address _user, uint256 _amount) internal {
		User storage user = users[_user];
		// update last
		if(poolLastReward.add(TIME_STEP) <= block.timestamp){
			poolLastReward = block.timestamp;
			user.dayDeposit = 0;

			// reward highest 10
			for(uint8 i = 0; i < 10; i++){
				if(poolDayTop[i] != address(0)){
					uint256 bonusAmount = poolAmount.mul(topBonusPercents[i]).div(PERCENTS_DIVIDER);
					// reward
					users[poolDayTop[i]].bonus = users[poolDayTop[i]].bonus.add(bonusAmount);
					// reset day top
					poolDayTop[i] = address(0);
				}
			}
			poolAmount = 0;
		}

		user.dayDeposit = user.dayDeposit.add(_amount);
		poolAmount = poolAmount.add(_amount.mul(POOL_PERCENTS).div(PERCENTS_DIVIDER));

        for(uint8 i = 0; i < 10; i++){
			if(poolDayTop[i] == _user){
				for(uint8 j = i; j < 10; j++){
					poolDayTop[j] = poolDayTop[j + 1];
				}
			}
        }

        for(uint8 i = 0; i < 10; i++){
            if(users[poolDayTop[i]].dayDeposit < user.dayDeposit){
                for(uint8 j = 9; j > i; j--){
                    poolDayTop[j] = poolDayTop[j - 1];
                }
                poolDayTop[i] = _user;
				break;
            }
        }
        
    }

	function withdraw(uint8 _plan) public {
		User storage user = users[msg.sender];
        require(user.checkpoint.add(TIME_STEP) < block.timestamp, "Withdrawal time is not reached");

		uint256 withdrawable = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		uint256 totalAmount = withdrawable.add(referralBonus);
		require(totalAmount > WITHDRAW_MIN_AMOUNT, "not enough");

		uint256 reInvest = withdrawable.mul(REINVEST_PERCENTS).div(PERCENTS_DIVIDER);
		totalReinvest = totalReinvest.add(reInvest);
		// reinvest
		(uint256 percent, uint256 profit, uint256 finish) = getResult(_plan, reInvest);
		user.deposits.push(Deposit(_plan, percent, reInvest, profit, block.timestamp, finish));
		user.totalDeposit = user.totalDeposit.add(reInvest);
		totalStaked = totalStaked.add(reInvest);

		withdrawable = withdrawable.sub(reInvest);
		uint256 backToContract = withdrawable.mul(BACK_TO_CONTRACT_PERCENTS).div(PERCENTS_DIVIDER);
		totalBack = totalBack.add(backToContract);
		uint256 feeDividends = withdrawable.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 insurDividends = withdrawable.mul(INSUR_PERCENTS).div(PERCENTS_DIVIDER);
		totalInsurance = totalInsurance.add(insurDividends);
		withdrawable = withdrawable.sub(backToContract).sub(feeDividends).sub(insurDividends);

		uint256 feeReferral;
		uint256 insurReferral;
		if (referralBonus > 0) {
			user.bonus = 0;
			feeReferral = referralBonus.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
			insurReferral = referralBonus.mul(INSUR_PERCENTS).div(PERCENTS_DIVIDER);
			withdrawable = withdrawable.add(referralBonus.sub(feeReferral).sub(insurReferral));
		}

		ITRC20(usdtAddr).transfer(feeReceiver, feeDividends.add(feeReferral));
		ITRC20(usdtAddr).transfer(insurReceiver, insurDividends.add(insurReferral));
		
		uint256 contractBalance = ITRC20(usdtAddr).balanceOf(address(this));
		if (contractBalance < withdrawable) {
			withdrawable = contractBalance;
		}
        
		user.checkpoint = block.timestamp;
		user.totalWithdrawn = user.totalWithdrawn.add(withdrawable);
		ITRC20(usdtAddr).transfer(msg.sender, withdrawable);
		emit Withdrawn(msg.sender, withdrawable);

	}

	function getContractInfo() public view returns(uint256[5] memory) {
		uint256[5] memory info;
		info[0] = totalStaked;
		info[1] = totalBack;
		info[2] = totalReinvest;
		info[3] = totalUsers;
		info[4] = poolAmount;
		return info;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			uint256 dayPercent = PERCENT_STEP.mul(block.timestamp.sub(startUNIX).div(TIME_STEP));
			uint256 percent = plans[plan].percent.add(dayPercent.mod(MAX_PERCENT.sub(plans[plan].percent)));
			return percent;
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256, uint256, uint256) {
		uint256 percent = getPercent(plan);
		uint256 profit;
		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		uint256 finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));

		return(percent, profit, finish);
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

	function getTopInfo() public view returns(address[10] memory, uint256[10] memory, uint256[10] memory) {
		address[10] memory topUsers;
		uint256[10] memory topInvest;
		uint256[10] memory bonusNow;

		for(uint8 i = 0; i < 10; i++){
			topUsers[i] = poolDayTop[i];
			topInvest[i] = users[poolDayTop[i]].dayDeposit;
			bonusNow[i] = poolAmount.mul(topBonusPercents[i]).div(PERCENTS_DIVIDER);
		}
		return(topUsers, topInvest, bonusNow);
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[6] memory) {
		uint256[6] memory levels;
		levels[0] = users[userAddress].levels[0];
		levels[1] = users[userAddress].levels[1];
		levels[2] = users[userAddress].levels[2];
		levels[3] = users[userAddress].levels[3];
		levels[4] = users[userAddress].levels[4];
		levels[5] = users[userAddress].levels[5];
		return levels;
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

	function getUserAvailable(address userAddress) public view returns(uint256, uint256) {
		uint256 withdrawable = getUserDividends(userAddress);
		uint256 referralBonus = getUserReferralBonus(userAddress);

		uint256 reInvest = withdrawable.mul(REINVEST_PERCENTS).div(PERCENTS_DIVIDER);
		withdrawable = withdrawable.sub(reInvest);
		uint256 backToContract = withdrawable.mul(BACK_TO_CONTRACT_PERCENTS).div(PERCENTS_DIVIDER);
		uint256 feeDividends = withdrawable.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 insurDividends = withdrawable.mul(INSUR_PERCENTS).div(PERCENTS_DIVIDER);
		withdrawable = withdrawable.sub(backToContract).sub(feeDividends).sub(insurDividends);

		uint256 feeReferral;
		uint256 insurReferral;
		if (referralBonus > 0) {
			feeReferral = referralBonus.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
			insurReferral = referralBonus.mul(INSUR_PERCENTS).div(PERCENTS_DIVIDER);
			withdrawable = withdrawable.add(referralBonus.sub(feeReferral).sub(insurReferral));
		}
		
		uint256 contractBalance = ITRC20(usdtAddr).balanceOf(address(this));
		if (contractBalance < withdrawable) {
			withdrawable = contractBalance;
		}

		return(withdrawable, reInvest);

	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDeposits(address userAddress) public view returns(uint8[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
		User storage user = users[userAddress];

		uint256 len = users[userAddress].deposits.length;
		uint8[] memory userPlans = new uint8[](len);
		uint256[] memory userPercents = new uint256[](len);
		uint256[] memory userAmounts = new uint256[](len);
		uint256[] memory userProfits = new uint256[](len);
		uint256[] memory userStarts = new uint256[](len);
		uint256[] memory userFinishs = new uint256[](len);
		for(uint256 i = 0; i < len; i++){
			userPlans[i] = user.deposits[i].plan;
			userPercents[i] = user.deposits[i].percent;
			userAmounts[i] = user.deposits[i].amount;
			userProfits[i] = user.deposits[i].profit;
			userStarts[i] = user.deposits[i].start;
			userFinishs[i] = user.deposits[i].finish;
		}

		return(userPlans, userPercents, userAmounts, userProfits, userStarts, userFinishs);
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8, uint256, uint256, uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		uint8 plan = user.deposits[index].plan;
		uint256 percent = user.deposits[index].percent;
		uint256 amount = user.deposits[index].amount;
		uint256 profit = user.deposits[index].profit;
		uint256 start = user.deposits[index].start;
		uint256 finish = user.deposits[index].finish;
		return(plan, percent, amount, profit, start, finish);
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