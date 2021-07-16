//SourceUnit: TronInv.sol



pragma solidity >= 0.5.10;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
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

contract TronInv is Ownable {
	using SafeMath for uint256;

	uint256 public constant MIN_INVEST = 200000000;
	uint256 public constant BASE_PERCENT = 5;
	uint256[] public REFERRAL_PERCENTS = [140, 50, 10];
	uint256 public constant PROJECT_FEE = 50;
	uint256 public constant PERCENTS_DIVIDER = 1000;
	uint256 public constant TIME_STEP = 1 days;
	uint256 public constant START_TIME = 1612089000;
	address payable public constant PROJECT_ADDRESS = address(0x410df68612974155e094bc5561c8d8257c936a5446);

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	struct Deposit {
		bool active;
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
        uint256[] referrals;
        uint256[] commission;
		uint256 checkpoint;
		address referrer;
		uint256 balance;
		uint256 withdrawn;
		bool active;
	}

	mapping (address => User) public users;


	event Registered(address indexed user, address indexed referrer);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event Refund(address indexed user, uint256 amount, uint256 depositNum);
	event RefReward(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

    modifier checkStart() {
        require(block.timestamp >= START_TIME, "Start time not reached!");
        _;
    }

	function refReward(address referrer, uint256 amount) internal{
		address upline = referrer;
		uint256 level = 0;
		while (level < 3 || upline != address(0)) {
			uint256 value = amount.mul(REFERRAL_PERCENTS[level]).div(PERCENTS_DIVIDER);
			users[upline].balance = users[upline].balance.add(value);
			if (users[upline].commission.length < 3){
				users[upline].commission = new uint256[](3);
			}
			users[upline].commission[level] = users[upline].commission[level].add(value);
			emit RefReward(upline, msg.sender, level, value);
			upline = users[upline].referrer;
            level = level.add(1);
		}
	}

	function register(address referrer) public {
		User storage user = users[msg.sender];
		require(!user.active, "Your account already activated!");
		require(referrer == address(0) || users[referrer].active, "The referrer account must be already activated!");
		
		user.active = true;
		user.referrer = referrer;
		user.checkpoint = block.timestamp;
		totalUsers = totalUsers.add(1);
		user.referrals = new uint256[](3);
		user.commission = new uint256[](3);
		
        uint256 level = 0;
        address upline = referrer;
        while(level < 3 && upline != address(0)){
            users[upline].referrals[level] = users[upline].referrals[level].add(1);
            upline = users[upline].referrer;
            level = level.add(1);
        }
		emit Registered(msg.sender, referrer);
	}

	function deposit(address referrer) public payable checkStart{
		require(msg.value >= MIN_INVEST, "Investment amount must be greater than 200 TRX!");
		User storage user = users[msg.sender];
		if (!user.active) {
			register(referrer);
		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
		}
		user.deposits.push(Deposit(true, msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw(uint256 amount) public{
		uint256 totalAmount = getDividends(msg.sender);
		User storage user = users[msg.sender];

		require(user.balance.add(totalAmount) >= amount, "User has no dividends!");
		refReward(user.referrer, totalAmount);
		user.balance = user.balance.add(totalAmount).sub(amount);
		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(amount);
		msg.sender.transfer(amount);
		PROJECT_ADDRESS.transfer(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		totalWithdrawn = totalWithdrawn.add(amount);
		emit Withdrawn(msg.sender, amount);
	}

	function refund(uint256 depositNum) public{
		User storage user = users[msg.sender];
		require(user.deposits.length > depositNum, "Invalid depositNum!");
		require(user.deposits[depositNum].active, "Allready refund the depositNum!");
		uint256 totalAmount = getDividends(msg.sender);
		uint256 amount = user.deposits[depositNum].amount;
		user.checkpoint = block.timestamp;
		user.balance = user.balance.add(totalAmount);
		user.deposits[depositNum].active = false;
		msg.sender.transfer(amount);
		PROJECT_ADDRESS.transfer(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit Refund(msg.sender, amount, depositNum);
	}

	function getRate(uint256 checkpoint) public view returns (uint256) {
		uint rate = BASE_PERCENT.add(block.timestamp.sub(checkpoint).div(TIME_STEP));
		if (rate > 50) rate = 50;
		return rate;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];
		uint256 rate = getRate(user.checkpoint);
		uint256 totalDividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (!user.deposits[i].active || user.deposits[i].withdrawn >= user.deposits[i].amount) continue;
			uint256 dividends;
			if (user.deposits[i].start > user.checkpoint) {
				dividends = (user.deposits[i].amount.mul(rate).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.deposits[i].start))
					.div(TIME_STEP);
			} else {
				dividends = (user.deposits[i].amount.mul(rate).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.checkpoint))
					.div(TIME_STEP);
			}
			if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount) {
				dividends = (user.deposits[i].amount).sub(user.deposits[i].withdrawn);
			}
			totalDividends = totalDividends.add(dividends);
		}
		return totalDividends;
	}

	function getDividends(address userAddress) internal returns (uint256) {
		User storage user = users[userAddress];
		uint256 rate = getRate(user.checkpoint);
		uint256 totalDividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (!user.deposits[i].active || user.deposits[i].withdrawn >= user.deposits[i].amount) continue;
			uint256 dividends;
			if (user.deposits[i].start > user.checkpoint) {
				dividends = (user.deposits[i].amount.mul(rate).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.deposits[i].start))
					.div(TIME_STEP);
			} else {
				dividends = (user.deposits[i].amount.mul(rate).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.checkpoint))
					.div(TIME_STEP);
			}
			if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount) {
				dividends = (user.deposits[i].amount).sub(user.deposits[i].withdrawn);
			}
			user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
			totalDividends = totalDividends.add(dividends);
		}
		return totalDividends;
	}

	function getDepositInfo(address userAddress) public view returns(bool[] memory actives, uint256[] memory amounts, uint256[] memory withdrawns, uint256[] memory starts) {
	    User memory user = users[userAddress];
		uint256 len = user.deposits.length;
		actives = new bool[](len);
		amounts = new uint256[](len);
		withdrawns = new uint256[](len);
		starts = new uint256[](len);
		for (uint256 i = 0; i < len; i++) {
			actives[i] = user.deposits[i].active;
			amounts[i] = user.deposits[i].amount;
			withdrawns[i] = user.deposits[i].withdrawn;
			starts[i] = user.deposits[i].start;
		}
	}
	
	function getUserInfo(address userAddress) public view returns(uint256 checkpoint, address referrer, uint256 balance, uint256 withdrawn, bool active, uint256 Dividends, uint256[] memory referrals, uint256[] memory commission) {
	    User memory user = users[userAddress];
		checkpoint = user.checkpoint;
		referrer = user.referrer;
		balance = user.balance;
		withdrawn = user.withdrawn;
		active = user.active;
		Dividends = getUserDividends(userAddress);
		referrals = user.referrals;
		commission = user.commission;
	}

	function getTotalInfo() public view returns (uint256 Users, uint256 Invested, uint256 Withdrawns, uint256 Deposits, uint256 Balance) {
		Users = totalUsers;
		Invested = totalInvested;
		Withdrawns = totalWithdrawn;
		Deposits = totalDeposits;
		Balance = address(this).balance;
	}
}