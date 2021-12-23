/**
 *Submitted for verification at snowtrace.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: Badger-Finance/[email protected]/BadgerGuestListAPI

interface BadgerGuestListAPI {
    function authorized(
        address guest,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    function setGuests(address[] calldata _guests, bool[] calldata _invited) external;
}

// Part: Badger-Finance/[email protected]/IERC20Detailed

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Detailed {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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

// Part: Badger-Finance/[email protected]/IStrategy

interface IStrategy {
    // Return value for harvest, tend and balanceOfRewards
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    function balanceOf() external view returns (uint256 balance);

    function balanceOfPool() external view returns (uint256 balance);

    function balanceOfWant() external view returns (uint256 balance);

    function earn() external;

    function withdraw(uint256 amount) external;

    function withdrawToVault() external returns (uint256 balance);

    function withdrawOther(address _asset) external;

    function harvest() external returns (TokenAmount[] memory harvested);
    function tend() external returns (TokenAmount[] memory tended);
    function balanceOfRewards() external view returns (TokenAmount[] memory rewards);

    function emitNonProtectedToken(address _token) external;
}

// Part: OpenZeppelin/[email protected]/AddressUpgradeable

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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// Part: OpenZeppelin/[email protected]/IERC20Upgradeable

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

// Part: OpenZeppelin/[email protected]/SafeMathUpgradeable

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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

// Part: OpenZeppelin/[email protected]/Initializable

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20Upgradeable

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

// Part: Badger-Finance/[email protected]/SettAccessControl

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

// Part: OpenZeppelin/[email protected]/ContextUpgradeable

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

// Part: OpenZeppelin/[email protected]/ReentrancyGuardUpgradeable

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// Part: OpenZeppelin/[email protected]/ERC20Upgradeable

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// Part: OpenZeppelin/[email protected]/PausableUpgradeable

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// Part: Badger-Finance/[email protected]/Vault

/*
    Source: https://github.com/iearn-finance/yearn-protocol/blob/develop/contracts/vaults/yVault.sol
    
    Changelog:

    V1.1
    * Strategist no longer has special function calling permissions
    * Version function added to contract
    * All write functions, with the exception of transfer, are pausable
    * Keeper or governance can pause
    * Only governance can unpause

    V1.2
    * Transfer functions are now pausable along with all other non-permissioned write functions
    * All permissioned write functions, with the exception of pause() & unpause(), are pausable as well

    V1.3
    * Add guest list functionality
    * All deposits can be optionally gated by external guestList approval logic on set guestList contract

    V1.4
    * Add depositFor() to deposit on the half of other users. That user will then be blockLocked.

    V1.5
    * Removed Controller
        - Removed harvest from vault (only on strategy)
    * Params added to track autocompounded rewards (lifeTimeEarned, lastHarvestedAt, lastHarvestAmount, assetsAtLastHarvest)
      this would work in sync with autoCompoundRatio to help us track harvests better.
    * Fees
        - Strategy would report the autocompounded harvest amount to the vault
        - Calculation performanceFeeGovernance, performanceFeeStrategist, withdrawalFee, managementFee moved to the vault.
        - Vault mints shares for performanceFees and managementFee to the respective recipient (treasury, strategist)
        - withdrawal fees is transferred to the rewards address set
    * Permission:
        - Strategist can now set performance, withdrawal and management fees
        - Governance will determine maxPerformanceFee, maxWithdrawalFee, maxManagementFee that can be set to prevent rug of funds.
    * Strategy would take the actors from the vault it is connected to
    * All goverance related fees goes to treasury
*/

contract Vault is ERC20Upgradeable, SettAccessControl, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 constant ONE_ETH = 1e18;

    /// ===== Storage Variables ====

    IERC20Upgradeable public token; // Token used for deposits
    BadgerGuestListAPI public guestList; // guestlist when vault is in experiment/ guarded state

    bool public pausedDeposit; // false by default Allows to only block deposits, use pause for the normal pause state

    address public strategy; // address of the strategy connected to the vault
    address public guardian; // guardian of vault and strategy
    address public treasury; // set by governance ... any fees go there

    address public badgerTree; // Address we send tokens too via reportAdditionalTokens

    /// @dev name and symbol prefixes for lpcomponent token of vault
    string internal constant _defaultNamePrefix = "Badger Sett ";
    string internal constant _symbolSymbolPrefix = "b";

    /// Params to track autocompounded rewards
    uint256 public lifeTimeEarned; // keeps track of total earnings
    uint256 public lastHarvestedAt; // timestamp of the last harvest
    uint256 public lastHarvestAmount; // amount harvested during last harvest
    uint256 public assetsAtLastHarvest; // assets for which the harvest took place.

    mapping (address => uint256) public additionalTokensEarned;
    mapping (address => uint256) public lastAdditionalTokenAmount;

    /// Fees ///
    /// @notice all fees will be in bps
    uint256 public performanceFeeGovernance; // Perf fee sent to `treasury`
    uint256 public performanceFeeStrategist; // Perf fee sent to `strategist`
    uint256 public withdrawalFee; // fee issued to `treasury` on withdrawal 
    uint256 public managementFee; // fee issued to `treasury` on report (typically on harvest, but only if strat is autocompounding)

    uint256 public maxPerformanceFee; // maximum allowed performance fees
    uint256 public maxWithdrawalFee; // maximum allowed withdrawal fees
    uint256 public maxManagementFee; // maximum allowed management fees

    uint256 public toEarnBps; // NOTE: in BPS, minimum amount of token to deposit into strategy when earn is called

    /// ===== Constants ====
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant SECS_PER_YEAR = 31_556_952; // 365.2425 days

    uint256 public constant WITHDRAWAL_FEE_HARD_CAP = 200; // Never higher than 2%
    uint256 public constant PERFORMANCE_FEE_HARD_CAP = 3_000; // Never higher than 30% // 30% maximum performance fee // We usually do 20, so this is insanely high already
    uint256 public constant MANAGEMENT_FEE_HARD_CAP = 200; // Never higher than 2%

    /// ===== Events ====
    // Emitted when a token is sent to the badgerTree for emissions
    event TreeDistribution(
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    // Emitted during a report, when there has been an increase in pricePerFullShare (ppfs)
    event Harvested(address indexed token, uint256 amount, uint256 indexed blockNumber, uint256 timestamp);

    event SetTreasury(address indexed newTreasury);
    event SetStrategy(address indexed newStrategy);
    event SetToEarnBps(uint256 newEarnToBps);
    event SetMaxWithdrawalFee(uint256 newMaxWithdrawalFee);
    event SetMaxPerformanceFee(uint256 newMaxPerformanceFee);
    event SetMaxManagementFee(uint256 newMaxManagementFee);
    event SetGuardian(address indexed newGuardian);
    event SetGuestList(address indexed newGuestList);
    event SetWithdrawalFee(uint256 newWithdrawalFee);
    event SetPerformanceFeeStrategist(uint256 newPerformanceFeeStrategist);
    event SetPerformanceFeeGovernance(uint256 newPerformanceFeeGovernance);
    event SetManagementFee(uint256 newManagementFee);
    event PauseDeposits(address indexed pausedBy);
    event UnpauseDeposits(address indexed pausedBy);

    function initialize(
        address _token,
        address _governance,
        address _keeper,
        address _guardian,
        address _treasury,
        address _strategist,
        address _badgerTree,
        string memory _name,
        string memory _symbol,
        uint256[4] memory _feeConfig
    ) public initializer whenNotPaused {
        require(_token != address(0)); // dev: _token address should not be zero
        require(_governance != address(0)); // dev: _governance address should not be zero
        require(_keeper != address(0)); // dev: _keeper address should not be zero
        require(_guardian != address(0)); // dev: _guardian address should not be zero
        require(_treasury != address(0)); // dev: _treasury address should not be zero
        require(_strategist != address(0)); // dev: _strategist address should not be zero
        require(_badgerTree != address(0)); // dev: _badgerTree address should not be zero

        // Check for fees being reasonable (see below for interpretation)
        require(_feeConfig[0] <= PERFORMANCE_FEE_HARD_CAP, "performanceFeeGovernance too high");
        require(_feeConfig[1] <= PERFORMANCE_FEE_HARD_CAP, "performanceFeeStrategist too high");
        require(_feeConfig[2] <= WITHDRAWAL_FEE_HARD_CAP, "withdrawalFee too high");
        require(_feeConfig[3] <= MANAGEMENT_FEE_HARD_CAP, "managementFee too high");

        string memory name;
        string memory symbol;


        // If they are non empty string we'll use the custom names
        // Else just add the default prefix
        IERC20Detailed namedToken = IERC20Detailed(_token);

        if(keccak256(abi.encodePacked(_name)) != keccak256("")) {
            name = _name;
        } else {
            name = string(abi.encodePacked(_defaultNamePrefix, namedToken.name()));
        }

        if (keccak256(abi.encodePacked(_symbol)) != keccak256("")) {
            symbol = _symbol;
        } else {
            symbol = string(abi.encodePacked(_symbolSymbolPrefix, namedToken.symbol()));
        }

        // Initializing the lpcomponent token
        __ERC20_init(name, symbol);
        // Initialize the other contracts
        __Pausable_init();
        __ReentrancyGuard_init();

        token = IERC20Upgradeable(_token);
        governance = _governance;
        treasury = _treasury;
        strategist = _strategist;
        keeper = _keeper;
        guardian = _guardian;
        badgerTree = _badgerTree;

        lastHarvestedAt = block.timestamp; // setting initial value to the time when the vault was deployed

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];
        managementFee = _feeConfig[3];
        maxPerformanceFee = PERFORMANCE_FEE_HARD_CAP; // 30% max performance fee
        maxWithdrawalFee = WITHDRAWAL_FEE_HARD_CAP; // 1% maximum withdrawal fee
        maxManagementFee = MANAGEMENT_FEE_HARD_CAP; // 2% maximum management fee

        toEarnBps = 9_500; // initial value of toEarnBps // 95% is invested to the strategy, 5% for cheap withdrawals
    }

    /// ===== Modifiers ====

    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian || msg.sender == governance, "onlyPausers");
    }

    function _onlyStrategy() internal view {
        require(msg.sender == strategy, "onlyStrategy");
    }

    /// ===== View Functions =====
    
    function version() external pure returns (string memory) {
        return "1.5";
    }

    /// @dev Return the price of a share, denominated in ONE_ETH
    function getPricePerFullShare() public view returns (uint256) {
        if (totalSupply() == 0) {
            return ONE_ETH;
        }
        return balance().mul(ONE_ETH).div(totalSupply());
    }

    /// @notice Return the total balance of the underlying token within the system
    /// @notice Sums the balance in the Sett and the Strategy
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /// @notice Defines how much of the Setts' underlying can be borrowed by the Strategy for use
    /// @notice Custom logic in here for how much the vault allows to be borrowed
    /// @notice Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(toEarnBps).div(MAX_BPS);
    }

    /// ===== Public Actions =====

    /// @notice Deposit assets into the Sett, and return corresponding shares to the user
    function deposit(uint256 _amount) external whenNotPaused {
        _depositWithAuthorization(_amount, new bytes32[](0));
    }

    /// @notice Deposit variant with proof for merkle guest list
    function deposit(uint256 _amount, bytes32[] memory proof) external whenNotPaused {
        _depositWithAuthorization(_amount, proof);
    }

    /// @notice Convenience function: Deposit entire balance of asset into the Sett, and return corresponding shares to the user
    function depositAll() external whenNotPaused {
        _depositWithAuthorization(token.balanceOf(msg.sender), new bytes32[](0));
    }

    /// @notice DepositAll variant with proof for merkle guest list
    function depositAll(bytes32[] memory proof) external whenNotPaused {
        _depositWithAuthorization(token.balanceOf(msg.sender), proof);
    }

    /// @notice Deposit assets into the Sett, and return corresponding shares to the user
    function depositFor(address _recipient, uint256 _amount) external whenNotPaused {
        _depositForWithAuthorization(_recipient, _amount, new bytes32[](0));
    }

    /// @notice Deposit variant with proof for merkle guest list
    function depositFor(
        address _recipient,
        uint256 _amount,
        bytes32[] memory proof
    ) external whenNotPaused {
        _depositForWithAuthorization(_recipient, _amount, proof);
    }

    /// @notice No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares) external whenNotPaused {
        _withdraw(_shares);
    }

    /// @notice Convenience function: Withdraw all shares of the sender
    function withdrawAll() external whenNotPaused {
        _withdraw(balanceOf(msg.sender));
    }

    /// ===== Permissioned Actions: Strategy =====

    /// @dev assigns harvest's variable and mints shares to governance and strategist for fees for autocompounded rewards
    /// @notice you are trusting the strategy to report the correct amount
    /// @notice Pausing on this function happens at the strategy level as harvest will be paused
    function reportHarvest(
        uint256 _harvestedAmount
    ) external nonReentrant {
        _onlyStrategy();

        uint256 harvestTime = block.timestamp;
        uint256 assetsAtHarvest = balance().sub(_harvestedAmount); // Must be less than or equal or revert

        _handleFees(_harvestedAmount, harvestTime);

        // Updated lastHarvestAmount
        lastHarvestAmount = _harvestedAmount;

        // if we withdrawAll
        // we will have some yield left
        // having 0 for assets will inflate APY
        // Instead, have the last harvest report with the previous assets
        // And if you end up harvesting again, that report will have both 0s
        if (assetsAtHarvest != 0) {
            assetsAtLastHarvest = assetsAtHarvest;
        } else if (_harvestedAmount == 0) {
            // If zero
            assetsAtLastHarvest = 0;
        }

        lifeTimeEarned = lifeTimeEarned.add(_harvestedAmount);
        // Update time either way
        lastHarvestedAt = harvestTime;

        emit Harvested(address(token), _harvestedAmount, block.number, block.timestamp);
    }

    /// @dev assigns harvest's variable and mints shares to governance and strategist for fees for non want rewards
    /// NOTE: non want rewards would remain in the strategy and can be withdrawn using
    // This function is called after the strat sends us the tokens
    // We have to receive the tokens as those are protected and no-one can pull those funds
    /// @notice Pausing on this function happens at the strategy level as harvest will be paused
    function reportAdditionalToken(address _token) external nonReentrant {
        _onlyStrategy();
        require(address(token) != _token, "No want");
        uint256 tokenBalance = IERC20Upgradeable(_token).balanceOf(address(this));

        additionalTokensEarned[_token] = additionalTokensEarned[_token].add(tokenBalance);
        lastAdditionalTokenAmount[_token] = tokenBalance;

        // We may have more, but we still report only what the strat sent
        uint256 governanceRewardsFee = _calculateFee(tokenBalance, performanceFeeGovernance);
        uint256 strategistRewardsFee = _calculateFee(tokenBalance, performanceFeeStrategist);

        IERC20Upgradeable(_token).safeTransfer(treasury, governanceRewardsFee);
        IERC20Upgradeable(_token).safeTransfer(strategist, strategistRewardsFee);

        // Send rest to tree
        uint256 newBalance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(badgerTree, newBalance);
        emit TreeDistribution(_token, newBalance, block.number, block.timestamp);
    }

    /// ===== Permissioned Actions: Governance =====

    /// @dev Changes the treasury, recipient of management and performanceFeeGovernance
    function setTreasury(address _treasury) external whenNotPaused {
        _onlyGovernance();
        require(_treasury != address(0), "Address 0");

        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /// @dev Changes the Strategy
    /// @notice This is arguably a rug vector, pay extreme attention to the next strategy being set
    /// @notice Changing the strategy should happen via timelock
    /// @notice This function must not be callable whenPaused as this would force depositors into a strategy they may not want to use
    function setStrategy(address _strategy) external whenNotPaused {
        _onlyGovernance();
        require(_strategy != address(0), "Address 0");


        /// NOTE: Migrate funds if settings strategy when already existing one
        if (strategy != address(0)) {
            require(IStrategy(strategy).balanceOf() == 0, "Please withdrawToVault before changing strat");
        }
        strategy = _strategy;
        emit SetStrategy(_strategy);
    }

    // === Setters that can be called by governance even when paused ===

    /// @notice Set maxWithdrawalFee
    /// @notice Can only be changed by governance
    function setMaxWithdrawalFee(uint256 _fees) external {
        _onlyGovernance();
        require(_fees <= WITHDRAWAL_FEE_HARD_CAP, "withdrawalFee too high");

        maxWithdrawalFee = _fees;
        emit SetMaxWithdrawalFee(_fees);
    }

    /// @notice Set maxPerformanceFee
    /// @notice Can only be changed by governance
    function setMaxPerformanceFee(uint256 _fees) external {
        _onlyGovernance();
        require(_fees <= PERFORMANCE_FEE_HARD_CAP, "performanceFeeStrategist too high");

        maxPerformanceFee = _fees;
        emit SetMaxPerformanceFee(_fees);
    }

    /// @notice Set maxPerformanceFee
    /// @notice Can only be changed by governance
    function setMaxManagementFee(uint256 _fees) external {
        _onlyGovernance();
        require(_fees <= MANAGEMENT_FEE_HARD_CAP, "managementFee too high");

        maxManagementFee = _fees;
        emit SetMaxManagementFee(_fees);
    }

    /// @notice Change guardian address
    /// @notice Can only be changed by governance
    function setGuardian(address _guardian) external {
        _onlyGovernance();
        require(_guardian != address(0), "Address cannot be 0x0");

        guardian = _guardian;
        emit SetGuardian(_guardian);
    }

    /// ===== Permissioned Functions: Trusted Actors =====

    /// @notice Set minimum threshold of underlying that must be deposited in strategy
    /// @notice Can only be changed by governance
    /// @notice This can only be changed when not paused as the amount set on strategy can be problematic
    function setToEarnBps(uint256 _newToEarnBps) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_newToEarnBps <= MAX_BPS, "toEarnBps should be <= MAX_BPS");

        toEarnBps = _newToEarnBps;
        emit SetToEarnBps(_newToEarnBps);
    } 

    /// @dev Changes the guestList, used to gate or limit deposits
    /// @notice can only be called by governance or strategist
    function setGuestList(address _guestList) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        guestList = BadgerGuestListAPI(_guestList);
        emit SetGuestList(_guestList);
    }

    /// @dev Sets the withdrawalFee, which is taken in want at the time of withdrawin
    /// @dev the fee taken in want is then used to issue shares
    /// @notice can also be called by strategist because bounds are set by governance
    function setWithdrawalFee(uint256 _withdrawalFee) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_withdrawalFee <= maxWithdrawalFee, "Excessive withdrawal fee");
        withdrawalFee = _withdrawalFee;
        emit SetWithdrawalFee(_withdrawalFee);
    }

    /// @dev Sets the performance fee for the strategist, taken at time of report
    /// @notice can also be called by strategist because bounds are set by governance
    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_performanceFeeStrategist <= maxPerformanceFee, "Excessive strategist performance fee");
        performanceFeeStrategist = _performanceFeeStrategist;
        emit SetPerformanceFeeStrategist(_performanceFeeStrategist);
    }

    /// @dev Sets the performance fee for the governance, taken at time of report
    /// @notice Governance fees are paid to treasury
    /// @notice can also be called by strategist because bounds are set by governance
    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_performanceFeeGovernance <= maxPerformanceFee, "Excessive governance performance fee");
        performanceFeeGovernance = _performanceFeeGovernance;
        emit SetPerformanceFeeGovernance(_performanceFeeGovernance);
    }

    /// @notice Set management fees, which are calculated during reports and issued to treasury
    /// @notice can also be called by strategist because bounds are set by governance
    function setManagementFee(uint256 _fees) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_fees <= maxManagementFee, "Excessive management fee");
        managementFee = _fees;
        emit SetManagementFee(_fees);
    }

    /// === Strategist level operations that can be done even when paused ==

    /// @dev Withdraws all funds from Strategy and deposits into vault
    /// @notice can only be called by governance or strategist
    /// @notice This is basically withdrawAll
    /// @notice We renamed it due to withdrawAll being used to allow a user to withdraw all their funds
    function withdrawToVault() external {
        _onlyGovernanceOrStrategist();
        IStrategy(strategy).withdrawToVault();
    }

    /// @dev Used to emit an extra token (e.g. airdrop), take fees and send to badgerTree for emission
    /// @notice This function is just calling `emitNonProtectedToken` on the BaseStrategy see the code there for details
    function emitNonProtectedToken(address _token) external {
        _onlyGovernanceOrStrategist();

        IStrategy(strategy).emitNonProtectedToken(_token);
    }

    /// @dev Used to withdraw an extra token and send it to governance
    function sweepExtraToken(address _token) external {
        _onlyGovernanceOrStrategist();
        require(address(token) != _token, "No want");

        IStrategy(strategy).withdrawOther(_token);
        // Send all `_token` we have
        // Safe because `withdrawOther` will revert on protected tokens  
        // Done this way works for both a donation to strategy or to vault
        IERC20Upgradeable(_token).safeTransfer(governance, IERC20Upgradeable(_token).balanceOf(address(this)));
    }

    /// @dev Transfer the underlying available to be claimed to the strategy
    /// @notice The strategy will use for yield-generating activities
    /// @notice Pause is enforced at the Strategy level (this allows to still earn yield when the Vault is paused)
    function earn() external {
        require(!pausedDeposit, "pausedDeposit"); // dev: deposits are paused, we don't earn as well
        _onlyAuthorizedActors();

        uint256 _bal = available();
        token.safeTransfer(strategy, _bal);
        IStrategy(strategy).earn();
    }

    /// @dev Pauses deposits
    /// @notice Deposits have an extra check to be paused, pause() will instead always pause everything
    function pauseDeposits() external {
        _onlyAuthorizedPausers();
        pausedDeposit = true;
        emit PauseDeposits(msg.sender);
    }
    
    /// @dev Resume deposits
    function unpauseDeposits() external {
        _onlyGovernance();
        pausedDeposit = false;
        emit UnpauseDeposits(msg.sender);
    }

    /// @dev Pauses everything
    /// @notice Emits event Paused(address account); from OZ Parent Contract
    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    /// @dev Unpauses everything
    /// @notice Emits event Unpaused(address account); from OZ Parent Contract
    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Implementations =====

    /// @dev Calculate the number of shares to issue for a given deposit
    /// @dev This is based on the realized value of underlying assets between Sett & associated Strategy

    /// @dev The actual deposit operation, nonReentant, take funds, issue shares
    function _depositFor(address _recipient, uint256 _amount) internal nonReentrant {
        require(_recipient != address(0), "Address 0");
        require(_amount != 0, "Amount 0");
        require(!pausedDeposit, "pausedDeposit"); // dev: deposits are paused

        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _mintSharesFor(_recipient, _after.sub(_before), _pool);
    }

    function _depositWithAuthorization(uint256 _amount, bytes32[] memory proof) internal {
        _depositForWithAuthorization(msg.sender, _amount, proof);
    }

    function _depositForWithAuthorization(
        address _recipient,
        uint256 _amount,
        bytes32[] memory proof
    ) internal {
        if (address(guestList) != address(0)) {
            require(guestList.authorized(_recipient, _amount, proof), "GuestList: Not Authorized");
        }
        _depositFor(_recipient, _amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    /// @notice Processes withdrawal fee if present
    function _withdraw(uint256 _shares) internal nonReentrant {
        require(_shares != 0, "0 Shares");

        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _toWithdraw = r.sub(b);
            IStrategy(strategy).withdraw(_toWithdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _toWithdraw) {
                r = b.add(_diff);
            }
        }
        uint256 _fee = _calculateFee(r, withdrawalFee);

        // Send funds to user
        token.safeTransfer(msg.sender, r.sub(_fee));

        // After you burned the shares, and you have sent the funds, adding here is equivalent to depositing
        // Process withdrawal fee
        _mintSharesFor(treasury, _fee, balance().sub(_fee));
    }

    /// @dev function to process an arbitrary fee
    /// @return fee : amount of fees to take
    function _calculateFee(uint256 amount, uint256 feeBps) internal pure returns (uint256) {
        if (feeBps == 0) {
            return 0;
        }
        uint256 fee = amount.mul(feeBps).div(MAX_BPS);
        return fee;
    }

    /// @dev used to manage the governance and strategist fee, make sure to use it to get paid!
    function _calculatePerformanceFee(uint256 _amount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 governancePerformanceFee = _calculateFee(_amount, performanceFeeGovernance);

        uint256 strategistPerformanceFee = _calculateFee(_amount, performanceFeeStrategist);

        return (governancePerformanceFee, strategistPerformanceFee);
    }

    /// @dev mints performance fees shares for governance and strategist
    function _mintSharesFor(
        address recipient,
        uint256 _amount,
        uint256 _pool
    ) internal {
        uint256 shares;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(recipient, shares);
    }

    /// @dev called by function report to handle minting of
    function _handleFees(uint256 _harvestedAmount, uint256 harvestTime) internal {
        (uint256 feeGovernance, uint256 feeStrategist) = _calculatePerformanceFee(_harvestedAmount);
        uint256 duration = harvestTime.sub(lastHarvestedAt);

        // Management fee is calculated against the assets before harvest, to make it fair to depositors
        uint256 management_fee = managementFee > 0 ? managementFee.mul(balance().sub(_harvestedAmount)).mul(duration).div(SECS_PER_YEAR).div(MAX_BPS) : 0;
        uint256 totalGovernanceFee = feeGovernance.add(management_fee);

        // Pool size is the size of the pool minus the fees, this way 
        // it's equivalent to sending the tokens as rewards after the harvest
        // and depositing them again
        uint256 _pool = balance().sub(totalGovernanceFee).sub(feeStrategist);

        // uint != is cheaper and equivalent to >
        if (totalGovernanceFee != 0) {
            _mintSharesFor(treasury, totalGovernanceFee, _pool);
        }

        if (feeStrategist != 0 && strategist != address(0)) {
            /// NOTE: adding feeGovernance backed to _pool as shares would have been issued for it.
            _mintSharesFor(strategist, feeStrategist, _pool.add(totalGovernanceFee));
        }
    }
}

// File: TheVault.sol

contract TheVault is Vault {
  // So Brownie compiles it tbh
  // Changes here invalidate the bytecode, breaking trust of the mix
  // DO NOT CHANGE THIS FILE
}