//SourceUnit: tron_buck.sol

pragma solidity 0.5.10;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TRONBUCK {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 1000 trx;
	uint256 constant public INVEST_MAX_AMOUNT = 100000 trx;
	uint256 constant public BASE_PERCENT = 10;
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
	address payable public sm1;
	address payable public sm2;
	address payable public sm3;
	address payable public sm4;

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
		uint256 bonus;
		uint256 ITT_BONUS;
		uint256 investedTotal;
		uint256 withdrawTotal;
	    uint total_team;
	    uint total_team_invest;
		uint256 withdrawRef;
		bool is_tm;
		mapping(uint256 => uint256) levelRefCount;
		mapping(uint256 => uint256) levelInvest;
		mapping(uint256 => uint256) poolIncome;
		mapping(uint256 => uint256) poolWithdrawal;
	}

	mapping (address => User) public users;
	
	uint public TL;
	mapping(uint => address) public TL_LIST;	
	mapping(address => bool) public TL_LIST_ACTIVE;
	
	uint public AMB;
	mapping(uint => address) public AMB_LIST;	
	mapping(address => bool) public AMB_LIST_ACTIVE;
	
	uint public MB;
	mapping(uint => address) public MB_LIST;	
	mapping(address => bool) public MB_LIST_ACTIVE;
	


	
	uint public pool_checkpoint;
	uint public today_investment;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event PoolWithdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

    
	constructor(address payable owner, address payable tsm1, address payable tsm2, address payable tsm3, address payable tsm4) public 
	{
		marketingAddress = owner;
		pool_checkpoint=now+24 hours;
		sm1=tsm1;
		sm2=tsm2;
		sm3=tsm3;
		sm4=tsm4;
	}
	
	function user_detail(address userAddress) public view returns(uint256,uint256,uint256)
	{
		return (users[userAddress].investedTotal,
		users[userAddress].withdrawTotal,
		users[userAddress].ITT_BONUS);
	}

	function invest(address payable referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT && msg.value<=INVEST_MAX_AMOUNT,"Invalid Amount");
        require((users[referrer].investedTotal>0) || referrer==marketingAddress,"Invalid Referrer Address");
    
		User storage user = users[msg.sender];

	if((users[msg.sender].investedTotal==0))
	{
			user.referrer = referrer;
	}
	else
	{
	    require(users[msg.sender].deposits[users[msg.sender].deposits.length-1].is_expired,"Investment Already Exist");
	    require(msg.value>=users[msg.sender].deposits[users[msg.sender].deposits.length-1].amount,"Invalid Amount");
	}
           
            
            address(uint160(marketingAddress)).send((msg.value*2)/100);
            
            address(uint160(sm1)).send((msg.value*1)/100);
            address(uint160(sm2)).send((msg.value*1)/100);
            address(uint160(sm3)).send((msg.value*1)/100);
            address(uint160(sm4)).send((msg.value*1)/100);
          
            
            address(uint160(user.referrer)).send((msg.value*10)/100);
            users[user.referrer].bonus=users[user.referrer].bonus.add((msg.value*10)/100);
            emit RefBonus(user.referrer, msg.sender, 1, (msg.value*10)/100);
            uint itt=msg.value/2;
            
            if(user.referrer==marketingAddress)
            {
                address(uint160(user.referrer)).send(itt);
                users[user.referrer].ITT_BONUS=users[user.referrer].ITT_BONUS.add(itt);
                emit RefBonus(user.referrer, msg.sender, 2, itt);   
            }
            else
            {
            uint _limit=users[user.referrer].investedTotal.mul(3);
            uint _total=users[user.referrer].withdrawTotal+users[user.referrer].ITT_BONUS;
            uint rest=0;
            if(_total<_limit)
            {
             uint _total2=_total+itt;
             if(_total2>_limit)
             {
               rest=_limit-_total;  
               users[user.referrer].deposits[users[user.referrer].deposits.length-1].is_expired=true;
             }
             else
             {
                 rest=itt;
             }
            }
            
		    if(rest>0)
		    {
		        address(uint160(user.referrer)).send(rest);
                users[user.referrer].ITT_BONUS=users[user.referrer].ITT_BONUS.add(rest);
                emit RefBonus(user.referrer, msg.sender, 2, rest);
		    }
            }

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 50; i++) {
				if (upline != address(0)) {
					users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;
					users[upline].levelInvest[i] = users[upline].levelInvest[i] +msg.value;
					users[upline].total_team = users[upline].total_team+1;
					users[upline].total_team_invest = users[upline].total_team_invest+msg.value;
					pool_entry(upline);
					if(users[upline].is_tm)
					{
					    address(uint160(upline)).send((msg.value*1)/100);
					}
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.withdrawRef = 0;
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,false));
        user.investedTotal=user.investedTotal.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		today_investment=today_investment.add(msg.value);
		totalDeposits = totalDeposits.add(1);
        pool_income();
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = BASE_PERCENT;

	
		uint256 dividends;
  
// 		for (uint256 i = 0; i < user.deposits.length; i++) {

// 			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {

// 				if (user.deposits[i].start > user.checkpoint) {

// 					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
// 						.mul(block.timestamp.sub(user.deposits[i].start))
// 						.div(TIME_STEP);

// 				} else {

// 					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
// 						.mul(block.timestamp.sub(user.checkpoint))
// 						.div(TIME_STEP);

// 				}

// 				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
// 					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
// 				}

// 				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
// 				totalAmount = totalAmount.add(dividends);

// 			}
// 		}
        (uint totalAmount,bool _expired)=getUserDividends(msg.sender);
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		
		if(_expired)
		{
		    user.deposits[user.deposits.length-1].is_expired=true;
		}

		if(totalAmount>0)
		{
		user.checkpoint = block.timestamp;
		msg.sender.transfer(totalAmount);
    	totalWithdrawn = totalWithdrawn.add(totalAmount);
        user.withdrawTotal=user.withdrawTotal.add(totalAmount);
    	emit Withdrawn(msg.sender, totalAmount);
		}
	}

    
    function pool_entry(address _user) private
    {
        User storage user = users[_user];
        
       if(!TL_LIST_ACTIVE[_user] && !AMB_LIST_ACTIVE[_user] && !MB_LIST_ACTIVE[_user])
       {
         if(user.levelRefCount[0]>=10 && user.total_team>=100 && user.investedTotal>=20000000000 && user.levelInvest[0]>=10000000000)
         {
             TL++;
             TL_LIST[TL]=_user;
             TL_LIST_ACTIVE[_user]=true;
         }
       }
       if(TL_LIST_ACTIVE[_user] && !AMB_LIST_ACTIVE[_user] && !MB_LIST_ACTIVE[_user])
       {
         if(user.levelRefCount[0]>=20 && user.total_team>=1000 && user.investedTotal>=30000000000 && user.levelInvest[0]>=15000000000)
         {
             if(TL_LIST_ACTIVE[_user])
             {
                 TL--;
                 TL_LIST_ACTIVE[_user]=false;
             }
             AMB++;
             AMB_LIST[AMB]=_user;
             AMB_LIST_ACTIVE[_user]=true;
         }  
       }
       if(AMB_LIST_ACTIVE[_user] && !MB_LIST_ACTIVE[_user])
       {
         if(user.levelRefCount[0]>=30 && user.total_team>=10000 && user.investedTotal>=50000000000 && user.levelInvest[0]>=25000000000)
         {
              if(TL_LIST_ACTIVE[_user])
             {
                 TL--;
                 TL_LIST_ACTIVE[_user]=false;
             }
              if(AMB_LIST_ACTIVE[_user])
             {
                 AMB--;
                 AMB_LIST_ACTIVE[_user]=false;
             }
             
             MB++;
             MB_LIST[MB]=_user;
             MB_LIST_ACTIVE[_user]=true;
         }  
       }
    }
    
    
     function makeTm(address _user) public
     {
        require(msg.sender==marketingAddress,"Only Owner");
        User storage user = users[_user];
        
        require(!user.is_tm,"User Already TM");
        user.is_tm=true;
    }
    
 
    
    
    function pool_income() private
    {
      if(now>pool_checkpoint)
      {
          if(TL>0)
          {
            uint256 income=((today_investment.mul(5)).div(100)).div(TL);
            
            uint i=1;
            while(i<=TL)
            {
                if(TL_LIST_ACTIVE[TL_LIST[i]]==true)
                {
                   User storage user = users[TL_LIST[i]];
                   user.poolIncome[0]=user.poolIncome[0].add(income);
                }
                i++;
            }
          }
          
           if(MB>0)
          {
            uint256 income=((today_investment.mul(2)).div(100)).div(MB);
            
            uint i=1;
            while(i<=MB)
            {
                if(MB_LIST_ACTIVE[MB_LIST[i]]==true)
                {
                   User storage user = users[MB_LIST[i]];
                   user.poolIncome[2]=user.poolIncome[2].add(income);
                }
                i++;
            }
          }
          
          if(AMB>0)
          {
            uint256 income=((today_investment.mul(3)).div(100)).div(AMB);
            
            uint i=1;
            while(i<=AMB)
            {
                if(AMB_LIST_ACTIVE[AMB_LIST[i]]==true)
                {
                   User storage user = users[AMB_LIST[i]];
                   user.poolIncome[1]=user.poolIncome[1].add(income);
                }
                i++;
            }
          }
          today_investment=0;
          pool_checkpoint=now+24 hours;
      }
    }
    
    
    function pool_withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = user.poolIncome[0]+user.poolIncome[1]+user.poolIncome[2];
        require(totalAmount>0,"No Pool Income");
        require(!(user.deposits[user.deposits.length-1].is_expired),"User Blocked");
		if(totalAmount>0)
		{
		msg.sender.transfer(totalAmount);
    	user.poolWithdrawal[0]=user.poolWithdrawal[0].add(user.poolIncome[0]);
    	user.poolWithdrawal[1]=user.poolWithdrawal[1].add(user.poolIncome[1]);
    	user.poolWithdrawal[2]=user.poolWithdrawal[2].add(user.poolIncome[2]);
    	user.poolIncome[0]=0;
    	user.poolIncome[1]=0;
    	user.poolIncome[2]=0;
    	emit PoolWithdrawn(msg.sender, totalAmount);
		}
	}
    


	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

   function poolIncome() public
   {
       require(msg.sender==marketingAddress,"Only Owner");
       pool_income();
   }



	function getUserDividends(address userAddress) public view returns (uint256,bool) {
		User storage user = users[userAddress];
		uint256 userPercentRate = BASE_PERCENT;
		uint256 totalDividends;
		uint256 dividends;
		bool _expired;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3) && user.deposits[i].is_expired==false) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(3)) {
					dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}
		
		    uint _limit=user.investedTotal.mul(3);
            uint _total=user.withdrawTotal+user.ITT_BONUS;
            uint rest=0;
            if(_total<_limit)
            {
             uint _total2=_total+totalDividends;
             if(_total2>_limit)
             {
               _expired=true;
               rest=_limit-_total;   
             }
             else
             {
                 rest=totalDividends;
             }
            }

		return (rest,_expired);
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	function getUserDownlineCount(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory levelRefCountss = new uint256[](50);
		for(uint8 j=0; j<50; j++)
		{
		  levelRefCountss[j]  =users[userAddress].levelRefCount[j];
		}
		return (levelRefCountss);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	
	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
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
	
	
	function getUserPoolIncome(address userAddress) public view returns(uint256, uint256, uint256) 
	{
	    User storage user = users[userAddress];
		return (user.poolIncome[0], user.poolIncome[1],user.poolIncome[2]);
	}
	
	function getUserPoolWithdrawal(address userAddress) public view returns(uint256, uint256, uint256) 
	{
	    User storage user = users[userAddress];
		return (user.poolWithdrawal[0], user.poolWithdrawal[1],user.poolWithdrawal[2]);
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


    function getHoldBonus(address userAddress) public view returns(uint256) {
    	if(getUserCheckpoint(userAddress) == 0){
        	return (block.timestamp.sub(users[userAddress].checkpoint)).mod(24);	
    	}else {
    		return 0;
    	}
    }
}