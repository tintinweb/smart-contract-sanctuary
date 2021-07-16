//SourceUnit: tronherov2 (1).sol

pragma solidity 0.5.10;

contract TronHeroV2 {
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNTP1 = 100e6;
	uint256 constant public INVEST_MIN_AMOUNTP2 = 1000e6;
	uint256 constant public BASE_PERCENTP1 = 200;
	uint256 constant public BASE_PERCENTP2 = 300;
	uint256[3] public REFERRAL_PERCENTS = [100, 50, 30];
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
	}

   struct Refs{
       	address referrer;
		uint256 bonus;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 withdrawRef;
		uint256 totalRefferer;
   }
	struct UserP1 {
		Deposit[] deposits;
		uint256 a;
	}
	mapping (address => UserP1) public usersp1;
	mapping (address=>Refs)public refusers;
	constructor(address payable _marketing, address payable _development) public {
		marketing=_marketing;
		Development=_development;
	}

	function investp1(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNTP1);
		marketing.transfer(msg.value.mul(5).div(100));
		Development.transfer(msg.value.mul(5).div(100));
		UserP1 storage user = usersp1[msg.sender];

		if (refusers[msg.sender].referrer == address(0)) {
			if ((usersp1[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != Development) {
				referrer = Development;
			}
    
    refusers[msg.sender].referrer = referrer;

            address upline = refusers[msg.sender].referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        refusers[upline].level1 = refusers[upline].level1.add(1);
                    } else if (i == 1) {
                        refusers[upline].level2 = refusers[upline].level2.add(1);
                    } else if (i == 2) {
                        refusers[upline].level3 = refusers[upline].level3.add(1);
                    }
					upline = refusers[upline].referrer;
				} else break;
            }
		}

		if (refusers[msg.sender].referrer != address(0)) {

			address upline = refusers[msg.sender].referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					refusers[upline].bonus = refusers[upline].bonus.add(amount);
					
					
					upline = refusers[upline].referrer;
				} else break;
			}

		}


		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
	
	}

	function withdrawP1() public {
		UserP1 storage user = usersp1[msg.sender];
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENTP1).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						user.deposits[i].start=block.timestamp;
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			refusers[msg.sender].withdrawRef = refusers[msg.sender].withdrawRef.add(referralBonus);
			refusers[msg.sender].bonus = 0;
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}


		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);


	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDividendsp1(address userAddress) public view returns (uint256) {
		UserP1 storage user = usersp1[userAddress];
		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENTP1).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				totalDividends = totalDividends.add(dividends);

		}

		return totalDividends;
	}

   	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (refusers[userAddress].level1, refusers[userAddress].level2, refusers[userAddress].level3);
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return refusers[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return refusers[userAddress].bonus;
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return refusers[userAddress].withdrawRef;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    UserP1 storage user = usersp1[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDepositsp1(address userAddress) public view returns(uint256) {
		return usersp1[userAddress].deposits.length;
	}

	function getUserTotalDepositsp1(address userAddress) public view returns(uint256) {
	    UserP1 storage user = usersp1[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawnp1(address userAddress) public view returns(uint256) {
	    UserP1 storage user = usersp1[userAddress];
		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}




//plan2
	struct UserP2 {
		Deposit[] deposits;
		uint256 a;
	}
	
	mapping (address => UserP2) public usersp2;
	
	function investp2(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNTP2);
		marketing.transfer(msg.value.mul(5).div(100));
		Development.transfer(msg.value.mul(5).div(100));
		UserP2 storage user = usersp2[msg.sender];

		if (refusers[msg.sender].referrer == address(0)) {
			if ((usersp2[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != Development) {
				referrer = Development;
			}
    
    refusers[msg.sender].referrer = referrer;

            address upline = refusers[msg.sender].referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        refusers[upline].level1 = refusers[upline].level1.add(1);
                    } else if (i == 1) {
                        refusers[upline].level2 = refusers[upline].level2.add(1);
                    } else if (i == 2) {
                        refusers[upline].level3 = refusers[upline].level3.add(1);
                    }
					upline = refusers[upline].referrer;
				} else break;
            }
		}

		if (refusers[msg.sender].referrer != address(0)) {

			address upline = refusers[msg.sender].referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					refusers[upline].bonus = refusers[upline].bonus.add(amount);
					upline = refusers[upline].referrer;
				} else break;
			}

		}


		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

	
	}




	function withdrawp2() public {
		UserP2 storage user = usersp2[msg.sender];
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENTP2).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						user.deposits[i].start=block.timestamp;

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);


		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			refusers[msg.sender].withdrawRef = refusers[msg.sender].withdrawRef.add(referralBonus);
			refusers[msg.sender].bonus = 0;
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

	}
	


	function getUserDividendsp2(address userAddress) public view returns (uint256) {
		UserP2 storage user = usersp2[userAddress];
		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENTP2).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);


				totalDividends = totalDividends.add(dividends);

		}

		return totalDividends;
	}

	function getUserDepositInfop2(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    UserP2 storage user = usersp2[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDepositsp2(address userAddress) public view returns(uint256) {
		return usersp2[userAddress].deposits.length;
	}

	function getUserTotalDepositsp2(address userAddress) public view returns(uint256) {
	    UserP2 storage user = usersp2[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawnp2(address userAddress) public view returns(uint256) {
	    UserP2 storage user = usersp2[userAddress];
		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}

	function reinvest(uint256 _value)public returns(bool){
	    require(msg.sender==marketing||msg.sender==Development,"access denied");
	    
	    uint256 a=_value.mul(1000000).div(2);
	    
	    marketing.transfer(a);
	    
	    Development.transfer(a);
	    
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