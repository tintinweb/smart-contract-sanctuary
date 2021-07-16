//SourceUnit: contract.sol

/*
 *   TRXFund.io - Public Fund.
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   |                                                                       |
 *   │   Website: https://trxfund.io/                                        │
 *   │                                                                       │  
 *   │   Official Public Fund Group: https://t.me/trxpublicfund              |
 *   │   Support:                    https://t.me/trxfund_tech               |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   - Connect to your wallet using the TronLink / TronMask browser extension or Klever.io mobile application.
 *   - Make an investment in TRON (TRX) cryptocurrency to the smart contract and start making profit.
 *   - Track the accrual of profit on investments and percents in real time.
 *   - Make a withdraw at any time. All your accruals will be paid out immediately.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: from 0.4% to 2% every 24 hours
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw 
 *   - Minimal investment: 500 TRX
 *   - Total income: from 200% up to 300% (investment included)
 *   - Withdraw at any time
 *   - 8%  Public Fund comission
 *
 */

pragma solidity 0.5.10;

contract TRXFund {
	using SafeMath for uint256;

	uint256 constant private INVEST_MIN_AMOUNT = 500 trx;

	uint256 constant private PERCENT_500    = 40; // 0.4% = 0.004 = 40 / 10000
	uint256 constant private PERCENT_2500   = 60; // 0.6% = 0.006 = 60 / 10000
	uint256 constant private PERCENT_5000   = 80; // 0.8% = 0.008 = 80 / 10000
	uint256 constant private PERCENT_10000  = 100; // 1% = 0.01 = 100 / 10000
	uint256 constant private PERCENT_20000  = 120; // 1.2% = 0.012 = 120 / 10000
	uint256 constant private PERCENT_50000  = 140; // 1.4% = 0.014 = 140 / 10000
	uint256 constant private PERCENT_100000 = 160; // 1.6% = 0.016 = 160 / 10000
	uint256 constant private PERCENT_150000 = 200; // 2% = 0.02 = 200 / 10000
	uint256 constant private PERCENT_MULTIPLIER = 10000;

	uint256 constant private PROJECT_FEE_PERCENT = 8;

	uint256 constant private TIME_STEP = 1 days;

	uint256 public totalUsersCount = 0;
	uint256 public totalInvestedSum = 0;
	uint256 public totalInvestmentsAmount = 0;

	address payable private projectAddress;

	struct Withdraw {
		uint256 amount;
		uint256 withdrawnAt;
	}

	struct Investment {
		uint256 amount;
		uint256 maximumWithdrawAmount;
		mapping(uint256 => Withdraw) withdraws;
      	uint256 withdrawsCount;
		uint256 withdrawnAmount;
		uint256 investedAt;
		uint256 percent;
	}

	struct User {
		Investment[] investments;
	}

	mapping (address => User) internal users;

	// Deployment - set the Project Address to receice the fee
	constructor(address payable f_projectAddress) public {
		require(!isContract(f_projectAddress));
		projectAddress = f_projectAddress;
	}

	function invest() public payable {
		// Check that the investment sum is not below the minimum allowed sum
		require(msg.value >= INVEST_MIN_AMOUNT);

        // Get current user
		User storage user = users[msg.sender];

        // Create new user
		if (user.investments.length == 0) {
			totalUsersCount = totalUsersCount.add(1);
		}

        // Add user investment
		Investment memory investment;
		investment.amount = msg.value;
		investment.maximumWithdrawAmount = calculateMaximumWithdrawAmount(msg.value);
		investment.investedAt = now;
		investment.percent = calculateInvestmentPercent(msg.value);
		investment.withdrawsCount = 0;
		investment.withdrawnAmount = 0;
		user.investments.push(investment);

        // Update statistics
		totalInvestedSum       = totalInvestedSum.add(msg.value);
		totalInvestmentsAmount = totalInvestmentsAmount.add(1);

        // Pay project fee
		projectAddress.transfer(msg.value.mul(PROJECT_FEE_PERCENT).div(100));
	}

	function calculateMaximumWithdrawAmount(uint256 amount) private pure returns(uint256) {
		if (amount >= 50000000000) { 
			return amount.mul(3);
		}

		return amount.mul(2);
	}

    function calculateInvestmentPercent(uint256 amount) private pure returns(uint256) {
        uint256 percent = 0;

        if (amount >= 500000000 && amount < 2500000000) {
            percent = PERCENT_500;
        } else if (amount >= 2500000000 && amount < 5000000000) {
            percent = PERCENT_2500;
        } else if (amount >= 5000000000 && amount < 10000000000) {
            percent = PERCENT_5000;
        } else if (amount >= 10000000000 && amount < 20000000000) {
            percent = PERCENT_10000;
        } else if (amount >= 20000000000 && amount < 50000000000) {
            percent = PERCENT_20000;
        } else if (amount >= 50000000000 && amount < 100000000000) {
            percent = PERCENT_50000;
        } else if (amount >= 100000000000 && amount < 150000000000) {
            percent = PERCENT_100000;
        } else if (amount >= 150000000000) {
            percent = PERCENT_150000;
        }

		return percent;
    }

	function withdraw(uint256 investment_index, uint256 withdraw_amount) public {
		User storage user = users[msg.sender];

		uint256 divable = 1;
		uint256 dividends;
		uint256 totalWithdrawn = 0;
		uint256 currentPercent;

		for (uint256 j = 0; j < user.investments[investment_index].withdrawsCount; j++) {
			totalWithdrawn = totalWithdrawn.add(user.investments[investment_index].withdraws[j].amount);
		}

		require(totalWithdrawn < user.investments[investment_index].maximumWithdrawAmount, "The investment is fully payed out!");

		uint256 checkpoint;

		if (user.investments[investment_index].withdrawsCount > 0) {
			checkpoint = user.investments[investment_index].withdraws[user.investments[investment_index].withdrawsCount - 1].withdrawnAt;
		} else {
			checkpoint = user.investments[investment_index].investedAt;
		}

		uint256 holdBonus = calculateHoldBonus(checkpoint).div(divable);
		currentPercent = user.investments[investment_index].percent.add(holdBonus);

		dividends = (user.investments[investment_index].amount.mul(currentPercent).div(PERCENT_MULTIPLIER));
		dividends = dividends.mul(secondsAgo(checkpoint)).div(TIME_STEP);


		if (totalWithdrawn.add(dividends) > user.investments[investment_index].maximumWithdrawAmount) {
			dividends = user.investments[investment_index].maximumWithdrawAmount.sub(totalWithdrawn);
		}

		uint256 contractBalance = getContractBalance();
		require (contractBalance > 0, "The contract balace is empty!");

		if (contractBalance < dividends) {
			dividends = contractBalance;
		}

		if (withdraw_amount < dividends) {
			dividends = withdraw_amount;
		}

		require(dividends > 0, "User has no dividends!");

		user.investments[investment_index].withdraws[user.investments[investment_index].withdrawsCount] = Withdraw(
			dividends,
			now
		);

		user.investments[investment_index].withdrawsCount = user.investments[investment_index].withdrawsCount.add(1);
		user.investments[investment_index].withdrawnAmount = user.investments[investment_index].withdrawnAmount.add(dividends);

		msg.sender.transfer(dividends);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function secondsAgo(uint256 timestamp) private view returns (uint256) {
		if (timestamp > 1000000000) {
			return now.sub(timestamp);
		}

		return 0;
	}

	function getUserDividends(address user_address, uint256 investment_index, uint256 divable) public view returns (uint256) {
		User storage user = users[user_address];

		uint256 dividends = 0;
		uint256 totalWithdrawn = 0;
		uint256 currentPercent;

		for (uint256 j = 0; j < user.investments[investment_index].withdrawsCount; j++) {
			totalWithdrawn = totalWithdrawn.add(user.investments[investment_index].withdraws[j].amount);
		}

		require(totalWithdrawn < user.investments[investment_index].maximumWithdrawAmount, "The investment is fully payed out!");

		uint256 checkpoint;

		if (user.investments[investment_index].withdrawsCount > 0) {
			checkpoint = user.investments[investment_index].withdraws[user.investments[investment_index].withdrawsCount - 1].withdrawnAt;
		} else {
			checkpoint = user.investments[investment_index].investedAt;
		}

		uint256 holdBonus = calculateHoldBonus(checkpoint).div(divable);
		currentPercent = user.investments[investment_index].percent.add(holdBonus);

		dividends = (user.investments[investment_index].amount.mul(currentPercent).div(PERCENT_MULTIPLIER));
		dividends = dividends.mul(secondsAgo(checkpoint)).div(TIME_STEP);

		if (totalWithdrawn.add(dividends) > user.investments[investment_index].maximumWithdrawAmount) {
			dividends = user.investments[investment_index].maximumWithdrawAmount.sub(totalWithdrawn);
		}

		return dividends;
	}

	function calculateHoldBonus(uint256 checkpoint) public view returns(uint256) {
		return secondsAgo(checkpoint).mul(100).div(TIME_STEP);
	}

	function getUserInvestmentInfo(address user_address, uint256 investment_index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[user_address];

		return (
			user.investments[investment_index].amount,
			user.investments[investment_index].maximumWithdrawAmount,
			user.investments[investment_index].investedAt
		);
	}

	function getUserInvestmentInfoAdditional(address user_address, uint256 investment_index, uint256 divable) public view returns(uint256, uint256, uint256, uint256) {
	    User storage user = users[user_address];

		uint256 checkpoint;

		if (user.investments[investment_index].withdrawsCount > 0) {
			checkpoint = user.investments[investment_index].withdraws[user.investments[investment_index].withdrawsCount - 1].withdrawnAt;
		} else {
			checkpoint = user.investments[investment_index].investedAt;
		}

		uint256 holdBonus = calculateHoldBonus(checkpoint).div(divable);

		return (
			user.investments[investment_index].withdrawsCount,
			user.investments[investment_index].withdrawnAmount,
			user.investments[investment_index].percent.add(holdBonus),
			getUserDividends(user_address, investment_index, divable)
		);
	}


	function getUserWithdrawInfo(address user_address, uint256 investment_index, uint256 withdraw_index) public view returns(uint256, uint256) {
	    User storage user = users[user_address];

		return (
			user.investments[investment_index].withdraws[withdraw_index].amount,
			user.investments[investment_index].withdraws[withdraw_index].withdrawnAt
		);
	}

	function getUserInvestmentsAmount(address user_address) public view returns(uint256) {
		return users[user_address].investments.length;
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
		require(c <= a, "SafeMath: subtraction overflow");

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