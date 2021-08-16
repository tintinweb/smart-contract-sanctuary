/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.4;

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IUniswapV2Router01 {
	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable;
}


contract BCFactory is Ownable {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.07 ether;
	uint256 constant public INVEST_MAX_AMOUNT = 70   ether;
	uint256 constant public BASE_PERCENT = 700;
	uint256[] public REFERRAL_PERCENTS = [700,500,300,100,50];
	uint256 constant public PROJECT_FEE = 600;
	uint256 constant public MARKETING_FEE = 400;
	uint256 constant public DEV_FEE = 200;
	uint256 constant public TOTAL_FEE = 1200;
	uint256 constant public ROI = 42700;
	uint256 constant public TOTAL_DAYS = 61;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CUT_RUN = 6000;
	uint256 constant public CUT_RUN_DAYS = 14;
	uint256 constant public ROUND = 8;
	uint256 constant public ROUND_LOCK = 7;
	uint256 constant public WITHDRAW_SEND = 7200;
	uint256 constant public WITHDRAW_RESERVED = 2300;
	// uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TIME_STEP = 60 * 60;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalDeposits;
	uint256 public totalReferral;
	uint256 public totalReward;

	address payable public devAddress;
	address payable public projectAddress;
	address payable public marketingAddress;
	uint256 public startDate;

	//Cake
	address constant public _pancakeRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
	IPancakeRouter02 public _pancakeRouter;
	address public _cakeAddress = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    IBEP20 _cakeToken;
	bool public swapEnabled = true;



	struct User {
		uint256 deposit;
		uint256 withdrawn;
		uint256 reserved;
		uint256 start;
		uint256 checkpoint;
		uint256 claimCheckpoint;
		address referrer;
		uint256[5] levels;
		uint256 refBonus;
		uint256 refTotal;
		uint256 rewTotal;
	}

	mapping (address => User) internal users;


	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RewBonus(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event SwapEnabledUpdated(bool enabled);
	event SwapETHForTokens(uint256 amountIn, address[] path);

	constructor(address payable devAddr, address payable projectAddr, address payable marketingAddr, uint256 start) {
		require(devAddr != address(0) && projectAddr != address(0) && marketingAddr != address(0));
		devAddress = devAddr;
		projectAddress = projectAddr;
		marketingAddress = marketingAddr;
		if(start>0){
			startDate = start;
		}
		else{
			startDate = block.timestamp;
		}

		_pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        _cakeToken = IBEP20(_cakeAddress);
	}

	function invest(address referrer) public payable {
		require(block.timestamp >= startDate," Not Launched yet ");
		require(msg.value >= INVEST_MIN_AMOUNT,"Min amount is 0.07 BNB");
		require(msg.value <= INVEST_MAX_AMOUNT,"Max amount is 70   BNB");

		devAddress.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(TOTAL_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		require(user.deposit == 0,"Only One Active Deposit is allowed");

		if (user.referrer == address(0) && users[referrer].deposit > 0 && referrer != msg.sender) {
			user.referrer = referrer;
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					if (amount > 0) {
						users[upline].refBonus = users[upline].refBonus.add(amount);
						users[upline].refTotal = users[upline].refTotal.add(amount);
						totalReferral += amount;
						emit RefBonus(upline, msg.sender, i, amount);
					}
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.checkpoint == 0) {
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.checkpoint = block.timestamp;
		user.claimCheckpoint = block.timestamp;
		user.start = block.timestamp;
		user.deposit= msg.value;

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		if(swapEnabled){
			uint256 bnbAmount = msg.value.mul(ROI).div(PERCENTS_DIVIDER).div(50);
			swapBNBForCake(bnbAmount);
		}


	}

	function withdraw() public {
		require(block.timestamp >= startDate," Not Launched yet ");
		User storage user = users[msg.sender];
		require(user.deposit > 0 , "No Deposit");

		//Only 24h after each 7 days
		require(withdrawStatus(user.checkpoint) , "Only 24h after each 7 days");

		uint256 amount = getUserDividends(msg.sender);

		if(user.refBonus>0){
			amount = amount.add(user.refBonus);
			user.refBonus=0;
		}

		if(user.reserved>0){
			amount = amount.add(user.reserved);
			user.reserved=0;
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < amount) {
			amount = contractBalance;
		}

		if(amount>0){
			uint256 sendAmount = amount.mul(WITHDRAW_SEND).div(PERCENTS_DIVIDER);
			user.reserved      = amount.mul(WITHDRAW_RESERVED).div(PERCENTS_DIVIDER);

			user.withdrawn  = user.withdrawn.add(amount);
			user.checkpoint = block.timestamp;

			payable(msg.sender).transfer(sendAmount);
			emit Withdrawn(msg.sender, amount);
		}
		
	}

	function claim() public {		require(block.timestamp >= startDate," Not Launched yet ");
		User storage user = users[msg.sender];
		require(user.deposit > 0 , "No Deposit");

		//Only 24h after each 7 days
		require(withdrawStatus(user.claimCheckpoint) , "Only 24h after each 7 days");

		uint256 bnbAmount=0;
		if (user.start > user.claimCheckpoint) {
			bnbAmount = user.deposit.mul(ROI).div(PERCENTS_DIVIDER).div(50)
				.mul(block.timestamp.sub(user.start))
				.div(TOTAL_DAYS.mul(TIME_STEP));
		} else {
			bnbAmount = user.deposit.mul(ROI).div(PERCENTS_DIVIDER).div(50)
				.mul(block.timestamp.sub(user.claimCheckpoint))
				.div(TOTAL_DAYS.mul(TIME_STEP));
		}
		

		if(bnbAmount>0){
			uint256 cakeAmount = _getCakeAmount(bnbAmount);


			uint256 cakeBalance = _cakeToken.balanceOf(address(this));
			if (cakeBalance < cakeAmount) {
				cakeAmount = cakeBalance;
			}

			if(cakeAmount>0){


				user.rewTotal  = user.rewTotal.add(cakeAmount);
				user.claimCheckpoint = block.timestamp;

				totalReward += cakeAmount;

				_cakeToken.transfer(msg.sender,cakeAmount);
				emit RewBonus(msg.sender, cakeAmount);
			}

		}
	}

	function cutAndRun() public {
		require(block.timestamp >= startDate," Not Launched yet ");
		User storage user = users[msg.sender];

		//Only 24h after each 7 days
		require(user.deposit > 0 , "No Deposit");
		require(withdrawStatus(user.checkpoint) , "Only 24h after each 7 days");
		require(user.start.add(TIME_STEP.mul(CUT_RUN_DAYS)) > block.timestamp , "Only is allowed in first two weeks");


		uint256 amount = user.deposit.mul(CUT_RUN).div(PERCENTS_DIVIDER);

		uint256 contractBalance = address(this).balance;
		if (contractBalance < amount) {
			amount = contractBalance;
		}

		user.withdrawn  = user.withdrawn.add(amount);
		user.checkpoint = block.timestamp;
		user.deposit = 0;
		user.reserved = 0;
		user.refBonus = 0;

		payable(msg.sender).transfer(amount);
		emit Withdrawn(msg.sender, amount);
	}

	function withdrawStatus(uint256 checkpoint) public view returns (bool){
		bool flag = false;
		if(block.timestamp > checkpoint){
			uint256 diff = block.timestamp.sub(checkpoint);
			diff = diff.mod(TIME_STEP.mul(ROUND));
			if(diff >= TIME_STEP.mul(ROUND_LOCK)){
				flag = true;
			}
		}
		return flag;
	}

	function getContractStats() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		return (
			totalUsers,
			totalInvested,
			totalDeposits,
			getContractBalance(),
			startDate,
			totalReferral,
			totalReward
		);
	}

	function getUserInvestmentStats(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		return (
			getUserTotalDeposits(userAddress),
			getUserTotalWithdrawn(userAddress),
			getUserAvailable(userAddress),
			getUserRefRewards(userAddress),
			getUserRewRewards(userAddress),
			getUserLastDepositDate(userAddress)
		);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		if (block.timestamp < startDate) return 0;

		User storage user = users[userAddress];
		uint256 dividends=0;

		if (user.withdrawn < user.deposit.mul(ROI).div(PERCENTS_DIVIDER)) {

			if (user.start > user.checkpoint) {
				dividends = (user.deposit.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.start))
					.div(TIME_STEP);
			} else {
				dividends = (user.deposit.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
					.mul(block.timestamp.sub(user.checkpoint))
					.div(TIME_STEP);
			}

			if (user.withdrawn.add(dividends) > user.deposit.mul(ROI).div(PERCENTS_DIVIDER)) {
				dividends = (user.deposit.mul(ROI).div(PERCENTS_DIVIDER)).sub(user.withdrawn);
			}

		}

		return dividends;
	}

	function getUserAvailableReward(address userAddress) public view returns (uint256) {
		if (block.timestamp < startDate) return 0;

		User storage user = users[userAddress];
		uint256 bnbAmount=0;

		if (user.start > user.claimCheckpoint) {
			bnbAmount = user.deposit.mul(ROI).div(PERCENTS_DIVIDER).div(50)
				.mul(block.timestamp.sub(user.start))
				.div(TOTAL_DAYS.mul(TIME_STEP));
		} else {
			bnbAmount = user.deposit.mul(ROI).div(PERCENTS_DIVIDER).div(50)
				.mul(block.timestamp.sub(user.claimCheckpoint))
				.div(TOTAL_DAYS.mul(TIME_STEP));
		}

		return bnbAmount;
	}

	function getUserReferralPercent(uint256 level) public view returns(uint256) {
		return REFERRAL_PERCENTS[level];
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserClaimCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].claimCheckpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserRefRewards(address userAddress) public view returns(uint256) {
		return users[userAddress].refTotal;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].refBonus;
	}

	function getUserRewRewards(address userAddress) public view returns(uint256) {
		return users[userAddress].rewTotal;
	}

	function getUserReserved(address userAddress) public view returns(uint256) {
		return users[userAddress].reserved;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(getUserReserved(userAddress));
	}

	function getUserLastDepositDate(address userAddress) public view returns(uint256) {
		return users[userAddress].start;
	}

	function getUserDepositInfo(address userAddress) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposit, user.withdrawn, user.start);
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		return user.deposit;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		return user.withdrawn;
	}

	function getUserWithdrawRef(address userAddress) public view returns(uint256) {
		return users[userAddress].refTotal.sub(users[userAddress].refBonus);
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3], users[userAddress].levels[4]);
	}

    function _getCakeAmount(uint256 amount) public view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = _pancakeRouter.WETH();
        path[1] = _cakeAddress;

        uint[] memory amounts = _pancakeRouter.getAmountsOut(amount, path);

        return amounts[1];
    }

    function swapBNBForCake(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = _cakeAddress;

      // Make the swap
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of Tokens
            path,
            address(this), 
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

	function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }
}