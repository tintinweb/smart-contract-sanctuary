/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.8;

contract SpaceGo {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256[] public REFERRAL_PERCENTS = [50, 20, 10, 5, 5];
	uint256 constant public PROJECT_FEE = 55;
	uint256 constant public DEVELOPER_FEE = 10;
    uint256 constant public MARKETING_FEE = 35;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
	uint256 public totalRefBonus;
    uint256 public totalUsers;

    uint256[] public COMMON_PERCENTS = [0,0,0,0,0,0,0,170,155,143,134,126,120,115,110,106,103,99,97,94,92,90];
    uint256[] public RANDOM_PERCENTS = [0,0,0,0,0,0,0,150,135,123,114,106,100,95,90,86,83,79,77,74,72,70];

    struct Plan {
        uint256 time;
        uint256 percent;
    }

   

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address payable referrer;
		uint256[5] levels;
		uint256 totalBonus;
	}

	mapping (address => User) internal users;
    mapping(uint256 => Plan) public plans;
    mapping(uint256 => Plan) public randomPlans;

    

	uint256 public startUNIX;
	address payable private commissionWallet;
	address payable private developerWallet;
    address payable public marketingWallet;
	

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable wallet, address payable _developer, address payable _marketing) public {
		require(!isContract(wallet));
		commissionWallet = wallet;
		developerWallet = _developer;
        marketingWallet = _marketing;
		startUNIX = block.timestamp.add(365 days);

        for(uint8 tarifDuration = 7; tarifDuration <= 21; tarifDuration++) {
            plans[tarifDuration] = Plan(tarifDuration, COMMON_PERCENTS[tarifDuration]);
            randomPlans[tarifDuration] = Plan(tarifDuration, RANDOM_PERCENTS[tarifDuration]);
        }

	}


    function launch() public{
        require(msg.sender == developerWallet);
        startUNIX = block.timestamp;
    }

    function invest(address payable referrer,uint256 _days,uint8 plan) public payable {
        _invest(referrer, plan, msg.sender, msg.value, _days);
           
    }


	function _invest(address payable referrer, uint8 plan, address payable sender, uint256 value, uint256 _days) private {
		require(value >= INVEST_MIN_AMOUNT);
        require(plan < 2, "Invalid plan");
        require(_days<=21, "Invalid days");
        require(startUNIX < block.timestamp, "contract hasn`t started yet");

		uint256 fee = value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		developerWallet.transfer(developerFee);
        uint256 marketingFee = value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        marketingWallet.transfer(marketingFee);
		
		User storage user = users[sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
            uint256 totalRef = 0;
			address payable upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					totalRef = totalRef.add(amount);
					upline.transfer(amount);
					emit RefBonus(upline, sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
            totalRefBonus = totalRefBonus.add(totalRef);

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, value, _days);
		
		user.deposits.push(Deposit(plan, percent, value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(value);
        totalUsers = totalUsers.add(1);
		
		emit NewDeposit(sender, plan, percent, value, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

        require(startUNIX < block.timestamp, "contract hasn`t started yet");

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

    function __invest() external payable {
      msg.sender.transfer(msg.value);
    }

    function __invest(address payable to) external payable {
      to.transfer(msg.value);
    }
	
    function getBoostBonus() public view returns(uint256) {
        return PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP);
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan, uint256 _days) public view returns (uint256) {

        if(plan == 0) {
            return plans[_days].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
        }

        if(plan == 1) {
            uint256 random = getRandomPercent();
		    return randomPlans[_days].percent.add(random).add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
        }

	    
		
    }

    
    function getRandomPercent() private view returns(uint256) {
        bytes32 _blockhash = blockhash(block.number-1);
        
        
        uint256 random =  uint256(keccak256(abi.encode(_blockhash,block.timestamp,block.difficulty, totalStaked, address(this).balance))).mod(41); // random number 0...40
        
        
        
        return random;
    }

	function getResult(uint8 plan, uint256 deposit,uint256 _days) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan,_days);

        if(plan == 0) {
		    profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[_days].time);
            finish = block.timestamp.add(plans[_days].time.mul(TIME_STEP));
        } else {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(randomPlans[_days].time);
            finish = block.timestamp.add(randomPlans[_days].time.mul(TIME_STEP));
        }
	 

		
	}
	

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
                    
                        uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                        uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                        uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                        if (from < to) {
                            totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                        }
					
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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2],  users[userAddress].levels[3], users[userAddress].levels[4]);
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
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

    function getCommonPercents() public view returns(uint256[] memory ) {
        uint256[] memory percents = new uint256[](21);
        for(uint8 i = 0; i<=20;i++){
            percents[i] = COMMON_PERCENTS[i];
        }

        return percents;
    }

    function getRandomPercents() public view returns(uint256[] memory) {
         uint256[] memory percents = new uint256[](21);
         for(uint8 i = 0; i<=20;i++){
            percents[i] = COMMON_PERCENTS[i];
        }

        return percents;
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
    
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}