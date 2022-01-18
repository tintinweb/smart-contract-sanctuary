/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

/**
 * Telegram Officials : t.me/bnbmeed
   Website : Bnbmeed.com
*/


pragma solidity 0.5.8;

contract BNBMeed {
	using SafeMath for uint256;

	uint256 constant public MIN_INVEST = 0.02 ether;
	uint256[] public REFERRAL_PERCENTS = [40, 20, 20];
	uint256 constant public ADV_FEE = 40;
	uint256 constant public PERCENT_STEP = 3; 
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public HOLD_BONUS = 5;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
	uint256 public totalUsers;
	uint256 public totalRefBonus;

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
		uint256 checkpointHold;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalPlanWithdrawn;
		uint256 totalHoldWithdrawn;
		uint256 holdBonus;
		bool wFlag;
	}

	mapping (address => User) internal users;

	uint256 public startTime = 1635364800; // Wed, 27 Oct 2021 20:00:00 UTC 

	address payable private owner;
	address payable private prj_1;
	address payable private adv_1;
	address payable private adv_2;
	

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable _adv1, address payable _adv2,  address payable _prj1) public {
		require(!isContract(msg.sender));
		owner = msg.sender;
		prj_1 = _prj1;
		adv_1 = _adv1;
		adv_2 = _adv2;
		
        plans.push(Plan(19, 60));
        plans.push(Plan(25, 50));
        plans.push(Plan(35, 40));
        plans.push(Plan(24, 60));
        plans.push(Plan(35, 50));
        plans.push(Plan(50, 40));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp > startTime, "Contract not start yet");	
		require(plan < 6, "Invalid plan");
		
		User storage user = users[msg.sender];
	
		uint investAmount;
		
		if (plan < 3) {
		    investAmount = msg.value;
		} else {
		    require(msg.value == 0, "Amount must be 0");
		    investAmount = getUserDividends(msg.sender);
		    user.checkpoint = block.timestamp;
		}		
		
		require(investAmount >= MIN_INVEST);

		uint256 fee = investAmount.mul(ADV_FEE).div(PERCENTS_DIVIDER);
		adv_1.transfer(fee);
		adv_2.transfer(fee);
		prj_1.transfer(fee);
		
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
				if (upline == address(0)) {
				    upline = owner;
				}
				uint256 amount = investAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(amount);
				users[upline].totalBonus = users[upline].totalBonus.add(amount);
				emit RefBonus(upline, msg.sender, i, amount);
				upline = users[upline].referrer;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.checkpointHold = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, investAmount);
		user.deposits.push(Deposit(plan, percent, investAmount, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(investAmount);
		emit NewDeposit(msg.sender, plan, percent, investAmount, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		require(totalAmount > 0, "User has no dividends");
		
		user.checkpoint = block.timestamp;
		
		if (user.wFlag == false) {
		    user.holdBonus = getUserHoldBonus(msg.sender);
		    user.wFlag = true;
		}
		
		user.totalPlanWithdrawn = user.totalPlanWithdrawn.add(totalAmount);
		msg.sender.transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
	function withdrawRef() public {
		User storage user = users[msg.sender];
		
		uint totalAmount = getUserReferralBonus(msg.sender);
		require(totalAmount > 0, "User has no dividends");
        
        user.bonus = 0;
        
		if (user.wFlag == false) {
		    user.holdBonus = getUserHoldBonus(msg.sender);
		    user.wFlag = true;
		}        

		msg.sender.transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}	
	
	function withdrawHold() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserHoldBonus(msg.sender);
		require(totalAmount > 0, "User has no dividends");

        user.holdBonus = 0;
		user.checkpointHold = block.timestamp;
		
		user.totalHoldWithdrawn = user.totalHoldWithdrawn.add(totalAmount);
		msg.sender.transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}	

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function getUserBalance(address userAddress) public view returns (uint256) {
		return address(userAddress).balance;
	}	

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startTime && plan > 2) {
		    uint pAdd = minVal(60, PERCENT_STEP.mul(block.timestamp.sub(startTime)).div(TIME_STEP));
			return plans[plan].percent.add(pAdd);
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
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
	
	function getUserHoldBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.wFlag == false) { 
			    if (user.checkpointHold < user.deposits[i].finish) {
				    uint256 share = user.deposits[i].amount.mul(HOLD_BONUS).div(PERCENTS_DIVIDER);
				    uint256 from = user.deposits[i].start > user.checkpointHold ? user.deposits[i].start : user.checkpointHold;
				    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
				    if (from < to) {
					    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				    }
			    }
			}
		}
		return user.holdBonus.add(totalAmount);
	}	
	
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a.sub(b); 
        } else {
           return 0;    
        }    
    }  
    
    function maxVal(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }     

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	
	function getUserCheckpointHold(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpointHold;
	}	

	function getUserWFlag(address userAddress) public view returns(bool) {
		return users[userAddress].wFlag;
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
	
	function getUserHoldWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalHoldWithdrawn;
	}	
	
	function getUserPlanWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalPlanWithdrawn;
	}	

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
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
	
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    } 	
	
    function changeDA(address payable _a1, address payable _a2,  address payable _p1) public onlyOwner {
		prj_1 = _p1;
		adv_1 = _a1;
		adv_2 = _a2;         
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