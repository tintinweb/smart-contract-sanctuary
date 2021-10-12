/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// Sources flattened with hardhat v2.6.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File contracts/TokenLock.sol



pragma solidity ^0.8.7;


contract TokenLock {
    using SafeERC20 for IERC20;

    // we never write both values together so packaging struct into sinle word wit uint128 does not make sense
    struct UnlockState {
        // total tokens to be released
        uint256 totalTokens;
        // already released tokens
        uint256 unlockedTokens;
    }

    // possible state of the Lock
    // NotFunded is initial state
    // transition to Funded happens only when required amount of "token" is on contract's balance
    enum State {
        Initialized,
        Funded
    }

    // emitted on token release
    event LogRelease(address indexed sender, uint256 amount);

    // emitted on token locked
    event LogLock(address wallet, uint256 amount);

    // emitted when all stakes are added
    event LogInitialized(uint256 totalLockedAmount);

    // emitted on lock funded
    event LogFunded();

    modifier onlyFunded() {
        require(_state == State.Funded, "Not in Initialized state");
        _;
    }

    modifier onlyInitialized() {
        require(_state == State.Initialized, "Not in Funded state");
        _;
    }

    uint256 internal constant DAYS_30_PERIOD = 30 days;

    // a value representing a whole (100%) of decimal fraction
    uint256 internal constant FRACTION_WHOLE = 10**18;

    IERC20 internal immutable _token;

    // start time of the vesting, Unix timestamp
    uint256 internal immutable _startTime;

    // period of the vesting in seconds
    uint256 internal immutable _vestingPeriod;

    // cliff period in seconds
    uint256 internal immutable _cliffPeriod;

    // token release on _startTime, decimal fraction where FRACTION_WHOLE is 100%
    uint256 internal immutable _initialReleaseFraction;

    // locked amount held and total amount
    mapping(address => UnlockState) internal _stakes;
    uint256 internal immutable _totalLockedAmount;

    // current state of the contract
    State internal _state;

    constructor(
        IERC20 token_,
        uint256 startTime_,
        uint256 vestingPeriod_,
        uint256 cliffPeriod_,
        uint256 initialReleaseFraction_,
        address[] memory wallets_,
        uint128[] memory amounts_
    ) {
        require(wallets_.length == amounts_.length, "number of elements in lists must match");
        // we put strong requirements for vesting parameters: this is not a generic vesting contract,
        // we support and test for just a limited range of parameters, see below
        require(vestingPeriod_ > 0, "vestingPeriod_ must be greater than 0");
        // all periods must be divisible by 30 days
        require(vestingPeriod_ % DAYS_30_PERIOD == 0, "vestingPeriod_ must be divisible by 30 days");
        require(cliffPeriod_ % DAYS_30_PERIOD == 0, "cliffPeriod_ must be divisible by 30 days");
        // cliff must be shorted than total vesting period
        require(cliffPeriod_ < vestingPeriod_, "cliffPeriod_ must be less than vestingPeriod_");
        // decimal fraction is between 0 and FRACTION_WHOLE
        require(initialReleaseFraction_ <= FRACTION_WHOLE, "initialReleaseFraction_ must be in range <0, 10**18>");
        // cliff cannot be present if initial release is set
        require(
            !(initialReleaseFraction_ > 0 && cliffPeriod_ > 0),
            "cliff period and initial release cannot be set together"
        );

        _token = token_;
        _startTime = startTime_;
        _vestingPeriod = vestingPeriod_;
        _cliffPeriod = cliffPeriod_;
        _initialReleaseFraction = initialReleaseFraction_;

        // create stakes, duplicates override each other and are not checked
        uint256 totalLockedAmount;
        for (uint256 ii = 0; ii < wallets_.length; ii += 1) {
            // duplicates in list of wallets are not allowed
            require(_stakes[wallets_[ii]].totalTokens == 0, "Duplicates in list of wallets not allowed");

            _stakes[wallets_[ii]].totalTokens = amounts_[ii];
            totalLockedAmount += amounts_[ii];
            emit LogLock(wallets_[ii], amounts_[ii]);
        }
        _totalLockedAmount = totalLockedAmount;
        emit LogInitialized(totalLockedAmount);
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function vestingPeriod() public view returns (uint256) {
        return _vestingPeriod;
    }

    function initialReleaseFraction() public view returns (uint256) {
        return _initialReleaseFraction;
    }

    function cliffPeriod() public view returns (uint256) {
        return _cliffPeriod;
    }

    function unlockedTokensOf(address sender) public view returns (uint256) {
        return _stakes[sender].unlockedTokens;
    }

    function totalTokensOf(address sender) public view returns (uint256) {
        return _stakes[sender].totalTokens;
    }

    function totalLockedTokens() public view returns (uint256) {
        return _totalLockedAmount;
    }

    function state() public view returns (State) {
        return _state;
    }

    function tokensVested(address sender, uint256 timestamp) public view returns (uint256 vestedTokens) {
        return tokensVestedInternal(_stakes[sender].totalTokens, timestamp);
    }

    function release() public onlyFunded {
        address sender = msg.sender;
        UnlockState memory stake = _stakes[sender];
        uint256 unlockAmount = tokensVestedInternal(stake.totalTokens, block.timestamp) - stake.unlockedTokens;

        // this should never happen
        assert(stake.totalTokens >= stake.unlockedTokens + unlockAmount);

        _stakes[sender].unlockedTokens += unlockAmount;

        emit LogRelease(sender, unlockAmount);
        token().safeTransfer(sender, unlockAmount);
    }

    function fund() public onlyInitialized {
        // change state first so there's no re-entry, contract reverts in all error cases
        _state = State.Funded;

        // transfer only what is missing, that allows to fund contract in two ways
        // (1) token transfer to contract, then anyone can call fund() function
        // (2) approve() and transferFrom from msg.sender
        uint256 owned = _token.balanceOf(address(this));
        if (owned < _totalLockedAmount) {
            // attempt to transfer sufficient amount of tokens from sender
            uint256 due = _totalLockedAmount - owned;
            // check allowance to provide nice revert code
            require(
                token().allowance(msg.sender, address(this)) >= due,
                "No sufficient allowance to fund the contract"
            );
            token().safeTransferFrom(msg.sender, address(this), due);
        }

        // emit funded log
        emit LogFunded();
    }

    function tokensVestedInternal(uint256 totalTokens, uint256 timestamp) internal view returns (uint256 vestedTokens) {
        // returns 0 before (start time + cliff period)
        // initial release is obtained after cliff
        if (timestamp >= _startTime + _cliffPeriod) {
            uint256 timeVestedSoFar = Math.min(timestamp - _startTime, _vestingPeriod);
            // compute initial release as fraction where FRACTION_WHOLE is total
            uint256 initialRelease = (totalTokens * _initialReleaseFraction) / FRACTION_WHOLE;
            // return initial release + the remainder proportionally to time from vesting start
            // mul first for best precision, v.8 compiler reverts on overflows
            vestedTokens = ((totalTokens - initialRelease) * timeVestedSoFar) / _vestingPeriod + initialRelease;
        }
    }
}


// File contracts/AddLockTokenLock.sol



pragma solidity ^0.8.7;

contract AddLockTokenLock is TokenLock {
    using SafeERC20 for IERC20;

    enum LeaverType {
        None,
        GoodLeaver,
        BadLeaver
    }

    event LogLeave(address indexed leaver, LeaverType leaverType, uint256 newTotalStake);
    event LogLockAmount(address indexed wallet, uint256 amount);

    // part of the accumulated tokens that stays with bad leaver
    uint256 internal constant BAD_LEAVER_DIVISOR = 10;

    // part of the tokens accumulated in the future that stays with the good leaver
    uint256 internal constant GOOD_LEAVER_DIVISOR = 2;

    // manager address that can execute leave method
    address internal _manager;

    // information on leavers
    mapping(address => LeaverType) internal _leavers;

    modifier onlyManager() {
        require(msg.sender == _manager, "Only manager");
        _;
    }

    modifier onlyNonLeaver(address wallet) {
        require(_leavers[wallet] == LeaverType.None, "Specified wallet already left");
        _;
    }

    constructor(
        IERC20 token_,
        uint256 startTime_,
        uint256 vestingPeriod_,
        address manager_,
        address[] memory wallets_,
        uint128[] memory amounts_
    ) TokenLock(token_, startTime_, vestingPeriod_, 0, 0, wallets_, amounts_) {
        _manager = manager_;
    }

    function managerAddress() public view returns (address) {
        return _manager;
    }

    function hasLeft(address wallet) public view returns (LeaverType) {
        return _leavers[wallet];
    }

    function lockAmount(address wallet, uint256 amount) public onlyManager onlyFunded onlyNonLeaver(wallet) {
        require(wallet != _manager, "Manager cannot restake itself");

        UnlockState memory managerStake = _stakes[_manager];

        // the difference between total tokens and unlocked tokens can be restaked to other accounts
        require(managerStake.totalTokens - managerStake.unlockedTokens >= amount, "Not enough available stake to add");

        // add stake to existing or new account
        _stakes[wallet].totalTokens += amount;
        // decrease manager stake
        _stakes[_manager].totalTokens = managerStake.totalTokens - amount;

        emit LogLockAmount(wallet, amount);
    }
}