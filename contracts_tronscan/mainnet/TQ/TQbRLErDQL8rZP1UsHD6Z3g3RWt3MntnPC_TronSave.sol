//SourceUnit: tronsave.sol

/*
 +-+-+-+-+-+-+-+-+
 |T|r|o|n|S|a|v|e|
 +-+-+-+-+-+-+-+-+

❔ How does it work?

TronSave is a decentralized Smart Contract website based on the Tron Blockchain. 
It's a brand new project that works based on a robust plan will make profits to all the participants.

⚖ Rules

1% fixed daily ROI
+0.1% daily from last withdrawal
+0.1% for every 1,000,000 TRX on contract (Maximum 15%)
Maximum 200+% profit (Includes Deposit)
Minimum deposit is 100 TRX
25% of withdrawals more than 100 TRX will be reinvested by the contract

⚖ The system takes only 6% of the balance as maintenance and support fee. This is the smallest amount between other projects

⚠ Notice: Investments are subject to market risk. Please invest only the amount you can afford to lose ⚠

*/

pragma solidity ^0.5.4;

contract TronSave {
    uint256 constant public REINVEST_PERCENT = 250;
    uint256 constant public MAX_REF_BONUS = 3;
	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public FIX_PERCENT = 10;
	uint256[] public REFERRAL_PERCENTS = [40, 5, 5];
	uint256 constant public MARKETING_FEE = 24;
	uint256 constant public SUPPORTING_FEE = 36;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public CONTRACT_BONUS_LIMIT = 150;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public supportAddress;
	
	using SafeMath for uint256;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 refCounter;
		uint256 checkpoint;
		uint256 lastWithdrawAmount;
		address referrer;
		uint256 bonus;
	}

	mapping (address => User) internal users;

	event NewUser(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event SystemReinvest(address user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event SupportFeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable supportAddr) public {
		require(!isContract(marketingAddr) && !isContract(supportAddr));
		marketingAddress = marketingAddr;
		supportAddress = supportAddr;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		supportAddress.transfer(msg.value.mul(SUPPORTING_FEE).div(PERCENTS_DIVIDER));
		
		emit SupportFeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(SUPPORTING_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && user.deposits.length == 0 && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0) && user.refCounter < MAX_REF_BONUS) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
			user.refCounter++;

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit NewUser(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
		uint256 depsLength = user.deposits.length;

		for (uint256 i = 0; i < depsLength; i++) {

            uint256 reinvestAmount = user.deposits[i].amount.mul(REINVEST_PERCENT).div(PERCENTS_DIVIDER);
            uint256 withdrawLimit = user.deposits[i].amount < INVEST_MIN_AMOUNT ? user.deposits[i].amount.mul(2) :
				                                                user.deposits[i].amount.mul(2).sub(reinvestAmount);
			if (user.deposits[i].withdrawn < withdrawLimit) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}
				                                           
				if (user.deposits[i].withdrawn.add(dividends) > withdrawLimit) {
					dividends = withdrawLimit.sub(user.deposits[i].withdrawn);
					if(withdrawLimit < user.deposits[i].amount.mul(2)){
					    user.deposits.push(Deposit(reinvestAmount, 0, block.timestamp));
					    emit SystemReinvest(msg.sender, reinvestAmount);
					}
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

		require(totalAmount > 0, "No dividends");

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
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		return FIX_PERCENT.add(contractBalancePercent > CONTRACT_BONUS_LIMIT ? CONTRACT_BONUS_LIMIT : contractBalancePercent);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 reinvestAmount = user.deposits[i].amount.mul(REINVEST_PERCENT).div(PERCENTS_DIVIDER);
			uint256 withdrawLimit = user.deposits[i].amount < INVEST_MIN_AMOUNT ? user.deposits[i].amount.mul(2) :
				                                                user.deposits[i].amount.mul(2).sub(reinvestAmount);
			if (user.deposits[i].withdrawn < withdrawLimit) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}
				                                                
				if (user.deposits[i].withdrawn.add(dividends) > withdrawLimit) {
					dividends = withdrawLimit.sub(user.deposits[i].withdrawn);
				}

				totalAmount = totalAmount.add(dividends);
			}
		}

		return totalAmount;
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
		    uint256 reinvestAmount = user.deposits[user.deposits.length-1].amount.mul(REINVEST_PERCENT).div(PERCENTS_DIVIDER);
            uint256 withdrawLimit = user.deposits[user.deposits.length-1].amount < INVEST_MIN_AMOUNT ? user.deposits[user.deposits.length-1].amount.mul(2) :
                                                                                user.deposits[user.deposits.length-1].amount.mul(2).sub(reinvestAmount);
			if (user.deposits[user.deposits.length-1].withdrawn < withdrawLimit) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

    function getStatsView() public view returns
        (uint256 statsTotalInvested, 
        uint256 statsTotalWithdrawn, 
        uint256 statsTotalDeposits, 
        uint256 statsContractBalance, 
        uint256 statsUserTotalDeposits, 
        uint256 statsUserTotalInvested,
        uint256 statsUserTotalWithdrawn,
        uint256 statsUserRefBonus,
        uint256 statsUserDividends,
        uint256 statsUserRate)
    {
            return 
                (totalInvested,
                totalWithdrawn,
                totalDeposits, 
                getContractBalance(),
                getUserAmountOfDeposits(msg.sender),
                getUserTotalDeposits(msg.sender),
                getUserTotalWithdrawn(msg.sender),
                getUserReferralBonus(msg.sender),
                getUserDividends(msg.sender),
                getUserPercentRate(msg.sender));
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