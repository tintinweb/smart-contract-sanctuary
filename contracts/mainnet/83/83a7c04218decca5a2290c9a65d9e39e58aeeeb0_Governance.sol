/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/Math.sol


pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/proxy/Initializable.sol


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        return !Address.isContract(address(this));
    }
}

// File: contracts/governance/Governable.sol

pragma solidity ^0.6.0;


/// @title Governable
/// @dev Governable is contract for governance role. Why don't use an AccessControl? Because the only one member exists
contract Governable {

    /// @notice The government address getter
    address public governance;

    /// @notice Simple contstructor that initialize the governance address
    constructor() public {
        governance = msg.sender;
    }

    /// @dev Prevents other msg.sender than governance address
    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }

    /// @notice Setter for governance address
    /// @param _newGovernance New value
    function setGovernance(address _newGovernance) public onlyGovernance {
        governance = _newGovernance;
    }

}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/governance/LPTokenWrapper.sol

pragma solidity ^0.6.0;





/// @title LPTokenWrapper
/// @notice Used as utility to simplify governance token operations in Governance contract
contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Wrapped governance token
    IERC20 public governanceToken;

    /// @notice Current balances
    mapping(address => uint256) private _balances;

    /// @notice Current total supply
    uint256 private _totalSupply;

    /// @notice Standard totalSupply method
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    /// @notice Standard balanceOf method
    /// @param _account User address
    function balanceOf(address _account) public view returns(uint256) {
        return _balances[_account];
    }

    /// @notice Standard deposit (stake) method
    /// @param _amount Amount governance tokens to stake (deposit)
    function stake(uint256 _amount) public virtual {
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        governanceToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Standard withdraw method
    /// @param _amount Amount governance tokens to withdraw
    function withdraw(uint256 _amount) public virtual {
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        governanceToken.transfer(msg.sender, _amount);
    }

    /// @notice Simple governance setter
    /// @param _newGovernanceToken New value
    function _setGovernanceToken(address _newGovernanceToken) internal {
        governanceToken = IERC20(_newGovernanceToken);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/interfaces/IRewardDistributionRecipient.sol

pragma solidity ^0.6.0;



abstract contract IRewardDistributionRecipient is Ownable {

    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution {
        require(msg.sender == rewardDistribution, "!rewardDistribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        public
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

// File: contracts/interfaces/IExecutor.sol

pragma solidity ^0.6.0;


interface IExecutor {
    function execute(uint256 _id, uint256 _for, uint256 _against, uint256 _quorum) external;
}

// File: contracts/governance/Governance.sol

pragma solidity ^0.6.0;










/// @title Governance
/// @notice
/// @dev
contract Governance is Governable, IRewardDistributionRecipient, LPTokenWrapper, Initializable {

    /// @notice The Proposal struct used to represent vote process.
    struct Proposal {
        uint256 id; // Unique ID of the proposal (here Counter lib can be used)
        address proposer; // An address who created the proposal
        mapping(address => uint256) forVotes; // Percentage (in base points) of governance token (votes) of 'for' side
        mapping(address => uint256) againstVotes; // Percentage (in base points) of governance token (votes) of 'against' side
        uint256 totalForVotes; // Total amount of governance token (votes) in side 'for'
        uint256 totalAgainstVotes; // Total amount of governance token (votes) in side 'against'
        uint256 start; // Block start
        uint256 end; // Start + period
        address executor; // Custom contract which can execute changes regarding to voting process end
        string hash; // An IPFS hash of the proposal document
        uint256 totalVotesAvailable; // Total amount votes that are not in voting process
        uint256 quorum; // Current quorum (in base points)
        uint256 quorumRequired; // Quorum to end the voting process
        bool open; // Proposal status
    }

    /// @notice Emits when new proposal is created
    /// @param _id ID of the proposal
    /// @param _creator Address of proposal creator
    /// @param _start Voting process start timestamp
    /// @param _duration Seconds during which the voting process occurs
    /// @param _executor Address of the the executor contract
    event NewProposal(uint256 _id, address _creator, uint256 _start, uint256 _duration, address _executor);

    /// @notice Emits when someone votes in proposal
    /// @param _id ID of the proposal
    /// @param _voter Voter address
    /// @param _vote 'For' or 'Against' vote type
    /// @param _weight Vote weight in percents (in base points)
    event Vote(uint256 indexed _id, address indexed _voter, bool _vote, uint256 _weight);

    /// @notice Emits when voting process finished
    /// @param _id ID of the proposal
    /// @param _for 'For' votes percentage in base points
    /// @param _against 'Against' votes percentage in base points
    /// @param _quorumReached Is quorum percents are above or equal to required quorum? (bool)
    event ProposalFinished(uint256 indexed _id, uint256 _for, uint256 _against, bool _quorumReached);

    /// @notice Emits when voter invoke registration method
    /// @param _voter Voter address
    /// @param _votes Governance tokens number to be placed as votes
    /// @param _totalVotes Total governance token placed as votes for all users
    event RegisterVoter(address _voter, uint256 _votes, uint256 _totalVotes);

    /// @notice Emits when voter invoke revoke method
    /// @param _voter Voter address
    /// @param _votes Governance tokens number to be removed as votes
    /// @param _totalVotes Total governance token removed as votes for all users
    event RevokeVoter(address _voter, uint256 _votes, uint256 _totalVotes);

    /// @notice Emits when reward for participation in voting processes is sent to governance contract
    /// @param _reward Amount of staking reward tokens
    event RewardAdded(uint256 _reward);

    /// @notice Emits when sum of governance token staked to governance contract
    /// @param _user User who stakes
    /// @param _amount Amount of governance token to stake
    event Staked(address indexed _user, uint256 _amount);

    /// @notice Emits when sum of governance token withdrawn from governance contract
    /// @param _user User who withdraw
    /// @param _amount Amount of governance token to withdraw
    event Withdrawn(address indexed _user, uint256 _amount);

    /// @notice Emits when reward for participation in voting processes is sent to user.
    /// @param _user Voter who receive rewards
    /// @param _reward Amount of staking reward tokens
    event RewardPaid(address indexed _user, uint256 _reward);

    /// @notice Period that your sake is locked to keep it for voting
    /// @dev voter => lock period
    mapping(address => uint256) public voteLock;

    /// @notice Exists to store proposals
    /// @dev id => proposal struct
    mapping(uint256 => Proposal) public proposals;

    /// @notice Amount of governance tokens staked as votes for each voter
    /// @dev voter => token amount
    mapping(address => uint256) public votes;

    /// @notice Exists to check if voter registered
    /// @dev user => is voter?
    mapping(address => bool) public voters;

    /// @notice Exists to keep history of rewards paid
    /// @dev voter => reward paid
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice Exists to track amounts of reward to be paid
    /// @dev voter => reward to pay
    mapping(address => uint256) public rewards;

    /// @notice Allow users to claim rewards instantly regardless of any voting process
    /// @dev Link (https://gov.yearn.finance/t/yip-47-release-fee-rewards/6013)
    bool public breaker = false;

    /// @notice Exists to generate ids for new proposals
    uint256 public proposalCount;

    /// @notice Voting period in blocks ~ 17280 3 days for 15s/block
    uint256 public period = 17280;

    /// @notice Vote lock in blocks ~ 17280 3 days for 15s/block
    uint256 public lock = 17280;

    /// @notice Minimal amount of governance token to allow proposal creation
    uint256 public minimum = 1e18;

    /// @notice Default quorum required in base points
    uint256 public quorum = 2000;

    /// @notice Total amount of governance tokens staked
    uint256 public totalVotes;

    /// @notice Token in which reward for voting will be paid
    IERC20 public rewardsToken;

    /// @notice Default duration of the voting process in seconds
    uint256 public constant DURATION = 7 days;

    /// @notice Time period in seconds during which rewards are paid
    uint256 public periodFinish = 0;

    /// @notice This variable regulates amount of staking reward token to be paid, it depends from period finish. The last claims the lowest reward
    uint256 public rewardRate = 0;

    /// @notice Amount of staking reward token per governance token staked
    uint256 public rewardPerTokenStored = 0;

    /// @notice Last time when rewards was added and recalculated
    uint256 public lastUpdateTime;

    /// @notice Default initialize method for solving migration linearization problem
    /// @dev Called once only by deployer
    /// @param _startId Starting ID (default 0)
    /// @param _rewardsTokenAddress Token in which rewards are paid
    /// @param _governance Governance address
    /// @param _governanceToken Governance token address
    function configure(
            uint256 _startId,
            address _rewardsTokenAddress,
            address _governance,
            address _governanceToken,
            address _rewardDistribution
    ) external initializer {
        proposalCount = _startId;
        rewardsToken = IERC20(_rewardsTokenAddress);
        _setGovernanceToken(_governanceToken);
        setGovernance(_governance);
        setRewardDistribution(_rewardDistribution);
    }

    /// @dev This methods evacuates given funds to governance address
    /// @param _token Exact token to evacuate
    /// @param _amount Amount of token to evacuate
    function seize(IERC20 _token, uint256 _amount) external onlyGovernance {
        require(_token != rewardsToken, "!rewardsToken");
        require(_token != governanceToken, "!governanceToken");
        _token.safeTransfer(governance, _amount);
    }

    /// @notice Usual setter
    /// @param _breaker New value
    function setBreaker(bool _breaker) external onlyGovernance {
        breaker = _breaker;
    }

    /// @notice Usual setter
    /// @param _quorum New value
    function setQuorum(uint256 _quorum) external onlyGovernance {
        quorum = _quorum;
    }

    /// @notice Usual setter
    /// @param _minimum New value
    function setMinimum(uint256 _minimum) external onlyGovernance {
        minimum = _minimum;
    }

    /// @notice Usual setter
    /// @param _period New value
    function setPeriod(uint256 _period) external onlyGovernance {
        period = _period;
    }

    /// @notice Usual setter
    /// @param _lock New value
    function setLock(uint256 _lock) external onlyGovernance {
        lock = _lock;
    }

    /// @notice Allows msg.sender exit from the whole governance process and withdraw all his rewards and governance tokens
    function exit() external {
        withdraw(balanceOf(_msgSender()));
        getReward();
    }

    /// @notice Adds to governance contract staking reward tokens to be sent to vote process participants.
    /// @param _reward Amount of staking rewards token in wei
    function notifyRewardAmount(uint256 _reward)
        external
        onlyRewardDistribution
        override
        updateReward(address(0))
    {
        IERC20(rewardsToken).safeTransferFrom(_msgSender(), address(this), _reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(_reward);
    }

    /// @notice Creates a proposal to vote
    /// @param _executor Executor contract address
    /// @param _hash IPFS hash of the proposal document
    function propose(address _executor, string memory _hash) public {
        require(votesOf(_msgSender()) > minimum, "<minimum");
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: _msgSender(),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            start: block.number,
            end: period.add(block.number),
            executor: _executor,
            hash: _hash,
            totalVotesAvailable: totalVotes,
            quorum: 0,
            quorumRequired: quorum,
            open: true
        });
        emit NewProposal(
            proposalCount,
            _msgSender(),
            block.number,
            period,
            _executor
        );
        proposalCount++;
        voteLock[_msgSender()] = lock.add(block.number);
    }

    /// @notice Called by third party to execute the proposal conditions
    /// @param _id ID of the proposal
    function execute(uint256 _id) public {
        (uint256 _for, uint256 _against, uint256 _quorum) = getStats(_id);
        require(proposals[_id].quorumRequired < _quorum, "!quorum");
        require(proposals[_id].end < block.number , "!end");
        if (proposals[_id].open) {
            tallyVotes(_id);
        }
        IExecutor(proposals[_id].executor).execute(_id, _for, _against, _quorum);
    }

    /// @notice Called by anyone to obtain the voting process statistics for specific proposal
    /// @param _id ID of the proposal
    /// @return _for 'For' percentage in base points
    /// @return _against 'Against' percentage in base points
    /// @return _quorum Current quorum percentage in base points
    function getStats(uint256 _id)
        public
        view
        returns(
            uint256 _for,
            uint256 _against,
            uint256 _quorum
        )
    {
        _for = proposals[_id].totalForVotes;
        _against = proposals[_id].totalAgainstVotes;
        uint256 _total = _for.add(_against);
        if (_total == 0) {
          _quorum = 0;
        } else {
          _for = _for.mul(10000).div(_total);
          _against = _against.mul(10000).div(_total);
          _quorum = _total.mul(10000).div(proposals[_id].totalVotesAvailable);
        }
    }

    /// @notice Synonimus name countVotes, called to stop voting process
    /// @param _id ID of the proposal to be closed
    function tallyVotes(uint256 _id) public {
        require(proposals[_id].open, "!open");
        require(proposals[_id].end < block.number, "!end");
        (uint256 _for, uint256 _against,) = getStats(_id);
        proposals[_id].open = false;
        emit ProposalFinished(
            _id,
            _for,
            _against,
            proposals[_id].quorum >= proposals[_id].quorumRequired
        );
    }

    /// @notice Called to obtain votes count for specific voter
    /// @param _voter To whom votes related
    /// @return Governance token staked to governance contract as votes
    function votesOf(address _voter) public view returns(uint256) {
        return votes[_voter];
    }

    /// @notice Registers new user as voter and adds his votes
    function register() public {
        require(!voters[_msgSender()], "voter");
        voters[_msgSender()] = true;
        votes[_msgSender()] = balanceOf(_msgSender());
        totalVotes = totalVotes.add(votes[_msgSender()]);
        emit RegisterVoter(_msgSender(), votes[_msgSender()], totalVotes);
    }

    /// @notice Nullify (revoke) all the votes staked by msg.sender
    function revoke() public {
        require(voters[_msgSender()], "!voter");
        voters[_msgSender()] = false;

        /// @notice Edge case dealt with in openzeppelin trySub methods.
        /// The case should be impossible, but this is defi.
        (,totalVotes) = totalVotes.trySub(votes[_msgSender()]);

        emit RevokeVoter(_msgSender(), votes[_msgSender()], totalVotes);
        votes[_msgSender()] = 0;
    }

    /// @notice Allow registered voter to vote 'for' proposal
    /// @param _id Proposal id
    function voteFor(uint256 _id) public {
        require(proposals[_id].start < block.number, "<start");
        require(proposals[_id].end > block.number, ">end");

        uint256 _against = proposals[_id].againstVotes[_msgSender()];
        if (_against > 0) {
            proposals[_id].totalAgainstVotes = proposals[_id].totalAgainstVotes.sub(_against);
            proposals[_id].againstVotes[_msgSender()] = 0;
        }

        uint256 vote = votesOf(_msgSender()).sub(proposals[_id].forVotes[_msgSender()]);
        proposals[_id].totalForVotes = proposals[_id].totalForVotes.add(vote);
        proposals[_id].forVotes[_msgSender()] = votesOf(_msgSender());

        proposals[_id].totalVotesAvailable = totalVotes;
        uint256 _votes = proposals[_id].totalForVotes.add(proposals[_id].totalAgainstVotes);
        proposals[_id].quorum = _votes.mul(10000).div(totalVotes);

        voteLock[_msgSender()] = lock.add(block.number);

        emit Vote(_id, _msgSender(), true, vote);
    }

    /// @notice Allow registered voter to vote 'against' proposal
    /// @param _id Proposal id
    function voteAgainst(uint256 _id) public {
        require(proposals[_id].start < block.number, "<start");
        require(proposals[_id].end > block.number, ">end");

        uint256 _for = proposals[_id].forVotes[_msgSender()];
        if (_for > 0) {
            proposals[_id].totalForVotes = proposals[_id].totalForVotes.sub(_for);
            proposals[_id].forVotes[_msgSender()] = 0;
        }

        uint256 vote = votesOf(_msgSender()).sub(proposals[_id].againstVotes[_msgSender()]);
        proposals[_id].totalAgainstVotes = proposals[_id].totalAgainstVotes.add(vote);
        proposals[_id].againstVotes[_msgSender()] = votesOf(_msgSender());

        proposals[_id].totalVotesAvailable = totalVotes;
        uint256 _votes = proposals[_id].totalForVotes.add(proposals[_id].totalAgainstVotes);
        proposals[_id].quorum = _votes.mul(10000).div(totalVotes);

        voteLock[_msgSender()] = lock.add(block.number);

        emit Vote(_id, _msgSender(), false, vote);
    }

    /// @dev Modifier to update stats when reward either sent to governance contract or to voter
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /// @notice Dynamic finish time getter
    /// @return Recalculated time when voting process needs to be finished
    function lastTimeRewardApplicable() public view returns(uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Dynamic reward per token amount getter
    /// @return Recalculated amount of staking reward tokens per governance token
    function rewardPerToken() public view returns(uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    /// @notice Calculate the size of reward for voter
    /// @param _account Voter address
    /// @return Amount of exact staking reward tokens to be paid
    function earned(address _account) public view returns(uint256) {
        return
            balanceOf(_account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
                .div(1e18)
                .add(rewards[_account]);
    }

    /// @notice Allow to add new governance tokens to voter weight, simultaneosly it recalculates reward size according to new weight
    /// @param _amount Amount of governance token to stake
    function stake(uint256 _amount) public override updateReward(_msgSender()) {
        require(_amount > 0, "!stake 0");
        if (voters[_msgSender()]) {
            votes[_msgSender()] = votes[_msgSender()].add(_amount);
            totalVotes = totalVotes.add(_amount);
        }
        super.stake(_amount);
        emit Staked(_msgSender(), _amount);
    }


    /// @notice Allow to remove old governance tokens from voter weight, simultaneosly it recalculates reward size according to new weight
    /// @param _amount Amount of governance token to withdraw
    function withdraw(uint256 _amount) public override updateReward(_msgSender()) {
        require(_amount > 0, "!withdraw 0");
        if (voters[_msgSender()]) {
            votes[_msgSender()] = votes[_msgSender()].sub(_amount);
            totalVotes = totalVotes.sub(_amount);
        }
        if (!breaker) {
            require(voteLock[_msgSender()] < block.number, "!locked");
        }
        super.withdraw(_amount);
        emit Withdrawn(_msgSender(), _amount);
    }

    /// @notice Transfer staking reward tokens to voter (msg.sender), simultaneosly it recalculates reward size according to new weight and rewards remaining
    function getReward() public updateReward(_msgSender()) {
        if (!breaker) {
            require(voteLock[_msgSender()] > block.number, "!voted");
        }
        uint256 reward = earned(_msgSender());
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.transfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }
}