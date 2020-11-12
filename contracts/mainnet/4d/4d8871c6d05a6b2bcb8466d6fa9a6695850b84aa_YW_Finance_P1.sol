// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).cls

 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal virtual view returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal virtual view returns (bytes memory) {
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
contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns (address) {
		return _owner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

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
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

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
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;


			bytes32 accountHash
		 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
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
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
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
	function functionCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	 * `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
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
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				"Address: low-level call with value failed"
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(
		address target,
		bytes memory data,
		uint256 weiValue,
		string memory errorMessage
	) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{
			value: weiValue
		}(data);
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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

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

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transfer.selector, to, value)
		);
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
		);
	}

	/**
	 * @dev Deprecated. This function has issues similar to the ones found in
	 * {IERC20-approve}, and its usage is discouraged.
	 *
	 * Whenever possible, use {safeIncreaseAllowance} and
	 * {safeDecreaseAllowance} instead.
	 */
	function safeApprove(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		// solhint-disable-next-line max-line-length
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeERC20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.approve.selector, spender, value)
		);
	}

	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender).add(
			value
		);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(
				token.approve.selector,
				spender,
				newAllowance
			)
		);
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender).sub(
			value,
			"SafeERC20: decreased allowance below zero"
		);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(
				token.approve.selector,
				spender,
				newAllowance
			)
		);
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

		bytes memory returndata = address(token).functionCall(
			data,
			"SafeERC20: low-level call failed"
		);
		if (returndata.length > 0) {
			// Return data is optional
			// solhint-disable-next-line max-line-length
			require(
				abi.decode(returndata, (bool)),
				"SafeERC20: ERC20 operation did not succeed"
			);
		}
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
contract YW_Finance_P1 is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	/**
	 * Stake section information struct
	 */
	struct Stake {
		address stakeholder;
		uint256 createdAt;
		uint256 stakeAmount;
		uint256 lastClaimAt;
		uint256 canUnlockAt;
	}

	struct StakePeriod {
		uint256 timestamp;
		uint256 stakeTotalAmount;
	}

	// Pool support tokens
	address public _stakeTokenAddress;
	// IERC20 interfaces of support tokens
	IERC20 internal _stakeToken;
	// Pool stakeholders
	address[] public _stakeholders;
	mapping(address => Stake) internal _userStakes;

	// Pool reward contract and IERC20 interface
	address public _rewardTokenAddress;
	IERC20 internal _rewardToken;
	// The accumulated rewards for each stakeholder.
	mapping(address => uint256) internal _rewards;
	mapping(address => uint256) internal _paidRewards;

	// 0% per transaction. Set later
	uint256 public _rewardClaimFee = 0;
	uint256 public _transactionFeeInWei = 20000000000000000; // 0.02 ETH
	uint256 public _stakeDepositFee = 1;

	// Pool rewards
	uint256 internal _poolTotalStake = 0;
	StakePeriod[] public _stakePeriods;
	uint256 internal _poolTotalReward = 0;
	uint256 internal _poolClaimedReward = 0;
	// Last time the pool distribute rewards to all stakeholders
	uint256 public _poolStartedAt = 0; // In date time
	uint256 public _poolRewardDistributionStartedAt = 0;
	uint256 public _poolRunDuration = 0; // In seconds
	uint256 public _poolEndedAt = 0; // In seconds
	uint256 public _poolRewardPerSecondRate = 0; // In seconds
	uint256 public _poolDepositFeeAmount = 0;

	// Pool owner
	address public pool;
	uint256 public poolDeployedAt = 0;

	// Pool developers
	mapping(address => bool) internal _developers;
	mapping(address => bool) internal _systemPools;

	constructor(
		address rewardTokenAddress,
		address stakeTokenAddress,
		uint256 poolStartedAt,
		uint256 poolRunDurationInHours,
		uint256 initRewardAmount
	) {
		_rewardTokenAddress = rewardTokenAddress;
		_rewardToken = IERC20(rewardTokenAddress);

		_stakeTokenAddress = stakeTokenAddress;
		_stakeToken = IERC20(stakeTokenAddress);

		// Current block
		poolDeployedAt = block.timestamp;
		// Current contract owner & pool
		pool = address(this);
		_poolStartedAt = poolStartedAt;
		_poolRunDuration = 60 * 60 * poolRunDurationInHours;
		_poolEndedAt = _poolStartedAt.add(_poolRunDuration);
		_poolTotalReward = _poolTotalReward.add(initRewardAmount);
		_poolRewardPerSecondRate = _poolTotalReward.div(_poolRunDuration);
	}

	event TransferSuccessful(
		address indexed _from,
		address indexed _to,
		uint256 _amount
	);

	event StakeSuccessful(
		address indexed _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	);

	event RewardClaimSuccessful(
		address indexed _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	);

	/**
	 * @notice Trigger to update stakeholder reward
	 * @param stakeholder Address of stakeholder to update reward
	 */
	modifier updateReward(address stakeholder) {
		uint256 amount = 0;
		(uint256 currentReward, , , ) = rewardOf(stakeholder);
		_rewards[stakeholder] = currentReward;
		_;
	}

	/**
	 * @notice Trigger to ensure transaction fee is paid
	 * @param amount Amount of current value of user transaction
	 */
	modifier validTransactionFee(uint256 amount) {
		require(amount >= _transactionFeeInWei, "Missing transaction fee.");
		_;
	}

	/**
	 * @notice Trigger to ensure pool start before user can stake
	 */
	modifier ensurePoolStart() {
		require(block.timestamp > _poolStartedAt, "Pool is not open yet.");
		_;
	}

	/**
	 * @notice Trigger to ensure pool available
	 */
	modifier poolAvailable() {
		require(block.timestamp < _poolEndedAt, "Pool is ended.");
		_;
	}

	/**
	 * @notice A method to set reward claim fee
	 * @param _fee Reward claim fee need to set
	 */
	function setRewardClaimFee(uint256 _fee) public onlyOwner {
		require(_fee > 0, "Reward claim fee must be none zero value.");
		_rewardClaimFee = _fee;
	}

	/**
	 * @notice A method to set transaction fee
	 * @param _fee The transaction fee to set
	 */
	function setTransactionFeeInWei(uint256 _fee) public onlyOwner {
		require(_fee > 0, "Reward claim fee must be none zero value.");
		_transactionFeeInWei = _fee;
	}

	/**
	 * @notice A method to add developer address to pool
	 * @param _address Developer wallet address
	 * @return bool True/False as the result
	 */
	function addPoolDeveloper(address _address)
		public
		onlyOwner
		returns (bool)
	{
		_developers[_address] = true;
		return true;
	}

	/**
	 * @notice A method remove developer wallet from pool
	 * @param _address Developer wallet address
	 * @return bool True/False as the result
	 */
	function removePoolDeveloper(address _address)
		public
		onlyOwner
		returns (bool)
	{
		_developers[_address] = false;
		return true;
	}

	/**
	 * @notice A method to add system related pools
	 * @param _pool Pool wallet address to add
	 * @return bool True/False as the result
	 */
	function addSystemPool(address _pool) public onlyOwner returns (bool) {
		_systemPools[_pool] = true;
		return true;
	}

	/**
	 * @notice A method to remove pool from this pool
	 * @param _pool Pool wallet address to remove
	 * @return bool True/False as the result
	 */
	function removeSystemPool(address _pool) public onlyOwner returns (bool) {
		_systemPools[_pool] = false;
		return true;
	}

	/**
	 * @notice A method to transfer remaining amount of reward to another pool (only related pools)
	 * @param _toPool Pool to transfer remaining reward
	 * @param _amount Amount of reward to transfer
	 * @return bool True/False as the result
	 */
	function transferUnpaidRewardsToPool(address _toPool, uint256 _amount)
		public
		onlyOwner
		returns (bool)
	{
		require(
			block.timestamp > _poolEndedAt,
			"This pool is active can not transfer rewards to another."
		);
		require(
			_developers[_toPool] == true,
			"Invalid pool address to transfer rewards."
		);
		uint256 balance = _rewardToken.balanceOf(pool);
		require(balance >= _amount, "Balance is not enough to transfer.");
		_rewardToken.safeTransfer(_toPool, _amount);
	}

	/**
	 * @notice A method to detect if an address is stakeholder wallet or not
	 * @param _address Pool to transfer remaining reward
	 * @return exists_ True/False as the result
	 * @return index_ Index of stakeholder in the pool
	 */
	function isStakeholder(address _address)
		public
		view
		returns (bool exists_, uint256 index_)
	{
		for (uint256 s = 0; s < _stakeholders.length; s += 1) {
			if (_address == _stakeholders[s]) return (true, s);
		}

		return (false, 0);
	}

	/**
	 * @notice A method to add new stakeholder/update existed stakeholder of the pool
	 * @param _stakeholder Pool to transfer remaining reward
	 * @param _amount Pool to transfer remaining reward
	 * @param _timestamp Pool to transfer remaining reward
	 */
	function addOrUpdateStakeholder(
		address _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	) internal returns (uint256) {
		(bool exists_, ) = isStakeholder(_stakeholder);
		if (!exists_) {
			_stakeholders.push(_stakeholder);

			Stake memory newStake = Stake({
				stakeholder: _stakeholder,
				createdAt: _timestamp,
				stakeAmount: _amount,
				lastClaimAt: 0,
				canUnlockAt: _poolEndedAt
			});

			_userStakes[_stakeholder] = newStake;
			_rewards[_stakeholder] = 0;
			return _amount;
		}

		// If stakeholder add new amount of stake tokens. Paid current reward to them and update new stake tokens of stakeholder
		claimRewardInternal(_stakeholder, _timestamp);
		_userStakes[_stakeholder].lastClaimAt = _timestamp;
		_userStakes[_stakeholder].createdAt = _timestamp;
		_userStakes[_stakeholder].stakeAmount = _userStakes[_stakeholder]
			.stakeAmount
			.add(_amount);

		return _amount;
	}

	/**
	 * @notice A method to take token
	 * @param _amount Amount of token to stake
	 * @return success_ True/False as result
	 * @return stakeAmount_ Succeed stake amount
	 */
	function stake(uint256 _amount)
		public
		payable
		updateReward(msg.sender)
		validTransactionFee(msg.value)
		poolAvailable
		ensurePoolStart
		returns (bool success_, uint256 stakeAmount_)
	{
		address stakeholder = msg.sender;
		require(_amount > 0, "Staking token amount must be none zero value.");

		uint256 _stakeAmount = _amount;
		if (_stakeDepositFee > 0) {
			uint256 _fee = _amount.mul(_stakeDepositFee).div(100);
			_stakeAmount = _amount.sub(_fee);
			_poolDepositFeeAmount = _poolDepositFeeAmount.add(_fee);
		}

		uint256 allowance = _stakeToken.allowance(msg.sender, pool);
		require(
			allowance >= _amount,
			"You have reach the token allowance to transfer to contract pool. Please approve and try again."
		);

		_stakeToken.safeTransferFrom(stakeholder, pool, _amount);
		emit TransferSuccessful(stakeholder, pool, _amount);

		uint256 timestamp = block.timestamp;
		// Reset lifetime of pool if first stakeholder stake their tokens
		// to make sure all reward will be distributed to all stakeholders
		if (_stakeholders.length == 0) {
			_poolRewardDistributionStartedAt = timestamp;
			_poolEndedAt = timestamp.add(_poolRunDuration);
		}

		uint256 addToTotalAmount = addOrUpdateStakeholder(
			stakeholder,
			_stakeAmount,
			timestamp
		);
		emit StakeSuccessful(stakeholder, _stakeAmount, timestamp);
		_poolTotalStake = _poolTotalStake.add(addToTotalAmount);
		return (true, _stakeAmount);
	}

	/**
	 * @notice A method to claim reward of stakeholder. Internal call only
	 * @param _stakeholder Stakeholder address to claim reward
	 * @param _timestamp The block timestamp
	 */
	function claimRewardInternal(address _stakeholder, uint256 _timestamp)
		internal
		returns (bool claimSuccess_, uint256 claimedAmount_)
	{
		(uint256 currentRewards, , , ) = rewardOf(_stakeholder);
		if (currentRewards == 0) {
			return (true, 0);
		}

		uint256 _receiveAmount = currentRewards;
		if (_rewardClaimFee > 0) {
			uint256 _fee = (currentRewards.mul(_rewardClaimFee)).div(100);
			_receiveAmount = currentRewards.sub(_fee);
		}

		_rewards[_stakeholder] = 0;
		_paidRewards[_stakeholder] = _paidRewards[_stakeholder].add(
			currentRewards
		);
		_rewardToken.safeTransfer(_stakeholder, _receiveAmount);
		_poolClaimedReward = _poolClaimedReward.add(currentRewards);
		_userStakes[_stakeholder].lastClaimAt = _timestamp;
		emit RewardClaimSuccessful(_stakeholder, _receiveAmount, _timestamp);
		return (true, currentRewards);
	}

	/**
	 * @notice A method to claim reward
	 * @return success_ True/False as result
	 * @return amount_ Claimable amount
	 */
	function claimReward()
		public
		payable
		updateReward(msg.sender)
		validTransactionFee(msg.value)
		ensurePoolStart
		returns (bool success_, uint256 amount_)
	{
		address stakeholder = msg.sender;
		uint256 timestamp = block.timestamp;
		(bool claimSuccess_, uint256 claimedAmount_) = claimRewardInternal(
			stakeholder,
			timestamp
		);
		return (claimSuccess_, claimedAmount_);
	}

	/**
	 * @notice A method to withdraw stake tokens
	 * @return success_ True/False as result
	 * @return withdrawAmount_ Withdraw amount
	 */
	function withdrawAndClaimReward()
		public
		payable
		// updateReward(msg.sender)
		validTransactionFee(msg.value)
		ensurePoolStart
		returns (bool success_, uint256 withdrawAmount_)
	{
		address _stakeholder = msg.sender;
		uint256 _timestamp = block.timestamp;
		(bool exists_, ) = isStakeholder(_stakeholder);
		require(exists_, "You are not stakeholder of this pool.");
		require(
			_userStakes[_stakeholder].stakeAmount > 0,
			"You have withdraw your token."
		);

		uint256 _withdrawAmount = _userStakes[_stakeholder].stakeAmount;
		require(
			block.timestamp > _userStakes[_stakeholder].canUnlockAt,
			"Tokens are in locked. Please wait until it's released."
		);

		// Transfer reward if any
		(bool claimSuccess_, ) = claimRewardInternal(_stakeholder, _timestamp);

		if (!claimSuccess_) {
			return (false, 0);
		}

		_userStakes[_stakeholder].stakeAmount = 0;
		// Transfer stake tokens
		_stakeToken.safeTransfer(_stakeholder, _withdrawAmount);
		return (true, _withdrawAmount);
	}

	/**
	 * @notice A method to withdraw stake tokens fee to pay for pool development team
	 * @param toAddress Add ress to receive deposit fee
	 */
	function withdrawDepositFee(address toAddress) public onlyOwner {
		uint256 balanceOfPool = _stakeToken.balanceOf(pool);
		require(
			balanceOfPool >= _poolDepositFeeAmount,
			"Balance is not enough to withdraw."
		);
		_stakeToken.safeTransfer(toAddress, _poolDepositFeeAmount);
	}

	/**
	 * @notice A method to get reward of stakeholder
	 * @param _stakeholder Pool to transfer remaining reward
	 */
	function rewardOf(address _stakeholder)
		public
		view
		returns (
			uint256 reward_,
			uint256 stakeAmount_,
			uint256 userStakePoolSeconds_,
			uint256 claimedReward_
		)
	{
		if (_poolRewardDistributionStartedAt == 0) {
			return (0, 0, 0, 0);
		}

		if (_userStakes[_stakeholder].stakeAmount == 0) {
			return (0, 0, 0, 0);
		}

		if (_poolTotalStake == 0) {
			return (0, 0, 0, 0);
		}

		uint256 lastTimePeriod = 0;
		if (block.timestamp > _poolEndedAt) {
			lastTimePeriod = _poolEndedAt;
		} else {
			lastTimePeriod = block.timestamp;
		}

		uint256 userStakePoolSeconds = 0;
		if (_userStakes[_stakeholder].lastClaimAt > 0) {
			userStakePoolSeconds = lastTimePeriod.sub(
				_userStakes[_stakeholder].lastClaimAt
			);
		} else {
			userStakePoolSeconds = lastTimePeriod.sub(
				_userStakes[_stakeholder].createdAt
			);
		}

		if (userStakePoolSeconds == 0) {
			return (0, 0, 0, 0);
		}

		uint256 availableReward = _userStakes[_stakeholder]
			.stakeAmount
			.mul(_poolRewardPerSecondRate.mul(userStakePoolSeconds))
			.div(_poolTotalStake);

		return (
			availableReward,
			_userStakes[_stakeholder].stakeAmount,
			userStakePoolSeconds,
			_paidRewards[_stakeholder]
		);
	}

	/**
	 * @notice A method to get pool distributed reward
	 * @param timestamp The timestamp to get distributed reward
	 * @return uint256 The pool distributed reward
	 */
	function getPoolDistributedReward(uint256 timestamp)
		public
		view
		returns (uint256)
	{
		if (_stakeholders.length == 0) {
			return 0;
		}

		if (timestamp < _poolStartedAt) {
			return 0;
		}

		if (_poolRewardDistributionStartedAt == 0) {
			return 0;
		}

		uint256 lastTimePeriod = 0;
		if (block.timestamp > _poolEndedAt) {
			lastTimePeriod = _poolEndedAt;
		} else {
			lastTimePeriod = block.timestamp;
		}

		uint256 poolSpentSeconds = lastTimePeriod.sub(
			_poolRewardDistributionStartedAt
		);

		return _poolRewardPerSecondRate.mul(poolSpentSeconds);
	}

	/**
	 * @notice A method to withdraw fee by developer (Use for development)
	 * @param _amount Amount to withdraw
	 * @return bool True/False as result
	 */
	function developerWithdraw(uint256 _amount) public returns (bool) {
		require(msg.sender != pool, "Invalid address to withdraw.");
		require(
			_developers[msg.sender] == true,
			"Your are not a developer of this pool."
		);

		require(address(this).balance > _amount, "Invalid amount to withdraw");
		msg.sender.transfer(_amount);
		return true;
	}

	/**
	 * @notice A method to add new stakeholder/update existed stakeholder of the pool
	 */
	function myPoolInformation()
		public
		view
		returns (
			address address_,
			uint256 stakeAmount_,
			uint256 createdAt_,
			uint256 lastClaimAt_,
			uint256 reward_,
			uint256 claimedReward_,
			uint256 canUnlockWithdrawAt
		)
	{
		address stakeholder = msg.sender;
		(bool exists_, ) = isStakeholder(stakeholder);
		if (!exists_) {
			return (
				0x0000000000000000000000000000000000000000,
				0,
				0,
				0,
				0,
				0,
				0
			);
		}

		(uint256 _reward, , , ) = rewardOf(stakeholder);
		uint256 _paidReward = _paidRewards[stakeholder];
		return (
			_userStakes[stakeholder].stakeholder,
			_userStakes[stakeholder].stakeAmount,
			_userStakes[stakeholder].createdAt,
			_userStakes[stakeholder].lastClaimAt,
			_reward,
			_paidReward,
			_userStakes[stakeholder].canUnlockAt
		);
	}

	/**
	 * @notice A method to get pool information
	 * @return poolTotalReward_ The pool total rewards
	 * @return poolRemainingReward_ The pool remaining rewards
	 * @return poolRunDuration_ The pool lifetime duration in seconds
	 * @return poolStartedAt_ The pool start date
	 * @return poolEnded_ Pool status is active/inactive
	 * @return poolDistributedReward_ The pool distributed rewards
	 * @return poolClaimedReward_ The pool paid rewards
	 * @return poolNumberOfStakeholders_ Total stakeholders of the pool
	 * @return poolTotalStake_ Total stake volume of the pool
	 */
	function getPoolInformation()
		public
		view
		returns (
			uint256 poolTotalReward_,
			uint256 poolRemainingReward_,
			uint256 poolRunDuration_,
			uint256 poolStartedAt_,
			bool poolEnded_,
			uint256 poolDistributedReward_,
			uint256 poolClaimedReward_,
			uint256 poolNumberOfStakeholders_,
			uint256 poolTotalStake_,
			uint256 poolRewardPerSecond_,
			uint256 poolEndedAt_
		)
	{
		uint256 _poolNumberOfStakeholders = _stakeholders.length;
		uint256 _poolDistributedReward = getPoolDistributedReward(
			block.timestamp
		);
		uint256 _poolRemainingReward = _poolTotalReward.sub(
			_poolDistributedReward
		);

		bool _poolEnded = block.timestamp > _poolEndedAt;
		return (
			_poolTotalReward,
			_poolRemainingReward,
			_poolRunDuration,
			_poolStartedAt,
			_poolEnded,
			_poolDistributedReward,
			_poolClaimedReward,
			_poolNumberOfStakeholders,
			_poolTotalStake,
			_poolRewardPerSecondRate,
			_poolEndedAt
		);
	}
}