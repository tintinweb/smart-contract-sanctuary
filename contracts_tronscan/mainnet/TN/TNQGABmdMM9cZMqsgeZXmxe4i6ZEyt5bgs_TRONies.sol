//SourceUnit: TRONies.sol

/*
 *
 *   TRONies - investment platform based on TRX blockchain smart-contract      technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://TRONies.net                                        │
 *   │                                                                       │
 *   │   Telegram Live Support: https://t.me/TRONiessupport                  |
 *   │   Telegram Public Group: https://t.me/TRONies_Official                |
 *   │   Telegram News Channel: https://t.me/troniesnews                     |
 *   |                                                                       |
 *   |   Twitter: https://twitter.com/NetTronies                             |
 *   |   YouTube: https://youtube.com/channel/UCTBBt-P_QcCcUXyRJgaU4Cg       |
 *   |   E-mail: admin@TRONies.net                                           |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (100 TRX minimum) using our website Deposit button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1.2% every 24 hours (+0.05% hourly)
 *   - Personal hold-bonus: +0.15% for every 24 hours without withdraw.After 30 days you will reach max hold bonus limit of 4.5%.
 *   - Contract total amount bonus: +0.05% for every 1,000,00 TRX on platform
 *   - Contract Balance will never decrease whether balance goes down.Contract bonus is capped at 14.30% with max holding bonus at 4.5% with basic earnings of 1.20% in total of 20%.Platform earnings will not go beyond 20% per day.
address balance
 *   - ELIGIBILITY For Contract Bonus: YOU MUST HAVE +0.30% PERSONAL HOLD-BONUS TO START EARNING FROM CONTRACT BONUS. This is our unique feature which will make this platform sustainable even with sudden growth.Bonus once increased will never go down.
 *   - All bonuses including Basic , personal hold-bonus & Contract total amount bonus is capped at 20% max per day.It can not go beyond that 20% Limit.Once that limit is reached you will get all 250% profit in 13 days.
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 250% (deposit included)
 *   - Earnings every second, withdraw whenever you want
 *
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 3-level referral commission: 6% - 2% - 1%
 *
 *   [FUNDS DISTRIBUTION]
 *   - 80% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 9% Affiliate program bonuses
 *   - 3% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TRONies LTD (#12928542)
 *   - Company status: https://beta.companieshouse.gov.uk/company/12928542
 *   - Certificate of incorporation: https://TRONies.net/certificate.pdf
 *
 *   [SMART-CONTRACT AUDIT AND SAFETY]
 *
 *   - Audited by independent company GROX Solutions (https://grox.solutions)
 *   - Audition certificate: https://TRONies.net/audit.pdf
 *   - Video-review: https://TRONies.net/auditreview.avi



*/

pragma solidity 0.5.10;

contract TRONies {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100e6;
	uint256 constant public BASE_PERCENT = 120;
	uint256[] public REFERRAL_PERCENTS = [600, 200, 100];
	uint256 constant public MARKETING_FEE = 800;
	uint256 constant public PROJECT_FEE = 200;
	uint256 constant public DEVELOPMENT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000e6;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;
	address payable public developmentAddress;
	address payable internal owner;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 bonus;
		uint256 withdrawRef;
	}

	mapping (address => User) internal users;

	uint256 internal maxBalance;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable projectAddr, address payable developmentAddr, address payable _owner) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr) && !isContract(developmentAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		developmentAddress = developmentAddr;
		owner = _owner;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		developmentAddress.transfer(msg.value.mul(DEVELOPMENT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE).add(DEVELOPMENT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}

			user.referrer = referrer;

            address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    }
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

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		if (address(this).balance > maxBalance) {
			maxBalance = address(this).balance;
		}
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(5).div(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(5).div(2)) {
					dividends = (user.deposits[i].amount.mul(5).div(2)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.withdrawRef = user.withdrawRef.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		return BASE_PERCENT.add(getContractBonus());
	}

    function getContractBonus() public view returns (uint256) {
		uint256 contractBalancePercent = maxBalance.div(CONTRACT_BALANCE_STEP).mul(5);
		if (contractBalancePercent > 1430) {
			contractBalancePercent = 1430;
		}
		return contractBalancePercent;
    }

    function getUserHoldBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		if (isActive(userAddress)) {
			uint256 holdBonus = (now.sub(user.checkpoint)).div(TIME_STEP).mul(15);
			if (holdBonus > 450) {
				holdBonus = 450;
			}
			return holdBonus;
		} else {
			return 0;
		}
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		if (block.timestamp.sub(users[userAddress].checkpoint) < 2 * TIME_STEP) {
			return BASE_PERCENT.add(getUserHoldBonus(userAddress));
		} else {
			return getContractBalanceRate().add(getUserHoldBonus(userAddress));
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(5).div(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(5).div(2)) {
					dividends = (user.deposits[i].amount.mul(5).div(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(5).div(2)) {
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