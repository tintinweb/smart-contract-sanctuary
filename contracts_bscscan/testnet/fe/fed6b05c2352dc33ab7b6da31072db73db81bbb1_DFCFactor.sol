/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

/*   DFCFactor - Community Experimental yield farm on Binance Smart Chain.
 *   The only official platform of original DFCFactor team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://dfcfactor.com                                      │
 *   │   Telegram Public Chat: @dfcfactor                                    │
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
 *   - Minimal deposit: 100,000,000 DFC, no maximal limit
 *   - Total income: 150% ROI (5% daily) 
 *   - Earnings every moment, withdraw every 10 days
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral reward: 7% - 3% - 1.5% - 1% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90% Platform main balance, using for participants payouts, affiliate program bonuses
 *   - 10% Advertising and promotion expenses, Support work, technical functioning, administration fee
 *
 *   Note: This is experimental community project,
 *   which means this project has high risks as well as high profits.
 *   Once contract balance drops to zero payments will stop,
 *   deposit at your own risk.
 */

pragma solidity 0.5.10;

interface AltcoinToken {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

contract DFCFactor {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 1e16; // 100M DFC
	uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public ADAY = 10;
	uint256 constant public TIME_STEP = ADAY;
	// uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalRefBonus;

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
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public commissionWallet;
	AltcoinToken dfctoken;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet, address _dfctoken) public {
	    dfctoken = AltcoinToken(_dfctoken);
		require(!isContract(wallet));
		commissionWallet = wallet;

        plans.push(Plan(30, 50));
	}

	function invest(uint8 plan, address referrer, uint256 amount) public {
		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(amount >= INVEST_MIN_AMOUNT);

		uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		dfctoken.transferFrom(msg.sender, address(this), amount);
		dfctoken.transfer(commissionWallet, fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 refAmount = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(refAmount);
					users[upline].totalBonus = users[upline].totalBonus.add(refAmount);
					emit RefBonus(upline, msg.sender, i, refAmount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, amount, block.timestamp));

		totalInvested = totalInvested.add(amount);

		emit NewDeposit(msg.sender, plan, amount);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		
		// withdrawal is once in 5 days
		require(user.checkpoint.add(ADAY.mul(5)) <= block.timestamp, "withdrawal is once in 5 days");

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = dfctoken.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		
		dfctoken.transfer(msg.sender, totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public returns (uint256) {
		return dfctoken.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(ADAY));
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

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
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
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(ADAY));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
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