//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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


//SourceUnit: TronEffect.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
import './TronEffect2_State.sol';

contract TronEffect2 is TronEffect2_State{

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event Reinvestment(address indexed user, uint amount);

	constructor(address payable marketingAddr,
	    address payable projectAddr, 
	    address payable devAddr, 
	    address payable insuredAddr,
	    address lotteryAdrr) public payable {
		require(!isContract(insuredAddr) &&
		    !isContract(marketingAddr) && 
		    !isContract(projectAddr) && 
		    !isContract(devAddr)&& 
		    isContract(lotteryAdrr));
		insuredAddress = insuredAddr;
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		devAddress = devAddr;
		insuredState = true;
	    lottery = LotteryEffect2(lotteryAdrr);
	}

	modifier checkUser_ () {
	    uint check = block.timestamp.sub(users[msg.sender].lastActivity);
	    require(check > TIME_STEP,'checkUser_');
	    _;
	}
	modifier insuredState_ () {
	    uint check = block.timestamp.sub(users[msg.sender].lastActivity);
	    require(insuredState,'insuredState');
	    _;
	}	
	
	function checkUser() external view returns (bool){
	    uint check = block.timestamp.sub(users[msg.sender].lastActivity);
	    if(check > TIME_STEP)
	    return true;
	}
	
	function invest(address referrer) external payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		devAddress.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE).add(DEV_FEE)).div(PERCENTS_DIVIDER));
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].referrerCount[i]=users[upline].referrerCount[i].add(1);
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

        Deposit memory newDeposit;        
        newDeposit.amount = msg.value;
        newDeposit.initAmount = msg.value;
		newDeposit.start = block.timestamp; 
		user.deposits.push(newDeposit);
		
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		giftLotteryTicket(msg.sender);
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() external  checkUser_  returns(bool) {
		require(isActive(msg.sender), "Dont is User");
		User storage user = users[msg.sender];
		uint256 userPercentRate = getUserPercentRate(msg.sender);		
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].initAmount.mul(MAX_PROFIT)) {

				if (user.deposits[i].start > user.checkpoint) {
				    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].initAmount.mul(MAX_PROFIT)) {
					dividends = (user.deposits[i].initAmount.mul(MAX_PROFIT)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
		}

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
		user.lastActivity = block.timestamp;

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);
        
		emit Withdrawn(msg.sender, totalAmount);
		return true;

	}
	
	function reinvestment() external checkUser_ payable returns (bool) {
	    require(isActive(msg.sender), "Dont is User");
	    User storage user = users[msg.sender];
	    uint256 totalDividends;
		uint dividends;
		
		uint userPercentRate = getUserPercentRate(msg.sender);
	    for (uint i = 0; i < user.deposits.length; i++) {
            
			if (user.deposits[i].withdrawn < user.deposits[i].initAmount.mul(MAX_PROFIT)) {
			    
				if (user.deposits[i].start > user.checkpoint) {
				    
					dividends = user.deposits[i].amount
					    .mul( userPercentRate )
					    .div( PERCENTS_DIVIDER )
						.mul( block.timestamp.sub( user.deposits[i].start ) )
						.div( TIME_STEP );
				}
				else {		
				    dividends = user.deposits[i].amount
				        .mul( userPercentRate )
				        .div( PERCENTS_DIVIDER )
						.mul( block.timestamp.sub(user.checkpoint) )
						.div( TIME_STEP );
				}
				

				if ( user.deposits[i].withdrawn.add(dividends) > user.deposits[i].initAmount.mul(MAX_PROFIT)) {
					dividends = user.deposits[i].initAmount
					    .mul(MAX_PROFIT) 
					    .sub(user.deposits[i].withdrawn);
				}
				
		        user.deposits[i].amount = user.deposits[i].amount.add(dividends);
		        totalDividends = totalDividends.add(dividends);
			}
		}
		
		marketingAddress.transfer(totalDividends.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(totalDividends.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		devAddress.transfer(totalDividends.mul(DEV_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, totalDividends.mul(MARKETING_FEE.add(PROJECT_FEE).add(DEV_FEE)).div(PERCENTS_DIVIDER));
		user.reinvested = user.reinvested.add(totalDividends);
		totalReinvested = totalReinvested.add(totalDividends);
		user.lastActivity = block.timestamp;
		giftLotteryTicket(msg.sender);
		emit Reinvestment(msg.sender, totalDividends);
		return true;
	}
	
	function giftLotteryTicket(address payable address_) internal {
	    uint256 priceTicket = lottery.getPriceTicket();
	    if(getContractBalance() > priceTicket )
		lottery.buyTicketToAddress.value(priceTicket)(address_);
	}
	
	function setInsuredState(bool state_) external returns(bool) {
	    require(msg.sender == insuredAddress, "error" );
	    insuredState = state_;
	    return insuredState;
	}	
	
	function secureDeposit() external insuredState_  payable returns (bool) {
	    require(isActive(msg.sender), "Dont is User");
	    User storage user = users[msg.sender];
	    Deposit storage lastDeposit = user.deposits[user.deposits.length - 1];
	    require(!lastDeposit.saved,'deposits saved');
	    require(lastDeposit.initAmount.mul(2000).div(PERCENTS_DIVIDER) == msg.value);
	    
	    if(user.safeId == 0){
	        idSafe = idSafe.add(1);
	        user.safeId = idSafe;
	        insuredUsers[user.safeId]=msg.sender;
	    }
	    
	    SafeDeposit memory save;
	    save.index=user.deposits.length - 1;
	    save.date = block.timestamp;
	    safeInvestment[msg.sender].safeDeposits.push(save);
	    lastDeposit.saved = true;
	    insuredAddress.transfer(msg.value);
	    return  true;	    
	}
	
	function getSecureDeposits(address userAddress) public view returns (uint[40] memory){
	    User storage user = users[userAddress];
	    require(user.deposits.length > 0, "Dont is User");
	    SafeDeposit[] memory safeDeposit_ = safeInvestment[userAddress].safeDeposits;
	    uint[40] memory response;
	    if(safeDeposit_.length>0){
	        
	        for(uint i=0; i < safeDeposit_.length; i++){
	            response[i] = safeDeposit_[i].index.add(1);
	        }
	        return response;
	    }
	}
	
	function calculateInsuredPayment(address userAddress) external view returns(uint){
	    User memory user = users[userAddress];
	    Deposit  memory lastDeposit = user.deposits[user.deposits.length - 1];
	    uint pay = lastDeposit.initAmount.mul(2000).div(PERCENTS_DIVIDER);
	    return pay;
	}
		
	function calculateSecureDeposits(address userAddress) external view returns(uint){
	    User memory user = users[userAddress];
	    require(user.deposits.length > 0, "Dont is User");
	    uint[40] memory secureDeposits_ = getSecureDeposits(userAddress);
	    uint dividends;
	    
	    for (uint i=0; i < secureDeposits_.length; i++){
	        if(secureDeposits_[i]==0)
	            break;
	        uint index  = secureDeposits_[i] - 1;
	        (uint initAmount_,,uint withdrawn_,,,)  = getUserDepositInfo(userAddress,index);
	        if(withdrawn_ >= initAmount_)
	        continue;
	        
            dividends = dividends.add(initAmount_.sub(withdrawn_));
	    }
	    return dividends;
	}	 
	
	function getNextUserAssignment(address userAddress) external view returns (uint) {
            uint check = users[userAddress].lastActivity.add(TIME_STEP);
            return check;
    }
    
	function getUserholdRate(address userAddress) public view returns (uint) {
    	User memory user = users[userAddress];
		if (isActive(userAddress)) {
				uint holdProfit =block.timestamp.sub(user.checkpoint).div(TIME_STEP).mul(HOLD_PERCENT);
				if( holdProfit > MAX_HOLD_PERCENT)
				   holdProfit = MAX_HOLD_PERCENT;
				return holdProfit;
		}
    }
    
    function getUserPercentRate(address userAddress) public view returns (uint) {
		uint holdProfit = getUserholdRate(userAddress);
		uint contractBalance = getContractBalance();
		
		if( contractBalance >= CONTRACT_BALANCE_STEP ){
		uint contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP).mul(5);
		return BASE_PERCENT.add(contractBalancePercent).add(holdProfit);
		}
		else
		return BASE_PERCENT.add(holdProfit);
	}
	
	function getContractBalanceRate() public view returns (uint) {
		uint contractBalance = getContractBalance();
		
		if( contractBalance >= CONTRACT_BALANCE_STEP ){
		uint contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP).mul(5);
		return BASE_PERCENT.add(contractBalancePercent);
		}
		else
		return BASE_PERCENT;		
	}	
	
	function getPublicData() external view returns(uint  totalUsers_,
	    uint  totalInvested_,
	    uint  totalReinvested_,
	    uint  totalWithdrawn_,
	    uint totalDeposits_,
	    uint balance_,
	    uint balanceRate_)
	{
	    totalUsers_ =totalUsers;
        totalInvested_ = totalInvested;
	    totalReinvested_ =totalReinvested;
	    totalWithdrawn_ = totalWithdrawn;
	    totalDeposits_ =totalDeposits;
	    balance_ = getContractBalance();
	    balanceRate_ = getContractBalanceRate();
	}
	
	function getUserData(address userAddress) external view returns(uint totalWithdrawn_, 
	    uint totalDeposits_,
	    uint totalBonus_,
	    uint totalreinvest_,
	    uint hold_,
	    uint balance_,
	    uint nextAssignment_,
	    uint insured_,
	    bool isUser_,
	    address referrer_,
	    uint[4] memory referrerCount_
	){
	    User memory user = users[userAddress];
	    totalreinvest_ = user.reinvested;
	    totalWithdrawn_ =getUserTotalWithdrawn(userAddress);
	    totalDeposits_ =getUserTotalDeposits(userAddress);
	    totalBonus_ = getUserReferralBonus(userAddress);
	    balance_ = getUserDividends(userAddress);
	    hold_ = getUserholdRate(userAddress);
	    isUser_ =  user.deposits.length>0;
	    referrer_ = users[userAddress].referrer;
	    referrerCount_ =users[userAddress].referrerCount;
	    nextAssignment_ = this.getNextUserAssignment(userAddress);
	    insured_ = this.calculateSecureDeposits(userAddress);
	}
	
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].initAmount.mul(MAX_PROFIT)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].initAmount.mul(MAX_PROFIT)) {
					dividends = user.deposits[i].initAmount
					    .mul(MAX_PROFIT)
					    .sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);
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

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User memory user = users[userAddress];
		
		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].initAmount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(
	    uint256 initAmount_,
	    uint256 amount_,
	    uint256 withdrawn_, 
	    uint256 timeStart_,
	    uint256 reinvested_,
	    bool saved_) {
	    User memory user = users[userAddress];
        initAmount_ =user.deposits[index].initAmount;
		amount_ = user.deposits[index].amount;
		withdrawn_ = user.deposits[index].withdrawn;
		timeStart_= user.deposits[index].start;
		reinvested_ = user.reinvested;
		saved_ = user.deposits[index].saved;
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

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

//SourceUnit: TronEffect2_State.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
import "SafeMath.sol";

interface LotteryEffect2{
    function buyTicketToAddress(address payable _address) external payable returns(uint256);
    function getPriceTicket() external view returns(uint256);
}

contract TronEffect2_State{
    using SafeMath for uint256;
    LotteryEffect2 lottery;

	uint256 constant internal INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant internal BASE_PERCENT = 300;
	uint256[4] internal REFERRAL_PERCENTS = [400, 300, 200, 100];
	uint256 constant internal MARKETING_FEE = 400;
	uint256 constant internal DEV_FEE = 400;
	uint256 constant internal PROJECT_FEE = 300;
	uint256 constant internal PERCENTS_DIVIDER = 10000;
		
	uint256 constant internal CONTRACT_BALANCE_STEP = 2000000 trx;
	uint256 constant internal MAX_HOLD_PERCENT = 200;
    uint256 constant internal HOLD_PERCENT = 5;
    uint256 constant internal MAX_PROFIT = 2;
    uint256 constant internal TIME_STEP = 1 days;
    
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint public totalReinvested;
	uint public idSafe;
	bool public insuredState;

	address payable public marketingAddress;
	address payable public projectAddress;
	address payable public devAddress;
	address payable public insuredAddress;
        
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 initAmount;
		uint256 start;
		bool saved;
	}

	struct User {
		Deposit[] deposits;
		uint256 lastActivity;
		uint256 reinvested;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256[4] referrerCount;
		uint256 safeId;
	}
	
	struct SafeDeposit {
	    uint256 index;
	    uint256 date;
	}
	struct SafeInvestment{
	    SafeDeposit[] safeDeposits;
	}

	mapping (address => User) public users;
	mapping(address =>SafeInvestment) safeInvestment;
	mapping(uint256 => address)  public insuredUsers;
    
}