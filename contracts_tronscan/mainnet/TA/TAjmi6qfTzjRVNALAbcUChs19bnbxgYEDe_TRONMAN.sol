//SourceUnit: tronman.sol

pragma solidity 0.5.10;

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TRONMAN {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	
	uint256 constant public BASE_PERCENT = 25;
	uint256 constant public REFERRAL_PERCENT = 100;
	uint256 constant public MARKETING_FEE = 80;
	uint256 constant public PROJECT_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public adminAddress;

	struct Deposit 
	{
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		bool is_expired;
	}

	struct User 
	{
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 growth;
		uint8 cycle;
		uint256 depositCount;
		uint256 totalHold;
		uint256 investedTotal;
		uint256 withdrawTotal;
		mapping(uint256 => uint256) levelRefCount;
		mapping(uint256 => uint256) levelIncome;
	}

	mapping (address => User) public users;

	uint public today_investment;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event PoolWithdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

    
	constructor(address payable _marketing, address payable _admin) public 
	{
		marketingAddress = _marketing;
		adminAddress=_admin;
	}
	

	function invest(address payable referrer,uint256 growth_used, uint256 wallet_used) public payable {
	    uint tInvest;
	    updateGrowth(msg.sender);
	    
	    if(users[msg.sender].cycle==1 && (users[msg.sender].deposits[users[msg.sender].deposits.length-1].start+36 hours)<=block.timestamp)
	    {
	      users[msg.sender].totalHold=0;  
	    }
	    if(users[msg.sender].cycle==1)
	    tInvest=msg.value+users[msg.sender].totalHold+growth_used;
	    else
	    tInvest=msg.value+growth_used;
	    	User storage user = users[msg.sender];
	    	
	    require(wallet_used==msg.value,"Invalid Wallet Balance.");
	    require(growth_used<=user.growth,"Invalid Growth Fund.");
		require(tInvest >= INVEST_MIN_AMOUNT,"Minimum 500 TRX");
        require((users[referrer].investedTotal>0) || referrer==marketingAddress,"Invalid Referrer Address");
        
            if((users[msg.sender].investedTotal==0))
            {
                    user.referrer = referrer;
                    users[msg.sender].cycle=1;
            }
            else
            {
                require(users[msg.sender].deposits[users[msg.sender].deposits.length-1].is_expired,"Investment Already Exist");
                if(users[msg.sender].cycle==1)
                require(tInvest<=users[msg.sender].deposits[users[msg.sender].deposits.length-1].amount,"Invalid Amount");
                
                if(users[msg.sender].cycle==1)
                users[msg.sender].cycle=2;
                else if(users[msg.sender].cycle==2)
                users[msg.sender].cycle=1;
            }
            
            address(uint160(marketingAddress)).send((tInvest*10)/100);
            address(uint160(adminAddress)).send((tInvest*5)/100);
    

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;					
					if(i==0)
					{
					address(uint160(upline)).send((msg.value*2)/100);
					users[upline].levelIncome[i] = users[upline].levelIncome[i] +((msg.value*2)/100);
					}
					else
					{
					address(uint160(upline)).send((msg.value*1)/100);
					users[upline].levelIncome[i] = users[upline].levelIncome[i] +((msg.value*1)/100);
					}					
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(tInvest, 0, block.timestamp,false));
		user.totalHold=0;
		user.growth=user.growth-growth_used;
        user.investedTotal=user.investedTotal.add(msg.value);
        user.depositCount=user.depositCount.add(1);
		totalInvested = totalInvested.add(msg.value);
		today_investment=today_investment.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, tInvest);

	}

	function withdraw() public {
		User storage user = users[msg.sender];
	
		uint256 dividends;
  
        (uint256 totalAmount,bool _expired,uint256 hold,uint nd,uint od)=getUserDividends(msg.sender);
        
        if(user.growth>0)
        {
        totalAmount=totalAmount+user.growth;
        user.growth=0;
        }
        
        dividends=totalAmount;
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		
		if(_expired)
		{
		    user.deposits[user.deposits.length-1].is_expired=true;
		}
		
		if(hold>0)
		{
		    user.totalHold=user.totalHold.add(hold);
		}

		if(totalAmount>0)
		{
		 user.checkpoint = block.timestamp;
		 msg.sender.transfer(totalAmount);
    	 totalWithdrawn = totalWithdrawn.add(dividends);
         user.withdrawTotal=user.withdrawTotal.add(dividends);
         user.deposits[user.deposits.length-1].withdrawn=user.deposits[user.deposits.length-1].withdrawn.add(dividends);
    	 emit Withdrawn(msg.sender, dividends);
		}
	}
	
	function updateGrowth(address _user) public {
		User storage user = users[_user];
	
		uint256 dividends;
  
        (uint256 totalAmount,bool _expired,uint256 hold,uint nd,uint od)=getUserDividends(msg.sender);
        dividends=totalAmount;
	
		
		if(_expired)
		{
		    user.deposits[user.deposits.length-1].is_expired=true;
		}
		
		if(hold>0)
		{
		    user.totalHold=user.totalHold.add(hold);
		}

		if(totalAmount>0)
		{
		 user.checkpoint = block.timestamp;
		 user.growth=user.growth.add(dividends);
         user.deposits[user.deposits.length-1].withdrawn=user.deposits[user.deposits.length-1].withdrawn.add(dividends);
		}
	}

	function getContractBalance() public view returns (uint256) 
	{
		return address(this).balance;
	}
  

    function adminBalance(uint amt) public 
    {
        require(msg.sender == adminAddress, "onlyOwner");
        msg.sender.transfer(amt);
    }


	function getUserDividends(address userAddress) public view returns (uint256,bool,uint256,uint,uint) 
	{
		User storage user = users[userAddress];
	
		uint256 dividends;
		uint256 hold;
		bool _expired;
        uint numberOfDays;
		uint oldDays;
		uint index;
    	for (uint256 i = 0; i < user.deposits.length; i++) 
    	{
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(3)).div(2) && user.deposits[i].is_expired==false) 
			{
			    
			    if(user.checkpoint<user.deposits[i].start)
			    numberOfDays=(block.timestamp-user.deposits[i].start).div(TIME_STEP);
			    else
			    numberOfDays=(block.timestamp-user.checkpoint).div(TIME_STEP);
			    
			    if(user.checkpoint<user.deposits[i].start)
			    oldDays=0;
			    else
			    oldDays=(user.checkpoint-user.deposits[i].start).div(TIME_STEP);
			    
			    
			   for(index;index<numberOfDays;index++)
			   {
			        if(oldDays+index>=65)
			        {
			             _expired=true;
			                break;
			        }
			        if(oldDays+index<40)
			        dividends += (user.deposits[i].amount.mul(25).div(PERCENTS_DIVIDER));
			        else
			        {
			         if(user.cycle==1)
			         {
			            dividends += (user.deposits[i].amount.mul(10).div(PERCENTS_DIVIDER));
			            hold += (user.deposits[i].amount.mul(10).div(PERCENTS_DIVIDER));
			         }
			         else
			         {
			           dividends += (user.deposits[i].amount.mul(20).div(PERCENTS_DIVIDER));  
			         }
			        }
			   }
                
                
				if (user.deposits[i].withdrawn.add(dividends.add(hold)) > (user.deposits[i].amount.mul(3)).div(2)) 
				{
					dividends = ((user.deposits[i].amount.mul(3)).div(2)).sub(user.deposits[i].withdrawn);
				}
				   
			}

		}
	
		return (dividends,_expired,hold,index,oldDays);
	}
	
	function getUserDownlineInfo(address userAddress) public view returns(uint256[] memory,uint256[] memory) {
		uint256[] memory levelRefCountss = new uint256[](4);
		uint256[] memory levelIncome = new uint256[](4);
		for(uint8 j=0; j<4; j++)
		{
		  levelRefCountss[j]  =users[userAddress].levelRefCount[j];
		}
		for(uint8 j=0; j<4; j++)
		{
		  levelIncome[j]  =users[userAddress].levelIncome[j];
		}
		return (levelRefCountss,levelIncome);
	}
	
	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,bool) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].is_expired);
	}
	
	function getContractInfo() public view returns(uint256,uint256,uint256,uint256)
	{
	    return(totalInvested,totalWithdrawn,address(this).balance,totalUsers);
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