/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// File: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

// File: contracts/interfaces/IMasterChef.sol



pragma solidity ^0.6.12;

interface IMasterChef {
    function cakePerBlock() view external returns(uint);
    function totalAllocPoint() view external returns(uint);

    function poolInfo(uint _pid) view external returns(address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint _pid, address _account) view external returns(uint amount, uint rewardDebt);
    function poolLength() view external returns(uint);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

}

// File: contracts/interfaces/IStakingRewardCompound.sol



pragma solidity ^0.6.12;

interface IStakingRewardCompound {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external ;

    function withdraw(uint256 amount) external ;

    function getReward() external;

    function exit(uint256 amount) external;

}

// File: contracts/interfaces/IPancakeRouter01.sol


pragma solidity 0.6.12;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/interfaces/IPancakeRouter02.sol


pragma solidity 0.6.12;


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/interfaces/IBank.sol


pragma solidity ^0.6.12;

interface IBank {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a `Transfer` event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through `transferFrom`. This is
   * zero by default.
   *
   * This value changes when `approve` or `transferFrom` are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * > Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an `Approval` event.
   */
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a `Transfer` event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /// @dev Return the total BNB entitled to the token holders. Be careful of unaccrued interests.
  function totalBNB() external view returns (uint);

  /// @dev Add more BNB to the bank. Hope to get some good returns.
  function deposit() external payable;

  /// @dev Withdraw BNB from the bank by burning the share tokens.
  function withdraw(uint share) external;
}

// File: contracts/interfaces/ISnowBank.sol



pragma solidity ^0.6.12;

/**
 * This interface is only to facilitate
 * interacting with the contract in remix.ethereum.org
 * after it has been deployed to a testnet or mainnet.
 *
 * Just copy/paste the interface in Remix and deploy
 * at contract address.
 */

interface ISnowBank {

  function TAX() external view returns (uint256);

  function DIVIDER() external view returns (uint256);

  function tempest() external view returns (address);

  function totalInterestClaimed() external view returns (uint256);

  function totalReserve() external view returns (uint256);

  function reserve() external view returns (address);

  function vault() external view returns (address);

  function invest(uint256) external;

  function sell(uint256) external;

  function claimInterest() external;

  function totalClaimRequired() external view returns (uint256);

  function claimRequired(uint256) external view returns (uint256);

  function totalContributed() external view returns (uint256);

  function getInterest() external view returns (uint256);

  function getTotalSupply() external view returns (uint256);

  function getBurnedTokensAmount() external view returns (uint256);

  function getCurrentTokenPrice() external view returns (uint256);

  function getReserveToTokensTaxed(uint256) external view returns (uint256);

  function getTokensToReserveTaxed(uint256) external view returns (uint256);

  function getReserveToTokens(uint256) external view returns (uint256);

  function getTokensToReserve(uint256) external view returns (uint256);
}

// File: contracts/SBVPcsCompoundV2.sol



pragma solidity 0.6.12;







// Inheritance






contract SBVPcsCompoundV2 is IStakingRewardCompound, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ============= */

    address public constant blizzardPool = 0x2Dcf7FB5F83594bBD13C781f5b8b2a9F55a4cdbb;

    IMasterChef public MASTER_CHEF;

    uint256 public slippageFactor;
    address public uniRouterAddress;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant XBLZD = 0x9a946c3Cb16c08334b69aE249690C236Ebd5583E;
    address public constant PcsRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken;
    address public earnedAddress;
    address public GALE ;
    address public snowBank;

    uint256 public wantLockedTotal = 0;
    uint256 public sharesTotal = 0;

    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public rewardsDuration;

    uint256 public lastUpdateTime;
    uint256 public periodFinish;

    uint256 public pid;
    address public admin;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping (address => bool) public whitelisted;
    mapping (address => bool) public rewardsDistributions;
    mapping(address => uint256) public balances;

    bool public emergencyStop;
    bool public isCakeStaking;

    address public token0Address;
    address public token1Address;

    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public earnedToBUSDPath;

    address[] public BUSDToxBLZDPath;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _snowBank,
        address _gale,
        bool _isCakeStaking,
        uint256 _pid,
        address _earnedAddress,
        address _farmAddress,
        address _uniRouterAddress,
        address _admin
    ) public initializer {
        (address _stakingToken,,,) = IMasterChef(_farmAddress).poolInfo(_pid);

        pid = _pid;
        snowBank = _snowBank;
        GALE = _gale;
        isCakeStaking = _isCakeStaking;
        earnedAddress = _earnedAddress;
        MASTER_CHEF = IMasterChef(_farmAddress);
        uniRouterAddress = _uniRouterAddress;
        admin = _admin;

        earnedToBUSDPath = [_earnedAddress, WBNB, BUSD];
        BUSDToxBLZDPath = [BUSD,XBLZD];

        if(!_isCakeStaking){
          token0Address = IUniswapV2Pair(_stakingToken).token0();
          token1Address = IUniswapV2Pair(_stakingToken).token1();

          earnedToToken0Path = [_earnedAddress, WBNB, token0Address];
          if (WBNB == token0Address) {
              earnedToToken0Path = [_earnedAddress, WBNB];
          }
          earnedToToken1Path = [_earnedAddress, WBNB, token1Address];
          if (WBNB == token1Address) {
              earnedToToken1Path = [_earnedAddress, WBNB];
          }
        }

        IERC20(_stakingToken).safeApprove(address(_farmAddress), uint256(-1));
        stakingToken = IERC20(_stakingToken);
        IERC20(_earnedAddress).safeApprove(address(_uniRouterAddress), uint256(-1));
        IERC20(BUSD).safeApprove(address(_snowBank), uint256(-1));
        IERC20(BUSD).safeApprove(address(PcsRouter), uint256(-1));

        rewardsDuration = 24 hours;
        slippageFactor = 950;
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
        if (sharesTotal == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(sharesTotal)
            );
    }

    function earned(address account) public view override returns (uint256) {
        return balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function stakedWantTokens(address _user) external view returns (uint256)
    {
        if (sharesTotal == 0) {
            return 0;
        }
        return balances[_user].mul(wantLockedTotal).div(sharesTotal);
    }

    // View function to see staked Want tokens on frontend.


    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender)
     onlyWhitelistOrEOA
     isNotEmergencyStop
     {
        require(amount > 0, "Cannot stake 0");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
         // fee 0.1% go to blizzardPool
        uint256 depositFee = amount.div(1000);

        stakingToken.safeTransfer(blizzardPool, depositFee);
        uint256 amounAfterFee =  amount.sub(depositFee);
        uint256 sharesAdded = amounAfterFee;

        if (wantLockedTotal > 0) {
            sharesAdded = amounAfterFee
                .mul(sharesTotal)
                .div(wantLockedTotal);
        }

        sharesTotal = sharesTotal.add(sharesAdded);
        wantLockedTotal = wantLockedTotal.add(amounAfterFee);
        balances[msg.sender] = balances[msg.sender].add(sharesAdded);

        if(isCakeStaking){
          MASTER_CHEF.enterStaking(amounAfterFee);
        }else{
          MASTER_CHEF.deposit(pid, amounAfterFee);
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        balances[msg.sender] = balances[msg.sender].sub(amount);

        uint256 amountLP = amount.mul(wantLockedTotal).div(sharesTotal);

        if(emergencyStop != true){
          if(isCakeStaking){
            MASTER_CHEF.leaveStaking(amountLP);
          }else{
            MASTER_CHEF.withdraw(pid, amountLP);
          }
        }

        // shared removed //
        uint256 sharesRemoved = amount;
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        wantLockedTotal = wantLockedTotal.sub(amountLP);

        stakingToken.safeTransfer(msg.sender, amountLP);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {

        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20 rewardsToken = IERC20(GALE);

            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit(uint256 amount) external override {
        withdraw(amount);
        getReward();
    }

    function harvest() public onlyWhitelistOrEOA isNotEmergencyStop {
        if(isCakeStaking){
          MASTER_CHEF.leaveStaking(0);
        }else{
          MASTER_CHEF.withdraw(pid, 0);
        }
        _harvest();
    }

    function notifyRewardAmount(uint256 reward) public onlyRewardsDistribution {
        IERC20 rewardsToken = IERC20(GALE);

        IERC20(rewardsToken).safeTransferFrom(msg.sender, address(this), reward);
        _notifyRewardAmount(reward);
    }


    receive () external payable {}

    /* ========== RESTRICTED FUNCTIONS ========== */


    function _harvest() private {
        require(sharesTotal > 0 , "!zero share");

        uint256 earnAmt = IERC20(earnedAddress).balanceOf(address(this));

        // swap 52.75% of reward to BUSD
        uint256 earnAmtToBUSD = earnAmt.mul(5275).div(10000);
        if(earnAmt > 0){
          _safeSwap(
              uniRouterAddress,
              earnAmtToBUSD,
              slippageFactor,
              earnedToBUSDPath,
              address(this),
              block.timestamp.add(600)
          );
        }
        uint256 amountBusd = IERC20(BUSD).balanceOf(address(this));

        // 47.25 in 52.75 busd to invest for gale
        uint256 usdAmountForGale = amountBusd.mul(4725).div(5275);
        uint256 GaleBefore = IERC20(GALE).balanceOf(address(this));
        ISnowBank(snowBank).invest(usdAmountForGale);
        uint256 amountGale = IERC20(GALE).balanceOf(address(this)).sub(GaleBefore);

        if (amountGale > 0) {
            _notifyRewardAmount(amountGale);
        }

        // 4 in 52.75 busd from busd to blizzardPool
        uint256 usdBlizzardPool = amountBusd.mul(400).div(5275);
        IERC20(BUSD).safeTransfer(blizzardPool, usdBlizzardPool);

        // remaining go to caller 1.5%
        uint256 harvestCallerAmt = amountBusd.sub(usdAmountForGale).sub(usdBlizzardPool);
        uint256 beforeXblzd = IERC20(XBLZD).balanceOf(address(this));

        //swap busd to xblzd
        if(harvestCallerAmt > 0){
          _safeSwap(
              PcsRouter,
              harvestCallerAmt,
              slippageFactor,
              BUSDToxBLZDPath,
              address(this),
              block.timestamp.add(600)
          );
        }
        uint256 afterXblzd = IERC20(XBLZD).balanceOf(address(this));

        IERC20(XBLZD).safeTransfer(msg.sender,
            afterXblzd.sub(beforeXblzd)
        );

         // 47.25% go to compound
        uint256 earnAmountForComp = earnAmt.sub(earnAmtToBUSD);

        if(!isCakeStaking){
          //swap cake to other
          if(token0Address != earnedAddress){
            _safeSwap(
                uniRouterAddress,
                earnAmountForComp.div(2),
                slippageFactor,
                earnedToToken0Path,
                address(this),
                block.timestamp.add(600)
            );
          }

          if(token1Address != earnedAddress){
            _safeSwap(
                uniRouterAddress,
                earnAmountForComp.div(2),
                slippageFactor,
                earnedToToken1Path,
                address(this),
                block.timestamp.add(600)
            );
          }
          // Add liquidity
          _safeAddLiquidityCompound();
        }

        uint256 compLp = IERC20(stakingToken).balanceOf(address(this));
        if(isCakeStaking){
          MASTER_CHEF.enterStaking(compLp);
        }else{
          MASTER_CHEF.deposit(pid, compLp);
        }
        wantLockedTotal = wantLockedTotal.add(compLp);

        emit Harvested(earnAmt);
    }

    function _notifyRewardAmount(uint256 reward) internal updateReward(address(0)) {

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        IERC20 rewardsToken = IERC20(GALE);
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
        emit AdminSet(_admin);
    }

    function setSlippageFactor(uint256 _slippageFactor) external onlyAdmin {
        require(_slippageFactor < 1000, "Cannot be 100% of slippage");
        slippageFactor = _slippageFactor;
        emit SlippageFactorSet(_slippageFactor);
    }

    function addWhiteList(address _whitelistAddress) public onlyAdmin
    {
        whitelisted[_whitelistAddress] = true;
        emit AddWhiteListAddress(_whitelistAddress);
    }

    function removeWhiteList(address _whitelistAddress) public onlyAdmin
    {
        whitelisted[_whitelistAddress] = false;
        emit RemoveWhiteListAddress(_whitelistAddress);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyAdmin {
        require(periodFinish == 0 || block.timestamp > periodFinish, "Reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function panic() public onlyAdmin {
        emergencyStop = true;
        MASTER_CHEF.emergencyWithdraw(pid);
        emit EmergencyWithdrawLp(emergencyStop);
    }

    function approveMax(address token, address spender) public onlyAdmin {
      uint256 max = uint256(-1);
      IERC20(token).safeApprove(spender, max);
    }

    function approveValue(address token, address spender, uint256 amount) public onlyAdmin {
      IERC20(token).safeApprove(spender, amount);
    }

    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual {
        uint256[] memory amounts =
            IPancakeRouter02(_uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IPancakeRouter02(_uniRouterAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut.mul(_slippageFactor).div(1000),
            _path,
            _to,
            _deadline
        );
    }

    function _safeAddLiquidityCompound() internal virtual {

      // Get want tokens, ie. add liquidity
      uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
      uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));

      if (token0Amt > 0 && token1Amt > 0) {
          /* IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
          );
          IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
          ); */
          IPancakeRouter02(uniRouterAddress).addLiquidity(
              token0Address,
              token1Address,
              token0Amt,
              token1Amt,
              0,
              0,
              address(this),
              block.timestamp.add(600)
          );
      }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardsDistribution() {
        require(rewardsDistributions[msg.sender] , "Caller is not RewardsDistribution contract");
        _;
    }

    modifier onlyWhitelistOrEOA() {
        require(msg.sender == tx.origin || whitelisted[msg.sender] , "Caller is not EOA or whitelisted contract");
        _;
    }

    modifier isNotEmergencyStop() {
        require(!emergencyStop , "Emergency Stop");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Harvested(uint256 amount);
    event RewardsDurationUpdated(uint256 newDuration);
    event AddWhiteListAddress(address indexed whitelistAddress);
    event RemoveWhiteListAddress(address indexed whitelistAddress);
    event EmergencyWithdrawLp(bool _emergencyStop);
    event AdminSet(address admin);
    event SlippageFactorSet(uint256 _slippageFactor);

}