/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

// SPDX-License-Identifier: MIT 

 /*   Welcome to PolygonPro.xyz 
 *
 *	  The long term investment platform on the Polygon Network. Invest your MATIC and earn 1% daily rewards for 365% APR, along with referral and compounding
 *    rewards to increase your daily return.
 *
 *    Contact
 *
 *   - Check out our telegram and twitter below: 
 *   - Telegram: https://t.me/PolygonPro
 *   - Twitter: https://twitter.com/PolygonPro_
 *   
 *    How does it work?
 *
 *   - Add the Polygon Network to Metamask, you can find out how to here: https://docs.polygon.technology/docs/develop/metamask/config-polygon-on-metamask/
 *   - Visit the official website at https://PolygonPro.xyz
 *   - Go to the Matic Pool section and enter the amount of MATIC you wish to invest.
 *   - View your investment projection and use the 'Invest' button to submit your investment.
 *   - Go to the 'My Rewards' section to Claim or Compound your MATIC rewards at anytime, using the 'Claim' and 'Compound' buttons. 
 *   - Compounding will increase your daily return.
 *
 *    Investment Details
 *
 *   - Invest with as little as 0.01 MATIC.
 *   - Your daily income starts at 1% with a total payout of 365%. This is not including compounding or referrals, which will increase your payout.
 *   - You can claim or compound at anytime.
 *
 *    Referral Details
 *
 *   - There are 3 levels to our referral system: 5% - 2.5% - 0.5%
 *
 *    Invesment Distribution
 *
 *   - 82% Platform balance and investment payouts
 *   - 8% Referral program bonuses
 *   - 5% Support work, technical functioning, administration fee - this applies to all investments.
 *   - 5% Advertising and promotion expenses - this applies to all investments.
 *
 *    Compound Distribution
 *
 *   - 95% Platform balance and investment payouts
 *   - 3% Support work, technical functioning, administration fee - this applies to all compounds.
 *
 */

pragma solidity 0.5.10;

contract PolygonPro {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.01 ether;
	uint256[] public REFERRAL_PERCENTS = [50e2, 25e2, 5e2];
	uint256 constant public INVESTMENT_PROJECT_FEE = 100e2;
	uint256 constant public COMPOUND_PROJECT_FEE = 30e2;
	uint256 constant public PERCENT_STEP = 1;
	uint256 constant public PERCENTS_DIVIDER = 1000e2;
	uint256 constant public TIME_STEP =1 days;

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	uint256 public totalWithdrawn;
	uint256 public totalCompounded;

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
		uint256 totalWithdraw;
		uint256 totalWithdrawNum;
		uint256 totalCompound;
		uint256 totalCompoundNum;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet, uint256 startDate) public {
		require(!isContract(wallet));
		require(startDate > 0);
		commissionWallet = wallet;
		startUNIX = startDate;

        plans.push(Plan(365, 10e2));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp >= startUNIX ,"Please wait until we have launched before investing!");
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 1, "Invalid plan");

		uint256 fee = msg.value.mul(INVESTMENT_PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

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
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	
	function autoCompound(address referrer, uint8 plan, uint256 _amount) private returns (bool) {
        

		User storage user = users[referrer];

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, _amount);
		user.deposits.push(Deposit(plan, percent, _amount, profit, block.timestamp, finish));

    	totalStaked = totalStaked.add(_amount);
        totalCompounded = totalCompounded.add(_amount);
        user.totalCompound = user.totalCompound.add(_amount);
        emit NewDeposit(referrer, plan, percent, _amount, profit, block.timestamp, finish);
        return true;
    
    }
	
	function withdraw(uint8 plan) public {
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
		
        uint256 compoundAmount = totalAmount.div(10);
        autoCompound(msg.sender, plan, compoundAmount);

		user.totalWithdrawNum = user.totalWithdrawNum.add(1);
        user.totalWithdraw = (user.totalWithdraw).add(totalAmount);
		msg.sender.transfer(totalAmount.sub(compoundAmount));
	
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);

	}
	
	    function compound(uint8 plan) public {
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

	    uint256 fee = totalAmount.mul(COMPOUND_PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);
		
		
		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, totalAmount);
		user.deposits.push(Deposit(plan, percent, totalAmount, profit, block.timestamp, finish));

		user.totalCompoundNum = user.totalCompoundNum.add(1);
        user.totalCompound = user.totalCompound.add(totalAmount);
        totalCompounded = totalCompounded.add(totalAmount);
		totalStaked = totalStaked.add(totalAmount);
		emit NewDeposit(msg.sender, plan, percent, totalAmount, profit, block.timestamp, finish);

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
	
	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].totalWithdraw;
    }

	function getUserTotalCompounded(address userAddress) public view returns(uint256) {
        return users[userAddress].totalCompound;
    }

	function getUserTotalWithdrawnNum(address userAddress) public view returns(uint256) {
        return users[userAddress].totalWithdrawNum;
    }

	function getUserTotalCompoundedNum(address userAddress) public view returns(uint256) {
        return users[userAddress].totalCompoundNum;
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