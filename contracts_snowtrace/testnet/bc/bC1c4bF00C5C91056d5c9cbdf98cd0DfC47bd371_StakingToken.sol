/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-19
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/IERC20Historical.sol


pragma solidity 0.8.9;

interface IERC20Historical is IERC20
{
	function totalSupply(uint256 _when) external view returns (uint256 _totalSupply);
	function balanceOf(address _account, uint256 _when) external view returns (uint256 _balance);

	function checkpoint() external;
}

interface IERC20HistoricalCumulative is IERC20Historical
{
	function cumulativeTotalSupply(uint256 _when) external view returns (uint256 _cumulativeTotalSupply);
	function cumulativeBalanceOf(address _account, uint256 _when) external view returns (uint256 _cumulativeBalance);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/DelayedActionGuard.sol


pragma solidity 0.8.9;

abstract contract DelayedActionGuard
{
	uint256 private constant DEFAULT_WAIT_INTERVAL = 1 days;
	uint256 private constant DEFAULT_OPEN_INTERVAL = 1 days;

	struct DelayedAction {
		uint256 release;
		uint256 expiration;
	}

	mapping (address => mapping (bytes32 => DelayedAction)) private actions_;

	modifier delayed()
	{
		bytes32 _actionId = keccak256(msg.data);
		DelayedAction storage _action = actions_[msg.sender][_actionId];
		require(_action.release <= block.timestamp && block.timestamp < _action.expiration, "invalid action");
		delete actions_[msg.sender][_actionId];
		emit ExecuteDelayedAction(msg.sender, _actionId);
		_;
	}

	function announceDelayedAction(bytes calldata _data) external
	{
		bytes4 _selector = bytes4(_data);
		bytes32 _actionId = keccak256(_data);
		(uint256 _wait, uint256 _open) = _delayedActionIntervals(_selector);
		uint256 _release = block.timestamp + _wait;
		uint256 _expiration = _release + _open;
		actions_[msg.sender][_actionId] = DelayedAction({ release: _release, expiration: _expiration });
		emit AnnounceDelayedAction(msg.sender, _actionId, _selector, _data, _release, _expiration);
	}

	function _delayedActionIntervals(bytes4 _selector) internal pure virtual returns (uint256 _wait, uint256 _open)
	{
		_selector;
		return (DEFAULT_WAIT_INTERVAL, DEFAULT_OPEN_INTERVAL);
	}

	event AnnounceDelayedAction(address indexed _sender, bytes32 indexed _actionId, bytes4 indexed _selector, bytes _data, uint256 _release, uint256 _expiration);
	event ExecuteDelayedAction(address indexed _sender, bytes32 indexed _actionId);
}


// File contracts/RewardDistributor.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;





contract RewardDistributor is Ownable, ReentrancyGuard, DelayedActionGuard
{
	using SafeERC20 for IERC20;

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	uint256 public constant CLAIM_BASIS = 10 minutes;
	uint256 public constant MIN_ALLOC_TIME = 1 minutes;

	uint256 constant DEFAULT_PENALTY_RATE = 50e16; // 50%
	uint256 constant DEFAULT_PENALTY_PERIODS = 1; // 10 minutes
	uint256 constant MAXIMUM_PENALTY_PERIODS = 5 * 52 * 7 * 24 * 6; // ~5 years

	address public immutable rewardToken;
	address public immutable escrowToken;
	address public immutable boostToken;

	address private immutable escrowOwnership_;
	address private immutable boostOwnership_;

	address public treasury;

	uint256 public penaltyRate = DEFAULT_PENALTY_RATE;
	uint256 public penaltyPeriods = DEFAULT_PENALTY_PERIODS;
	address public penaltyRecipient = FURNACE;

	uint256 private lastAlloc_;
	uint256 private rewardBalance_;
	mapping(uint256 => uint256) private rewardPerPeriod_;

	uint256 private immutable firstPeriod_;
	mapping(address => uint256) private lastPeriod_;

	constructor(address _rewardToken, address _escrowToken, bool _escrowCumulative, address _boostToken, bool _boostCumulative, address _treasury)
	{
		address _escrowOwnership = _escrowCumulative ? address(new _CumulativeOwnership(_escrowToken, CLAIM_BASIS)) : address(new _Ownership(_escrowToken));
		address _boostOwnership = address(0);
		if (_boostToken != address(0)) {
			_boostOwnership = _boostCumulative ? address(new _CumulativeOwnership(_boostToken, CLAIM_BASIS)) : address(new _Ownership(_boostToken));
		}
		rewardToken = _rewardToken;
		escrowToken = _escrowToken;
		boostToken = _boostToken;
		escrowOwnership_ = _escrowOwnership;
		boostOwnership_ = _boostOwnership;
		treasury = _treasury;
		lastAlloc_ = block.timestamp;
		firstPeriod_ = (block.timestamp / CLAIM_BASIS + 1) * CLAIM_BASIS;
	}

	function unallocated() external view returns (uint256 _amount)
	{
		uint256 _oldTime = lastAlloc_;
		uint256 _newTime = block.timestamp;
		uint256 _time = _newTime - _oldTime;
		if (_time < MIN_ALLOC_TIME) return 0;
		uint256 _oldBalance = rewardBalance_;
		uint256 _newBalance = IERC20(rewardToken).balanceOf(address(this));
		uint256 _balance = _newBalance - _oldBalance;
		return _balance;
	}

	function allocate() public returns (uint256 _amount)
	{
		uint256 _oldTime = lastAlloc_;
		uint256 _newTime = block.timestamp;
		uint256 _time = _newTime - _oldTime;
		if (_time < MIN_ALLOC_TIME) return 0;
		uint256 _oldBalance = rewardBalance_;
		uint256 _newBalance = IERC20(rewardToken).balanceOf(address(this));
		uint256 _balance = _newBalance - _oldBalance;
		lastAlloc_ = _newTime;
		rewardBalance_ = _newBalance;
		if (_balance > 0) {
			uint256 _start = _oldTime;
			uint256 _period = (_start / CLAIM_BASIS) * CLAIM_BASIS;
			while (true) {
				uint256 _nextPeriod = _period + CLAIM_BASIS;
				uint256 _end = _nextPeriod < _newTime ? _nextPeriod : _newTime;
				rewardPerPeriod_[_nextPeriod] += _balance * (_end - _start) / _time;
				if (_end == _newTime) break;
				_start = _end;
				_period = _nextPeriod;
			}
			emit Allocate(_balance);
		}
		return _balance;
	}

	function available(address _account, bool _noPenalty) external view returns (uint256 _amount, uint256 _penalty)
	{
		uint256 _lastAlloc = block.timestamp - lastAlloc_ < MIN_ALLOC_TIME ? lastAlloc_ : block.timestamp;
		(_amount, _penalty,,) = _claim(_account, _noPenalty, _lastAlloc);
		return (_amount, _penalty);
	}

	function claim(bool _noPenalty) external nonReentrant returns (uint256 _amount, uint256 _penalty)
	{
		IERC20Historical(escrowToken).checkpoint();
		if (boostToken != address(0)) {
			IERC20Historical(boostToken).checkpoint();
		}
		allocate();
		uint256 _excess;
		(_amount, _penalty, _excess, lastPeriod_[msg.sender]) = _claim(msg.sender, _noPenalty, lastAlloc_);
		uint256 _total = _amount + _penalty + _excess;
		if (_total > 0) {
			rewardBalance_ -= _total;
			if (_amount > 0) {
				IERC20(rewardToken).safeTransfer(msg.sender, _amount);
			}
			if (_penalty > 0) {
				IERC20(rewardToken).safeTransfer(penaltyRecipient, _penalty);
			}
			emit Claim(msg.sender, _amount, _penalty, _excess);
		}
		return (_amount, _penalty);
	}

	function _claim(address _account, bool _noPenalty, uint256 _lastAlloc) internal view returns (uint256 _amount, uint256 _penalty, uint256 _excess, uint256 _period)
	{
		uint256 _firstPeriod = lastPeriod_[_account];
		if (_firstPeriod < firstPeriod_) _firstPeriod = firstPeriod_;
		uint256 _lastPeriod = (_lastAlloc / CLAIM_BASIS + 1) * CLAIM_BASIS;
		uint256 _middlePeriod =_lastPeriod - penaltyPeriods * CLAIM_BASIS;
		if (_middlePeriod < _firstPeriod) _middlePeriod = _firstPeriod;
		if (_noPenalty) _lastPeriod = _middlePeriod;
		(uint256 _amount1, uint256 _excess1) = _calculateAccruedClaim(_account, _firstPeriod, _middlePeriod);
		(uint256 _amount2, uint256 _excess2) = _calculateAccruedClaim(_account, _middlePeriod, _lastPeriod);
		_penalty = _amount2 * penaltyRate / 100e16;
		_amount = _amount1 + (_amount2 - _penalty);
		_excess = _excess1 + _excess2;
		return (_amount, _penalty, _excess, _lastPeriod);
	}

	function _calculateAccruedClaim(address _account, uint256 _firstPeriod, uint256 _lastPeriod) internal view returns (uint256 _amount, uint256 _excess)
	{
		_amount = 0;
		_excess = 0;
		if (boostToken == address(0)) {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = _IOwnership(escrowOwnership_).totalOwnership(_period);
				if (_total > 0) {
					uint256 _local = _IOwnership(escrowOwnership_).localOwnership(_account, _period);
					uint256 _rewardPerPeriod = rewardPerPeriod_[_period];
					_amount += _rewardPerPeriod * _local / _total;
				}
			}
		} else {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = _IOwnership(escrowOwnership_).totalOwnership(_period);
				uint256 _boostTotal = _IOwnership(boostOwnership_).totalOwnership(_period);
				uint256 _normalizedTotal = 10 * _total * _boostTotal;
				if (_normalizedTotal > 0) {
					uint256 _local = _IOwnership(escrowOwnership_).localOwnership(_account, _period);
					uint256 _boostLocal = _IOwnership(boostOwnership_).localOwnership(_account, _period);
					uint256 _isolatedLocal = 10 * _local * _boostTotal;
					uint256 _normalizedLocal = 4 * _local * _boostTotal + 6 * _total * _boostLocal;
					uint256 _limitedLocal = _normalizedLocal > _isolatedLocal ? _isolatedLocal : _normalizedLocal;
					uint256 _exceededLocal = _normalizedLocal - _limitedLocal;
					uint256 _rewardPerPeriod = rewardPerPeriod_[_period];
					_amount += _rewardPerPeriod * _limitedLocal / _normalizedTotal;
					_excess += _rewardPerPeriod * _exceededLocal / _normalizedTotal;
				}
			}
		}
		return (_amount, _excess);
	}

	function unrecycled() external view returns (uint256 _amount)
	{
		uint256 _lastAlloc = block.timestamp - lastAlloc_ < MIN_ALLOC_TIME ? lastAlloc_ : block.timestamp;
		(_amount,) = _recycle(_lastAlloc);
		return _amount;
	}

	function recycle() external returns (uint256 _amount)
	{
		IERC20Historical(escrowToken).checkpoint();
		if (boostToken != address(0)) {
			IERC20Historical(boostToken).checkpoint();
		}
		allocate();
		(_amount, lastPeriod_[address(0)]) = _recycle(lastAlloc_);
		if (_amount > 0) {
			rewardBalance_ -= _amount;
			emit Recycle(_amount);
		}
		return _amount;
	}

	function _recycle(uint256 _lastAlloc) internal view returns (uint256 _amount, uint256 _period)
	{
		uint256 _firstPeriod = lastPeriod_[address(0)];
		if (_firstPeriod < firstPeriod_) _firstPeriod = firstPeriod_;
		uint256 _lastPeriod = (_lastAlloc / CLAIM_BASIS + 1) * CLAIM_BASIS;
		_amount = _calculateAccruedRecycle(_firstPeriod, _lastPeriod);
		return (_amount, _lastPeriod);
	}

	function _calculateAccruedRecycle(uint256 _firstPeriod, uint256 _lastPeriod) internal view returns (uint256 _amount)
	{
		_amount = 0;
		if (boostToken == address(0)) {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = _IOwnership(escrowOwnership_).totalOwnership(_period);
				if (_total == 0) {
					_amount += rewardPerPeriod_[_period];
				}
			}
		} else {
			for (uint256 _period = _firstPeriod; _period < _lastPeriod; _period += CLAIM_BASIS) {
				uint256 _total = _IOwnership(escrowOwnership_).totalOwnership(_period);
				uint256 _boostTotal = _IOwnership(boostOwnership_).totalOwnership(_period);
				uint256 _normalizedTotal = 10 * _boostTotal * _total;
				if (_normalizedTotal == 0) {
					_amount += rewardPerPeriod_[_period];
				}
			}
		}
		return _amount;
	}

	function recoverLostFunds(address _token) external onlyOwner nonReentrant
	{
		require(_token != rewardToken, "invalid token");
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).safeTransfer(treasury, _balance);
	}

	function setTreasury(address _newTreasury) external onlyOwner
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	function setPenaltyParams(uint256 _newPenaltyRate, uint256 _newPenaltyPeriods, address _newPenaltyRecipient) external onlyOwner delayed
	{
		require(_newPenaltyRate <= 100e16, "invalid rate");
		require(_newPenaltyPeriods <= MAXIMUM_PENALTY_PERIODS, "invalid periods");
		require(_newPenaltyRecipient != address(0), "invalid recipient");
		(uint256 _oldPenaltyRate, uint256 _oldPenaltyPeriods, address _oldPenaltyRecipient) = (penaltyRate, penaltyPeriods, penaltyRecipient);
		(penaltyRate, penaltyPeriods, penaltyRecipient) = (_newPenaltyRate, _newPenaltyPeriods, _newPenaltyRecipient);
		emit ChangePenaltyParams(_oldPenaltyRate, _oldPenaltyPeriods, _oldPenaltyRecipient, _newPenaltyRate, _newPenaltyPeriods, _newPenaltyRecipient);
	}

	event Allocate(uint256 _amount);
	event Claim(address indexed _account, uint256 _amount, uint256 _penalty, uint256 _excess);
	event Recycle(uint256 _amount);
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
	event ChangePenaltyParams(uint256 _oldPenaltyRate, uint256 _oldPenaltyPeriods, address _oldPenaltyRecipient, uint256 _newPenaltyRate, uint256 _newPenaltyPeriods, address _newPenaltyRecipient);
}

interface _IOwnership
{
	function totalOwnership(uint256 _when) external view returns (uint256 _totalOwnership);
	function localOwnership(address _account, uint256 _when) external view returns (uint256 _localOwnership);
}

contract _Ownership is _IOwnership
{
	address private immutable token_;

	constructor(address _token)
	{
		token_ = _token;
	}

	function totalOwnership(uint256 _when) external view override returns (uint256 _totalOwnership)
	{
		return IERC20Historical(token_).totalSupply(_when);
	}

	function localOwnership(address _account, uint256 _when) external view override returns (uint256 _localOwnership)
	{
		return IERC20Historical(token_).balanceOf(_account, _when);
	}
}

contract _CumulativeOwnership is _IOwnership
{
	address private immutable token_;
	uint256 private immutable period_;

	constructor(address _token, uint256 _period)
	{
		token_ = _token;
		period_ = _period;
	}

	function totalOwnership(uint256 _when) external view override returns (uint256 _totalOwnership)
	{
		return IERC20HistoricalCumulative(token_).cumulativeTotalSupply(_when) - IERC20HistoricalCumulative(token_).cumulativeTotalSupply(_when - period_);
	}

	function localOwnership(address _account, uint256 _when) external view override returns (uint256 _localOwnership)
	{
		return IERC20HistoricalCumulative(token_).cumulativeBalanceOf(_account, _when) - IERC20HistoricalCumulative(token_).cumulativeBalanceOf(_account, _when - period_);
	}
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/StakingToken.sol


pragma solidity 0.8.9;





contract StakingToken is IERC20HistoricalCumulative, Ownable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	struct UserInfo {
		uint256 amount;
	}

	struct Point {
		uint256 bias;
		uint256 area;
		uint256 time;
	}

	uint8 private immutable decimals_;

	address public immutable reserveToken;

	mapping(address => UserInfo) public userInfo;

	Point[] private points_;
	mapping(address => Point[]) private userPoints_;

	bool public emergencyMode;

	constructor(string memory _name, string memory _symbol, uint8 _decimals, address _reserveToken)
		ERC20(_name, _symbol)
	{
		decimals_ = _decimals;
		reserveToken = _reserveToken;
		_appendPoint(points_, 0, 0, block.timestamp);
	}

	modifier nonEmergency()
	{
		require(!emergencyMode, "not available");
		_;
	}

	function decimals() public view override returns (uint8 _decimals)
	{
		return decimals_;
	}

	function enterEmergencyMode() external onlyOwner nonEmergency
	{
		emergencyMode = true;
		emit EmergencyDeclared();
	}

	function deposit(uint256 _amount) external nonReentrant nonEmergency
	{
		UserInfo storage _user = userInfo[msg.sender];
		uint256 _oldAmount = _user.amount;
		uint256 _newAmount = _oldAmount + _amount;
		_user.amount = _newAmount;
		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);
		_mint(msg.sender, _amount);
		_checkpoint(msg.sender, _newAmount, totalSupply());
		emit Deposit(msg.sender, _amount);
	}

	function withdraw(uint256 _amount) external nonReentrant
	{
		UserInfo storage _user = userInfo[msg.sender];
		uint256 _oldAmount = _user.amount;
		require(_amount <= _oldAmount, "insufficient balance");
		uint256 _newAmount = _oldAmount - _amount;
		_user.amount = _newAmount;
		_burn(msg.sender, _amount);
		IERC20(reserveToken).safeTransfer(msg.sender, _amount);
		if (!emergencyMode) {
			_checkpoint(msg.sender, _newAmount, totalSupply());
		}
		emit Withdraw(msg.sender, _amount);
	}

	function checkpoint() external override nonEmergency
	{
	}

	function totalSupply(uint256 _when) external override view returns (uint256 _totalSupply)
	{
		Point[] storage _points = points_;
		uint256 _index = _findPoint(_points, _when);
		if (_index == 0) return 0;
		Point storage _point = _points[_index - 1];
		return _point.bias;
	}

	function balanceOf(address _account, uint256 _when) external override view returns (uint256 _balance)
	{
		Point[] storage _points = userPoints_[_account];
		uint256 _index = _findPoint(_points, _when);
		if (_index == 0) return 0;
		Point storage _point = _points[_index - 1];
		return _point.bias;
	}

	function cumulativeTotalSupply(uint256 _when) external override view returns (uint256 _cumulativeTotalSupply)
	{
		Point[] storage _points = points_;
		uint256 _index = _findPoint(_points, _when);
		if (_index == 0) return 0;
		Point storage _point = _points[_index - 1];
		uint256 _ellapsed = _when - _point.time;
		return _point.area + _point.bias * _ellapsed;
	}

	function cumulativeBalanceOf(address _account, uint256 _when) external override view returns (uint256 _cumulativeBalance)
	{
		Point[] storage _points = userPoints_[_account];
		uint256 _index = _findPoint(_points, _when);
		if (_index == 0) return 0;
		Point storage _point = _points[_index - 1];
		uint256 _ellapsed = _when - _point.time;
		return _point.area + _point.bias * _ellapsed;
	}

	function _findPoint(Point[] storage _points, uint256 _when) internal view returns (uint256 _index)
	{
		uint256 _min = 0;
		uint256 _max = _points.length;
		if (_when >= block.timestamp) return _max;
		while (_min < _max) {
			uint256 _mid = (_min + _max) / 2;
			if (_points[_mid].time <= _when)
				_min = _mid + 1;
			else
				_max = _mid;
		}
		return _min;
	}

	function _appendPoint(Point[] storage _points, uint256 _bias, uint256 _area, uint256 _time) internal
	{
		uint256 _length = _points.length;
		if (_length > 0) {
			Point storage _point = _points[_length - 1];
			if (_point.time == _time) {
				_point.bias = _bias;
				_point.area = _area;
				return;
			}
			require(_time > _point.time, "invalid time");
		}
		_points.push(Point({ bias: _bias, area: _area, time: _time }));
	}

	function _checkpoint(address _account, uint256 _balance, uint256 _totalSupply) internal
	{
		{
			Point[] storage _points = points_;
			Point storage _point = _points[_points.length - 1];
			uint256 _ellapsed = block.timestamp - _point.time;
			uint256 _area = _point.area + _point.bias * _ellapsed;
			_appendPoint(_points, _totalSupply, _area, block.timestamp);
		}
		{
			Point[] storage _points = userPoints_[_account];
			uint256 _area = 0;
			if (_points.length > 0) {
				Point storage _point = _points[_points.length - 1];
				uint256 _ellapsed = block.timestamp - _point.time;
				_area = _point.area + _point.bias * _ellapsed;
			}
			_appendPoint(_points, _balance, _area, block.timestamp);
		}
	}

	event Deposit(address indexed _account, uint256 _amount);
	event Withdraw(address indexed _account, uint256 _amount);
	event EmergencyDeclared();
}


// File contracts/ValueEscrowToken.sol


pragma solidity 0.8.9;




contract ValueEscrowToken is IERC20Historical, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct UserInfo {
		uint256 amount;
		uint256 unlock;
	}

	struct Point {
		uint256 bias;
		uint256 slope;
		uint256 time;
	}

	uint256 public constant UNLOCK_BASIS = 10 minutes;
	uint256 public constant MAX_LOCK_TIME = 4 days; // 4 days

	string public name;
	string public symbol;
	uint8 public immutable decimals;

	address public immutable reserveToken;

	mapping(address => UserInfo) public userInfo;

	Point[] private points_;
	mapping(address => Point[]) private userPoints_;
	mapping(uint256 => uint256) private slopeDecay_;

	bool public emergencyMode;

	constructor(string memory _name, string memory _symbol, uint8 _decimals, address _reserveToken)
	{
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		reserveToken = _reserveToken;
		_appendPoint(points_, 0, 0, block.timestamp);
	}

	modifier nonEmergency()
	{
		require(!emergencyMode, "not available");
		_;
	}

	function enterEmergencyMode() external onlyOwner nonEmergency
	{
		emergencyMode = true;
		emit EmergencyDeclared();
	}

	function deposit(uint256 _amount, uint256 _newUnlock) external nonReentrant nonEmergency
	{
		require(_newUnlock % UNLOCK_BASIS == 0 && block.timestamp < _newUnlock && _newUnlock <= block.timestamp + MAX_LOCK_TIME, "invalid unlock");
		UserInfo storage _user = userInfo[msg.sender];
		uint256 _oldUnlock = _user.unlock;
		require(_oldUnlock == 0 || _oldUnlock > block.timestamp, "expired unlock");
		require(_newUnlock >= _oldUnlock, "shortened unlock");
		uint256 _oldAmount = _user.amount;
		uint256 _newAmount = _oldAmount + _amount;
		_checkpoint(msg.sender, _oldAmount, _oldUnlock, _newAmount, _newUnlock);
		_user.amount = _newAmount;
		_user.unlock = _newUnlock;
		if (_amount > 0) {
			IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);
		}
		emit Deposit(msg.sender, _amount, _newUnlock);
	}

	function withdraw() external nonReentrant
	{
		UserInfo storage _user = userInfo[msg.sender];
		uint256 _unlock = _user.unlock;
		uint256 _amount = _user.amount;
		if (!emergencyMode) {
			require(block.timestamp >= _unlock, "not available");
			_checkpoint(msg.sender, _amount, _unlock, 0, 0);
		}
		_user.amount = 0;
		_user.unlock = 0;
		IERC20(reserveToken).safeTransfer(msg.sender, _amount);
		emit Withdraw(msg.sender, _amount);
	}

	function checkpoint() external override nonEmergency
	{
		Point[] storage _points = points_;
		Point storage _point = _points[_points.length - 1];
		if (block.timestamp >= _point.time + UNLOCK_BASIS) {
			_checkpoint(address(0), 0, 0, 0, 0);
		}
	}

	function totalSupply(uint256 _when) public override view returns (uint256 _totalSupply)
	{
		Point[] storage _points = points_;
		uint256 _index = _findPoint(_points, _when);
		if (_index == 0) return 0;
		Point storage _point = _points[_index - 1];
		uint256 _bias = _point.bias;
		uint256 _slope = _point.slope;
		uint256 _start = _point.time;
		uint256 _period = (_start / UNLOCK_BASIS) * UNLOCK_BASIS;
		while (true) {
			uint256 _nextPeriod = _period + UNLOCK_BASIS;
			uint256 _end = _nextPeriod < _when ? _nextPeriod : _when;
			uint256 _ellapsed = _end - _start;
			uint256 _maxEllapsed = _slope > 0 ? _bias / _slope : type(uint256).max;
			_bias = _ellapsed <= _maxEllapsed ? _bias - _slope * _ellapsed : 0;
			if (_end == _nextPeriod) _slope -= slopeDecay_[_nextPeriod];
			if (_end == _when) break;
			_start = _end;
			_period = _nextPeriod;
		}
		return _bias;
	}

	function balanceOf(address _account, uint256 _when) public override view returns (uint256 _balance)
	{
		Point[] storage _points = userPoints_[_account];
		uint256 _index = _findPoint(_points, _when);
		if (_index == 0) return 0;
		Point storage _point = _points[_index - 1];
		uint256 _bias = _point.bias;
		uint256 _slope = _point.slope;
		uint256 _start = _point.time;
		uint256 _end = _when;
		uint256 _ellapsed = _end - _start;
		uint256 _maxEllapsed = _slope > 0 ? _bias / _slope : type(uint256).max;
		return _ellapsed <= _maxEllapsed ? _bias - _slope * _ellapsed : 0;
	}

	function totalSupply() external view override returns (uint256 _totalSupply)
	{
		return totalSupply(block.timestamp);
	}

	function balanceOf(address _account) external view override returns (uint256 _balance)
	{
		return balanceOf(_account, block.timestamp);
	}

	function allowance(address _account, address _spender) external pure override returns (uint256 _allowance)
	{
		_account; _spender;
		return 0;
	}

	function approve(address _spender, uint256 _amount) external pure override returns (bool _success)
	{
		require(false, "forbidden");
		_spender; _amount;
		return false;
	}

	function transfer(address _to, uint256 _amount) external pure override returns (bool _success)
	{
		require(false, "forbidden");
		_to; _amount;
		return false;
	}

	function transferFrom(address _from, address _to, uint256 _amount) external pure override returns (bool _success)
	{
		require(false, "forbidden");
		_from; _to; _amount;
		return false;
	}

	function _findPoint(Point[] storage _points, uint256 _when) internal view returns (uint256 _index)
	{
		uint256 _min = 0;
		uint256 _max = _points.length;
		if (_when >= block.timestamp) return _max;
		while (_min < _max) {
			uint256 _mid = (_min + _max) / 2;
			if (_points[_mid].time <= _when)
				_min = _mid + 1;
			else
				_max = _mid;
		}
		return _min;
	}

	function _appendPoint(Point[] storage _points, uint256 _bias, uint256 _slope, uint256 _time) internal
	{
		uint256 _length = _points.length;
		if (_length > 0) {
			Point storage _point = _points[_length - 1];
			if (_point.time == _time) {
				_point.bias = _bias;
				_point.slope = _slope;
				return;
			}
			require(_time > _point.time, "invalid time");
		}
		_points.push(Point({ bias: _bias, slope: _slope, time: _time }));
	}

	function _checkpoint(address _account, uint256 _oldAmount, uint256 _oldUnlock, uint256 _newAmount, uint256 _newUnlock) internal
	{
		uint256 _oldBias = 0;
		uint256 _oldSlope = 0;
		if (_oldUnlock > block.timestamp && _oldAmount > 0) {
			_oldSlope = _oldAmount / MAX_LOCK_TIME;
			_oldBias = _oldSlope * (_oldUnlock - block.timestamp);
			slopeDecay_[_oldUnlock] -= _oldSlope;
		}

		uint256 _newBias = 0;
		uint256 _newSlope = 0;
		if (_newUnlock > block.timestamp && _newAmount > 0) {
			_newSlope = _newAmount / MAX_LOCK_TIME;
			_newBias = _newSlope * (_newUnlock - block.timestamp);
			slopeDecay_[_newUnlock] += _newSlope;
		}

		{
			Point[] storage _points = points_;
			uint256 _when = block.timestamp;
			Point storage _point = _points[_points.length - 1];
			uint256 _bias = _point.bias;
			uint256 _slope = _point.slope;
			uint256 _start = _point.time;
			uint256 _period = (_start / UNLOCK_BASIS) * UNLOCK_BASIS;
			while (true) {
				uint256 _nextPeriod = _period + UNLOCK_BASIS;
				uint256 _end = _nextPeriod < _when ? _nextPeriod : _when;
				uint256 _ellapsed = _end - _start;
				uint256 _maxEllapsed = _slope > 0 ? _bias / _slope : type(uint256).max;
				_bias = _ellapsed <= _maxEllapsed ? _bias - _slope * _ellapsed : 0;
				if (_end == _nextPeriod) _slope -= slopeDecay_[_nextPeriod];
				if (_end == _when) break;
				_appendPoint(_points, _bias, _slope, _end);
				_start = _end;
				_period = _nextPeriod;
			}
			_bias += _newBias - _oldBias;
			_slope += _newSlope - _oldSlope;
			_appendPoint(_points, _bias, _slope, block.timestamp);
		}

		if (_account != address(0)) {
			_appendPoint(userPoints_[_account], _newBias, _newSlope, block.timestamp);
		}
	}

	event Deposit(address indexed _account, uint256 _amount, uint256 indexed _unlock);
	event Withdraw(address indexed _account, uint256 _amount);
	event EmergencyDeclared();
}