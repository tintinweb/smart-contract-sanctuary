// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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



pragma solidity ^0.6.0;

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



pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/*
 * 
 *   USDTex - investment platform based on Ethereun blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://usdtex.top                                         │
 *   │                                                                       │  
 *   |   E-mail: admin@usdtex.top                                     		 |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *
 */

pragma solidity 0.6.12;


contract USDTexV2 {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	// USDT contract  Decimals: 6
	IERC20 public  investToken;

	uint256 constant public INVEST_MIN_AMOUNT = 1e7; // 10 usdt
	uint256 constant public PERCENTS_DIVIDER =  1e13 ;//1000;
	uint256 constant public BASE_PERCENT = 1e11;
	uint256 constant public MAX_PERCENT = 18*(1e12);
	uint256 constant public MARKETING_FEE = 75*(1e10);
	uint256 constant public PROJECT_FEE = 25*(1e10);

	// uint256 constant public REFERRAL_PERCENTS = 1e11;
	uint256[] public REFERRAL_PERCENTS = [ 5*1e11, 2*1e11];
	
	uint256 constant public TIME_STEP = 1 days ; //days
	uint256 constant public BASE_AMOUNT_DALIY = 1e12; // 100w USDT
	uint256 constant public START_POINT = 1603209600; // contract start timestample
	uint256 constant public PERCENT_INVEST = 10; // increase percent pre Invest
	uint256 constant public PERCENT_WITHDRAW = 15; // decreased percent pre Withdraw

	uint256 public presentPercent = 1e11;

	uint256 public presentDayAmount = BASE_AMOUNT_DALIY;
	uint256 public presentDaysInterval = 0;

	uint256 public totalLottery; //sum of latest 100 ticker
	uint256 public totalLotteryReward; //sum of 5% of invest

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	bool public announceWinner; //  announce Winners

	address public marketingAddress;
	address public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 totalInvested;
		// invite reward
		uint256 totalBonus;
		uint256 missedBonus;
		//lottery reward
		uint256 lotteryBonus;
	}
	struct LotteryTicket {
		address user;
		uint256 amount;
	}

	// modifier uniqueHash() {
    //     require(_owner == msg.hash, "Ownable: caller is not the owner");
    //     _;
    // } 

	mapping (address => User) internal users;
	mapping (uint256 => uint256) internal daliyInvestAmount;
	mapping(address => uint256[]) public userLotteryTicker;
	LotteryTicket[] public  lotteryPool;


	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event WithdrawWinning(address indexed user, uint256 amount);

	constructor(address _investToken, address marketingAddr, address projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		investToken = IERC20(_investToken);
	}

	function updateTodayAmount(uint daysInterval) private {

		if(daysInterval > presentDaysInterval) {
			uint power = daysInterval - presentDaysInterval;

			// presentDayAmount = presentDayAmount.mul(11**power).div(10**power);
			for (uint256 index = 0; index < power; index++) {
				presentDayAmount = presentDayAmount.mul(11).div(10);
			}

			presentDaysInterval = daysInterval;
		}
	}

	function invest(address referrer , uint256 _amount) public {
		require(_amount >= INVEST_MIN_AMOUNT, "Less than minimum");
		require(!isContract(msg.sender), "cannot call from contract");
		require(!announceWinner, "Game Over"); // game over!
		
		uint daysInterval = getDaysInterval(); // count days passed
		updateTodayAmount(daysInterval);
	
		uint todayAmount = presentDayAmount.sub(daliyInvestAmount[daysInterval]);
		require(todayAmount>0, "Sold out today");
		uint amount = _amount > todayAmount  ? _amount.sub(todayAmount) : _amount;

		investToken.safeTransferFrom(address(msg.sender), address(this), amount);
		investToken.safeTransfer( address(marketingAddress), amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		investToken.safeTransfer( address(projectAddress), amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		
		// emit FeePayed(msg.sender, amount.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 2; i++) {
				if (upline != address(0)) {
					uint256 bonuAmount = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					if (users[upline].totalBonus.add(bonuAmount) <= users[upline].totalInvested) {
						users[upline].bonus = users[upline].bonus.add(bonuAmount);
						users[upline].totalBonus = users[upline].totalBonus.add(bonuAmount);
						emit RefBonus(upline, msg.sender, i, bonuAmount);
					} else {
						users[upline].missedBonus = users[upline].missedBonus.add(bonuAmount);	
					}
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			// emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(amount, 0, block.timestamp));
		user.totalInvested = user.totalInvested.add(amount);

		updateRate(amount, true);
		addLotteryTicket(msg.sender, amount);

		daliyInvestAmount[daysInterval] = daliyInvestAmount[daysInterval].add(amount);

		totalInvested = totalInvested.add(amount);
		totalDeposits = totalDeposits.add(1);
		
		emit NewDeposit(msg.sender, amount);
	}

	function addLotteryTicket(address _user, uint256 _amount) private {
		uint256 index = totalDeposits  % 100;//100  totalDeposits from 0
		LotteryTicket[] storage  lotPool = lotteryPool;

		if (lotPool.length == 100) { //reuse 100
			totalLottery = totalLottery.add(_amount).sub(lotPool[index].amount);
			lotPool[index].amount = _amount;
			lotPool[index].user   = _user;

		} else {
			lotPool.push(LotteryTicket({
				user : _user,
				amount : _amount
			}));
			totalLottery = totalLottery.add(_amount);
		}
		userLotteryTicker[_user].push(index);

		totalLotteryReward = totalLotteryReward.add( _amount.div(20) );
	}

	function withdrawWinning() public {	
		require(announceWinner, "Not allowed");
		
		uint256 winning = winningAmount(msg.sender);
		require(winning > 0, "No winnings");

		User storage user = users[msg.sender];
		user.lotteryBonus = user.lotteryBonus.add(winning);

		investToken.safeTransfer( msg.sender, winning);

		emit WithdrawWinning(msg.sender, winning);
	}

	function winningAmount(address _user) public view returns (uint256) {
		uint256[] memory useTickers = userLotteryTicker[_user];

		if (useTickers.length == 0 ) {
			return 0;
		}

		uint userAmount;
		LotteryTicket[] memory lotPool = lotteryPool;
		for (uint256 i = useTickers.length - 1 ; i < useTickers.length; i--) {

			if(lotPool[useTickers[i]].user == _user) {
				userAmount = userAmount.add(lotPool[useTickers[i]].amount);
			}else break;
		}

		return userAmount.mul(totalLotteryReward).div(totalLottery).sub(users[msg.sender].lotteryBonus);

	}

	function withdraw() public {
		require(!announceWinner, "Game Over"); // game over!
		User storage user = users[msg.sender];

		uint256 userPercentRate = presentPercent;

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(18).div(10)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(18).div(10)) {
					dividends = (user.deposits[i].amount.mul(18).div(10)).sub(user.deposits[i].withdrawn);
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
		// balance = ERC20.balanceOf().sub(totalLotteryReward);
		uint256 contractBalance = investToken.balanceOf(address(this)).sub(totalLotteryReward);
		if (contractBalance <= totalAmount) {
			totalAmount = contractBalance;
			// Announce Winner, Game Over
			announceWinner = true;
		}

		user.checkpoint = block.timestamp;

		investToken.safeTransfer( msg.sender, totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		updateRate(totalAmount, false);
		emit Withdrawn(msg.sender, totalAmount);

	}

	function getDailyAmount() public view returns (uint256) {
		
		uint256 timePower = getDaysInterval().sub(presentDaysInterval);
		uint presentAmount = presentDayAmount;
		for (uint256 index = 0; index < timePower; index++) { // 10% increase daily
				presentAmount = presentAmount.mul(11).div(10);
		}
		return presentAmount; 
	}

	function getDaysInterval() public view returns (uint256) {
		return  now.sub(START_POINT).div(TIME_STEP);
	}
	function getContractBalance() public view returns (uint256) {
		return investToken.balanceOf(address(this));
	}
	function updateRate(uint256 _amount, bool _invest) private {
		if (_invest) {
			presentPercent = presentPercent.add( _amount.mul(PERCENT_INVEST) );
			if ( presentPercent > MAX_PERCENT ) {
				presentPercent = MAX_PERCENT;
			}
		} else {
			uint decrease = _amount.mul(PERCENT_WITHDRAW);
			if ( presentPercent < BASE_PERCENT.add(decrease) ) {
				presentPercent = BASE_PERCENT;
			} else {
				presentPercent = presentPercent.sub(decrease);
			}
		}
		
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = presentPercent;

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(18).div(10)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(18).div(10)) {
					dividends = (user.deposits[i].amount.mul(18).div(10)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getStartPoint() public pure returns(uint256) {
		return START_POINT;
	} 
	function getUserPercent() public view returns(uint256) {
		return presentPercent.div(1e9);
	}
	function getBasePercent() public pure returns(uint256) {
		return BASE_PERCENT.div(1e9);
	}
	function getContractPercent() public view returns(uint256) {
		return presentPercent.sub(BASE_PERCENT).div(1e9);
	}

	function getTodayAmount() public view returns(uint256) {
		return getDailyAmount().sub(daliyInvestAmount[getDaysInterval()]);
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserMissedBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].missedBonus;
	}

	function getUserTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
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

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
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