/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// File: contracts/protocols/bep/BepLib.sol
// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.7;
pragma experimental ABIEncoderV2;

interface IBEP20 {

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
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly { codehash := extcodehash(account) }
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
	 * - the calling contract must have an BNB balance of at least `value`.
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

abstract contract Ownable is Context {
	uint256 public _timeLock = 0;
	uint256 public _minimumVotes = 1;
	address[] public _vote;
	address[] public _authorizedCallersArray;
	address public _owner;
	mapping(address => bool) public _authorizedCallers;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event AuthorizedCaller(address account,bool value);
	event TimeLockOperationRequested(address account,uint256 when,uint256 timelock);
	event TimeLockOperationAndVoteReset(address account);
	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor () {
		_owner = _msgSender();
		_setAuthorizedCallers(_owner,true);
		emit OwnershipTransferred(address(0), _owner);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier needVote {
		require((_vote.length >= _minimumVotes),"Function does not meet quorum, initiate a vote request before and meet quorum.");
		_timeLock = 0;
		if (_vote.length > 0) {
			delete _vote;
		}
		emit TimeLockOperationAndVoteReset(_msgSender());
		_;
	}

	modifier timeLockOperationAndNeedVote {
		require((_vote.length >= _minimumVotes) && (_timeLock > 0 && _timeLock <= block.timestamp),"Function is timelocked, initiate a timelock request before and wait for timelock to unlock");
		_timeLock = 0;
		if (_vote.length > 0) {
			delete _vote;
		}
		emit TimeLockOperationAndVoteReset(_msgSender());
		_;
	}

	modifier timeLockOperationOrNeedVote {
		require((_vote.length >= _minimumVotes) || (_timeLock > 0 && _timeLock <= block.timestamp),"Function is timelocked, initiate a timelock request before and wait for timelock to unlock");
		_timeLock = 0;
		if (_vote.length > 0) {
			delete _vote;
		}
		emit TimeLockOperationAndVoteReset(_msgSender());
		_;
	}

	modifier onlyOwner {
		require(_owner == _msgSender(), "Ownable: caller must be owner");
		_;
	}

	modifier authorizedCallers {
		require(_owner == _msgSender() || _authorizedCallers[_msgSender()] == true, "Ownable: caller is not authorized");
		_;
	}
	
	function vote() external authorizedCallers {
		for (uint256 i = 0; i < _vote.length; i++) {
			if (_vote[i] == _msgSender()) {
				// already voted
				return;
			}
		}
		_vote.push(_msgSender());
	}

	function setMinimumVotes(uint256 nbrVotes) external authorizedCallers timeLockOperationOrNeedVote {
		require(nbrVotes > 0,"minimum voters needed too low");
		require(nbrVotes <= _authorizedCallersArray.length,"maximum authorized callers length voters needed");
		_minimumVotes = nbrVotes;
	}
	

	function initiateTimeLock() external authorizedCallers {
		_timeLock = block.timestamp + 24 hours;
		emit TimeLockOperationRequested(_msgSender(),block.timestamp,_timeLock);
	}
	
	function resetTimeLockAndVote() external authorizedCallers() {
		_timeLock = 0;
		if (_vote.length > 0) {
			delete _vote;
		}
		emit TimeLockOperationAndVoteReset(_msgSender());
	}

	function _setAuthorizedCallers(address account,bool value) internal {
		if (account == address(0)) return;
		if (value && _authorizedCallers[account]) return;
		if (!value && !_authorizedCallers[account]) return;
		if (value) {
			_authorizedCallersArray.push(account);
		} else {
			if (_authorizedCallersArray.length == 1) {
				_authorizedCallersArray.pop();
			} else {
				for (uint256 i = 0; i < _authorizedCallersArray.length; i++) {
					if (_authorizedCallersArray[i] == account) {
						_authorizedCallersArray[i] = _authorizedCallersArray[_authorizedCallersArray.length - 1];
						_authorizedCallersArray.pop();
						break;
					}
				}
			}
		}
		// ensure voters are always <= _authorizedCallersArray.length
		if (_minimumVotes > _authorizedCallersArray.length) {
			_minimumVotes = _authorizedCallersArray.length;
		}
		_authorizedCallers[account] = value;
		emit AuthorizedCaller(account,value);
	}

	function setAuthorizedCallers(address account,bool value) external authorizedCallers timeLockOperationOrNeedVote {
		_setAuthorizedCallers(account,value);
	}

	function renounceOwnership() public virtual onlyOwner timeLockOperationAndNeedVote {
		emit OwnershipTransferred(_owner, address(0));
		_setAuthorizedCallers(_owner,false);
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual authorizedCallers timeLockOperationAndNeedVote {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_setAuthorizedCallers(_owner,false);
		_setAuthorizedCallers(newOwner,true);
		_owner = newOwner;
	}
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
	// Booleans are more expensive than uint256 or any type that takes up a full
	// word because each write operation emits an extra SLOAD to first read the
	// slot's contents, replace the bits taken up by the boolean, and then write
	// back. This is the compiler's defense against contract upgrades and
	// pointer aliasing, and it cannot be disabled.

	// The values being non-zero value makes deployment a bit more expensive,
	// but in exchange the refund on every call to nonReentrant will be lower in
	// amount. Since refunds are capped to a percentage of the total
	// transaction's gas, it is best to keep them low in cases like this one, to
	// increase the likelihood of the full refund coming into effect.
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor () {
		_status = _NOT_ENTERED;
	}

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and make it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}

	modifier isHuman() {
		require(tx.origin == msg.sender, "sorry humans only");
		_;
	}
}

interface LegatoV1 {
	function getUserStakes(uint256 poolIndex,address account) external view returns (uint256);
}

interface StakePool {
	struct Pool {
		address ldogeToken;
		address WBNB;
    	address BUSD;
    	address LegatoV1Address;
    	address LDOGE_WBNB_pair;
    	address BUSD_WBNB_pair;
		uint256 minimumLDOGEHoldingsInDollars;
		uint256 minimumLDOGEHoldingsInLDOGE;
		address parentOwner;
		address poolCreator;
		address stakedToken;
		address rewardToken;
		uint256 stakeTax;
		uint256 unstakeTax;
		uint256 unstakeRewardTax;
		uint256 stakePeriod;
		uint256 rewardTokensByPeriod;
		uint256 minTotalStakedForFullReward;
		uint256 minStakersForFullReward;
		uint256 minUserStakesForReward;
		uint256 minStakeTime;
		bool keepTax;
		bool disabled;
	}

	function updateminimumLDOGEHoldingsInDollars(uint256 minimumLDOGEHoldingsInDollars,uint256 minimumLDOGEHoldingsInLDOGE) external;
	function getPool() external view returns (Pool memory);
	function addRewardToPool(uint256 amount) external;
}

contract Legato is Context, Ownable, ReentrancyGuard, StakePool {
	using SafeMath for uint256;
	using Address for address;

	Pool private _pool;

	uint256 public _rewardPool;
	uint256 public _taxPool;
	uint256 public _totalStaked;
	uint256 public _totalRewards;
	uint256 public _countStakers;

	mapping(address => uint256) public _userStakes;
	mapping(address => uint256) public _userRewards;
	mapping(address => uint256) public _nextClaimDate;
	mapping(address => uint256) public _firstStake;

	address public _retrieveFundWallet;
	
	event RewardAddedSuccessfully (
		address rewardTokenAddress,
		uint256 amount
	);

	event StakeTokenSuccessfully(
		address from,
		uint256 totalAmount,
		uint256 tax,
		uint256 amount,
		uint256 nextClaimDate
	);

	event ClaimRewardSuccessfully(
		address from,
		uint256 amount,
		uint256 nextClaimDate
	);

	event RetrieveRewardSuccessfully(
		address to,
		uint256 rewardBalance
	);

	event UnstakeTokenSuccessfully(
		address to,
		uint256 amount
	);

	event MinimumHoldingChanged (
		uint256 amountInDollars,
		uint256 amountInLDOGE
	);
	
	constructor(Pool memory pool) {
		require(pool.stakedToken  != address(0),"staked token address must be != 0");
		require(pool.rewardToken  != address(0),"Reward token address must be != 0");
		require(pool.stakePeriod > 0,"Staking period must be greater than 0");
		// reset rights to parentOwner
		_setAuthorizedCallers(_msgSender(),false);
		_owner = pool.parentOwner;
		_setAuthorizedCallers(_owner,true);
		emit OwnershipTransferred(_msgSender(), _owner);
		_pool = pool;
	}
	
	function getPool() external view override returns (Pool memory)  {
		return _pool;
	}
	
	function disablePool() external authorizedCallers {
	    _pool.disabled = true;
	}

	function enablePool() external authorizedCallers {
	    _pool.disabled = false;
	}

	function mulScale(uint x, uint y, uint128 scale) internal pure returns (uint) {
		uint256 a = x.div(scale);
		uint256 b = x.mod(scale);
		uint256 c = y.div(scale);
		uint256 d = y.mod(scale);
		return (a.mul(c).mul(scale)).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(scale));
	}
	
	function setTax(uint256 stakeTokenTax,uint256 unstakeTokenTax,uint256 unstakeRewardTax) external authorizedCallers {
		_pool.stakeTax = stakeTokenTax;
		_pool.unstakeTax = unstakeTokenTax;
		_pool.unstakeRewardTax = unstakeRewardTax;
	}
	
	function updateminimumLDOGEHoldingsInDollars(uint256 minimumLDOGEHoldingsInDollars,uint256 minimumLDOGEHoldingsInLDOGE) external override {
		require(_msgSender() == _pool.poolCreator,"Only LDOGE pool creator can change ldoge minimum holdings");
		require(!(minimumLDOGEHoldingsInLDOGE > 0 && minimumLDOGEHoldingsInDollars > 0),"Dollars or fixed LDOGE.");
		_pool.minimumLDOGEHoldingsInDollars = minimumLDOGEHoldingsInDollars;
		_pool.minimumLDOGEHoldingsInLDOGE = minimumLDOGEHoldingsInLDOGE;
		emit MinimumHoldingChanged(_pool.minimumLDOGEHoldingsInDollars,_pool.minimumLDOGEHoldingsInLDOGE);
	}

	function setStakePeriod(uint256 stakePeriod) external authorizedCallers {
		require(stakePeriod > 0,"Staking period must be greater than 0");
		_pool.stakePeriod = stakePeriod;
	}

	function setRewardTokensByPeriod(uint256 amount) external authorizedCallers {
		require(_pool.rewardTokensByPeriod > 0,"Reward by period must be greater than 0");
		_pool.rewardTokensByPeriod = amount;
	}

	function setMinStakersForFullReward(uint256 count) external authorizedCallers {
		_pool.minStakersForFullReward = count;
	}

	function setMinTotalStakedForFullReward(uint256 amount) external authorizedCallers {
		_pool.minTotalStakedForFullReward = amount;
	}

	function setMinUserStakesForReward(uint256 amount) external authorizedCallers {
		_pool.minUserStakesForReward = amount;
	}
	
	function setMinStakeTime(uint256 time) external authorizedCallers {
		_pool.minStakeTime = time;
	}

	/**
	 * Add tokens to the reward pool, anybody can add rewards
	 */
	function addRewardToPool(uint256 amount) external override nonReentrant {
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(_pool.rewardToken).transferFrom(_msgSender(),address(this),amount);
		_rewardPool = _rewardPool + amount;
		uint256 maxToRetrieve = IBEP20(_pool.rewardToken).balanceOf(address(this));
		if (_rewardPool > maxToRetrieve) {
			_rewardPool = maxToRetrieve;
		}
		emit RewardAddedSuccessfully(_pool.rewardToken,amount);
	}
	
	function computeMinimumLDOGEHoldings() public view returns (uint256) {
		if (_pool.minimumLDOGEHoldingsInLDOGE > 0) return _pool.minimumLDOGEHoldingsInLDOGE;
	    if (_pool.minimumLDOGEHoldingsInDollars == 0) return 0;
		IBEP20 WBNB = IBEP20(_pool.WBNB);
		IBEP20 BUSD = IBEP20(_pool.BUSD);
		IBEP20 LDOGE = IBEP20(_pool.ldogeToken);
		uint256 BNBPrice_MINDOLLARS = (BUSD.balanceOf(_pool.BUSD_WBNB_pair).mul(1000).div(WBNB.balanceOf(_pool.BUSD_WBNB_pair))).div(_pool.minimumLDOGEHoldingsInDollars);
        return (LDOGE.balanceOf(_pool.LDOGE_WBNB_pair).mul(1000000000000000000000).div(WBNB.balanceOf(_pool.LDOGE_WBNB_pair))).div(BNBPrice_MINDOLLARS);	
	}
	
	function hasMinimumLdogeHolding(address account) public view returns (bool) {
		if (_pool.ldogeToken == address(0)) return true;
	    if (_pool.minimumLDOGEHoldingsInDollars == 0 && _pool.minimumLDOGEHoldingsInLDOGE == 0) return true;
		IBEP20 LDOGE = IBEP20(_pool.ldogeToken);
		IBEP20 PAIR = IBEP20(_pool.LDOGE_WBNB_pair);
		uint256 ldogeAmountInPair = LDOGE.balanceOf(_pool.LDOGE_WBNB_pair);
		uint256 totalSupplyInPair = PAIR.totalSupply();
		uint256 oneLp = ldogeAmountInPair.div(totalSupplyInPair);
		// compute balance
		uint256 balance = LDOGE.balanceOf(account);
		balance = balance.add(LegatoV1(_pool.LegatoV1Address).getUserStakes(1,account));
		balance = balance.add(LegatoV1(_pool.LegatoV1Address).getUserStakes(2,account).mul(oneLp));
		balance = balance.add(PAIR.balanceOf(account).mul(oneLp));
		if (balance >= computeMinimumLDOGEHoldings()) {
			return true;
		}
		return false;
	}

	/**
	 * Stake amount tokens into pool
	 */
	function stakeTokens(uint256 amount) external isHuman nonReentrant {
		// Check LDOGE Holdings	
		require(hasMinimumLdogeHolding(_msgSender()),"Not holding enough LDOGE");
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(_pool.stakedToken).transferFrom(_msgSender(),address(this),amount);
		// take tax fee
		uint256 totalAmount = amount;
		uint256 tax = _pool.stakeTax == 0 ? 0 : mulScale(amount,_pool.stakeTax,1000000);
		if (tax != 0) {
			// remove tax from staked amount
			amount = amount - tax;
			// add it to reward if both tokens are the same.
			if (!_pool.keepTax && _pool.stakedToken == _pool.rewardToken) {
				// add tax to reward pool
				_rewardPool = _rewardPool + tax;
			} else {
				// add it to tax pool to be retrieved.
				_taxPool = _taxPool + tax;
			}
		}
		// add stake to user stakes
		bool isNew = _userStakes[_msgSender()] == 0;
		_userStakes[_msgSender()] = _userStakes[_msgSender()].add(amount);
		// update total staked
		_totalStaked = _totalStaked.add(amount);
		// could claim rewards for current period ? then do
		if (_nextClaimDate[_msgSender()] != 0 && _nextClaimDate[_msgSender()] < block.timestamp) {
			_claimRewards(_msgSender());
		}
		// update next claim date
		_nextClaimDate[_msgSender()] = block.timestamp + _pool.stakePeriod;
		if (isNew) {
			_countStakers = _countStakers.add(1);
			_firstStake[_msgSender()] = block.timestamp;
		}
		emit StakeTokenSuccessfully(_msgSender(), totalAmount, tax, amount, _nextClaimDate[_msgSender()]);
	}

	/**
	 * Estimate how much reward the staker can get when the stake period is over
	 */
	function _estimatedRewards(address account) private view returns (uint256) {
		uint256 stakerBalance = _userStakes[account];
		uint256 minUserStake = _pool.minUserStakesForReward;
		if (stakerBalance < minUserStake) {
			return 0;
		}
		if (_nextClaimDate[account] == 0) {
			return 0;
		}
		if (_nextClaimDate[account] > block.timestamp) {
			return 0;
		}
		uint256 poolAmount = _rewardPool;
		if (_pool.stakePeriod > 0) {
			uint256 elapsedPeriod = ((block.timestamp.sub(_nextClaimDate[account])).div(_pool.stakePeriod)).add(1);
			poolAmount = _pool.rewardTokensByPeriod.mul(elapsedPeriod);
		}
		if (poolAmount > _rewardPool) {
			poolAmount = _rewardPool;
		}
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = _pool.minStakersForFullReward;
			uint256 minTotalStaked = _pool.minTotalStakedForFullReward;
			if (minTotalStaked == 0 ||_totalStaked >= minTotalStaked) {
				minTotalStaked = _totalStaked;
			}
			if (_countStakers < minStakers) {
				if (minTotalStaked > 0) {
					rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				}
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				if (minStakers > 0) {
					rewardPercentage = mulScale(rewardPercentage,_countStakers,uint128(minStakers));
				}
			} else {
				if (minTotalStaked > 0) {
					rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				}
			}
			uint256 reward = mulScale(poolAmount,rewardPercentage,1000000);
			// initial percentage changed, take as mush as current pool amount.
			if (reward > _rewardPool) {
				if (_totalStaked == stakerBalance) {
					reward = _rewardPool;	
				} else {
					reward = mulScale(_rewardPool,rewardPercentage,1000000);
				}
			}
			return reward;
		} else {
			return 0;
		}
	}

	/**
	 * Estimate how much reward the staker could get at claim date
	 */
	function estimatedRewards(address account) public view returns (uint256) {
		if (_nextClaimDate[account] != 0 && _nextClaimDate[account] <= block.timestamp) {
			return _estimatedRewards(account);
		}
		uint256 stakerBalance = _userStakes[account];
		uint256 minUserStakes = _pool.minUserStakesForReward;
		if (stakerBalance < minUserStakes) {
			return 0;
		}
		uint256 poolAmount = _pool.rewardTokensByPeriod;
		if (poolAmount > _rewardPool) {
			poolAmount = _rewardPool;
		}
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = _pool.minStakersForFullReward;
			uint256 minTotalStaked = _pool.minTotalStakedForFullReward;
			if (minTotalStaked == 0 || _totalStaked >= minTotalStaked) {
				minTotalStaked = _totalStaked;
			}
			if (_countStakers < minStakers) {
				if (minTotalStaked > 0) {
					rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				}
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				if (minStakers > 0) {
					rewardPercentage = mulScale(rewardPercentage,_countStakers,uint128(minStakers));
				}
			} else {
				if (minTotalStaked > 0) {
					rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				}
			}
			uint256 reward = mulScale(poolAmount,rewardPercentage,1000000);
			// initial percentage changed, take as mush as current pool amount.
			if (reward > _rewardPool) {
				if (_totalStaked == stakerBalance) {
					reward = _rewardPool;	
				} else {
					reward = mulScale(_rewardPool,rewardPercentage,1000000);
				}
			}
			return reward;
		} else {
			return 0;
		}
	}
	
	function estimatedMyRewards() public view returns (uint256) {
		return estimatedRewards(_msgSender());
	}

	function _claimRewards(address account) private {
		if (_nextClaimDate[account] == 0) {
			return;
		}
		address rewardTokenAddress = _pool.rewardToken;
		address tokenAddress = _pool.stakedToken;
		if (_nextClaimDate[account] <= block.timestamp) {
			uint256 reward = _estimatedRewards(account);
			// next claim, next period.
			_nextClaimDate[account] = block.timestamp + _pool.stakePeriod;
			if (reward > 0) {
				// remove rewards from pool
				_rewardPool = _rewardPool.sub(reward);
				// add reward to total reward
				_totalRewards = _totalRewards.add(reward);
				if (rewardTokenAddress == tokenAddress) {
					// add automatically to user stakes
					_userStakes[account] = _userStakes[account].add(reward);
					_userRewards[account] = _userRewards[account].add(reward);
				} else {
					_userRewards[account] = _userRewards[account].add(reward);
				}
			}
			emit ClaimRewardSuccessfully(account, reward, _nextClaimDate[account]);
		}
	}

	function claimRewards() public isHuman nonReentrant {
		if (_nextClaimDate[_msgSender()] != 0 && _nextClaimDate[_msgSender()] < block.timestamp) {
			_claimRewards(_msgSender());
		}
	}

	function _retrieveRewards(address account,bool fromUnstake) private {
		// Check LDOGE Holdings
		if (!fromUnstake) {
			require(hasMinimumLdogeHolding(_msgSender()),"Not holding enough LDOGE");
		}
		address rewardTokenAddress = _pool.rewardToken;
		address tokenAddress = _pool.stakedToken;
		if (_nextClaimDate[account] != 0 && _nextClaimDate[account] < block.timestamp) {
			_claimRewards(account);
		}
		uint256 rewardBalance = _userRewards[account];
		if (rewardBalance > _totalRewards) {
			rewardBalance = _totalRewards;
		}
		uint256 maxToRetrieve = IBEP20(rewardTokenAddress).balanceOf(address(this));
		if (rewardBalance > maxToRetrieve) {
			rewardBalance = maxToRetrieve;
		}
		uint256 unstakeTax = _pool.unstakeRewardTax;
		// take tax fee
		uint256 totalToRemove = rewardBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(totalToRemove,unstakeTax,1000000);
		if (tax != 0) {
			rewardBalance = totalToRemove - tax;
			// add tax to reward pool
			_rewardPool = _rewardPool + tax;
		}
		if (rewardTokenAddress == tokenAddress) {
			_userStakes[account] = _userStakes[account].sub(_userRewards[account]);
		}
		_totalRewards = _totalRewards.sub(_userRewards[account]);
		// remove reward from user reward
		_userRewards[account] = 0;
		if (rewardBalance == 0) {
			return;
		}
		// send token
		bool sent = IBEP20(rewardTokenAddress).transfer(account,rewardBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		emit RetrieveRewardSuccessfully(account, rewardBalance);
	}

	function retrieveRewards(address account) public authorizedCallers nonReentrant {
		_retrieveRewards(account,false);
	}

	function retrieveMyRewards() public isHuman nonReentrant {
		_retrieveRewards(_msgSender(),false);
	}
	
	function getUserRewards(address account) external view returns (uint256) {
		return _userRewards[account];
	}	

	function getUserStakes(address account) external view returns (uint256) {
		uint256 stakerBalance = _userStakes[account];
		if (_pool.stakedToken == _pool.rewardToken && stakerBalance > 0) {
			stakerBalance = stakerBalance.sub(_userRewards[account]);
		}
		return stakerBalance;
	}	

	function _unstakeTokens(address account,uint256 amount) private {
		// Check LDOGE Holdings
		require(hasMinimumLdogeHolding(_msgSender()),"Not holding enough LDOGE");
		if (_pool.minStakeTime > 0) {
		    require(((_firstStake[_msgSender()] + _pool.minStakeTime) <= block.timestamp),"Cannot unstake before _minStakeTime.");
		}
		address tokenAddress = _pool.stakedToken;
		if (_nextClaimDate[account] != 0 && _nextClaimDate[account] < block.timestamp) {
			_claimRewards(account);
		}
		_retrieveRewards(account,true);
		uint256 stakerBalance = _userStakes[account];
		if (amount == 0) {
			amount = stakerBalance;
		}
		require(stakerBalance > 0,"No tokens to unstake");
		if (amount > stakerBalance) {
			amount = stakerBalance;
		}
		// take tax fee
		uint256 unstakeTax = _pool.unstakeTax;
		uint256 totalToRemove = amount;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(amount,unstakeTax,1000000);
		// remove tax from staked amount
		if (tax > 0) {
			amount = amount.sub(tax);
			if (!_pool.keepTax && _pool.stakedToken == _pool.rewardToken) {
				_rewardPool = _rewardPool.add(tax);
			} else {
				_taxPool = _taxPool.add(tax);
			}
		}
		_totalStaked = _totalStaked.sub(totalToRemove);
		if (_userStakes[account] >= totalToRemove) {
    		_userStakes[account] = _userStakes[account].sub(totalToRemove);
		} else {
		    _userStakes[account] = 0;
		}
		_userRewards[account] = 0;
		if (amount > 0) {
			bool sent = IBEP20(tokenAddress).transfer(account,amount);
			require(sent, 'Error: Cannot withdraw TOKEN');
		}
		if (_countStakers >= 1 && _userStakes[account] == 0) {
			_countStakers = _countStakers.sub(1);
			_firstStake[account] = 0;
		}
		emit UnstakeTokenSuccessfully(account, amount);
	}

	function unstakeMyTokens() public isHuman nonReentrant {
		_unstakeTokens(_msgSender(),0);
	}

	function unstakeMyTokensAmount(uint256 amount) public isHuman nonReentrant {
		_unstakeTokens(_msgSender(),amount);
	}

	function canDoOperation(bool unstake) public view returns (bool) {
		if (hasMinimumLdogeHolding(_msgSender())) {
			if (unstake && _pool.minStakeTime > 0 && ((_firstStake[_msgSender()] + _pool.minStakeTime) > block.timestamp)) {
				return false;
			}
			return true;
		}
		return false;
	}

	// Retrieve the tokens in the Reward pool for the given tokenAddress
	function retrieveRewardTokens() external nonReentrant authorizedCallers timeLockOperationOrNeedVote {
		address tokenAddress = _pool.rewardToken;
		uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		uint256 toRetrieve = _rewardPool;
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, 'Error: Cannot withdraw TOKEN not enough fund.');
		_rewardPool = 0;
		bool sent = IBEP20(tokenAddress).transfer(_retrieveFundWallet,toRetrieve);
		require(sent, 'Error: Cannot withdraw TOKEN');
	}

	/** 
	 * Retrieve the tokens in the contract balance for the given tokenAddress which are not of the pool token type
	 */
	function retrieveTokens(address tokenAddress,uint256 amount) external nonReentrant authorizedCallers timeLockOperationOrNeedVote {
		if (tokenAddress == address(0)) {
			uint256 toRetrieve = address(this).balance;
			if (amount > toRetrieve || amount == 0) {
				amount = toRetrieve;
			}
			(bool sent,) = address(_retrieveFundWallet).call{value : amount}("");
			require(sent, 'Error: Cannot withdraw BNB');
		} else {
			require(tokenAddress != _pool.rewardToken,"Cannot remove type of tokens of this pools. Use retrieveRewardTokens or unstake.");
			uint256 toRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
			if (tokenAddress == _pool.stakedToken) {
				amount = _taxPool;
				_taxPool = 0;
			}
			if (amount > toRetrieve) {
				amount = toRetrieve;
			}
			require(amount > 0, 'Error: Cannot withdraw TOKEN not enough fund.');
			bool sent = IBEP20(tokenAddress).transfer(_retrieveFundWallet,amount);
			require(sent, 'Error: Cannot withdraw TOKEN');
		}
	}
}

contract LegatoFactory is Ownable {
	using SafeMath for uint256;
	using Address for address;
	
	function createNewPool(StakePool.Pool memory pool) external onlyOwner returns (address) {
		return address(new Legato(pool));
	}
}


contract LegatoCreator is Context, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;
	
	uint256 public _poolIndex = 0;
	address public _vault;
	address public _ldogeToken;
	address public _WBNB;
	address public _BUSD;
	address public _LegatoV1Address;
	address public _LDOGE_WBNB_pair;
	address public _BUSD_WBNB_pair;
	uint256 public _creationFeePrice;
	uint256 public _minimumLDOGEHoldingsInDollars;
	uint256 public _minimumLDOGEHoldingsInLDOGE;
	LegatoFactory public _factory;
	mapping(uint256 => address) public _pools;
	mapping(address => uint256) public creationFeesReceived;

	struct NewPoolInfo {
		address stakedToken;
		address rewardToken;
		uint256 stakeTax;
		uint256 unstakeTax;
		uint256 unstakeRewardTax;
		uint256 stakePeriod;
		uint256 rewardTokensByPeriod;
		uint256 minTotalStakedForFullReward;
		uint256 minStakersForFullReward;
		uint256 minUserStakesForReward;
		uint256 minStakeTime;
		bool keepTax;
	}

	constructor (address vault,address ldogeToken,address WBNB,address BUSD,address LegatoV1Address,address LDOGE_WBNB_pair,address BUSD_WBNB_pair,uint256 minimumLDOGEHoldingsInDollars,uint256 minimumLDOGEHoldingsInLDOGE,uint256 creationFeePrice) {
		_vault = vault;
		_ldogeToken = ldogeToken;
		_WBNB = WBNB;
		_BUSD = BUSD;
		_LegatoV1Address = LegatoV1Address;
		_LDOGE_WBNB_pair = LDOGE_WBNB_pair;
		_BUSD_WBNB_pair = BUSD_WBNB_pair;
		_factory = new LegatoFactory();
		_minimumLDOGEHoldingsInDollars = minimumLDOGEHoldingsInDollars;
		if (minimumLDOGEHoldingsInDollars == 0) {
			_minimumLDOGEHoldingsInLDOGE = minimumLDOGEHoldingsInLDOGE;
		}
		_creationFeePrice = creationFeePrice;
	}
	
	function setFees(uint256 minimumLDOGEHoldingsInDollars,uint256 minimumLDOGEHoldingsInLDOGE,uint256 creationFeePrice) external authorizedCallers {
		require(!(minimumLDOGEHoldingsInLDOGE > 0 && minimumLDOGEHoldingsInDollars > 0),"LDOGE or Dollars not both.");
		_minimumLDOGEHoldingsInDollars = minimumLDOGEHoldingsInDollars;
		_minimumLDOGEHoldingsInLDOGE = minimumLDOGEHoldingsInLDOGE;
		_creationFeePrice = creationFeePrice;
	}

	function getPoolInfoByAddress(address pool) external view returns (StakePool.Pool memory) {
		return StakePool(pool).getPool();
	}

	function getPoolInfoByIndex(uint256 pool) external view returns (StakePool.Pool memory) {
		return StakePool(_pools[pool]).getPool();
	}
	
	receive() external payable {
		(bool sent,) = address(_vault).call{value : msg.value}("");
		require(sent, 'Error: Cannot withdraw BNB');
		creationFeesReceived[_msgSender()].add(msg.value);
	}

	function _deposit(uint256 WBNBamount) private {
		IBEP20(_WBNB).transferFrom(_msgSender(),address(_vault),WBNBamount);
		creationFeesReceived[_msgSender()].add(WBNBamount);
	}
	
	function deposit(uint256 WBNBamount) public nonReentrant {
		_deposit(WBNBamount);
	}

	function retrieveTokens(address tokenAddress,uint256 amount) external nonReentrant authorizedCallers timeLockOperationOrNeedVote {
		if (tokenAddress == address(0)) {
			uint256 toRetrieve = address(this).balance;
			if (amount > toRetrieve || amount == 0) {
				amount = toRetrieve;
			}
			(bool sent,) = address(_vault).call{value : amount}("");
			require(sent, 'Error: Cannot withdraw BNB');
		} else {
			uint256 toRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
			if (amount > toRetrieve) {
				amount = toRetrieve;
			}
			require(amount > 0, 'Error: Cannot withdraw TOKEN not enough fund.');
			bool sent = IBEP20(tokenAddress).transfer(_vault,amount);
			require(sent, 'Error: Cannot withdraw TOKEN');
		}
	}
	
	function _createNewPool(NewPoolInfo memory info) private returns (address) {
		if (!_authorizedCallers[_msgSender()]) {
			require(creationFeesReceived[_msgSender()] >= _creationFeePrice,"You must first pay the pool creation fee.");
			creationFeesReceived[_msgSender()].sub(_creationFeePrice);
		}
		StakePool.Pool memory pool;
		if (!_authorizedCallers[_msgSender()]) {
    		pool.minimumLDOGEHoldingsInDollars = _minimumLDOGEHoldingsInDollars;
		    pool.minimumLDOGEHoldingsInLDOGE = _minimumLDOGEHoldingsInLDOGE;
    		pool.poolCreator = owner();
		} else {
		    pool.minimumLDOGEHoldingsInDollars = 0;
		    pool.minimumLDOGEHoldingsInLDOGE = 0;
    		pool.poolCreator = _msgSender();
		}
		pool.ldogeToken = _ldogeToken;
		pool.WBNB = _WBNB;
		pool.BUSD = _BUSD;
		pool.LegatoV1Address = _LegatoV1Address;
		pool.LDOGE_WBNB_pair = _LDOGE_WBNB_pair;
        pool.BUSD_WBNB_pair = _BUSD_WBNB_pair;
		pool.parentOwner = _msgSender();
		pool.stakedToken = info.stakedToken;
		pool.rewardToken = info.rewardToken;
		pool.stakeTax = info.stakeTax;
		pool.unstakeTax = info.unstakeTax;
		pool.unstakeRewardTax = info.unstakeRewardTax;
		pool.stakePeriod = info.stakePeriod;
		pool.rewardTokensByPeriod = info.rewardTokensByPeriod;
		pool.minTotalStakedForFullReward = info.minTotalStakedForFullReward;
		pool.minStakersForFullReward = info.minStakersForFullReward;
		pool.minUserStakesForReward = info.minUserStakesForReward;
		pool.minStakeTime = info.minStakeTime;
		pool.keepTax = info.keepTax;
		address newPoolAddress = _factory.createNewPool(pool);
		_pools[_poolIndex++] = newPoolAddress;
		return newPoolAddress;
	}

	function createNewPool(NewPoolInfo memory info) external nonReentrant returns (address) {
		return _createNewPool(info);
	}

	function createNewPoolAndAddReward(NewPoolInfo memory info,uint256 rewardAmount) external nonReentrant returns (address) {
		address newPoolAddress = _createNewPool(info);
		StakePool(newPoolAddress).addRewardToPool(rewardAmount);
		return newPoolAddress;
	}
	
	function createNewPoolAndPay(NewPoolInfo memory info) external nonReentrant returns (address) {
		_deposit(_creationFeePrice);
		return _createNewPool(info);
	}

	function createNewPoolAndPayAndAddReward(NewPoolInfo memory info,uint256 rewardAmount) external nonReentrant returns (address) {
		_deposit(_creationFeePrice);
		address newPoolAddress = _createNewPool(info);
		StakePool(newPoolAddress).addRewardToPool(rewardAmount);
		return newPoolAddress;
	}
}