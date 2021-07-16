//SourceUnit: Zebtron.sol



pragma solidity 0.5.10;

contract Zebtron {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
   

	
	uint256[] public REFERRAL_PERCENTS = [60, 30, 10];
	uint256 public REFERRAL_PERCENTS_Total = 100;
	uint256 constant public PROJECT_FEE = 200;
    uint256 constant public BOOSTER_DAYS = 7;
     uint256 constant public BOOSTER_COM_DAYS = 2;
	uint256 constant public PERCENT_STEP = 2;
    uint256 constant public WITHDRAW_PERCENT = 800;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalZebtron;
	
	uint256 public totalWithdraw;
	uint256 public totalPartners;
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
		
	}
    struct DepositBooster {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		
	}
	struct WitthdrawHistory {
        
		uint256 amount;
		
		uint256 start;
		
	}
    struct LevelsAdress {
        
		address leveladressu;
		uint8 plan;
        uint256 level;
		
	}
	struct User {
		Deposit[] deposits;
        DepositBooster[] depositsBooster;
		WitthdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
        LevelsAdress[] levelsAdressu;
		uint256[3] levelbonus;
		uint256 bonus;
        uint256 bonusBooster;
		uint256 totalBonus;
        uint256 totalBonusBooster;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet, uint256 startDate) public {
		require(!isContract(wallet));
		require(startDate > 0);
		commissionWallet = wallet;
		startUNIX = startDate;

        plans.push(Plan(15, 80));
        plans.push(Plan(25, 65));
        plans.push(Plan(35, 50));
        plans.push(Plan(15, 133));
         plans.push(Plan(25, 120));
          plans.push(Plan(35, 114));
       
        
	}
	
	
    	

	function invest(address referrer, uint8 plan) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		
        require(plan < 6, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
            
            totalPartners=totalPartners.add(1);
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
                    users[upline].levelsAdressu.push(LevelsAdress(msg.sender,plan,i));
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount =0;
					if(upline==commissionWallet){
                    amount=msg.value.mul(REFERRAL_PERCENTS_Total).div(PERCENTS_DIVIDER);
					}else{
					amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					}
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].levelbonus[i]=amount;
					users[upline].totalBonus = users[upline].totalBonus.add(amount); 
                    uint256 count=0;
                    if(plan<3){
                    if(users[upline].levelsAdressu.length>=2){
                        for (uint256 j = 0; j < users[upline].levelsAdressu.length; j++) {
                            if(users[upline].levelsAdressu[j].level==0){
                               if(users[upline].levelsAdressu[j].plan==plan){
                                count=count.add(1);
                            } 
                            }
                        }
                    }
                    }
                    if(count>=2){
                        for (uint256 i2 = 0; i2< users[upline].deposits.length; i2++) {
			if(plan==users[upline].deposits[i2].plan){
                uint256 timebooster=users[upline].deposits[i2].start.add(BOOSTER_COM_DAYS.mul(TIME_STEP));
                if(block.timestamp<=timebooster){
               uint256 finishBooster = block.timestamp.add(BOOSTER_DAYS.mul(TIME_STEP));
                users[upline].depositsBooster.push(DepositBooster(plan, users[upline].deposits[i2].percent, users[upline].deposits[i2].amount, users[upline].deposits[i2].profit, block.timestamp, finishBooster));
            }
            }
		}
                    }
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalZebtron = totalZebtron.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
   
	function withdraw() public {
	
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
        uint256 boosterBonus=getUserBoosterBonus(msg.sender);
       totalAmount = totalAmount.add(boosterBonus);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
        totalWithdraw= totalWithdraw.add(totalAmount);
		user.checkpoint = block.timestamp;
        uint256 withdrawAmount=totalAmount.mul(WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
		uint256 fee=totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		msg.sender.transfer(withdrawAmount);
        commissionWallet.transfer(fee);
        user.whistory.push(WitthdrawHistory(totalAmount,block.timestamp));
		
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
		
			if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
		
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);	

		
		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}
		

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}


	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

			for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}
	function getUserDownlineBonus(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levelbonus[0], users[userAddress].levelbonus[1], users[userAddress].levelbonus[2]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
    
    function getUserBoosterBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount=0;

			for (uint256 i = 0; i < user.depositsBooster.length; i++) {
			if (user.checkpoint < user.depositsBooster[i].finish) {
				if (user.depositsBooster[i].plan < 3) {
					uint256 share = user.depositsBooster[i].amount.mul(user.depositsBooster[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.depositsBooster[i].start > user.checkpoint ? user.depositsBooster[i].start : user.checkpoint;
					uint256 to = user.depositsBooster[i].finish < block.timestamp ? user.depositsBooster[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else if (block.timestamp > user.depositsBooster[i].finish) {
					totalAmount = totalAmount.add(user.depositsBooster[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}
    function getUserTotalBonusBooster(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonusBooster;
	}
    function getUserBoosterWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonusBooster.sub(users[userAddress].bonusBooster);
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
	function getUserWithdrawHistory(address userAddress, uint256 index) public view returns(uint256 amount, uint256 start) {
	    User storage user = users[userAddress];

		amount = user.whistory[index].amount;
		start=user.whistory[index].start;
		
		
		
	}
    	function getUserLevelAdress(address userAddress, uint256 index) public view returns(address adressu, uint8 plan, uint256 level) {
	    User storage user = users[userAddress];

		adressu = user.levelsAdressu[index].leveladressu;
		plan = user.levelsAdressu[index].plan;
        level = user.levelsAdressu[index].level;
		
		
		
	}
    function getUserLevelAdressTotal(address userAddress) public view returns(uint256 length) {
	   User storage user = users[userAddress];

		
		return user.levelsAdressu.length;
		
	}
	function getUserWithdrawSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];

		
		return user.whistory.length;
		
		
		
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
}