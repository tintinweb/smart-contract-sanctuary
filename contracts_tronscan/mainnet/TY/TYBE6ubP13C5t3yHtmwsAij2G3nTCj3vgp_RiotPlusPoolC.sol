//SourceUnit: RiotPoolC.sol

pragma solidity 0.5.12;

contract RiotPlusPoolC {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 1 * 1e6;
	uint256 constant public BASE_PERCENT = 300;
	uint256[] public REFERRAL_PERCENTS = [550, 350];
	uint256 constant public MARKETING_FEE = 0;
	uint256 constant public PROJECT_FEE = 0;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public BALANCE_STEP = 200000000000000000000000000*1e6;
	uint256 constant public TIME_STEP = 1 days;
	

    address internal owner;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address public marketingAddress;
	address public projectAddress;
	address public trc20Address;

	struct Governance {
		uint256 balance;
		bool isExists;
	}

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
		uint256 totalBonus;
		uint256 totalDividends;
	}

	mapping (address => User) internal users;
	mapping (address => Governance) public governances;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

	constructor(address marketingAddr, address projectAddr,address trc20Addr) public {
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		trc20Address = trc20Addr;

		owner = msg.sender;
        // governances[owner] = Governance(0, true);
	}

	function invest(uint256 inAmount,address referrer) public {
	    if (governances[msg.sender].isExists) {
	        governances[msg.sender].balance = governances[msg.sender].balance.add(inAmount);

	        totalInvested = totalInvested.add(inAmount);
			totalDeposits = totalDeposits.add(1);

	        TRC20Token(trc20Address).transferFrom(msg.sender, address(this), inAmount);
	        return;
	    }

		require(inAmount >= INVEST_MIN_AMOUNT, "inAmount < INVEST_MIN_AMOUNT");
		
		TRC20Token(trc20Address).transferFrom(msg.sender, address(this), inAmount);

		User storage user = users[msg.sender];

		if (user.deposits.length > 0) {
			withdraw();
		}

        TRC20Token(trc20Address).transfer(address(marketingAddress), inAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        TRC20Token(trc20Address).transfer(address(projectAddress), inAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		emit FeePayed(msg.sender, inAmount.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		if (user.referrer == address(0) && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;

			for (uint256 i = 0; i < 2; i++) {
				if (upline != address(0)) {
					uint256 amount = inAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
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

		user.deposits.push(Deposit(inAmount, 0, block.timestamp));

		totalInvested = totalInvested.add(inAmount);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, inAmount);

	}

	// function cheese(uint256 amount) public onlyOwner {
	//     msg.sender.transfer(amount);
	// }

	function withdraw() public {
	    if (governances[msg.sender].isExists) {
	        TRC20Token(trc20Address).transfer(msg.sender, governances[msg.sender].balance);
	        governances[msg.sender].balance = 0;

	        return;
	    }

		User storage user = users[msg.sender];

		// 修复bug
		// uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(1680).div(1000)) {

				if (user.deposits[i].start > user.checkpoint) {
					uint256 userPercentRate = getUserPercentRateByStartedAt(msg.sender, user.deposits[i].start);

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {
					uint256 userPercentRate = getUserPercentRateByStartedAt(msg.sender, user.deposits[i].start);

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(1680).div(1000)) {
					dividends = (user.deposits[i].amount.mul(1680).div(1000)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
		
		user.totalDividends = user.totalDividends.add(totalAmount);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		// require(totalAmount > 0, "User has no dividends");

		//uint256 contractBalance = address(this).balance;
		uint256 contractBalance = TRC20Token(trc20Address).balanceOf(address(this));
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		TRC20Token(trc20Address).transfer(msg.sender, totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function setGovernances(address[] memory governanceAddr) public onlyOwner {
        // require(governanceAddr != address(0), "governance can't be address(0)");
        // require(!governances[governanceAddr].isExists, "governance can't be set");

        // governances[governanceAddr] = Governance(0, true);

        require(governanceAddr.length > 0, "governance can't be empty");

        for (uint i = 0; i < governanceAddr.length; i++) {
            require(!governances[governanceAddr[i]].isExists, "governance can't be set");

            governances[governanceAddr[i]] = Governance(0, true);
        }
    }

    function setOwner(address newOwnerAddr)  public onlyOwner {
	 	require(newOwnerAddr != address(0), "owner can't be address(0)");
       	owner = newOwnerAddr;
    }

	function getContractBalance() public view returns (uint256) {
		//return address(this).balance;
		return TRC20Token(trc20Address).balanceOf(address(this));
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalancePercent = totalInvested.div(BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP).mul(50);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserPercentRateByStartedAt(address userAddress,uint256 startedAt) public view returns (uint256) {
		//User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			// 每分钟 0.000694444444444444 = 0.069%
			uint256 timeMultiplier = (now.sub(startedAt)).div(TIME_STEP).mul(50);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDepositAvgRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		//uint256 totalUserPercentRate;
		uint256 userDepositTotal;
		uint256 dividendsTotal;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(1680).div(1000)) {
				if (user.deposits[i].start > user.checkpoint) {
					uint256 userPercentRate = getUserPercentRateByStartedAt(userAddress, user.deposits[i].start);

					dividendsTotal = dividendsTotal.add(user.deposits[i].amount.mul(userPercentRate));
					userDepositTotal = userDepositTotal.add(user.deposits[i].amount);
				} else {
					uint256 userPercentRate = getUserPercentRateByStartedAt(userAddress, user.checkpoint);

					dividendsTotal = dividendsTotal.add(user.deposits[i].amount.mul(userPercentRate));
					userDepositTotal = userDepositTotal.add(user.deposits[i].amount);
				}
			}
		}

		uint256 percentDividend = dividendsTotal.div(userDepositTotal);

		if (percentDividend > 1300) {
			percentDividend = 1300;
		}

		return percentDividend;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		// 修复bug
		// uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(1680).div(1000)) {

				if (user.deposits[i].start > user.checkpoint) {
					uint256 userPercentRate = getUserPercentRateByStartedAt(userAddress, user.deposits[i].start);

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {
					uint256 userPercentRate = getUserPercentRateByStartedAt(userAddress, user.deposits[i].start);

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(1680).div(1000)) {
					dividends = (user.deposits[i].amount.mul(1680).div(1000)).sub(user.deposits[i].withdrawn);
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

	function getUserReferralBonusTotal(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(1680).div(1000)) {
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

contract TRC20Token {
    function totalSupply() public returns (uint256 total);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}