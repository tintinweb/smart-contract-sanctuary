//SourceUnit: Troni.sol

pragma solidity 0.5.17;

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




contract Troni {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 200 trx;
	uint256 constant public BASE_PERCENT = 20;
	uint256 constant public MAX_HOLD_PERCENT = 5;
	uint256[] public REFERRAL_PERCENTS = [100,30, 20];
	uint256 constant public MARKETING_FEE = 100;
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	
	uint256 constant public TIME_STEP = 24 hours;
	uint256 constant public LEADER_BONUS_STEP=5;
	uint256 constant public MAX_LEADER_PERCENT=5;

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
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address payable referrer;
		uint256 bonus;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 refEarning;
		uint256 match_bonus;
	    uint256 reinvested;
	    uint256 withdrawn;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable projectAddr) public {
       	require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
	}

	function invest(address payable referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT,"min amount is 200 Trx");
		uint256 _amount=msg.value;
       	marketingAddress.transfer(_amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(_amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, _amount.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					if(i == 0){
						users[upline].level1 = users[upline].level1.add(1);	
					} else if(i == 1){
						users[upline].level2 = users[upline].level2.add(1);	
					} else if(i == 2){
						users[upline].level3 = users[upline].level3.add(1);	
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

		user.deposits.push(Deposit(_amount, 0, block.timestamp));

		totalInvested = totalInvested.add(_amount);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, _amount);

	}
	
	
	function ReInvest(address userAddress,uint256 amount) private {
	//	require(amount >= INVEST_MIN_AMOUNT,"min amount is 200 Trx");
    
		User storage user = users[userAddress];

	
		user.deposits.push(Deposit(amount, 0, block.timestamp));

		totalInvested = totalInvested.add(amount);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(userAddress, amount);
        
        user.reinvested = user.reinvested.add(amount);
	}
	
	
	

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {

				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT.add(userPercentRate)).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						
				} else {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT.add(userPercentRate)).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(3)) {
					dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
		}
        
        
        
        distributeRefBonus(msg.sender,totalAmount);
        
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
			user.refEarning = user.refEarning.add(referralBonus);
		}
		if(user.match_bonus>0){
        totalAmount= totalAmount.add(user.match_bonus);
        user.match_bonus = 0;
		}
        
		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		require(contractBalance > totalAmount,"Contract Balance is lower");
		user.withdrawn = user.withdrawn.add(totalAmount);
		ReInvest(msg.sender,totalAmount.mul(40).div(100));
		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount.mul(60).div(100));

		totalWithdrawn = totalWithdrawn.add(totalAmount.mul(60).div(100));

		emit Withdrawn(msg.sender, totalAmount.mul(60).div(100));

	}
	
	function distributeRefBonus(address userAddress,uint256 amount) private
	{   
	    
	    for(uint256 i=0;i<10;i++)
	    {
	        address payable upline = users[userAddress].referrer;
	        if(upline!=address(0))
	        {
	           users[upline].match_bonus = users[upline].match_bonus.add(amount.mul(10).div(100));
	           userAddress = upline;
	        }
	    }
	}
	
	

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
			return timeMultiplier.add(getLeaderBonusRate(userAddress));
		} else {
			return getLeaderBonusRate(userAddress);
		}
	}
    
    function getLeaderBonusRate(address userAddress) public view returns (uint) {
        uint leaderBonusPercent = users[userAddress].level1.div(LEADER_BONUS_STEP);

        if (leaderBonusPercent < MAX_LEADER_PERCENT) {
            return leaderBonusPercent;
        } else {
            return MAX_LEADER_PERCENT;
        }
    }
    
    
    
    
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		 uint userPercentRate = BASE_PERCENT.add(getUserPercentRate(msg.sender));
		
	

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {

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

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
	User memory _user=users[userAddress];
		return (_user.level1, _user.level2, _user.level3
		);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return (users[userAddress].bonus);
	}
	
	function getUserMatchBonus(address userAddress) public view returns(uint256) {
		return (users[userAddress].match_bonus);
	}
	
	

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
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
	
	function getUserReinvested(address userAddress) public view returns(uint256) {
		return users[userAddress].reinvested;
	}
	
	function getUserRefEarnings(address userAddress) public view returns(uint256,uint256) {
		return (users[userAddress].refEarning,users[userAddress].withdrawn);
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