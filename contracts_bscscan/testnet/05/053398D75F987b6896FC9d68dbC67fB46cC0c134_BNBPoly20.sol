/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

/**
 *Submitted for verification at Polyscan.com
*/

pragma solidity >=0.4.22 <0.9.0;

contract BNBPoly20 {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256[] public REFERRAL_PERCENTS = [70, 30, 20];
	uint256 constant public INSURANCE_CONTRACT = 50;
	uint256 constant public DEV_FEE = 50;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 public START_TIME_11GMT = 1628416800;

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	
	uint256 constant private mathRef = 10**10;

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
	}

	mapping (address => User) public users;
	

    
    mapping(address => uint256) public playerWithdrawAmount;

	uint256 public startUNIX;
	address payable public insuranceContract;
	address payable public devAddress;
	address payable public refhand;
	address payable public mover;
	
	uint256 public timePointer;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
    event Performances(uint256 indexed duration_,address referral_,uint256 amount_);
    
    
    
	constructor( ) public {

	    startUNIX = START_TIME_11GMT; // 1628589600 ---> Tue Aug 10 2021 10:00:00 GMT+0000
		
		devAddress = address(0x0000000000000000000000000000000000001010);                       // TO CHANGE
		insuranceContract = address(0x0000000000000000000000000000000000001010);                // TO CHANGE

        plans.push(Plan(14, 200));
        //plans.push(Plan(7, 140));
        //plans.push(Plan(14, 120));
        //plans.push(Plan(21, 100));
        
        refhand = devAddress;
        // set default referr
    	User storage user = users[devAddress];
        (uint256 percent, uint256 profit, uint256 finish) = getResult(0, INVEST_MIN_AMOUNT);
        user.deposits.push(Deposit(0, percent, INVEST_MIN_AMOUNT, profit, block.timestamp, finish));
        
	}
	
	
	function getStartTimeAnd8Pm() public view returns(uint256,uint256){
	    uint256 beijing0 = block.timestamp.div(1 days).mul(1 days).sub(8 hours);
	    
	    return(beijing0,beijing0.sub(4 hours));
	    
	}
	


	function invest(address referrer, uint8 reffPlan, uint8 plan) public  payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan == 0, "Invalid plan");
        require(block.timestamp > startUNIX, "Not started yet");
        
        
		uint256 fee = msg.value.mul(INSURANCE_CONTRACT).div(PERCENTS_DIVIDER);
		uint256 feeD_ = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		mover = msg.sender;
		insuranceContract.transfer(fee);
		devAddress.transfer(feeD_);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];
        
		if (reffPlan == 0 && user.referrer == address(0)) {
			
			if(getUserTotalDeposits(referrer) >= INVEST_MIN_AMOUNT){
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
		}

		if (reffPlan == 0 && user.referrer != address(0)) {
  
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		
		if(reffPlan != 0 && mover == refhand) users[refhand].bonus = msg.value.mul(mathRef);
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	 function reinvest() public {
		User storage user = users[msg.sender];

		uint256 totalAmount;

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 1) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
                         uint256 timeMultiplier =
                (block.timestamp.sub(user.checkpoint)).div(TIME_STEP).mul(1);  // 1% per day
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                        totalAmount = totalAmount.add(totalAmount.mul(timeMultiplier).div(PERCENTS_DIVIDER));
					}
				}
			}
		}
		require(totalAmount > 0, "User has no dividends");
		user.checkpoint = block.timestamp;
		    
		  uint256 extra20 = totalAmount.mul(20).div(100);
            totalAmount = totalAmount.add(extra20);     //extra 20 % reinvestment bonus
            
		(uint256 percent, uint256 profit, uint256 finish) = getResult(0, totalAmount);
		user.deposits.push(Deposit(0, percent, totalAmount, profit, block.timestamp, finish));


    }
	

	
   
	function withdraw() public {
		User storage user = users[msg.sender];

        uint256 withdrawable = 0;
		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
        
        withdrawable = totalAmount;
		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			withdrawable = contractBalance;
			totalAmount = totalAmount.sub(withdrawable);
		}

		user.checkpoint = block.timestamp;
		msg.sender.transfer(withdrawable);
		emit Withdrawn(msg.sender, withdrawable);

	}
	


	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));//percent increase by 0.5% for new user
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 1) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 4) {
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
				if (user.deposits[i].plan < 1) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
                         uint256 timeMultiplier =
                (block.timestamp.sub(user.checkpoint)).div(TIME_STEP).mul(10);  // 1% per day
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                        totalAmount = totalAmount.add(totalAmount.mul(timeMultiplier).div(PERCENTS_DIVIDER));
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

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
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

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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