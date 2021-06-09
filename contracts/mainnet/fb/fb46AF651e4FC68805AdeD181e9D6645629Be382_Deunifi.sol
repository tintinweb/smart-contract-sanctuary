// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { IUniswapV2Router02 } from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import { IUniswapV2Callee } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

import { ILendingPool } from "./ILendingPool.sol";
import { IFlashLoanReceiver } from "./IFlashLoanReceiver.sol";

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IFeeManager } from "./IFeeManager.sol";

uint256 constant MAX_UINT256 = ~uint256(0);


// // TODO Remove 
// import "hardhat/console.sol";

interface IDSProxy{

    function execute(address _target, bytes calldata _data)
        external
        payable;

    function setOwner(address owner_)
        external;

}

interface IWeth{
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IPsm{
    function buyGem(address usr, uint256 gemAmt) external;
    function sellGem(address usr, uint256 gemAmt) external;
}

contract Deunifi is IFlashLoanReceiver, Ownable {

    event LockAndDraw(address sender, uint cdp, uint collateral, uint debt);
    event WipeAndFree(address sender, uint cdp, uint collateral, uint debt);

    address public feeManager;

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint8 public constant WIPE_AND_FREE = 1;
    uint8 public constant LOCK_AND_DRAW = 2;

    fallback () external payable {}

    function setFeeManager(address _feeManager) public onlyOwner{
        feeManager = _feeManager;
    }

    struct PayBackParameters {
        address sender;
        address debtToken;
        uint debtToPay;
        address tokenA;
        address tokenB;
        address pairToken;
        uint collateralAmountToFree;
        uint collateralAmountToUseToPayDebt;
        uint debtToCoverWithTokenA;
        uint debtToCoverWithTokenB;
        address[] pathTokenAToDebtToken;
        address[] pathTokenBToDebtToken;
        uint minTokenAToRecive;
        uint minTokenBToRecive;
        uint deadline;
        address dsProxy;
        address dsProxyActions;
        address manager;
        address gemJoin;
        address daiJoin;
        uint cdp;
        address router02;
        address weth;

        // PSM swap parameters
        address tokenToSwapWithPsm;
        address tokenJoinForSwapWithPsm;
        address psm;
        uint256 psmSellGemAmount;
        uint256 expectedDebtTokenFromPsmSellGemOperation;

        address lendingPool;
    }
    
    function lockGemAndDraw(
        address gemToken,
        address dsProxy,
        address dsProxyActions,
        address manager,
        address jug,
        address gemJoin,
        address daiJoin, 
        uint cdp,
        uint collateralToLock,
        uint daiToBorrow,
        bool transferFrom
        ) internal {

        safeIncreaseMaxUint(gemToken, dsProxy, collateralToLock);

        IDSProxy(dsProxy).execute(
            dsProxyActions,
            abi.encodeWithSignature("lockGemAndDraw(address,address,address,address,uint256,uint256,uint256,bool)",
                manager, jug, gemJoin, daiJoin, cdp, collateralToLock, daiToBorrow, transferFrom)
        );

    }

    struct LockAndDrawParameters{

        address sender;

        address debtToken;

        address router02;
        address psm;

        address token0;
        uint256 debtTokenForToken0;
        uint256 token0FromDebtToken;
        address[] pathFromDebtTokenToToken0;
        bool usePsmForToken0;

        address token1;
        uint256 debtTokenForToken1;
        uint256 token1FromDebtToken;
        address[] pathFromDebtTokenToToken1;
        bool usePsmForToken1;

        uint256 token0FromUser;
        uint256 token1FromUser;

        uint256 minCollateralToBuy;
        uint256 collateralFromUser;

        address gemToken;
        address dsProxy;
        address dsProxyActions;
        address manager;
        address jug;
        address gemJoin;
        address daiJoin;
        uint256 cdp;
        uint256 debtTokenToDraw;
        bool transferFrom;

        uint256 deadline;

        address lendingPool;

    }

    function approveDebtToken(uint256 pathFromDebtTokenToToken0Length, uint256 pathFromDebtTokenToToken1Length,
        address debtToken, address router02, address psm,
        uint256 debtTokenForToken0, uint256 debtTokenForToken1,
        bool usePsmForToken0, bool usePsmForToken1) internal {
        
        uint256 amountToApproveRouter02 = 0;
        uint256 amountToApprovePsm = 0;

        if (pathFromDebtTokenToToken0Length > 0){
            if (usePsmForToken0)
                amountToApprovePsm = amountToApprovePsm.add(debtTokenForToken0);
            else
                amountToApproveRouter02 = amountToApproveRouter02.add(debtTokenForToken0);
        }

        if (pathFromDebtTokenToToken1Length > 0){
            if (usePsmForToken1)
                amountToApprovePsm = amountToApprovePsm.add(debtTokenForToken1);
            else
                amountToApproveRouter02 = amountToApproveRouter02.add(debtTokenForToken1);
        }

        if (amountToApproveRouter02 > 0){
            safeIncreaseMaxUint(debtToken, router02, 
                amountToApproveRouter02);
        }

        if (amountToApprovePsm > 0){
            safeIncreaseMaxUint(debtToken, psm, 
                amountToApprovePsm);
        }

    }

    function lockAndDrawOperation(bytes memory params) internal{

        ( LockAndDrawParameters memory parameters) = abi.decode(params, (LockAndDrawParameters));
        
        approveDebtToken(parameters.pathFromDebtTokenToToken0.length, parameters.pathFromDebtTokenToToken1.length,
            parameters.debtToken, parameters.router02, parameters.psm,
            parameters.debtTokenForToken0, parameters.debtTokenForToken1,
            parameters.usePsmForToken0, parameters.usePsmForToken1);

        uint token0FromDebtToken = 0;
        uint token1FromDebtToken = 0;
        uint boughtCollateral;

        // Swap debt token for gems or one of tokens that compose gems.
        if (parameters.debtTokenForToken0 > 0){

            if (parameters.debtToken == parameters.token0){

                token0FromDebtToken = parameters.debtTokenForToken0;

            } else {

                if (parameters.usePsmForToken0){

                    token0FromDebtToken = parameters.token0FromDebtToken;
                    
                    IPsm(parameters.psm).buyGem(address(this), token0FromDebtToken);

                }else{

                    token0FromDebtToken = IUniswapV2Router02(parameters.router02).swapExactTokensForTokens(
                        parameters.debtTokenForToken0, // exact amount for token 'from'
                        0, // min amount to recive for token 'to'
                        parameters.pathFromDebtTokenToToken0, // path of swap
                        address(this), // reciver
                        parameters.deadline
                        )[parameters.pathFromDebtTokenToToken0.length-1];

                }

            }

            boughtCollateral = token0FromDebtToken;

        }

        // Swap debt token the other token that compose gems.
        if (parameters.debtTokenForToken1 > 0){

            if (parameters.debtToken == parameters.token1){

                token1FromDebtToken = parameters.debtTokenForToken1;

            } else {

                if (parameters.usePsmForToken1){

                    token1FromDebtToken = parameters.token1FromDebtToken;
                    
                    IPsm(parameters.psm).buyGem(address(this), token1FromDebtToken);

                }else{

                    token1FromDebtToken = IUniswapV2Router02(parameters.router02).swapExactTokensForTokens(
                        parameters.debtTokenForToken1, // exact amount for token 'from'
                        0, // min amount to recive for token 'to'
                        parameters.pathFromDebtTokenToToken1, // path of swap
                        address(this), // reciver
                        parameters.deadline
                        )[parameters.pathFromDebtTokenToToken1.length-1];

                }

            }

        }

        if (parameters.token1FromUser.add(token1FromDebtToken) > 0){

            safeIncreaseMaxUint(parameters.token0, parameters.router02,
                parameters.token0FromUser.add(token0FromDebtToken));
            safeIncreaseMaxUint(parameters.token1, parameters.router02,
                parameters.token1FromUser.add(token1FromDebtToken));

            ( uint token0Used, uint token1Used, uint addedLiquidity) = IUniswapV2Router02(parameters.router02).addLiquidity(
                parameters.token0,
                parameters.token1,
                parameters.token0FromUser.add(token0FromDebtToken),
                parameters.token1FromUser.add(token1FromDebtToken),
                0,
                0,
                address(this), // reciver
                parameters.deadline
            );

            boughtCollateral = addedLiquidity;

            // Remaining tokens are returned to user.

            if (parameters.token0FromUser.add(token0FromDebtToken).sub(token0Used) > 0)
                IERC20(parameters.token0).safeTransfer(
                    parameters.sender,
                    parameters.token0FromUser.add(token0FromDebtToken).sub(token0Used));

            if (parameters.token1FromUser.add(token1FromDebtToken).sub(token1Used) > 0)
                IERC20(parameters.token1).safeTransfer(
                    parameters.sender,
                    parameters.token1FromUser.add(token1FromDebtToken).sub(token1Used));

        }

        require(boughtCollateral >= parameters.minCollateralToBuy, "Deunifi: Bought collateral lower than expected collateral to buy.");

        uint collateralToLock = parameters.collateralFromUser.add(boughtCollateral);

        lockGemAndDraw(
            parameters.gemToken,
            parameters.dsProxy,
            parameters.dsProxyActions,
            parameters.manager, 
            parameters.jug,
            parameters.gemJoin,
            parameters.daiJoin, 
            parameters.cdp,
            collateralToLock,
            parameters.debtTokenToDraw,
            parameters.transferFrom
        );

        // Fee Service Payment
        safeIncreaseMaxUint(parameters.debtToken, feeManager, 
            parameters.debtTokenToDraw); // We are passing an amount higher so it is not necessary to calculate the fee.

        if (feeManager!=address(0))
            // TODO parameters.sender
            IFeeManager(feeManager).collectFee(parameters.sender, parameters.debtToken, parameters.debtTokenToDraw);

        // Approve lending pool to collect flash loan + fees.
        safeIncreaseMaxUint(parameters.debtToken, parameters.lendingPool,
            parameters.debtTokenToDraw); // We are passing an amount higher so it is not necessary to calculate the fee.

        emit LockAndDraw(parameters.sender, parameters.cdp, collateralToLock, parameters.debtTokenToDraw);
        
    }

    function paybackDebt(PayBackParameters memory parameters) internal
        returns (uint freeTokenA, uint freeTokenB, uint freePairToken){

        parameters.debtToPay;

        wipeAndFreeGem(
            parameters.dsProxy,
            parameters.dsProxyActions,
            parameters.manager,
            parameters.gemJoin,
            parameters.daiJoin,
            parameters.cdp,
            parameters.collateralAmountToFree,
            parameters.debtToPay,
            parameters.debtToken
        );

        (uint remainingTokenA, uint remainingTokenB) = swapCollateralForTokens(
            SwapCollateralForTokensParameters(
                parameters.router02,
                parameters.tokenA,
                parameters.tokenB, // Optional in case of Uniswap Pair Collateral
                parameters.pairToken,
                parameters.collateralAmountToUseToPayDebt, // Amount of tokenA or liquidity to remove 
                                    // of pair(tokenA, tokenB)
                parameters.minTokenAToRecive, // Min amount remaining after swap tokenA for debtToken
                            // (this has more sense when we are working with pairs)
                parameters.minTokenBToRecive, // Optional in case of Uniswap Pair Collateral
                parameters.deadline,
                parameters.debtToCoverWithTokenA, // amount in debt token
                parameters.debtToCoverWithTokenB, // Optional in case of Uniswap Pair Collateral
                parameters.pathTokenAToDebtToken, // Path to perform the swap.
                parameters.pathTokenBToDebtToken, // Optional in case of Uniswap Pair Collateral
                parameters.tokenToSwapWithPsm,
                parameters.tokenJoinForSwapWithPsm,
                parameters.psm,
                parameters.psmSellGemAmount,
                parameters.expectedDebtTokenFromPsmSellGemOperation
            )
        );

        uint pairRemaining = 0;

        if (parameters.pairToken != address(0)){
            pairRemaining = parameters.collateralAmountToFree
                .sub(parameters.collateralAmountToUseToPayDebt);
        }

        return (remainingTokenA, remainingTokenB, pairRemaining);

    }

    function safeIncreaseMaxUint(address token, address spender, uint amount) internal {
        if (IERC20(token).allowance(address(this), spender) < amount){
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, MAX_UINT256);
        } 
    }

    /**
    Preconditions:
    - this should have enough `wadD` DAI.
    - DAI.allowance(this, daiJoin) >= wadD
    - All addresses should correspond with the expected contracts.
    */
    function wipeAndFreeGem(
        address dsProxy,
        address dsProxyActions,
        address manager,
        address gemJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadC,
        uint256 wadD,
        address daiToken
    ) internal {

        safeIncreaseMaxUint(daiToken, dsProxy, wadD);

        IDSProxy(dsProxy).execute(
            dsProxyActions,
            abi.encodeWithSignature("wipeAndFreeGem(address,address,address,uint256,uint256,uint256)",
                manager, gemJoin, daiJoin, cdp, wadC, wadD)
        );

    }
    
    struct SwapCollateralForTokensParameters{
        address router02; // Uniswap V2 Router
        address tokenA; // Token to be swap for debtToken
        address tokenB; // Optional in case of Uniswap Pair Collateral
        address pairToken;
        uint amountToUseToPayDebt; // Amount of tokenA or liquidity to remove 
                                   // of pair(tokenA, tokenB)
        uint amountAMin; // Min amount remaining after swap tokenA for debtToken
                         // (this has more sense when we are working with pairs)
        uint amountBMin; // Optional in case of Uniswap Pair Collateral
        uint deadline;
        uint debtToCoverWithTokenA; // amount in debt token
        uint debtToCoverWithTokenB; // Optional in case of Uniswap Pair Collateral
        address[] pathTokenAToDebtToken; // Path to perform the swap.
        address[] pathTokenBToDebtToken; // Optional in case of Uniswap Pair Collateral

        address tokenToSwapWithPsm;
        address tokenJoinForSwapWithPsm;
        address psm;
        uint256 psmSellGemAmount;
        uint256 expectedDebtTokenFromPsmSellGemOperation;
    }

    /**
    Preconditions:
    - this should have enough amountToUseToPayDebt, 
        tokenA for debtToCoverWithTokenA and 
        tokenb for debtToCoverWithTokenB and 
    - pair(tokenA, tokenB).allowance(this, router02) >= amountToUseToPayDebt.
    - tokenA.allowance(this, router02) >= (debtToCoverWithTokenA in token A)
    - tokenB.allowance(this, router02) >= (debtToCoverWithTokenB in token B)
    - All addresses should correspond with the expected contracts.
    - pair(tokenA, tokenB) should be a valid Uniswap V2 pair.
    */
    function swapCollateralForTokens(
        SwapCollateralForTokensParameters memory parameters
    ) internal returns (uint remainingTokenA, uint remainingTokenB) {
        
        uint amountA = 0;
        uint amountB = 0;
        uint amountACoveringDebt = 0;
        uint amountBCoveringDebt = 0;

        if (parameters.tokenB!=address(0)){

            safeIncreaseMaxUint(parameters.pairToken, parameters.router02, parameters.amountToUseToPayDebt);

            (amountA, amountB) = IUniswapV2Router02(parameters.router02).removeLiquidity(      
                parameters.tokenA,
                parameters.tokenB,
                parameters.amountToUseToPayDebt,
                0, // Min amount of token A to recive
                0, // Min amount of token B to recive
                address(this),
                parameters.deadline
            );

            if (parameters.debtToCoverWithTokenB > 0){
                
                if (parameters.pathTokenBToDebtToken.length == 0){

                    amountBCoveringDebt = parameters.debtToCoverWithTokenB;

                } else {

                    if (parameters.tokenToSwapWithPsm == parameters.tokenB){

                        safeIncreaseMaxUint(parameters.tokenB, parameters.tokenJoinForSwapWithPsm, 
                            parameters.psmSellGemAmount);

                        IPsm(parameters.psm).sellGem(address(this), parameters.psmSellGemAmount);

                        amountBCoveringDebt = parameters.psmSellGemAmount;

                    }else{

                        // IERC20(parameters.tokenB).safeIncreaseAllowance(parameters.router02, amountB.sub(parameters.amountBMin));
                        safeIncreaseMaxUint(parameters.tokenB, parameters.router02, 
                            amountB.mul(2));  // We are passing an amount higher because we do not know how much is going to be spent.
                        
                        amountBCoveringDebt = IUniswapV2Router02(parameters.router02).swapTokensForExactTokens(
                            parameters.debtToCoverWithTokenB,
                            amountB.sub(parameters.amountBMin), // amountInMax (Here we validate amountBMin)
                            parameters.pathTokenBToDebtToken,
                            address(this),
                            parameters.deadline
                        )[0];

                    }

                }

            }

        }else{

            // In case we are not dealing with a pair, we need 
            amountA = parameters.amountToUseToPayDebt;

        }

        if (parameters.debtToCoverWithTokenA > 0){

                if (parameters.pathTokenAToDebtToken.length == 0){

                    amountACoveringDebt = parameters.debtToCoverWithTokenA;

                } else {

                    if (parameters.tokenToSwapWithPsm == parameters.tokenA){

                        safeIncreaseMaxUint(parameters.tokenA, parameters.tokenJoinForSwapWithPsm, 
                            parameters.psmSellGemAmount);

                        IPsm(parameters.psm).sellGem(address(this), parameters.psmSellGemAmount);

                        amountACoveringDebt = parameters.psmSellGemAmount;

                    }else{

                        // IERC20(parameters.tokenA).safeIncreaseAllowance(parameters.router02, amountA.sub(parameters.amountAMin));
                        safeIncreaseMaxUint(parameters.tokenA, parameters.router02,
                            amountA.mul(2)); // We are passing an amount higher because we do not know how much is going to be spent.

                        amountACoveringDebt = IUniswapV2Router02(parameters.router02).swapTokensForExactTokens(
                            parameters.debtToCoverWithTokenA,
                            amountA.sub(parameters.amountAMin), // amountInMax (Here we validate amountAMin)
                            parameters.pathTokenAToDebtToken,
                            address(this),
                            parameters.deadline
                        )[0];

                    }

                }

        }

        return (
            amountA.sub(amountACoveringDebt),
            amountB.sub(amountBCoveringDebt)
            );

    }

    function wipeAndFreeOperation(bytes memory params) internal{

        ( PayBackParameters memory decodedData ) = abi.decode(params, (PayBackParameters));

        (uint remainingTokenA, uint remainingTokenB, uint pairRemaining) = paybackDebt(decodedData);

        require(remainingTokenA >= decodedData.minTokenAToRecive, "Deunifi: Remaining token lower than expected.");
        require(remainingTokenB >= decodedData.minTokenBToRecive, "Deunifi: Remaining token lower than expected.");

        // Fee Service Payment
        safeIncreaseMaxUint(decodedData.debtToken, feeManager, 
            decodedData.debtToPay); // We are passing an amount higher so it is not necessary to calculate the fee.

        if (feeManager!=address(0))
            IFeeManager(feeManager).collectFee(decodedData.sender, decodedData.debtToken, decodedData.debtToPay);

        // Conversion from WETH to ETH when needed.
        if (decodedData.weth != address(0)){

            uint wethBalance = 0;

            if (decodedData.tokenA == decodedData.weth){
                wethBalance = remainingTokenA;
                remainingTokenA = 0;
            }

            if (decodedData.tokenB == decodedData.weth){
                wethBalance = remainingTokenB;
                remainingTokenB = 0;
            }

            if (wethBalance>0){
                IWeth(decodedData.weth).withdraw(wethBalance);
                decodedData.sender.call{value: wethBalance}("");
            }
        }

        if (remainingTokenA > 0 || decodedData.minTokenAToRecive > 0){
            IERC20(decodedData.tokenA).safeTransfer(decodedData.sender, remainingTokenA);
        }

        if (remainingTokenB > 0 || decodedData.minTokenBToRecive > 0){
            IERC20(decodedData.tokenB).safeTransfer(decodedData.sender, remainingTokenB);
        }

        if (pairRemaining > 0){
            // We do not verify because pairRemaining because the contract should have only
            // the exact amount to transfer.
            IERC20(decodedData.pairToken).safeTransfer(decodedData.sender, pairRemaining);
        }

        safeIncreaseMaxUint(decodedData.debtToken, decodedData.lendingPool,
            decodedData.debtToPay.mul(2)); // We are passing an amount higher so it is not necessary to calculate the fee.

        emit WipeAndFree(decodedData.sender, decodedData.cdp, decodedData.collateralAmountToFree, decodedData.debtToPay);

    }

    struct Operation{
        uint8 operation;
        bytes data;
    }

    /**
        This function is called after your contract has received the flash loan amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {

        ( Operation memory operation ) = abi.decode(params, (Operation));

        if (operation.operation == WIPE_AND_FREE)
            wipeAndFreeOperation(operation.data);
        else if(operation.operation == LOCK_AND_DRAW)
            lockAndDrawOperation(operation.data);
        else
            revert('Easy Vault: Invalid operation.');

        return true;
    }

    /**
    Executed as DSProxy.
     */
    function flashLoanFromDSProxy(
        address owner, // Owner of DSProxy calling this function.
        address target, // Target contract that will resolve the flash loan.
        address[] memory ownerTokens, // owner tokens to transfer to target
        uint[] memory ownerAmounts, // owner token amounts to transfer to target
        address lendingPool,
        address[] memory loanTokens,
        uint[] memory loanAmounts,
        uint[] memory modes,
        bytes memory data,
        address weth // When has to use or recive ETH, else should be address(0)
        ) public payable{

        if (msg.value > 0){
            IWeth(weth).deposit{value: msg.value}();
            IERC20(weth).safeTransfer(
                target, msg.value
            );
        }

        IDSProxy(address(this)).setOwner(target);

        for (uint i=0; i<ownerTokens.length; i=i.add(1)){
            IERC20(ownerTokens[i]).safeTransferFrom(
                owner, target, ownerAmounts[i]
            );
        }

        ILendingPool(lendingPool).flashLoan(
            target,
            loanTokens,
            loanAmounts,
            modes, // modes: 0 = no debt, 1 = stable, 2 = variable
            target, // onBehalfOf
            data,
            0 // referralCode
        );

        IDSProxy(address(this)).setOwner(owner);
        
    }

}

pragma solidity 0.7.6;

interface IFeeManager{

    function collectFee(address sender, address debtToken, uint baseAmount) external;

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface ILendingPool{

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function FLASHLOAN_PREMIUM_TOTAL()
        external view
        returns(uint256);

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}