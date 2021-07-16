//SourceUnit: Uptron.sol

pragma solidity 0.5.12;

// Bonus Base 4.2 % diario - Bonus Personal 0.5 % daily without withdrow - Bonus Balance 0.5 % every 500.000 in Live Balance.
// Referidos Tier 1 4% / Tier 3 2% / Tier 3 1%
// 120 % included initial deposit
// Maximum Bonus Rate 12 % daily / If Withdraw Bonus Balance set in Zero % forever
// 87 % Balance Deposit Fund / 10 % Marketing / 3 % Company
// Start Time 2020.12.09 15:00 GMT

contract Uptron {
	using SafeMath for uint256;

	uint256 constant public START_TIME = 1607526000;//Start Time 2020.12.09 15:00 GMT, timestamp
	uint256 constant public INVEST_MIN_AMOUNT = 200 trx;//min 200 trx for investing
	uint256 constant public BASE_PERCENT = 42;//4,2% / day
	uint256 constant public HOLD_BONUS = 5;//+0.5% daily without withdrow
	uint256 constant public MAX_PERCENT = 120;//12% max percent/day
	uint256 constant public MAX_PROFIT = 1500;//150% max profit (+ 50% to the deposit)
	uint256[] public REFERRAL_PERCENTS = [40, 30, 10];//1lvl=4%,2lvl=3%,3lvl=10%
	uint256 constant public MARKETING_FEE = 100;//10% to marketing wallet
	uint256 constant public PROJECT_FEE = 30;//3% to project wallet
	uint256 constant public DEPOSIT_FUNDS = 870;//87% on deposit
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 500000 trx;
	uint256 constant public CONTRACT_BONUS_STEP = 5;//Bonus Balance 0.5 % every 500.000 in Live Balance 
	uint256 constant public TIME_STEP = 1 days ;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public backBalance;

	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;

	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
	}

	function invest(address referrer) public payable {
		require(now >= START_TIME);
		require(msg.value >= INVEST_MIN_AMOUNT);
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));
		
		User storage user = users[msg.sender];
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
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
		backBalance = backBalance.add(msg.value.div(PERCENTS_DIVIDER).mul(DEPOSIT_FUNDS));
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER))) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
		}
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
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
		uint256 contractBalance = backBalance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent.mul(CONTRACT_BONUS_STEP));
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 contractBalanceRate = getContractBalanceRate();
        if (getUserTotalWithdrawn(userAddress) > 0){ // if User Whithdrawn Shometing, set 0 balance bonus + basic
            contractBalanceRate = getContractBalanceRate();
        }
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP).mul(HOLD_BONUS);
            if(contractBalanceRate.add(timeMultiplier) >= MAX_PERCENT){ // if % is more than MAX_PERCENT% , set MAX_PERCENT%
                return MAX_PERCENT;
            }else{
				return contractBalanceRate.add(timeMultiplier) ;
			}
		}else{
            if(contractBalanceRate >= MAX_PERCENT){ // if % is more than MAX_PERCENT% , set MAX_PERCENT%
                return MAX_PERCENT;
            } else{
				return contractBalanceRate;
			}
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 userPercentRate = getUserPercentRate(userAddress);
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER))) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
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

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(3)) {
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