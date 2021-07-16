//SourceUnit: Access.sol

pragma solidity 0.5.10;

import './DataStorage.sol';

contract Access is DataStorage {

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal reentryStatus;

  modifier isOwner(address _account) {
    require(owner == _account, "Restricted Access!");
    _;
  }
  
  modifier blockReEntry() {
    require(reentryStatus != ENTRY_DISABLED, "Security Block");
    reentryStatus = ENTRY_DISABLED;

    _;

    reentryStatus = ENTRY_ENABLED;
  }
}

//SourceUnit: DataStorage.sol

pragma solidity 0.5.10;

contract DataStorage {

    uint256 constant public INVEST_MIN_AMOUNT = 200 trx;
	uint256[] public REFERRAL_PERCENTS = [50, 30, 10, 5, 5, 5, 5];
	uint256 public PROJECT_FEE = 0;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

  	uint256 public totalInvest;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint256 fee;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address payable referrer;
		uint256[7] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalPayout;
		uint256 totalRefDeposit;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;
    address payable public owner;
}

//SourceUnit: Events.sol

pragma solidity 0.5.10;

contract Events {
  event Newbie(address user, address referrer);
  event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
  event Withdrawn(address indexed user, uint256 amount);
  event RefBonus(address indexed referrer , address indexed referral, uint256 indexed level, uint256 amount);
  event FeePayed(address indexed user, uint256 totalAmount);
}

//SourceUnit: Tronnetworks.sol

pragma solidity 0.5.10;
import './DataStorage.sol';
import './Access.sol';
import './Events.sol';

contract Tronnetworks is DataStorage, Access, Events  {
	using SafeMath for uint256;
	
	constructor(address payable wallet, address payable _owner, uint256 startDate) public {
		require(!isContract(wallet));
		require(startDate > 0);
		commissionWallet = wallet;
		owner = _owner;
		startUNIX = startDate;
        reentryStatus = ENTRY_ENABLED;
         
        plans.push(Plan(45, 2));
        plans.push(Plan(90, 4));
        plans.push(Plan(150, 6));
        plans.push(Plan(210, 8));
        plans.push(Plan(270, 10));
        plans.push(Plan(360, 12));
	}

	function invest(address payable referrer, uint8 plan) external payable blockReEntry() {
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");

		User storage user = users[msg.sender];
		uint256 fee = 0;
		if(PROJECT_FEE > 0) {
		  	fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
            commissionWallet.transfer(fee);
    		emit FeePayed(msg.sender, fee);   
		}
		
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 7; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address payable upline = user.referrer;
			for (uint256 i = 0; i < 7; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					users[upline].totalRefDeposit = users[upline].totalRefDeposit.add(msg.value);
					processPayout(upline, amount);
					users[upline].totalPayout = users[upline].totalPayout.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender, referrer);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish, fee));

		totalInvest = totalInvest.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	
	function processPayout(address _addr, uint _amount) internal {
        (bool success, ) = address(uint160(_addr)).call.gas(40000).value(_amount)("");

        require(success, 'Transfer Failed');
    }

	function withdraw() external blockReEntry() {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
	   
	    require(totalAmount > 5 trx, "Min withdraw is 5 trx");
        msg.sender.transfer(totalAmount);
        user.totalPayout = user.totalPayout.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		return plans[plan].percent;
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 6) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (block.timestamp > user.deposits[i].finish) {
			        	totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP)).add(user.deposits[i].amount);
			        } else if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					} 
				} 
			} 
		}

		return totalAmount;
	}
	
	function getUserTotalRefDeposit(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRefDeposit;
	}
	
	function getUserTotalPayout(address userAddress) public view returns(uint256) {
		return users[userAddress].totalPayout;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3], users[userAddress].levels[4], users[userAddress].levels[5], users[userAddress].levels[6]);
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
		return getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	function setOwner(address payable _addr) external isOwner(msg.sender) {
        owner = _addr;
    }
    
    function setFeeSystem(uint256 _fee) external isOwner(msg.sender) {
        PROJECT_FEE = _fee;
    }
    
    function setCommissionsWallet(address payable _addr) external isOwner(msg.sender) {
        commissionWallet = _addr;
    }

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function handleForfeitedBalance(address payable _addr, uint256 _amount) external {
        require((msg.sender == commissionWallet), "Restricted Access!");
        
        (bool success, ) = _addr.call.value(_amount)("");
    
        require(success, 'Failed');
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