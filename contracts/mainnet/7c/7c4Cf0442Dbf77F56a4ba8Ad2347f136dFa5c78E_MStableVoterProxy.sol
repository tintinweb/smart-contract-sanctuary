/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
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
library SafeMathUpgradeable {
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




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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





interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address) external returns (uint256 balance);

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function getName() external pure returns (string memory);

    function setStrategist(address _strategist) external;

    function setWithdrawalFee(uint256 _withdrawalFee) external;

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external;

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external;

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function tend() external;

    function harvest() external;
}


pragma experimental ABIEncoderV2;

/// @title  IMStableVoterProxy
/// @author mStable
/// @notice VoterProxy that deposits into mStable vaults and uses MTA stake to boosts rewards.
/// @dev    Receives MTA from Strategies and Loans in order to bolster Stake. Any MTA held here is
///         assumed to be invested to staking.
interface IMStableVoterProxy {
    /***************************************
                    VOTINGLOCK
    ****************************************/

    function createLock(uint256 _endTime) external;

    function harvestMta() external;

    function extendLock(uint256 _unlockTime) external;

    function exitLock() external returns (uint256 mtaBalance);

    function changeLockAddress(address _newLock) external;

    function changeRedistributionRate(uint256 _newRate) external;

    /***************************************
                        LOANS
    ****************************************/

    function loan(uint256 _amt) external;

    function repayLoan(address _creditor) external;

    /***************************************
                    STRATEGIES
    ****************************************/

    function supportStrategy(address _strategy, address _vault) external;

    /***************************************
                    POOL
    ****************************************/

    function deposit(uint256 _amt) external;

    function withdrawAll(address _want) external;

    function withdrawSome(address _want, uint256 _amt) external;

    function claim() external returns (uint256 immediateUnlock, uint256 vested);
}



abstract contract IMStableVotingLockup {
    function createLock(uint256 _value, uint256 _unlockTime) external virtual;

    function withdraw() external virtual;

    function exit() external virtual;

    function increaseLockAmount(uint256 _value) external virtual;

    function increaseLockLength(uint256 _unlockTime) external virtual;

    function claimReward() public virtual;

    function earned(address _account) public virtual view returns (uint256);

    // View only ERC20 fns

    function balanceOf(address _owner) public virtual view returns (uint256);

    function balanceOfAt(address _owner, uint256 _blockNumber) public virtual view returns (uint256);

    function totalSupply() public virtual view returns (uint256);

    function totalSupplyAt(uint256 _blockNumber) public virtual view returns (uint256);
}


/**
 * @title INexus
 * @dev Basic interface for interacting with the Nexus i.e. SystemKernel
 */
interface IMStableNexus {
    function governor() external view returns (address);
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}












/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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







interface IMStableBoostedVault {
    /**
     * @dev Get the RAW balance of a given account
     * @param _account User for which to retrieve balance
     */
    function rawBalanceOf(address _account) external view returns (uint256);

    /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stake(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function exit() external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function exit(uint256 _first, uint256 _last) external;

    /**
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external;

    /**
     * @dev Claims all unlocked rewards for sender.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function claimRewards() external;

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last) external;

    /**
     * @dev Pokes a given account to reset the boost
     */
    function pokeBoost(address _account) external;

    /**
     * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) external view returns (uint256);

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 first,
            uint256 last
        );
}










/*
    Common base for permissioned roles throughout Sett ecosystem
*/
contract SettAccessControl is Initializable {
    address public governance;
    address public strategist;
    address public keeper;

    // ===== MODIFIERS =====
    function _onlyGovernance() internal view {
        require(msg.sender == governance, "onlyGovernance");
    }

    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist || msg.sender == governance, "onlyGovernanceOrStrategist");
    }

    function _onlyAuthorizedActors() internal view {
        require(msg.sender == keeper || msg.sender == governance, "onlyAuthorizedActors");
    }

    // ===== PERMISSIONED ACTIONS =====

    /// @notice Change strategist address
    /// @notice Can only be changed by governance itself
    function setStrategist(address _strategist) external {
        _onlyGovernance();
        strategist = _strategist;
    }

    /// @notice Change keeper address
    /// @notice Can only be changed by governance itself
    function setKeeper(address _keeper) external {
        _onlyGovernance();
        keeper = _keeper;
    }

    /// @notice Change governance address
    /// @notice Can only be changed by governance itself
    function setGovernance(address _governance) public {
        _onlyGovernance();
        governance = _governance;
    }

    uint256[50] private __gap;
}


/// @title  MStableVoterProxy
/// @author mStable
/// @notice VoterProxy that deposits into mStable vaults and uses MTA stake to boosts rewards.
/// @dev    Receives MTA from Strategies and Loans in order to bolster Stake. Any MTA held here is
///         assumed to be invested to staking.
///         This is a dumb contract that:
///          - Deposits and withdraws LP tokens from all mStable vaults
///          - Manages the lock in the MTA staking contract
///          - Earns APY on staked MTA and reinvests
///          - Boosts rewards in vault deposits
///          - Migrates to a new Staking contract if necessary
contract MStableVoterProxy is IMStableVoterProxy, PausableUpgradeable, SettAccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    mapping(address => IMStableBoostedVault) public strategyToVault; // strategy => vault
    address[] public strategies;

    address public badgerGovernance;
    IMStableNexus public nexus; // mStable Nexus maintains record of governor address
    IMStableVotingLockup public votingLockup; // Current MTA staking contract address

    mapping(address => uint256) public loans; // Outstanding loans made to this contract
    IERC20Upgradeable public constant mta = IERC20Upgradeable(0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2);

    uint256 public constant MAX_RATE = 10000;
    uint256 public redistributionRate;

    event LockCreated(uint256 amt, uint256 unlockTime);
    event MtaHarvested(uint256 existing, uint256 harvested, uint256 distributed, uint256 invested);
    event LockExtended(uint256 unlockTime);
    event LockIncreased(uint256 amount);
    event LockExited();
    event LockChanged(address newLock);
    event RedistributionRateChanged(uint256 newRate);

    event Loaned(address creditor, uint256 amt);
    event LoanRepaid(address creditor, uint256 amt);

    event StrategyAdded(address strategy, address vault);

    function initialize(
        address _dualGovernance,
        address _badgerGovernance,
        address _strategist,
        address _keeper,
        address[2] memory _config,
        uint256[1] memory _rates
    ) public initializer {
        __Pausable_init();
        governance = _dualGovernance;
        badgerGovernance = _badgerGovernance;
        strategist = _strategist;
        keeper = _keeper;

        nexus = IMStableNexus(_config[0]);
        votingLockup = IMStableVotingLockup(_config[1]);

        redistributionRate = _rates[0];

        mta.safeApprove(address(votingLockup), type(uint256).max);
    }

    /// @dev Verifies that the caller is an active strategy and returns the address of the vault
    function _onlyActiveStrategy() internal view returns (IMStableBoostedVault vault) {
        vault = strategyToVault[msg.sender];
        require(address(vault) != address(0), "onlyStrategy");
    }

    /// @dev Callable by either the mStableDAO or the BadgerDAO signers
    function _onlyGovernors() internal view {
        require(msg.sender == badgerGovernance || msg.sender == nexus.governor(), "onlyGovernors");
    }

    /// @dev Callable by either the mStableDAO or the BadgerDAO signers
    function _onlyHarvesters() internal view {
        require(msg.sender == badgerGovernance || msg.sender == nexus.governor() || msg.sender == keeper, "onlyHarvesters");
    }

    /***************************************
                    VOTINGLOCK
    ****************************************/

    /// @dev Creates a lock in the mStable MTA staking contract, using the mta balance of
    /// this contract, and unlocking at the specified unlock time
    /// @param _unlockTime Time at which the stake will unlock
    function createLock(uint256 _unlockTime) external override {
        _onlyGovernance();

        uint256 bal = mta.balanceOf(address(this));
        votingLockup.createLock(bal, _unlockTime);

        emit LockCreated(bal, _unlockTime);
    }

    /// @dev Claims MTA rewards from Staking, distributes a percentage proportionately to all
    /// active strategies, and reinvests the remainder back into the staking contract.
    /// Also picks up any MTA that was transferred here FROM strategies, and adds this to the lock.
    /// Callable by either mStable or Badger DAO multisigs, or keeper.
    function harvestMta() external override {
        _onlyHarvesters();

        // balBefore = any MTA that was transferred here as a govMTA % from the stratgies
        uint256 balBefore = mta.balanceOf(address(this));
        votingLockup.claimReward();
        uint256 balAfter = mta.balanceOf(address(this));
        // e.g. (2e18 - 1e18) * 1000 / 10000;
        uint256 redistribute = balAfter.sub(balBefore).mul(redistributionRate).div(MAX_RATE);
        // Redistribute a % of the revenue from staking back to the strategies
        if (redistribute > 0) {
            uint256 len = strategies.length;
            for (uint256 i = 0; i < len; i++) {
                mta.safeTransfer(strategies[i], redistribute.div(len));
            }
        }
        // Increase that lock
        votingLockup.increaseLockAmount(balAfter.sub(redistribute));

        emit MtaHarvested(balBefore, balAfter.sub(balBefore), redistribute, balAfter.sub(redistribute));
    }

    /// @dev Simply extends the lock period in staking
    /// @param _unlockTime New time at which the stake will unlock
    function extendLock(uint256 _unlockTime) external override {
        _onlyGovernance();

        votingLockup.increaseLockLength(_unlockTime);

        emit LockExtended(_unlockTime);
    }

    /// @dev Simply extends the lock amount in staking
    function increaseLock() external {
        _onlyGovernance();

        uint256 bal = mta.balanceOf(address(this));
        votingLockup.increaseLockAmount(bal);

        emit LockIncreased(bal);
    }

    /// @dev Exits the lock and keeps MTA in contract
    /// @return mtaBalance Balance of MTA in this contract
    function exitLock() external override returns (uint256 mtaBalance) {
        _onlyGovernors();

        votingLockup.exit();

        emit LockExited();
    }

    /// @dev Changes the address of the VotingLockup
    /// WARNING - this approves mta on the new contract, so should be taken with care
    /// @param _newLock Address of the new VotingLockup
    function changeLockAddress(address _newLock) external override {
        _onlyGovernance();

        require(votingLockup.balanceOf(address(this)) == 0, "Active lockup");

        votingLockup = IMStableVotingLockup(_newLock);

        IERC20Upgradeable(mta).safeApprove(_newLock, type(uint256).max);

        emit LockChanged(_newLock);
    }

    /// @dev Changes the percentage of MTA earned via staking that gets redistributed to strategies
    /// @param _newRate Scaled pct of earnings to redistribute to strategies, where 100% = 10000
    function changeRedistributionRate(uint256 _newRate) external override {
        _onlyGovernors();
        require(_newRate < MAX_RATE, "Invalid rate");

        redistributionRate = _newRate;

        emit RedistributionRateChanged(_newRate);
    }

    /***************************************
                        LOANS
    ****************************************/

    /// @dev Loans the voter proxy a given amt by transferring and logging
    /// @param _amt Amt to send to the proxy!
    function loan(uint256 _amt) external override {
        require(loans[msg.sender] == 0, "Existing loan");

        mta.safeTransferFrom(msg.sender, address(this), _amt);
        loans[msg.sender] = _amt;

        emit Loaned(msg.sender, _amt);
    }

    /// @dev Repays the initially loaned MTA amount to a creditor
    /// @param _creditor Address of the initial creditor
    function repayLoan(address _creditor) external override {
        _onlyGovernors();

        uint256 loanAmt = loans[_creditor];
        require(loanAmt != 0, "Non-existing loan");

        loans[_creditor] = 0;
        mta.safeTransfer(_creditor, loanAmt);

        emit LoanRepaid(_creditor, loanAmt);
    }

    /***************************************
                    STRATEGIES
    ****************************************/

    /// @dev Adds a new supported strategy, looking up want and approving to vault
    /// @param _strategy Address of the BadgerStrategy
    /// @param _vault Address of the mStable vault
    function supportStrategy(address _strategy, address _vault) external override {
        _onlyGovernance();

        require(address(strategyToVault[_strategy]) == address(0), "Strategy already supported");

        uint256 len = strategies.length;
        for (uint256 i = 0; i < len; i++) {
            address vaulti = address(strategyToVault[strategies[i]]);
            require(vaulti != _vault, "Vault already supported");
        }

        // Lookup want in strategy
        address want = IStrategy(_strategy).want();
        // Approve spending to vault
        IERC20Upgradeable(want).safeApprove(_vault, type(uint256).max);
        // Whitelist strategy
        strategyToVault[_strategy] = IMStableBoostedVault(_vault);
        strategies.push(_strategy);

        emit StrategyAdded(_strategy, _vault);
    }

    /***************************************
                    POOL
    ****************************************/

    /// @dev Simply stakes in pool
    /// NOTE - Assumes that the want has already been transferred here
    /// @param _amt Amt of want that should be staked in the vault
    function deposit(uint256 _amt) external override {
        IMStableBoostedVault vault = _onlyActiveStrategy();

        vault.stake(_amt);
    }

    /// @dev Withdraws balance from vault, returning to strategy
    /// Passes _want to avoid having to read _want again via ext call
    /// @param _want Address of the LP token to return back to sender
    function withdrawAll(address _want) external override {
        IMStableBoostedVault vault = _onlyActiveStrategy();

        uint256 rawBal = vault.rawBalanceOf(address(this));
        vault.withdraw(rawBal);
        IERC20Upgradeable(_want).safeTransfer(msg.sender, rawBal);
    }

    /// @dev Withdraws _amt from vault, returning to strategy
    /// Passes _want to avoid having to read _want again via ext call
    /// @param _want Address of the LP token to return back to sender
    /// @param _amt Amount of want to withdraw and return
    function withdrawSome(address _want, uint256 _amt) external override {
        IMStableBoostedVault vault = _onlyActiveStrategy();

        vault.withdraw(_amt);
        IERC20Upgradeable(_want).safeTransfer(msg.sender, _amt);
    }

    /// @dev Claims rewards from the matching vault, and returns them to sender.
    /// @return immediateUnlock Amount of tokens that were earned without need for vesting
    /// @return vested Amount of tokens that were earned post-vesting
    function claim() external override returns (uint256 immediateUnlock, uint256 vested) {
        IMStableBoostedVault vault = _onlyActiveStrategy();

        // Get balance of MTA before (there could be residual MTA here waiting to be reinvested in vMTA)
        uint256 balBefore = mta.balanceOf(address(this));
        // Get MTA ready for immediate unlock (this is a view fn)
        immediateUnlock = vault.earned(address(this));
        // Actually claim rewards - both immediately unlocked as well as post-vesting rewards
        vault.claimRewards();
        // Calc the total amount claimed based on changing bal
        uint256 balAfter = mta.balanceOf(address(this));
        uint256 totalClaimed = balAfter.sub(balBefore);
        // Amount of the claim that was subject to vesting
        vested = totalClaimed.sub(immediateUnlock);

        mta.safeTransfer(msg.sender, totalClaimed);
    }
}