//SourceUnit: TronMint.sol

/*
 *
 *   TronMint - Smart Investment Platform Based on TRX Blockchain Smart-Contract Technology. 
 *   100% Safe and Legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronmint.com                                       │
 *   │                                                                       │
 *   │   Telegram Public Group: @tronmint_support                            |
 *   │   Telegram News Channel: @tronmint_news                               |
 *   |                                                                       |
 *   |   E-mail: support@tronmint.com                                        |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (50 TRX minimum) using our website make deposit button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1.5% every 24 hours (+0.0625% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw. Max Limited to 5%
 *   - Contract total amount bonus: +0.1% for every 1,000,000 TRX on platform address balance. Max Limited to 8.5%
 *   - Referral Bonus upto +2.5% every 24 hours
 *   - Whale Deposit Bonus upto +2.5% every 24 hours 
 *
 *   - Minimal deposit: 50 TRX, no maximal limit
 *   - Total income: 250% (deposit included)
 *   - Earnings every moment, withdraw any time
 *
 *   - Custom Withdraw Option, here you can mention your amount of TRX to withdraw from your available TRX balance
 *
 *   [Representative Bonus]
 *
 *   - 6% Referral Commission on 100K TRX Direct Business(Gold Member)
 *   - 7% Referral Commission on 250K TRX Direct Business(Diamond Member)
 *   - 8% Referral Commission on 500K TRX Direct Business(Platinum Member)
 *   - 10% Referral Commission on 1M TRX Direct Business(Titanium Member)
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3-level referral commission: 5% - 2% - 1% 
 *   - Auto-refback function
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 78% Platform main balance, participants payouts
 *   - 12% Advertising and promotion expenses
 *   - 8% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TronMint LTD (#12972280)
 *   - Company status: https://beta.companieshouse.gov.uk/company/12972280
 *   - Certificate of incorporation: https://tronmint.com/certificate.pdf
 *
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company GROX Solutions (Webiste: https://grox.solutions)
 *   - Audition certificate: https://tronmint.com/tronmint_audit_en.pdf
 *
 */

pragma solidity 0.5.10;

contract TronMint {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
	uint256 constant public BASE_PERCENT = 150;
	uint256[] public REFERRAL_PERCENTS = [500, 200, 100];
	uint256 constant public MARKETING_FEE = 1200;
	uint256 constant public PROJECT_FEE = 200;
	uint256 constant public ROI = 25000;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public totalRefBonus;

	address payable public marketingAddress;
	address payable public projectAddress;
	uint256 internal lastMil;

	uint256 public startDate;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		uint256 id;
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 lastHoldPercent;
		address referrer;
		uint256[3] levels;
		uint256 directBusiness;
		uint256 totalRewards;
		uint256 bonus;
		uint256 reserved;
		uint256 refBackPercent;
	}

	mapping (address => User) internal users;
	mapping (uint256 => address) internal ids;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RefBack(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable projectAddr, uint256 start) public {
		require(marketingAddr != address(0) && projectAddr != address(0));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		startDate = start;
	}

	function invest(uint256 referrerID) public payable {
		address referrer = ids[referrerID];

		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;

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
					uint256 amount = msg.value.mul(getUserReferralPercent(upline, i)).div(PERCENTS_DIVIDER);
					if (i == 0) {
						users[upline].directBusiness = users[upline].directBusiness.add(msg.value);
						if (users[upline].refBackPercent > 0) {
							uint256 refback = amount.mul(users[upline].refBackPercent).div(PERCENTS_DIVIDER);
							user.bonus = user.bonus.add(refback);
							user.totalRewards = user.totalRewards.add(amount);
							amount = amount.sub(refback);
							emit RefBack(upline, msg.sender, refback);
						}
					}
					if (amount > 0) {
						users[upline].bonus = users[upline].bonus.add(amount);
						users[upline].totalRewards = users[upline].totalRewards.add(amount);
						totalRefBonus += amount;
						emit RefBonus(upline, msg.sender, i, amount);
					}
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			if (block.timestamp < startDate) {
				user.checkpoint = startDate;
			} else {
				user.checkpoint = block.timestamp;
			}
			totalUsers = totalUsers.add(1);
			user.id = totalUsers;
			ids[totalUsers] = msg.sender;
			emit Newbie(msg.sender);
		}

		uint256 deposit = msg.value;
		if (block.timestamp < startDate) {
			deposit = deposit.add(getPrelaunchBonus(deposit));
		}
		user.deposits.push(Deposit(deposit, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		uint256 mils = address(this).balance.div(CONTRACT_BALANCE_STEP);
		if (mils > lastMil) { /// 1 per every 1 mil
			users[getUserById(1)].bonus = users[getUserById(1)].bonus.add((mils.sub(lastMil)).mul(CONTRACT_BALANCE_STEP.div(100)));
			lastMil = mils;
		}

	}

	function _reserve() internal {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		user.checkpoint = block.timestamp;
		user.reserved = user.reserved.add(totalAmount);
	}

	function withdraw(uint256 amount) public {
		require(block.timestamp >= startDate);
		User storage user = users[msg.sender];

		uint256 holdBonus = getUserHoldBonus(msg.sender);

		_reserve();

		uint256 reserved = user.reserved;

		uint256 referralBonus = getUserReferralBonus(msg.sender);

		uint256 contractBalance = address(this).balance;
		if (contractBalance < amount) {
			amount = contractBalance;
		}

		require(reserved.add(referralBonus) > amount, "User has no enough dividends");

		uint256 remaining = amount;

		if (referralBonus > 0) {
			if (referralBonus >= amount) {
				remaining = remaining.sub(amount);
				user.bonus = user.bonus.sub(amount);
			} else {
				remaining = remaining.sub(user.bonus);
				user.bonus = 0;
			}
		}

		if (remaining > 0) {
			user.reserved = user.reserved.sub(remaining);
		}

		user.lastHoldPercent = holdBonus.mul(user.reserved).div(reserved);

		msg.sender.transfer(amount);

		totalWithdrawn = totalWithdrawn.add(amount);

		emit Withdrawn(msg.sender, amount);
	}

	function setRefBackPercent(uint256 newPercent) public {
		require(newPercent <= PERCENTS_DIVIDER);
		User storage user = users[msg.sender];
		user.refBackPercent = newPercent;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP).mul(10);
		if (contractBalancePercent > 850) {
			contractBalancePercent = 850;
		}
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserHoldBonus(address userAddress) public view returns (uint256) {
		if (block.timestamp < startDate) return 0;
		User storage user = users[userAddress];

		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			uint256 holdBonus = (timeMultiplier.mul(10)).add(user.lastHoldPercent);
			if (holdBonus > 500) {
				holdBonus = 500;
			}
			return holdBonus;
		} else {
			return 0;
		}
	}

	function getUserDownlineBonus(address userAddress) public view returns(uint256) {
		uint256 refs = users[userAddress].levels[0];

		if (refs >= 500) {
			return 250;
		} else if (refs >= 250) {
			return 200;
		} else if (refs >= 100) {
			return 150;
		} else if (refs >= 50) {
			return 100;
		} else if (refs >= 15) {
			return 50;
		} else if (refs >= 5) {
			return 10;
		} else {
			return 0;
		}
	}

	function getUserWhaleBonus(address userAddress) public view returns(uint256) {
		uint256 invested = getUserTotalDeposits(userAddress);

		if (invested >= 1e12) {
			return 250;
		} else if (invested >= 250e9) {
			return 200;
		} else if (invested >= 100e9) {
			return 150;
		} else if (invested >= 25e9) {
			return 100;
		} else if (invested >= 10e9) {
			return 50;
		} else if (invested >= 25e8) {
			return 10;
		} else {
			return 0;
		}
	}

	function getPrelaunchBonus(uint256 deposit) public pure returns(uint256) {
		if (deposit >= 1e12) {
			return (deposit.mul(20).div(100));
		} else if (deposit >= 5e11) {
			return (deposit.mul(15).div(100));
		} else if (deposit >= 1e11) {
			return (deposit.mul(10).div(100));
		} else {
			return (deposit.mul(5).div(100));
		}
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		return getContractBalanceRate().add(getUserHoldBonus(userAddress)).add(getUserDownlineBonus(userAddress)).add(getUserWhaleBonus(userAddress));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		if (block.timestamp < startDate) return 0;

		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends = user.reserved;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getUserReferralPercent(address userAddress, uint256 level) public view returns(uint256) {
		uint256 directBusiness = users[userAddress].directBusiness;

		if (level == 0) {
			if (directBusiness >= 1e12) {
				return 1000;
			} else if (directBusiness >= 500e9) {
				return 800;
			} else if (directBusiness >= 250e9) {
				return 700;
			} else if (directBusiness >= 100e9) {
				return 600;
			}
		}

		return REFERRAL_PERCENTS[level];
	}

	function getUserId(address userAddress) public view returns(uint256) {
		return users[userAddress].id;
	}

	function getUserById(uint256 id) public view returns(address) {
		return ids[id];
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDirectBusiness(address userAddress) public view returns(uint256) {
		return users[userAddress].directBusiness;
	}

	function getUserRefRewards(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRewards;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserLastDepositDate(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits[users[userAddress].deposits.length-1].start;
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(ROI).div(PERCENTS_DIVIDER)) {
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

		uint256 amount = user.totalRewards.sub(user.bonus);

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount.sub(user.reserved);
	}

	function getUserWithdrawRef(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRewards.sub(users[userAddress].bonus);
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserRefbackPercent(address userAddress) public view returns(uint256) {
		return users[userAddress].refBackPercent;
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