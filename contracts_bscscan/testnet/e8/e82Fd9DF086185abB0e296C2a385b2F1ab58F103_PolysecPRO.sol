/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.3;
contract PolysecPRO {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256[] public REFERRAL_PERCENTS = [50e2, 10e2, 10e2];
	uint256 public constant MARKETING_FEE = 70;
	uint256 constant public PROJECT_FEE = 65;
	uint256 constant public FUND_FEE = 65;	
	uint256 constant public PERCENT_STEP = 2e2;
	uint256 constant public PERCENTS_DIVIDER = 1000e2;
	uint256 constant public DECREASE_DAY_STEP = 0.2 days; //0.25 days
	uint256 constant public TIME_STEP = 1 days; //1 days

	uint256 public constant PENALTY_STEP = 500;
    

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	uint256 public startUNIX;
	address payable public fundAds;
    address payable public mktAds;
    address payable public prjAds;

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
		bool force;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 lottobonus;
        uint256 lottoparticipations;
        uint256 lottolimit;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event ForceWithdrawn(address indexed user, uint256 amount, uint256 penaltyAmount);

	constructor(address payable fundAddr,address payable mktAddr,address payable prjAddr,uint256 startDate){
        require(!isContract(fundAddr));
		require(startDate > 0);
		fundAds = fundAddr;
        mktAds = mktAddr;
        prjAds = prjAddr;
        startUNIX = startDate;

        plans.push(Plan(14, 75e2));
        plans.push(Plan(21, 55e2));
        plans.push(Plan(28, 45e2));
        plans.push(Plan(14, 75e2));
        plans.push(Plan(21, 55e2));
        plans.push(Plan(28, 45e2));
	}
    
	function FeePayout(uint256 amt) internal{
    uint256 mktFee = amt.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
    uint256 prjFee = amt.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
    uint256 fundFee = amt.mul(FUND_FEE).div(PERCENTS_DIVIDER);
    mktAds.transfer(mktFee);
    prjAds.transfer(prjFee);
    fundAds.transfer(fundFee);
    emit FeePayed(msg.sender, (mktFee.add(prjFee)).add(fundFee));
}

	function invest(address referrer, uint8 plan) public payable {
	    require(block.timestamp >= startUNIX ,"Not Launch");
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");

		FeePayout(msg.value);

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

		uint256 refsamount;
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else {
				    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				    refsamount = refsamount.add(amount);
				}
			}
			if (refsamount > 0){
            prjAds.transfer(refsamount.div(2));
            fundAds.transfer(refsamount.div(2));
			}
		}
		else{
		    uint256 refbk = 70;
		    uint256 amount = msg.value.mul(refbk).div(PERCENTS_DIVIDER);
            prjAds.transfer(amount.div(2));
            fundAds.transfer(amount.div(2));
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}
		
		(uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish, true));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
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
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    user.deposits[i].force = false;
                } else if (block.timestamp > user.deposits[i].finish) {
                    user.deposits[i].force = false;
                }
            }
        }
        payable(msg.sender).transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }
    
	function forceWithdraw(uint256 index) public {
        User storage user = users[msg.sender];

        require(index < user.deposits.length, "Invalid index");

        require(user.deposits[index].plan >= 3 && user.deposits[index].plan < 6, 'force withdraw not valid');
        
        require(user.deposits[index].finish > block.timestamp, 'you can not force withdraw');

        uint256 depositAmount = user.deposits[index].amount;
        uint256 penaltyAmount =
            depositAmount.mul(PENALTY_STEP).div(PERCENTS_DIVIDER);

        payable(msg.sender).transfer(depositAmount.sub(penaltyAmount));

        user.deposits[index] = user.deposits[user.deposits.length - 1];
        user.deposits.pop();

        emit ForceWithdrawn(
            msg.sender,
            depositAmount,
            penaltyAmount
        );
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
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }
	
	function getResult(uint8 plan, uint256 deposit) public view returns ( uint256 percent, uint256 profit, uint256 current, uint256 finish){
        percent = getPercent(plan);
        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
            }
        }
        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }
	
	function getUserDividends(address userAddress) public view returns (uint256){
        User memory user = users[userAddress];

        uint256 totalAmount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                    if (from < to) {
                        uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress = planTime.div(getDecreaseDays(plans[user.deposits[i].plan].time));
                        totalAmount = totalAmount.add(share.mul(to.sub(from)).mul(redress).div(TIME_STEP));
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }
        return totalAmount;
    }
	
	function getDecreaseDays(uint256 planTime) public view returns (uint256) {
        uint256 limitDays = TIME_STEP.mul(4);
        uint256 pastDays = block.timestamp.sub(startUNIX).div(TIME_STEP);
        uint256 decreaseDays = pastDays.mul(DECREASE_DAY_STEP);
        if (decreaseDays > limitDays){
        decreaseDays = limitDays;
        }
        uint256 minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);
        
        return minimumDays;  
        
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
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, bool force){
        User memory user = users[userAddress];
        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }


	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function minZero(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    function maxVal(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    function minVal(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
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
        return a % b;
    }
}