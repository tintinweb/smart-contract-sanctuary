// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

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
contract GenericPool_YFCC_Finance is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	/**
	 * Stake section information struct
	 */
	struct Stake {
		address stakeholder;
		uint256 createdAt;
		address referredBy;
		uint256 stakeAmount;
		uint256 expiredAt;
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
	mapping(address => uint256) internal _referRewards;
	address public _defaultReferAddress;

	// Pool init stats
	// 0% per transaction. Set later
	uint256 public _rewardClaimFee = 0;
	uint256 public _transactionFeeInEther = 20000000000000000; // 0.02 ETH
	// 20% of 1st round of reward distribution
	uint256 public _poolRewardDistributionRate = 0;

	// Pool rewards
	uint256 internal _poolTotalStake = 0;
	uint256 internal _poolRemainingReward = 0;
	uint256 internal _poolDistributedReward = 0;
	uint256 internal _poolTotalReward = 0;
	uint256 internal _poolClaimedReward = 0;
	// Last time the pool distribute rewards to all stakeholders
	uint256 internal _lastRewardDistributionOn;
	uint256 public _poolRewardHalvingAt = 0;
	// 24 hours rewards halving
	uint256 public _poolHalvingIntervalMinutes = 1440;
	uint256 public _poolRewardDistributionIntervalMinutes = 5;

	// Pool owner
	address public pool;
	bool public _poolLifeCircleEnded = false;
	uint256 public poolDeployedAt = 0;

	// Pool developers
	mapping(address => bool) internal _developers;

	constructor(
		address rewardTokenAddress,
		address stakeTokenAddress,
		uint256 poolHalvingIntervalMinutes,
		uint256 poolRewardDistributionIntervalMinutes,
		address defaultReferAddress
	) {
		_rewardTokenAddress = rewardTokenAddress;
		_rewardToken = IERC20(rewardTokenAddress);

		_stakeTokenAddress = stakeTokenAddress;
		_stakeToken = IERC20(stakeTokenAddress);

		// Current block
		poolDeployedAt = uint40(block.timestamp);
		// Current contract owner & pool
		pool = address(this);
		_poolHalvingIntervalMinutes = poolHalvingIntervalMinutes;
		_poolRewardDistributionIntervalMinutes = poolRewardDistributionIntervalMinutes;
		_defaultReferAddress = defaultReferAddress;
	}

	// ---------- EVENTS ----------------
	event TransferSuccessful(
		address indexed _from,
		address indexed _to,
		uint256 _amount
	);
	event TransferRewardsToPoolContract(
		address indexed _from,
		address indexed _to,
		address indexed _rewardToken,
		uint256 _amount
	);
	event StakeSuccessful(
		address indexed _stakeholder,
		address indexed _referral,
		uint256 _amount,
		uint256 _timestamp
	);
	event UnstakeSuccessful(address indexed _stakeholder, uint256 _timestamp);
	event RewardClaimSuccessful(
		address indexed _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	);
	event RewardDistributeSuccessful(
		address indexed _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	);
	event RewardDistributeIgnore(
		address indexed _stakeholder,
		uint256 _expiredAt,
		uint256 _timestamp
	);
	event ReferRewardDistributeSuccessful(
		address indexed _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	);

	// ---------- POOL ACTIONS ----------
	/**
	 * @notice A method to add reward to pool contract.
	 * @param _rewardAmount Amount of reward token.
	 */
	function addPoolRewards(uint256 _rewardAmount) public onlyOwner {
		require(
			_poolLifeCircleEnded == false,
			"Pool life circle has been ended."
		);

		require(
			_rewardAmount > 0,
			"Reward token amount must be none zero value."
		);

		// Add pool init & remaining reward
		_poolRemainingReward = _poolRemainingReward.add(_rewardAmount);
		_poolTotalReward = _poolTotalReward.add(_rewardAmount);

		// 20% rewards will be distributed to stakeholders on 1st round
		_poolRewardDistributionRate = (_poolTotalReward.mul(20)).div(100);

		// Transfer tokens to pool from owner
		uint256 _allowance = _rewardToken.allowance(msg.sender, pool);
		require(
			_allowance >= _rewardAmount,
			"You did not approve the reward to transfer to Pool."
		);

		_rewardToken.safeTransferFrom(msg.sender, pool, _rewardAmount);

		// Emit event of transfer
		emit TransferRewardsToPoolContract(
			msg.sender,
			pool,
			_rewardTokenAddress,
			_rewardAmount
		);
	}

	/**
	 * @notice A method to set reward claim fee.
	 * @param _fee Reward claim fee.
	 */
	function setRewardClaimFee(uint256 _fee) public onlyOwner {
		require(_fee > 0, "Reward claim fee must be none zero value.");
		_rewardClaimFee = _fee;
	}

	/**
	 * @notice A method to set pool halving interval hours.
	 * @param _minutes Halving interval hours.
	 */
	function setRewardHalvingInterval(uint256 _minutes) public onlyOwner {
		require(_minutes > 0, "Halving interval minutes must be none zero value.");
		_poolHalvingIntervalMinutes = _minutes;
	}

	/**
	 * @notice A method to set pool reward distribution interval hours.
	 * @param _minutes Distribution interval hours.
	 */
	function setRewardDistributionInterval(uint256 _minutes) public onlyOwner {
		require(_minutes > 0, "Halving interval minutes must be none zero value.");
		_poolRewardDistributionIntervalMinutes = _minutes;
	}

	/**
	 * @notice A method to set reward claim fee in ether.
	 * @param _fee Reward claim fee in ether.
	 */
	function setTransactionFeeInEther(uint256 _fee) public onlyOwner {
		require(_fee > 0, "Reward claim fee must be none zero value.");
		_transactionFeeInEther = _fee;
	}

	/**
	 * @notice A method to set developers of the pool
	 * @param _address The developer address to add
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
	 * @notice A method to remove developers from the pool
	 * @param _address The developer address to add
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
	 * @notice A method to set reward pool life circle
	 */
	function endPoolLifeCircle() public onlyOwner {
		_poolLifeCircleEnded = true;
	}

	// ---------- STAKEHOLDERS ----------
	/**
	 * @notice A method to check if an address is a stakeholder.
	 * @param _address The address to verify.
	 * @return exists_ Exist or not
	 * @return index_ Access index of stakeholder
	 */
	function isStakeholder(address _address)
		public
		view
		returns (bool exists_, uint256 index_)
	{
		// Find stakeholder
		for (uint256 s = 0; s < _stakeholders.length; s += 1) {
			if (_address == _stakeholders[s]) return (true, s);
		}

		return (false, 0);
	}

	/**
	 * @notice A method to add a stakeholder.
	 * @param _stakeholder The stakeholder to add.
	 * @param _referredBy The user wallet to get refer bonus
	 * @param _amount The amount of stake token
	 * @param _timestamp The timestamp when stakeholder added to pool
	 */
	function addStakeholder(
		address _stakeholder,
		address _referredBy,
		uint256 _amount,
		uint256 _timestamp
	) internal {
		(bool exists_, ) = isStakeholder(_stakeholder);
		if (!exists_) {
			// Add new stakeholder
			_stakeholders.push(_stakeholder);

			// Add new stake information
			Stake memory newStake = Stake({
				stakeholder: _stakeholder,
				createdAt: _timestamp,
				referredBy: _referredBy,
				stakeAmount: _amount,
				expiredAt: 0
			});

			_userStakes[_stakeholder] = newStake;
			_rewards[_stakeholder] = 0;
		} else {
			_userStakes[_stakeholder].stakeAmount = _userStakes[_stakeholder]
				.stakeAmount
				.add(_amount);
			// Reset expiredAt value
			_userStakes[_stakeholder].expiredAt = 0;
		}
	}

	/**
	 * @notice A method to the stake ERC20 token to get reward.
	 * @return success_ Whether the address is a stakeholder
	 * @return stakeAmount_ Stake amount
	 */
	function stake(address _referral, uint256 _amount)
		public
		payable
		returns (bool success_, uint256 stakeAmount_)
	{
		// Allow claim fee if any
		if (_transactionFeeInEther > 0) {
			require(
				msg.value >= _transactionFeeInEther,
				"You need to pay transaction to claim your rewards."
			);
		}

		require(
			_poolLifeCircleEnded == false,
			"Pool life circle has been ended."
		);

		address stakeholder = msg.sender;
		require(_amount > 0, "Staking token amount must be none zero value.");

		require(
			_referral != stakeholder,
			"You can not refer yourself into this pool."
		);

		// If no referral set stake referral to global settings
		if (_referral == address(0x0000000000000000000000000000000000000000)) {
			_referral = _defaultReferAddress;
		} else {
			// Check if referral is a valid stakeholder
			(bool exists_, ) = isStakeholder(_referral);
			if (!exists_) {
				_referral = _defaultReferAddress;
			}
		}

		// Check available token of sender and withdraw to the pool
		uint256 allowance = _stakeToken.allowance(msg.sender, pool);
		require(
			allowance >= _amount,
			"You have reach the token allowance to transfer to contract pool. Please approve and try again."
		);

		// Transfer ERC20 tokens to pool => locked amount pool
		_stakeToken.safeTransferFrom(stakeholder, pool, _amount);
		// Emit transfer event
		emit TransferSuccessful(stakeholder, pool, _amount);

		uint256 timestamp = block.timestamp;

		// Add to stakeholders
		addStakeholder(stakeholder, _referral, _amount, timestamp);
		emit StakeSuccessful(stakeholder, _referral, _amount, timestamp);

		// Update staking total amount
		_poolTotalStake = _poolTotalStake.add(_amount);
		return (true, _amount);
	}

	/**
	 * @notice A method to the stake ERC20 token to get reward.
	 */
	function unstakeInternal(address _stakeholder, uint256 timestamp)
		internal
		returns (bool success_, uint256 expiredAt_)
	{
		(bool exists_, ) = isStakeholder(_stakeholder);
		require(exists_, "You are not stakeholder of this pool.");
		if (_userStakes[_stakeholder].expiredAt > 0) {
			return (true, _userStakes[_stakeholder].expiredAt);
		}

		_userStakes[_stakeholder].expiredAt = timestamp;
		return (true, timestamp);
	}

	/**
	 * @notice A method to the stake ERC20 token to get reward.
	 * @return success_ Action result
	 * @return expiredAt_ Expired time
	 */
	function unstake()
		public
		payable
		returns (bool success_, uint256 expiredAt_)
	{
		// Allow transaction fee if any
		if (_transactionFeeInEther > 0) {
			require(
				msg.value >= _transactionFeeInEther,
				"You need to pay transaction to claim your rewards."
			);
		}
		// Unstake token
		address stakeholder = msg.sender;
		uint256 timestamp = block.timestamp;
		(bool success__, uint256 expiredAt__) = unstakeInternal(
			stakeholder,
			timestamp
		);

		if (success_) {
			emit UnstakeSuccessful(stakeholder, timestamp);
			// Update total stake pool
			_poolTotalStake = _poolTotalStake.sub(
				_userStakes[stakeholder].stakeAmount
			);
		}
		// Return a success result
		return (success__, expiredAt__);
	}

	/**
	 * @notice A method to the unstake stake ERC20 token to get staking reward.
	 */
	function unstakeAndClaimReward()
		public
		payable
		returns (bool success_, uint256 claimAmount_)
	{
		// Allow transaction fee if any
		if (_transactionFeeInEther > 0) {
			require(
				msg.value >= _transactionFeeInEther,
				"You need to pay transaction to claim your rewards."
			);
		}

		// Unstake token
		address stakeholder = msg.sender;
		uint256 timestamp = block.timestamp;
		(bool success__, ) = unstakeInternal(stakeholder, timestamp);

		if (!success__) {
			return (false, 0);
		}

		// Update pool staking amount
		_poolTotalStake = _poolTotalStake.sub(
			_userStakes[stakeholder].stakeAmount
		);
		// Claim all reward
		uint256 _reward = rewardOf(stakeholder);
		uint256 _bonus = referBonusOf(stakeholder);
		uint256 unclaimReward = _reward.add(_bonus);

		// If reward is available to transfer
		if (unclaimReward > 0) {
			_rewards[stakeholder] = 0;
			_referRewards[stakeholder] = 0;
			transferRewardInternal(stakeholder, unclaimReward, timestamp);
		}

		return (true, unclaimReward);
	}

	/**
	 * @notice A method to claim refer bonus reward
	 *  @return success_ Transaction result is success or fail
	 * @return amount_ Amount of refer bonus
	 */
	function claimReferReward()
		public
		returns (bool success_, uint256 amount_)
	{
		address claimer = msg.sender;
		uint256 timestamp = block.timestamp;

		uint256 _referReward = referBonusOf(claimer);
		require(_referReward > 0, "You have no refer bonus to claim.");

		_referRewards[claimer] = 0;
		transferRewardInternal(claimer, _referReward, timestamp);
		return (true, _referReward);
	}

	/**
	 * @notice A method allow stakeholder to withdraw their stake tokens
	 */
	function withdraw()
		public
		payable
		returns (bool success_, uint256 withdrawAmount_)
	{
		// Allow transaction fee if any
		if (_transactionFeeInEther > 0) {
			require(
				msg.value >= _transactionFeeInEther,
				"You need to pay transaction to claim your rewards."
			);
		}

		address _stakeholder = msg.sender;
		uint256 _timestamp = block.timestamp;
		(bool exists_, ) = isStakeholder(_stakeholder);
		require(exists_, "You are not stakeholder of this pool.");
		require(
			_userStakes[_stakeholder].stakeAmount > 0,
			"You have withdraw your token."
		);

		uint256 _withdrawAmount = _userStakes[_stakeholder].stakeAmount;

		_userStakes[_stakeholder].stakeAmount = 0;
		_userStakes[_stakeholder].expiredAt = _timestamp;
		_poolTotalStake = _poolTotalStake.sub(_withdrawAmount);
		_stakeToken.safeTransfer(_stakeholder, _withdrawAmount);

		return (true, _withdrawAmount);
	}

	/**
	 * @notice A method to withdraw developer assets from the pool
	 * @param _amount Amount of withdrawal
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
	 * @notice A method to get stakeholder information
	 * @return address_ Stakeholder address
	 * @return stakeAmount_ Staking amount
	 * @return createdAt_ Staking created date
	 * @return expiredAt_ Expiration time
	 * @return reward_ Earned rewards
	 */
	function myPoolInformation()
		public
		view
		returns (
			address address_,
			uint256 stakeAmount_,
			uint256 createdAt_,
			uint256 expiredAt_,
			uint256 reward_,
			uint256 referReward_
		)
	{
		address stakeholder = msg.sender;
		(bool exists_, ) = isStakeholder(stakeholder);
		if (!exists_) {
			return (0x0000000000000000000000000000000000000000, 0, 0, 0, 0, 0);
		}

		uint256 _reward = rewardOf(stakeholder);
		uint256 _referReward = referBonusOf(stakeholder);
		return (
			_userStakes[stakeholder].stakeholder,
			_userStakes[stakeholder].stakeAmount,
			_userStakes[stakeholder].createdAt,
			_userStakes[stakeholder].expiredAt,
			_reward,
			_referReward
		);
	}

	/**
	 * @notice Transfer function to transfer reward token to stakeholder
	 * @param _stakeholder Address of stakeholder to transfer
	 * @param _amount Amount of reward to claim
	 * @param _timestamp Timestamp to transfer
	 */
	function transferRewardInternal(
		address _stakeholder,
		uint256 _amount,
		uint256 _timestamp
	) internal {
		_rewardToken.safeTransfer(_stakeholder, _amount);
		emit RewardClaimSuccessful(_stakeholder, _amount, _timestamp);
	}

	// ---------- REWARDS ----------
	/**
	 * @notice A method to allow a stakeholder to check his rewards.
	 * @param _stakeholder The stakeholder to check rewards for.
	 * @return reward_ Rewards of stakeholder
	 */
	function rewardOf(address _stakeholder)
		public
		view
		returns (uint256 reward_)
	{
		return _rewards[_stakeholder];
	}

	/**
	 * @notice A method to allow a stakeholder to check his bonus rewards.
	 * @param _stakeholder The stakeholder to check rewards for.
	 * @return bonus_ Rewards of stakeholder
	 */
	function referBonusOf(address _stakeholder)
		public
		view
		returns (uint256 bonus_)
	{
		return _referRewards[_stakeholder];
	}

	/**
	 * @notice A simple method that calculates the rewards for each stakeholder.
	 * @param _stakeAmount The stakeholder staking amount to calculate rewards.
	 * @param _availableReward Pool available rewards.
	 */
	function calculateReward(uint256 _stakeAmount, uint256 _availableReward)
		internal
		view
		returns (uint256)
	{
		// When all users unstake
		if (_poolTotalStake == 0) {
			return 0;
		}

		uint256 _reward = (_availableReward.mul(_stakeAmount)).div(
			_poolTotalStake
		);

		return _reward;
	}

	/**
	 * @notice A method to distribute rewards to all stakeholders.
	 */
	function distributeRewards() public onlyOwner {
		uint256 timestamp = block.timestamp;
		uint256 totalDistributedRewards = 0;
		if (_poolRewardHalvingAt > 0 && timestamp >= _poolRewardHalvingAt && _stakeholders.length > 0) {
			// Do reward halving
			_poolRewardDistributionRate = (_poolRewardDistributionRate.mul(50))
				.div(100);
		}

		uint256 availableReward = (
			_poolRewardDistributionRate.mul(_poolRewardDistributionIntervalMinutes)
		)
			.div(_poolHalvingIntervalMinutes);

		// Loop for all staking slots base on support stake token list
		for (uint256 t = 0; t < _stakeholders.length; t += 1) {
			Stake storage _stake = _userStakes[_stakeholders[t]];

			if (_stake.expiredAt > 0 && timestamp > _stake.expiredAt) {
				emit RewardDistributeIgnore(
					_stake.stakeholder,
					_stake.expiredAt,
					timestamp
				);

				continue;
			}

			// Calculate stakeholder reward
			uint256 reward = calculateReward(
				_stake.stakeAmount,
				availableReward
			);

			// Add it to reward hub
			_rewards[_stake.stakeholder] = _rewards[_stake.stakeholder].add(
				reward
			);

			emit RewardDistributeSuccessful(
				_stake.stakeholder,
				reward,
				timestamp
			);

			totalDistributedRewards = totalDistributedRewards.add(reward);

			// Add refer bonus
			if (
				_stake.referredBy !=
				address(0x0000000000000000000000000000000000000000)
			) {
				// Get 5% bonus from user you refer to the pool
				uint256 bonusReward = (reward.mul(5)).div(100);
				_referRewards[_stake.referredBy] = _referRewards[_stake
					.referredBy]
					.add(bonusReward);

				// Emit event
				emit ReferRewardDistributeSuccessful(
					_stake.referredBy,
					bonusReward,
					timestamp
				);

				totalDistributedRewards = totalDistributedRewards.add(
					bonusReward
				);
			}
		}

		// 5% of rewards will be add to pool dev address
		uint256 devRewards = (totalDistributedRewards.mul(5)).div(100);
		_rewards[_defaultReferAddress] = _rewards[_defaultReferAddress].add(
			devRewards
		);

		totalDistributedRewards = totalDistributedRewards.add(devRewards);
		// Update some pool information
		_poolRemainingReward = _poolRemainingReward.sub(
			totalDistributedRewards
		);
		_poolDistributedReward = _poolDistributedReward.add(
			totalDistributedRewards
		);

		_lastRewardDistributionOn = timestamp;
		if (_poolRewardHalvingAt == 0 || timestamp >= _poolRewardHalvingAt) {
			// Minus 1 minute of the time
			uint256 nextHalvingTimestamp = (60 * _poolHalvingIntervalMinutes) - 60;
			_poolRewardHalvingAt = _lastRewardDistributionOn.add(
				nextHalvingTimestamp
			);
		}
	}

	/**
	 * @notice A method to claim stakeholder reward
	 * @return success_ Claim result true/false
	 */
	function claimReward()
		public
		payable
		returns (bool success_, uint256 amount_)
	{
		// Allow transaction fee if any
		if (_transactionFeeInEther > 0) {
			require(
				msg.value >= _transactionFeeInEther,
				"You need to pay transaction to claim your rewards."
			);
		}

		// Check validation
		address stakeholder = msg.sender;
		// Get current reward
		uint256 _reward = rewardOf(stakeholder);
		uint256 _bonus = referBonusOf(stakeholder);
		uint256 totalRewards = _reward.add(_bonus);
		require(totalRewards > 0, "You do not have any reward to claim.");

		// Process to transfer reward and update remaining unclaim reward
		uint256 _receiveAmount = totalRewards;
		uint256 timestamp = block.timestamp;

		// Subtract claim fee
		if (_rewardClaimFee > 0) {
			uint256 _fee = (totalRewards.mul(_rewardClaimFee)).div(100);
			_receiveAmount = totalRewards.sub(_fee);
		}

		// Update new reward balances
		_rewards[stakeholder] = 0;
		_referRewards[stakeholder] = 0;

		// Transfer reward tokens
		transferRewardInternal(stakeholder, _receiveAmount, timestamp);
		_poolClaimedReward = _poolClaimedReward.add(_receiveAmount);

		// Emit event
		emit RewardClaimSuccessful(stakeholder, _receiveAmount, timestamp);
		return (true, _receiveAmount);
	}

	/**
	 * @notice A method to get pool reward stats
	 * @return lastRewardDistributionOn_ The last time when pool distribute rewards to all stakeholders
	 * @return poolTotalReward_ Total pool reward amount
	 * @return poolRemainingReward_ Total remaining reward for staking
	 * @return poolDistributedReward_ Total
	 * @return poolClaimedReward_ Total claimed reward from stakeholders
	 */
	function getPoolInformation()
		public
		view
		returns (
			uint256 lastRewardDistributionOn_,
			uint256 poolTotalReward_,
			uint256 poolRemainingReward_,
			uint256 poolDistributedReward_,
			uint256 poolClaimedReward_,
			uint256 poolNextHalvingAt_,
			uint256 poolNumberOfStakeholders_,
			uint256 poolTotalStake_,
			uint256 poolInitialRewards_
		)
	{
		uint256 _poolNumberOfStakeholders = _stakeholders.length;
		return (
			_lastRewardDistributionOn,
			_poolTotalReward,
			_poolRemainingReward,
			_poolDistributedReward,
			_poolClaimedReward,
			_poolRewardHalvingAt,
			_poolNumberOfStakeholders,
			_poolTotalStake,
			_poolRewardDistributionRate
		);
	}
}