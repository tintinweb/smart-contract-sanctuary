//SourceUnit: Tronworldtrade.sol

pragma solidity 0.5.10;

contract TronwWorldTrade{
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public BASE_PERCENT = 250;
	uint256[] public REFERRAL_PERCENTS = [100, 50, 30];
	uint256 constant public ADMIN_FEE=100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	address payable public adminAddress;
	address public owner;

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
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 bonus_withdrawn;
	}

	mapping (address => User) internal users;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);


	constructor(address payable _admin) public {
		adminAddress=_admin;
		owner = msg.sender;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		adminAddress.transfer(msg.value.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
		User storage user = users[msg.sender];
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
				    if(i == 0){
						users[upline].level1 = users[upline].level1.add(1);	
					} else if(i == 1){
						users[upline].level2 = users[upline].level2.add(1);	
					} else if(i == 2){
						users[upline].level3 = users[upline].level3.add(1);	
					}
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
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(3)) {
					dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
			user.bonus_withdrawn = user.bonus_withdrawn.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
	   user.checkpoint = block.timestamp;
       uint256 a=totalAmount.mul(50).div(100);
       Reinvest(totalAmount.mul(50).div(100));
	   msg.sender.transfer(totalAmount.sub(a));
	   totalWithdrawn = totalWithdrawn.add(totalAmount.sub(a));
	   emit Withdrawn(msg.sender, totalAmount);
	}


	function Reinvest(uint256 _value) internal {
		User storage user = users[msg.sender];
		user.deposits.push(Deposit(_value, 0, block.timestamp));
		totalInvested = totalInvested.add(_value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, _value);
	}

	function updateAdminAddress(address payable _newAdminAccount) public{
		require(msg.sender == owner);
        adminAddress = _newAdminAccount;
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		return BASE_PERCENT;
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			return contractBalanceRate;
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 userPercentRate = getUserPercentRate(userAddress);
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(3)) {
					dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
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

    function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3, users[userAddress].bonus, users[userAddress].bonus_withdrawn);
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];
		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(300).div(100)) {
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