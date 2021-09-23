/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-14
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IPancakeERC20 {
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
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

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
    constructor ()  {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
    * - Subtraction cannot overflow.
    */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    * - The divisor cannot be zero.
    */
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IGiftingHandler {
    
    //MANAGEMENT FUNCTIONS
    
    //BUYBACK
    function giftBuyBack() external;
    
    //GIFTING FUNCTIONS
    
    //GIFTING
    function giftTokens(uint256 _option, bytes32 _hash, uint256 _referralID) external payable returns(uint256, uint256);
    function giftUsdVoucher(uint256 _option, bytes32 _hash, uint256 _referralID) external payable returns(uint256, uint256);
    function giftNFT(bytes32 _hash, uint256 _referralID, address _nftAddress, uint256 _nftID) external payable returns(uint256, uint256);
    
    //REDEEMING
    function redeemGiftedTokens(address payable _recipient, string memory _redemptionString, uint256 _giftID) external;
    function redeemUSDVoucher(address payable _recipient, string memory _redemptionString, uint256 _giftID, uint256 _redeemUsdOption) external;
    function redeemNFT(address payable _recipient, string memory _redemptionString, uint256 _giftID) external;
    
    //RECOVERING
    function recoverGiftedTokens(uint256 _giftID) external;
    function recoverUSDVoucher(uint256 _giftID) external;
    function recoverNFT(uint256 _giftID) external;
    
    //GIFTING VIEW FUNCTIONS
    
    //GIFT PACKAGES
    function viewGiftTokensOptionsLength() external view returns(uint256);
    function viewGiftedTokensOption(uint256 _option) external view returns(uint256, uint256, uint256, uint256, uint256, address[] memory, uint256[] memory);
    function viewGiftedTokens(uint256 _giftID) external view returns(uint256, bool);
    function viewGiftedTokensIndexes(address _sender) external view returns(uint256[] memory);
    
    //GIFT USD VOUCHERS
    function viewGiftedUSDVoucherOptionsLength() external view returns(uint256);
    function viewGiftedUSDVoucherOption(uint256 _optionID) external view returns(uint256, uint256, uint256, uint256);
    function viewGiftedUSDVouchers(uint256 _giftID) external view returns(uint256, bool );
    function viewGiftedUSDVouchersIndexes(address _sender) external view returns(uint256[] memory);
    
    //GIFT NFTS
    function viewGiftedNFTs(uint256 _giftID) external view returns(address, uint256, bool);
    function viewGiftedNFTsIndexes(address _sender) external view returns(uint256[] memory);
    function viewGiftNFTCosts() external view returns(uint256, uint256, uint256, uint256);

    //REFERRAL FUNCTIONS
    function withdrawReferralFunds() external;
    function queryReferrerByAddress(address _referrer) external view returns(uint256, uint256, uint256, uint256, bool);
    
}

contract GiftingHandler is IGiftingHandler, Ownable, ReentrancyGuard {
   
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //GIFT PACKAGES DATA
    
    struct giftTokensOption {
        
        uint256 giftFee;
        uint256 redeemRefundFee;
        uint256 referralFee;
        uint256 gasTopUp;
        uint256 giftAmount;
        uint256 BnbCost;
        address[] tokens;
        uint256[] tokenWeights;
    } 
    
    struct giftedTokens {
        
        uint256 option;
        address payable sender;
        bytes32 hash;
        bool redeemed;

    }    
    
    giftedTokens[] private giftedTokensArr;
    giftTokensOption[] private giftedTokensOptionsArr;
    mapping(address => uint256[]) private addyToGiftedTokensSent;
    
    //GIFT USD VOUCHERS DATA
    
    struct giftUsdVoucherOption {
        
        uint256 giftFee;
        uint256 redeemRefundFee;
        uint256 referralFee;
        uint256 gasTopUp;
        uint256 giftAmount;
        uint256 bnbCost;
        
    }
    
    struct giftedUsdVoucher {
        
        uint256 option;
        address payable sender;
        bytes32 hash;
        bool redeemed;
        
    }
    
    giftedUsdVoucher[] private giftedUsdVoucherArr;
    giftUsdVoucherOption[] private giftUsdVoucherOptionArr;
    mapping(address => uint256[]) private addyToGiftedUsdVoucherSent;
    
    struct redeemUsdVoucherOption {
        address[] tokens;
        uint256[] tokenWeights; 
    }
    
    redeemUsdVoucherOption[] private redeemUsdVoucherOptionArr;
    
    //GIFT NFT DATA
    
    struct giftedNFT {
        
        address payable sender;
        address nft;
        uint256 tokenID;
        bytes32 hash;
        bool redeemed;
        
    }
    
    uint256 NFTGiftFee;
    uint256 NFTRedeemRefundFee;
    uint256 NFTReferralFee;
    uint256 NFTGasTopUp;
    
    giftedNFT[] private giftedNFTArr;
    mapping(address => uint256[]) private addyToGiftedNFTSent;
    
    //LOTTERY DATA
    
    GIFTLottery lottery;
        
        
    //REFERRALS DATA
    
    struct referrer {

        uint256 balance;
        uint256 totalEarned;
        uint256 referrals;
        uint256 referralSales;
    }    
    
    mapping(address => uint256) private refaddyToUID;
    mapping(address => uint256) private customerToReferrerUID;
    mapping(uint256 => referrer) private UIDToReferrer;
    
    uint256 private currentID;
    
    //BALANCE COUNTERS
    
    uint256 private bnbGiftFeesBalance;
    
    //MANAGEMENT ADDRESSES
    
    address payable private redeemer;
    address payable private manager;
    address payable private buybackAdmin;
    address payable private admin;
    
    //POOL ADDRESSES
    
    address payable private buybackPool;
    
    //PANCAKESWAP DATA
    
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IPancakeRouter02 private  _pancakeRouter;
    
    //TOKEN DATA
    
    address private busdTokenAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    IERC20 private busdToken = IERC20(busdTokenAddress);
    
    address private giftTokenAddress;
    IERC20 private giftToken;
    
    //COUNTERS
    
    uint256 private redeemCounter;
    uint256 private refundCounter;
    uint256 public bnbGiftFeesAccrued;
    
    //CONSTRUCTOR 
    
    constructor(address payable _marketing, address _giftToken, uint256 _NFTRedeemRefund, uint256 _NFTGasTopUp)  {
        
        //Balance INITIALIZATION

        bnbGiftFeesBalance = 0;
        
        //Counter INITIALIZATION
        
        bnbGiftFeesAccrued = 0;
        redeemCounter = 0;
        refundCounter = 0;
        
        //NFT INITIALIZATION
        
        NFTRedeemRefundFee = _NFTRedeemRefund;
        NFTGasTopUp = _NFTGasTopUp;
        
        //MANAGER INITIALIZATION
        redeemer = msg.sender;
        manager = msg.sender;
        buybackAdmin = msg.sender;
        admin = msg.sender;
        
        //REFERAL INITIALIZATION;
        currentID = 2;
        refaddyToUID[_marketing] = 1;
        UIDToReferrer[1] = referrer(0, 0, 0, 0);
        
        //PANCAKESWAP INITIALIZATION
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        
        //TOKEN INITIALIZATION
        giftTokenAddress = _giftToken;
        giftToken = IERC20(giftTokenAddress);
        
        lottery = new GIFTLottery(_giftToken, address(this), 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, 0x404460C6A5EdE2D891e8297795264fDe62ADBB75, 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c, 0.2 * 10 ** 18);
        
    }
    
    //MAMAGER SECTION
    
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    modifier onlyBuybackAdmin() {
        require(msg.sender == buybackAdmin);
        _;
    }
    
    modifier onlyRedeemer() {
        require(msg.sender == redeemer);
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function changeManager(address payable _manager) onlyManager external  {
        manager = _manager;
    }
    
    function changeAdmins(address payable _buybackAdmin, address payable _redeemer, address payable _admin) onlyManager external  {
        buybackAdmin = _buybackAdmin;
        redeemer = _redeemer;
        admin = _admin;
    }

    function changeGiftToken(address _token) external onlyManager  {
        giftTokenAddress = _token;
        giftToken = IERC20(giftTokenAddress);
    }
    
    function changeBuybackPool(address payable _pool) external onlyManager {
        buybackPool = _pool;
    }
    
    //BUYBACK ADMIN
    
    function giftBuyBack() external onlyBuybackAdmin override {
        
        require(bnbGiftFeesBalance > 0, "NO FEES IN BALANCE");
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = giftTokenAddress;
        
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbGiftFeesBalance} (
            0,
            path,
            buybackPool,
            block.timestamp+10
            );
        
        bnbGiftFeesAccrued = bnbGiftFeesAccrued + bnbGiftFeesBalance;
        bnbGiftFeesBalance = 0;
        
    }
    
    //ADMIN
    
    function addGiftTokenOption(uint256 _giftFee, uint256 _redeemRefundFee, uint256 _referralFee, uint256 _gasTopUp, uint256 _giftAmount, uint256 _bnbCost, address[] memory _tokens, uint256[] memory _tokenWeights) external onlyAdmin  {
        giftedTokensOptionsArr.push(giftTokensOption(_giftFee, _redeemRefundFee, _referralFee, _gasTopUp, _giftAmount, _bnbCost, _tokens, _tokenWeights));
    }
    
    function changeGiftTokenOptionTokens(address[] memory _tokens, uint256[] memory _tokenWeights, uint256 _option) external onlyAdmin  {
        require(_option < giftedTokensOptionsArr.length, "INVALID OPTION");
        giftedTokensOptionsArr[_option].tokens = _tokens;
        giftedTokensOptionsArr[_option].tokenWeights = _tokenWeights;
    }
    
    function addGiftUsdVoucherOption(uint256 _giftFee, uint256 _redeemRefundFee, uint256 _referralFee, uint256 _gasTopUp, uint256 _giftAmount, uint256 _bnbCost) external onlyAdmin  {
        
        giftUsdVoucherOptionArr.push(giftUsdVoucherOption(_giftFee, _redeemRefundFee, _referralFee, _gasTopUp, _giftAmount, _bnbCost));
    }
    
    function addGiftUsdVoucherRedeemOption(address[] memory _tokens, uint256[] memory _tokenWeights) external onlyAdmin  {
        redeemUsdVoucherOptionArr.push(redeemUsdVoucherOption(_tokens, _tokenWeights));
    }
    
    function changeGiftUsdVoucherRedeemOption(address[] memory _tokens, uint256[] memory _tokenWeights, uint256 _option) external onlyAdmin  {
        require(_option < redeemUsdVoucherOptionArr.length, "INVALID OPTION");
        redeemUsdVoucherOptionArr[_option].tokens = _tokens;
        redeemUsdVoucherOptionArr[_option].tokenWeights = _tokenWeights;
    }
    
    function changeNFTCosts(uint256 _giftFee, uint256 _referralFee) external onlyAdmin  {
        NFTGiftFee = _giftFee;
        NFTReferralFee = _referralFee;
    }
    
    
    //GIFTING SECTION
   
    function giftTokens(uint256 _option, bytes32 _hash, uint256 _referralID) external payable nonReentrant override returns(uint256, uint256) {
        
        require(_option < giftedTokensOptionsArr.length, "NOT VALID OPTION");
        require(msg.value == giftedTokensOptionsArr[_option].BnbCost, "INCORRECT COST");
        
        giftedTokensArr.push(giftedTokens(_option, msg.sender, _hash, false));
        addyToGiftedTokensSent[msg.sender].push(giftedTokensArr.length-1);
        bnbGiftFeesBalance = bnbGiftFeesBalance.add(giftedTokensOptionsArr[_option].giftFee);
       
        return(giftedTokensArr.length-1, payReferrer(_referralID, giftedTokensOptionsArr[_option].referralFee));
       
    }
    
    function giftUsdVoucher(uint256 _option, bytes32 _hash, uint256 _referralID) external payable nonReentrant override returns(uint256, uint256) {
        
        require(_option < giftUsdVoucherOptionArr.length, "NOT VALID OPTION");
        require(msg.value == giftUsdVoucherOptionArr[_option].bnbCost, "INCORRECT COST");
        require(busdToken.allowance(msg.sender, address(this)) >= giftUsdVoucherOptionArr[_option].giftAmount, "NOT APPROVED");
        require(busdToken.balanceOf(msg.sender) >= giftUsdVoucherOptionArr[_option].giftAmount, "INSUFFICIENT BUSD");
            
        busdToken.safeTransferFrom(msg.sender, address(this), giftUsdVoucherOptionArr[_option].giftAmount);
        giftedUsdVoucherArr.push(giftedUsdVoucher(_option, msg.sender, _hash, false));
        addyToGiftedUsdVoucherSent[msg.sender].push(giftedUsdVoucherArr.length-1);
        bnbGiftFeesBalance = bnbGiftFeesBalance.add(giftUsdVoucherOptionArr[_option].giftFee);
        
        return(giftedUsdVoucherArr.length-1, payReferrer(_referralID, giftUsdVoucherOptionArr[_option].referralFee));
    }
    
    function giftNFT(bytes32 _hash, uint256 _referralID, address _nftAddress, uint256 _nftID) external payable nonReentrant override returns(uint256, uint256) {
        
        require(IERC721(_nftAddress).getApproved(_nftID) == address(this), "NOT APPROVED");
        require(msg.value == NFTGiftFee.add(NFTReferralFee).add(NFTGasTopUp).add(NFTRedeemRefundFee), "INCORRECT COST");
        
        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _nftID);
        giftedNFTArr.push(giftedNFT(msg.sender, _nftAddress, _nftID, _hash, false));
        bnbGiftFeesBalance = bnbGiftFeesBalance.add(NFTGiftFee);
        
        return(giftedNFTArr.length-1, payReferrer(_referralID, NFTReferralFee));
        
    }
    
    //REDEEMING SECTION
    
    function redeemGiftedTokens(address payable _recipient, string memory _redemptionString, uint256 _giftID) external nonReentrant override onlyRedeemer {

        require(_giftID < giftedTokensArr.length, "NOT VALID GIFT");
        require(giftedTokensArr[_giftID].redeemed == false, "GIFT REDEEMED");
        require(keccak256(abi.encodePacked(_redemptionString)) == giftedTokensArr[_giftID].hash, "WRONG REDEMPTION CODE");
                
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
                
        for(uint256 i = 0; i<giftedTokensOptionsArr[giftedTokensArr[_giftID].option].tokens.length; i++) {
                
            path[1] = giftedTokensOptionsArr[giftedTokensArr[_giftID].option].tokens[i];  //ChosenToken
            
            if (path[0] == path[1]) {
                _recipient.transfer(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].tokenWeights[i].mul(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].giftAmount).div(100));
            } else {
                _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: (giftedTokensOptionsArr[giftedTokensArr[_giftID].option].tokenWeights[i].mul(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].giftAmount)).div(100)}(
                0,
                path,
                _recipient,
                block.timestamp+10
                );                
            }
                
                        
        }
        
        redeemGasAndRefund(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].gasTopUp, giftedTokensOptionsArr[giftedTokensArr[_giftID].option].redeemRefundFee, giftedTokensArr[_giftID].sender, _recipient);
        giftedTokensArr[_giftID].redeemed = true;
        
    }
    
    function redeemUSDVoucher(address payable _recipient, string memory _redemptionString, uint256 _giftID, uint256 _redeemUsdOption) external nonReentrant onlyRedeemer override {

        require(_giftID < giftedUsdVoucherArr.length, "NOT VALID GIFT");
        require(giftedUsdVoucherArr[_giftID].redeemed == false, "GIFT REDEEMED");
        require(_redeemUsdOption < redeemUsdVoucherOptionArr.length, "NOT VALID REDEEM OPTION");
        require(keccak256(abi.encodePacked(_redemptionString)) == giftedUsdVoucherArr[_giftID].hash, "WRONG REDEMPTION CODE");
        
        busdToken.approve(PancakeRouter, giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].giftAmount);
        address[] memory path = new address[](2);
        path[0] = busdTokenAddress; //BUSD
            
            
        for(uint256 i = 0; i<redeemUsdVoucherOptionArr[_redeemUsdOption].tokens.length; i++) {
            path[1] = redeemUsdVoucherOptionArr[_redeemUsdOption].tokens[i];  //ChosenToken
    
            _pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                (giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].giftAmount.mul(redeemUsdVoucherOptionArr[_redeemUsdOption].tokenWeights[i])).div(100),
                0,
                path,
                _recipient,
                block.timestamp+10
            );    
        }
        
        redeemGasAndRefund(giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].gasTopUp, giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].redeemRefundFee, giftedUsdVoucherArr[_giftID].sender, _recipient);
        giftedUsdVoucherArr[_giftID].redeemed = true;
        
    }
    
    function redeemNFT(address payable _recipient, string memory _redemptionString, uint256 _giftID) external nonReentrant onlyRedeemer override {
        
        require(_giftID < giftedNFTArr.length, "NOT VALID GIFT");
        require(giftedNFTArr[_giftID].redeemed == false, "GIFT REDEEMED");
        require(keccak256(abi.encodePacked(_redemptionString)) == giftedUsdVoucherArr[_giftID].hash, "WRONG REDEMPTION CODE");
        
        IERC721(giftedNFTArr[_giftID].nft).safeTransferFrom(address(this),_recipient, giftedNFTArr[_giftID].tokenID);
        
        redeemGasAndRefund(NFTGasTopUp, NFTRedeemRefundFee, giftedNFTArr[_giftID].sender, _recipient);
        giftedNFTArr[_giftID].redeemed = true;
        
    }
    
    function redeemGasAndRefund(uint256 _a, uint256 _b, address payable _aAdd, address payable _bAdd) internal {
        _bAdd.transfer(_a);
        msg.sender.transfer(_b);
        
        lottery.addToLottery(_aAdd, _bAdd);
        redeemCounter++;
    }
    
    //RECOVERING SECTION
    
    function recoverGiftedTokens(uint256 _giftID) external nonReentrant override {
        
        require(msg.sender == giftedTokensArr[_giftID].sender, "NOT ORIGINAL SENDER");
        require(giftedTokensArr[_giftID].redeemed == false, "ALREADY REDEEMED");
        
        msg.sender.transfer(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].giftAmount.add(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].gasTopUp).add(giftedTokensOptionsArr[giftedTokensArr[_giftID].option].redeemRefundFee));
        
        giftedTokensArr[_giftID].redeemed = true;
        refundCounter ++;
        
    }
    
    function recoverUSDVoucher(uint256 _giftID) external nonReentrant override {
        
        require(msg.sender == giftedUsdVoucherArr[_giftID].sender, "NOT ORIGINAL SENDER");
        require(giftedUsdVoucherArr[_giftID].redeemed == false, "ALREADY REDEEMED");
        
        busdToken.safeTransfer(msg.sender, giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].giftAmount);
        
        recoverGasAndRefund(giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].redeemRefundFee, giftUsdVoucherOptionArr[giftedUsdVoucherArr[_giftID].option].gasTopUp);
        giftedUsdVoucherArr[_giftID].redeemed = true;
        
    }
    
    function recoverNFT(uint256 _giftID) external nonReentrant override {
        
        require(msg.sender == giftedNFTArr[_giftID].sender, "NOT ORIGINAL SENDER");
        require(giftedNFTArr[_giftID].redeemed == false, "ALREADY REDEEMED");
        
        IERC721(giftedNFTArr[_giftID].nft).safeTransferFrom(address(this),msg.sender, giftedNFTArr[_giftID].tokenID);
        recoverGasAndRefund(NFTRedeemRefundFee, NFTGasTopUp);
        
        giftedTokensArr[_giftID].redeemed = true;
        
    }
    
    function recoverGasAndRefund(uint256 _a, uint256 _b) internal {
        msg.sender.transfer(_a.add(_b));
        refundCounter ++;
    }
    
    //VIEW SECTION
    
    //VIEW GENERAL STATS

    function viewTotalGifts() external view returns(uint256) {
        return(giftedTokensArr.length.add(giftedUsdVoucherArr.length).add(giftedNFTArr.length));
    }
  
    function viewGiftsRedeemed() external view returns(uint256) {
        return(redeemCounter);
    }
    
    //VIEW TOKEN GIFT INFO
    
    function viewGiftTokensOptionsLength() external view override returns(uint256) {
        return giftedTokensOptionsArr.length;
    }
    
    function viewGiftedTokensOption(uint256 _option) external view override returns(uint256, uint256, uint256, uint256, uint256, address[] memory, uint256[] memory) {
        return(giftedTokensOptionsArr[_option].giftFee, giftedTokensOptionsArr[_option].referralFee, giftedTokensOptionsArr[_option].gasTopUp, giftedTokensOptionsArr[_option].redeemRefundFee, giftedTokensOptionsArr[_option].BnbCost, giftedTokensOptionsArr[_option].tokens, giftedTokensOptionsArr[_option].tokenWeights);
    }
    
    function viewGiftedTokens(uint256 _giftID) external view override returns(uint256, bool) {
        
        return(giftedTokensArr[_giftID].option, giftedTokensArr[_giftID].redeemed);
        
    }
    
    function viewGiftedTokensIndexes(address _sender) external view override returns(uint256[] memory) {
        return(addyToGiftedTokensSent[_sender]);
    }
    
    //VIEW USDVOUCHER GIFT INFO
    
    function viewGiftedUSDVoucherOptionsLength() external view override returns(uint256) {
        return(giftUsdVoucherOptionArr.length);
    }
    
    function viewGiftedUSDVoucherOption(uint256 _optionID) external view override returns(uint256, uint256, uint256, uint256) {
        return(giftUsdVoucherOptionArr[_optionID].giftFee, giftUsdVoucherOptionArr[_optionID].referralFee, giftUsdVoucherOptionArr[_optionID].gasTopUp, giftUsdVoucherOptionArr[_optionID].redeemRefundFee);
    }    
    
    function viewGiftedUSDVouchers(uint256 _giftID) external view override returns(uint256, bool ) {
        
        return(giftedUsdVoucherArr[_giftID].option, giftedUsdVoucherArr[_giftID].redeemed);
    }
    
    function viewGiftedUSDVouchersIndexes(address _sender) external view override returns(uint256[] memory) {
        
        return(addyToGiftedUsdVoucherSent[_sender]);
        
    }
    
    //VIEW NFT GIFT INFO
    
    function viewGiftedNFTs(uint256 _giftID) external view override returns(address, uint256, bool){
        return(giftedNFTArr[_giftID].nft, giftedNFTArr[_giftID].tokenID, giftedNFTArr[_giftID].redeemed);
    }
    
    function viewGiftedNFTsIndexes(address _sender) external view override returns(uint256[] memory){
        return(addyToGiftedNFTSent[_sender]);
        
    }
    
    function viewGiftNFTCosts() external view override returns(uint256, uint256, uint256, uint256){
        return(NFTGiftFee, NFTRedeemRefundFee, NFTReferralFee, NFTGasTopUp);
    }
    
    //REFERRALS SECTION
    
    function payReferrer(uint256 _UID, uint256 _payment) internal returns(uint256){

        if(customerToReferrerUID[msg.sender]==0) {

            if(_UID == 0 || _UID >= currentID) {
                customerToReferrerUID[msg.sender] = 1;
            } else {
                customerToReferrerUID[msg.sender] = _UID;
            }
            UIDToReferrer[customerToReferrerUID[msg.sender]].referrals++;
        }
        
        UIDToReferrer[customerToReferrerUID[msg.sender]].referralSales++;
        UIDToReferrer[customerToReferrerUID[msg.sender]].balance = UIDToReferrer[customerToReferrerUID[msg.sender]].balance + _payment;

        if (refaddyToUID[msg.sender] == 0) {

            return(registerReferrer());
            
        } else {

            return(refaddyToUID[msg.sender]);
        }
    }
    
    function registerReferrer() public returns (uint256) {
        
        require(refaddyToUID[msg.sender]==0, "ALREADY REGISTERED");
        refaddyToUID[msg.sender]=currentID;
        UIDToReferrer[currentID] = referrer(0,0,0,0);
        currentID++;
        return refaddyToUID[msg.sender];
        
    }
    
    function changeReferrerAddress(address payable _newAddress) external  {
        require(refaddyToUID[msg.sender] != 0, "WRONG ADDRESS");
        require(refaddyToUID[_newAddress] == 0, "NEW ADDRESS TAKEN");

        refaddyToUID[_newAddress] = refaddyToUID[msg.sender];
        refaddyToUID[msg.sender] = 0;
    }
    
    function withdrawReferralFunds() external nonReentrant override {
        
        require(refaddyToUID[msg.sender] != 0, "INVALID ADDRESS");
        require(UIDToReferrer[refaddyToUID[msg.sender]].balance > 0, "BALANCE IS ZERO");
        msg.sender.transfer(UIDToReferrer[refaddyToUID[msg.sender]].balance);
        UIDToReferrer[refaddyToUID[msg.sender]].totalEarned = UIDToReferrer[refaddyToUID[msg.sender]].totalEarned + UIDToReferrer[refaddyToUID[msg.sender]].balance;
        UIDToReferrer[refaddyToUID[msg.sender]].balance = 0;
         
    }
    
    //Returns data for referrer by address, if address in unregistered returns false
    function queryReferrerByAddress(address _referrer) external view override returns(uint256, uint256, uint256, uint256, bool) {
        if(refaddyToUID[_referrer] == 0) {
            return(0,0,0,0, false);
        } else {
            return(UIDToReferrer[refaddyToUID[_referrer]].balance, UIDToReferrer[refaddyToUID[_referrer]].totalEarned, UIDToReferrer[refaddyToUID[_referrer]].referrals, UIDToReferrer[refaddyToUID[_referrer]].referralSales, true);

        }
        
    }
    
    function withdraw() external onlyManager {
        busdToken.safeTransfer(msg.sender, busdToken.balanceOf(address(this)));
        msg.sender.transfer(address(this).balance);
    }

}

contract GIFTLottery is VRFConsumerBase{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct lotteryEntry {
        address payable sender;
        address payable recipient;
    }
    
    lotteryEntry[] private entriesArr;
    address payable winner1;
    address payable winner2;
    
    address handler;
    address lotteryAdmin;
    address manager;
    
    address private giftTokenAddress;
    IERC20 private giftToken;
    
    //CHAINLINK 
    
    bytes32 keyHash;
    uint256 chainlinkFee;
    
    constructor(address _giftToken, address _handler, address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee) VRFConsumerBase(_vrfCoordinator, _link) {
        
        handler = _handler;
        manager = tx.origin;
        
        //Chainlink INITIALIZATION
        
        chainlinkFee = _fee;
        keyHash = _keyHash;
        
        giftTokenAddress = _giftToken;
        giftToken = IERC20(giftTokenAddress);
    }
    
    modifier onlyManager() {
        require(msg.sender == manager, "NOT MANAGER");
        _;
    }

    modifier onlyHandler() {
        require(msg.sender == handler, "NOT HANDLER");
        _;
    }
    
    modifier onlyLotteryAdmin() {
        require(msg.sender == lotteryAdmin, "NOT LOTTERY ADMIN");
        _;
    }
    
    function changeManager(address _manager) onlyManager external {
        manager = _manager;
    }
    
    function changeLotteryAdmin(address _lotteryAdmin) onlyManager external {
        lotteryAdmin = _lotteryAdmin;
    }
    
    function changeChainlinkFee(uint256 _fee) external onlyManager  {
        chainlinkFee = _fee * 10 ** 18;
    }
    
    function changeGiftToken(address _giftToken) external onlyManager {
        giftTokenAddress = _giftToken;
        giftToken = IERC20(giftTokenAddress);
    }

    function addToLottery(address payable _sender, address payable _redeemer) external onlyHandler{
        
        entriesArr.push(lotteryEntry(_sender, _redeemer));
    }
    
    //This function calls the VRF Chainlink Coordinator to get a random number for the draw
    function getLotteryNumber() external onlyLotteryAdmin  {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK - fill contract with faucet");
        requestRandomness(keyHash, chainlinkFee);
    }
    
    //This function decides the lottery result, takes the random number, sets the winners, sends the rewards and resets the lottery entries array
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        
        uint256 winnersIndex = randomness.mod(entriesArr.length);
        uint256 lotteryFund = giftToken.balanceOf(address(this));
        uint256 winAmount = giftToken.balanceOf(address(this)).div(2);
        giftToken.safeTransfer(entriesArr[winnersIndex].sender, winAmount);
        giftToken.safeTransfer(entriesArr[winnersIndex].recipient, lotteryFund.sub(winAmount));
        winner1 = entriesArr[winnersIndex].sender;
        winner2 = entriesArr[winnersIndex].recipient;
        delete entriesArr;
        
    }
    
    function viewLotteryJackpot() external view returns(uint256) {

        return(giftToken.balanceOf(address(this)));
        
    }
    
    function viewLotteryWinners() external view returns(address payable _sender, address payable _recipient) {
        
        return(winner1, winner2);
    }
    
    function withdraw() external onlyManager {
        giftToken.safeTransfer(msg.sender, giftToken.balanceOf(address(this)));
    }
    
    
}