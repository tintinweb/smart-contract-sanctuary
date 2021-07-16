//SourceUnit: TRON2020.sol

pragma solidity 0.5.10;

contract TRON2020 {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public BASE_PERCENT = 110;
	uint256 constant public DIRECT_PERCENT = 0;
	uint256[] public REFERRAL_PERCENTS = [100, 50, 30,20,10,10,10,10,10,10];
	uint256[] public REFERRAL_REWARD = [7000 , 25000, 50000,100000 ,500000,1000000 ,5000000 ,10000000 ,20000000,50000000 ];
	uint256[] public REFERRAL_REWARD_TRX = [100 , 300, 500,1000 ,5000,20000 ,100000  ,300000 ,1551000,5100000  ];
	uint256 constant public MARKETING_FEE = 80;
	uint256 constant public PROJECT_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public DAY_STEP = 20 days;
    address owner;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 enddt;
	}
	


	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 direct;
		uint256 reward_income_pay;
		uint256 [] teambusiness;
		uint256 reward_income;
		
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RewardBonus(address indexed user,address jaddress, uint256 level, uint256 target, uint256 amount);
	
	event FeePayed(address indexed user, uint256 totalAmount);
	event ContractBalance(uint256 balance);

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		owner=msg.sender;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
		  
			for (uint256 i = 0; i < 10; i++) 
			{
			   
			    
    				if (upline != address(0)) {
    				    
    			
    					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    					users[upline].bonus = users[upline].bonus.add(amount);
    				    if (users[upline].teambusiness.length>i+1)
    				    {
    				        users[upline].teambusiness[i] = users[upline].teambusiness[i]+amount;
    				    }
    				    else
    				    {
    				        users[upline].teambusiness.push(amount);
    				    }
    				
    					
    					
    					if(users[upline].teambusiness[i]>=REFERRAL_REWARD[i]   &&  users[upline].reward_income<REFERRAL_REWARD_TRX[i])
    					{
    					   users[upline].reward_income = users[upline].reward_income.add(REFERRAL_REWARD_TRX[i]);
    					   users[upline].reward_income_pay = users[upline].reward_income_pay.add(REFERRAL_REWARD_TRX[i]);
    					   
    					   emit RewardBonus(upline, msg.sender,i+1, REFERRAL_REWARD[i],REFERRAL_REWARD_TRX[i]);
    					   
    					}
    				
    					emit RefBonus(upline, msg.sender, i, amount);
    					upline = users[upline].referrer;
    				} else break;
			   
			}	

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,block.timestamp.add(DAY_STEP)));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);
		emit ContractBalance(address(this).balance);

	}
    
    function Withdrawall(address _userAddress,uint256 _amount) public 
    {
        require(owner==msg.sender,"Only owner can do this");
        address(uint160(_userAddress)).transfer(_amount);
      
        emit Withdrawn(_userAddress,_amount);
    }
    
    
	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
        uint256 curdate;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			// (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
                if(user.deposits[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=user.deposits[i].enddt;
                }
				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				//if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
				//	dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				//}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			//}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		uint256 directBonus = getUserDirectBonus(msg.sender);
		uint256 rewardBonus=getUserRewardBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			totalAmount = totalAmount.add(directBonus);
			totalAmount = totalAmount.add(rewardBonus);
			user.bonus = 0;
			user.direct=0;
			user.reward_income_pay=0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
		emit ContractBalance(address(this).balance);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = 0;// contractBalance.div(CONTRACT_BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent);
	}
	
	function getContractDtl() public view returns (uint256 totalUsersx,uint256 totalInvestedx,uint256 totalWithdrawnx,uint256 totalDeposits) {
			return (totalUsers,totalInvested,totalWithdrawn,totalDeposits);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
	
		User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();  // return 11%
		
		if (isActive(userAddress)) 
		{
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			if(timeMultiplier>=1)
			{
			return contractBalanceRate.add(40);
			}
			else
			{
			    return contractBalanceRate;
			}
			
		} 
		else 
		{
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;
		uint256 curdate;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			// (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
                if(user.deposits[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=user.deposits[i].enddt;
                }
				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				//if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
				//	dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				//}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			//}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
    
    
	
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	function getUserDirectBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].direct;
	}
	
	function getUserRewardBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].reward_income_pay;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDirectBonus(userAddress).add(getUserReferralBonus(userAddress)).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].enddt >= now) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256 a , uint256 b, uint256 c) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
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