//SourceUnit: TronAct.sol


pragma solidity 0.6.0;

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




contract TronAct {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
	uint256 constant public BASE_PERCENT = 20;
	uint256 constant public MAX_HOLD_PERCENT = 5;
	uint256[] public REFERRAL_PERCENTS = [70,30, 15,10,5,5,5,5,5,5];
	uint256 constant public MARKETING_FEE = 120;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public MAX_ROI = 210;
	
	uint256 constant public TIME_STEP = 24 hours;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;

	struct User {
		uint256 checkpoint;
		address payable referrer;
		uint256 bonus;
		uint256 match_bonus;
		mapping(uint256=>uint256) referrals;
		uint256 refEarning;
	    uint256 withdrawn;
	    uint256 invested;
	    uint256 dividends;
	}

	mapping (address => User) public users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable marketingAddr) public {
       	require(!isContract(marketingAddr));
		marketingAddress = marketingAddr;
	}
	
	function settleDividend(address userAddress) internal
	{ 
	    users[userAddress].dividends = users[userAddress].dividends.add(getUserDividends(userAddress)); 
	}

	function invest(address payable referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT,"Invalid amount");
		uint256 _amount=msg.value;
       bool isNew = false;
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].invested > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
			isNew = true;
		}
        
        settleDividend(msg.sender);
        
        distributeRefBonus(msg.sender,_amount,isNew);
       
        if(user.invested==0){
		totalUsers = totalUsers.add(1);
		emit Newbie(msg.sender);
        }
		user.invested = user.invested.add(msg.value);
		
		user.checkpoint = block.timestamp;
		
        //settleDividend();
		totalInvested = totalInvested.add(_amount);
		totalDeposits = totalDeposits.add(1);
        
		emit NewDeposit(msg.sender, _amount);
		
	    marketingAddress.transfer(_amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));

	}
	

	function distributeRefBonus(address userAddress,uint256 amount,bool isNew) private
	{   
	    
	    for(uint256 i=0;i<10;i++)
	    {
	        address payable upline = users[userAddress].referrer;
	        if(upline!=address(0))
	        {
	           users[upline].bonus = users[upline].bonus.add(amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER));
	           if(isNew)
	           {
	               users[upline].referrals[i]++;
	           }
	           userAddress = upline;
	        }
	    }
	}
	
	

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount;
	
	    totalAmount =  getUserDividends(msg.sender);
	    users[msg.sender].dividends = 0;
        distributeRefBonusROI(msg.sender,totalAmount);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
			user.refEarning = user.refEarning.add(referralBonus);
		}
		
		if (users[msg.sender].match_bonus > 0) {
			totalAmount = totalAmount.add(users[msg.sender].match_bonus);
			user.match_bonus = 0;
		}
		
		if(totalAmount>users[msg.sender].invested.mul(MAX_ROI).div(100))
		{
		    totalAmount = users[msg.sender].invested.mul(MAX_ROI).div(100);
		}
		
	    
	    
        
		require(totalAmount > 200 trx, "Need minimum 200 trx.");

		uint256 contractBalance = address(this).balance;
		require(contractBalance > totalAmount,"Contract Balance is lower");
	
		user.withdrawn = user.withdrawn.add(totalAmount);
		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);
        
		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}
	

    
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

	    uint userPercentRate = BASE_PERCENT.add(getUserPercentRate(msg.sender));
		uint256 dividends;

		dividends = (user.invested.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
						dividends = dividends.add(user.dividends);
			
				if (user.withdrawn.add(dividends) > user.invested.mul(MAX_ROI).div(100)) {
					dividends = (user.invested.mul(MAX_ROI).div(100)).sub(user.withdrawn);
				}
			
		return dividends;
	}
	
	function distributeRefBonusROI(address userAddress,uint256 amount) private
	{   
	    address payable upline = users[userAddress].referrer;
	    for(uint256 i=0;i<10;i++)
	    {
	        if(upline!=address(0))
	        {
	            if(users[upline].referrals[0]>=(i+1)){
	           users[upline].match_bonus = users[upline].match_bonus.add(amount.div(10));
	            }
	           userAddress = upline;
	        }
	    }
	}
	

	
	

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
			return timeMultiplier;
		
	}
    
   
    
    
	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	function getUserDownlineCount(address userAddress) public view returns(uint256) {
	User storage _user=users[userAddress];
		return (_user.referrals[0]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return (users[userAddress].bonus);
	}
	

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}


	
	function getUserRefEarnings(address userAddress) public view returns(uint256,uint256) {
		return (users[userAddress].refEarning,users[userAddress].withdrawn);
	}

    function getReferralIncome(address userAddress) public view returns(uint256[] memory referrals){
        uint256[] memory _referrals = new uint256[](REFERRAL_PERCENTS.length);
         for(uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
             _referrals[i]=users[userAddress].referrals[i];
         }
        return (_referrals);
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