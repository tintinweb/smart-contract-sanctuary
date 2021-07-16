//SourceUnit: CrazyTRX.sol

// https://crazytrx.pro/
// Start 01/30/2021 @ 5:00pm (UTC)
// The minimum deposit amount is 200 trx.
// There are no restrictions on the maximum investment amount.
// The main percentage of the profit of deposits is 50% per day.
// The total maximum deposit profit is 150%.
// Developer takes 10% (7,3) of deposit fees  
// Referral Tier - 10% - 3% -1%

pragma solidity 0.5.12;

contract CrazyTRX {
	using SafeMath for uint256;

	uint256 constant public START_TIME = 1612026000;
	uint256 constant public INVEST_MIN_AMOUNT = 200 trx;//min 200 trx for investing
	uint256 constant public BASE_PERCENT = 500;//50% / day
	uint256 constant public MAX_PROFIT = 1500;//150% max profit
	uint256[] public REFERRAL_PERCENTS = [100, 30, 10];//1lvl=10%,2lvl=3%,3lvl=1%
	uint256 constant public MARKETING_FEE = 70;//7% to marketing wallet
	uint256 constant public PROJECT_FEE = 30;//3% to project wallet
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalWithdrawn;

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
		uint256[3] fromref;
		uint256 fromref_await;
		address referrer;
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
		require(now >= START_TIME,"Start of the project on January 30, 2021 at 17:00 UTC");
		require(msg.value >= INVEST_MIN_AMOUNT,"Min amount 200 trx");
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
					users[upline].fromref[i] = users[upline].fromref[i].add(amount);
					users[upline].fromref_await = users[upline].fromref_await.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER))) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
				totalAmount = totalAmount.add(dividends);
			}
		}
		if (user.fromref_await > 0) {
			totalAmount = totalAmount.add(user.fromref_await);
			user.fromref_await = 0;
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

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER))) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}
				totalDividends = totalDividends.add(dividends);
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

	function getUserFromref(address userAddress, uint256 level) public view returns(uint256) {
		return users[userAddress].fromref[level];
	}

	function getUserFromrefAwait(address userAddress) public view returns(uint256) {
		return users[userAddress].fromref_await;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].withdrawn);
		}
		return amount;
	}

	function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
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