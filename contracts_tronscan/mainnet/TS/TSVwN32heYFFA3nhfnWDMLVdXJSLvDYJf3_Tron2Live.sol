//SourceUnit: Tron2Live.sol



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

contract Tron2Live is Ownable {
	using SafeMath for uint256;

	uint256 public INVEST_MIN_AMOUNT = 100000000;
	uint256 public BASE_PERCENT = 20;
	uint256[] public REFERRAL_PERCENTS = [22, 20, 2, 2, 2, 2];
	uint256 public MARKETING_FEE = 50;
	uint256 public PROJECT_FEE = 50;
	uint256 public PERCENTS_DIVIDER = 1000;
	uint256 public CONTRACT_BALANCE_STEP = 1000000000000;
	uint256 public TIME_STEP = 1 days;
	uint256 public START_TIME = 1610017200;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
        uint256[] refCount;
        uint256[] refBonus;
		uint256 checkpoint;
		address referrer;
		uint256 balance;
		uint256 withdrawn;
		bool active;
	}

	mapping (address => User) public users;

	event Activation(address indexed user, address indexed referrer);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

    modifier checkStart() {
        require(block.timestamp >= START_TIME, "Start time not reached!");
        _;
    }

	function activeAccount(address referrer) public {
		User storage user = users[msg.sender];
		require(!user.active, "The user already activated!");
		require(referrer == address(0) || users[referrer].active, "The referrer account must be already activated!");
		
		user.active = true;
		user.referrer = referrer;
		user.checkpoint = block.timestamp;
		totalUsers = totalUsers.add(1);
		user.refCount = new uint256[](6);
		user.refBonus = new uint256[](6);
		
        uint256 level = 0;
        address upline = referrer;
        while(upline != address(0) && level < 6){
            users[upline].refCount[level] = users[upline].refCount[level].add(1);
            upline = users[upline].referrer;
            level = level.add(1);
        }
		emit Activation(msg.sender, referrer);
	}
	
	function setParam(address payable marketingAddr, address payable projectAddr, uint256 percent) public onlyOwner {
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		MARKETING_FEE = percent;
	}

	function invest(address referrer) public payable checkStart{
		require(msg.value >= INVEST_MIN_AMOUNT, "Your investment amount is less than the minimum amount!");
		User storage user = users[msg.sender];
		if (!user.active) {
			activeAccount(referrer);
		}

		address upline = user.referrer;
		for (uint256 i = 0; i < 6; i++) {
			if (upline == address(0)) {
				break;
			}
			uint256 value = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
			users[upline].balance = users[upline].balance.add(value);
			users[upline].refBonus[i] = users[upline].refBonus[i].add(value);
			emit RefBonus(upline, msg.sender, i, value);
			upline = users[upline].referrer;
		}

		user.deposits.push(Deposit(msg.value, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw(uint256 amount) public{
		uint256 totalAmount = getUserDividends(msg.sender);
		User storage user = users[msg.sender];

		require(user.balance.add(totalAmount) >= amount, "User has no dividends!");
		user.balance = user.balance.add(totalAmount).sub(amount);
		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(amount);
		msg.sender.transfer(amount);
		marketingAddress.transfer(amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		totalWithdrawn = totalWithdrawn.add(amount);
		emit Withdrawn(msg.sender, amount);
	}

	function reinvest(uint256 amount) public{
		require(amount >= INVEST_MIN_AMOUNT, "Your reinvest amount is less than the minimum amount!");
		uint256 totalAmount = getUserDividends(msg.sender);
		User storage user = users[msg.sender];

		require(user.balance.add(totalAmount) >= amount, "User has no dividends!");
		user.balance = user.balance.add(totalAmount).sub(amount);
		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(amount);
		marketingAddress.transfer(amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		totalWithdrawn = totalWithdrawn.add(amount);
		emit Withdrawn(msg.sender, amount);

		address upline = user.referrer;
		for (uint256 i = 0; i < 6; i++) {
			if (upline == address(0)) {
				break;
			}			
			uint256 value = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
			users[upline].balance = users[upline].balance.add(value);
			users[upline].refBonus[i] = users[upline].refBonus[i].add(value);
			emit RefBonus(upline, msg.sender, i, value);
			upline = users[upline].referrer;
		}

		user.deposits.push(Deposit(amount, block.timestamp));
		totalInvested = totalInvested.add(amount);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, amount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		if (contractBalancePercent > 20) contractBalancePercent = 20;
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];
		uint256 rate = getRate();
		uint256 totalDividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].start > user.checkpoint) {
				totalDividends = totalDividends.add((user.deposits[i].amount.mul(rate).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.deposits[i].start))
					.div(TIME_STEP));
			} else {
				totalDividends = totalDividends.add((user.deposits[i].amount.mul(rate).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.checkpoint))
					.div(TIME_STEP));
			}
		}
		return totalDividends;
	}

	function getUserInfo(address userAddress) public view returns(uint256 Dividends, uint256[] memory amounts, uint256[] memory starts, uint256[] memory refCount, uint256[] memory refBonus) {
	    User memory user = users[userAddress];
		uint256 len = user.deposits.length;
		amounts = new uint256[](len);
		starts = new uint256[](len);
		Dividends = getUserDividends(userAddress);
		for (uint256 i = 0; i < len; i++) {
			amounts[i] = user.deposits[i].amount;
			starts[i] = user.deposits[i].start;
		}
		refCount = user.refCount;
		refBonus = user.refBonus;
	}

	function getTotalInfo() public view returns (uint256 Users, uint256 Invested, uint256 Withdrawns, uint256 Deposits, uint256 Balance) {
		Users = totalUsers;
		Invested = totalInvested;
		Withdrawns = totalWithdrawn;
		Deposits = totalDeposits;
		Balance = getContractBalance();
	}
}