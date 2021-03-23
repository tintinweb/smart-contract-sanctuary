/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

//          
//              &&&&
//              &&&&
//              &&&&
//              &&&&  &&&&&&&&&       &&&&&&&&&&&&          &&&&&&&&&&/   &&&&.&&&&&&&&&
//              &&&&&&&&&   &&&&&   &&&&&&     &&&&&,     &&&&&    &&&&&  &&&&&&&&   &&&&
//               &&&&&&      &&&&  &&&&#         &&&&   &&&&&       &&&&& &&&&&&     &&&&&
//               &&&&&       &&&&/ &&&&           &&&& #&&&&        &&&&  &&&&&
//               &&&&         &&&& &&&&&         &&&&  &&&&        &&&&&  &&&&&
//               %%%%        /%%%%   %%%%%%   %%%%%%   %%%%  %%%%%%%%%    %%%%%
//              %%%%%        %%%%      %%%%%%%%%%%    %%%%   %%%%%%       %%%%
//                                                    %%%%
//                                                    %%%%
//                                                    %%%%
//

// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}


// File @openzeppelin/contracts/token/ERC777/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}


// File @openzeppelin/contracts/introspection/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/HoprFarm.sol

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

/**
 * 5 million HOPR tokens are allocated as incentive for liquidity providers on uniswap.
 * This incentive will be distributed on an approx. weekly-basis over 3 months (13 weeks) 
 * Liquidity providers (LPs) can deposit their LP-tokens (UniswapV2Pair token for HOPR-DAI)
 * to this HoprFarm contract for at least 1 week (minimum deposit period) to receive rewards. 
 */
contract HoprFarm is IERC777Recipient, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Arrays for uint256[];

    uint256 public constant TOTAL_INCENTIVE = 5000000 ether;
    uint256 public constant WEEKLY_BLOCK_NUMBER = 44800; // Taking 13.5 s/block as average block time. thus 7*24*60*60/13.5 = 44800 blocks per week. 
    uint256 public constant TOTAL_CLAIM_PERIOD = 13; // Incentives are released over a period of 13 weeks. 
    uint256 public constant WEEKLY_INCENTIVE = 384615384615384615384615; // 5000000/13 weeks There is very small amount of remainder for the last week (+5 wei)

    // setup ERC1820
    IERC1820Registry private constant ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    struct LiquidityProvider {
        mapping(uint256=>uint256) eligibleBalance; // Amount of liquidity tokens
        uint256 claimedUntil; // the last period where the liquidity provider has claimed tokens
        uint256 currentBalance;
    }

    // an ascending block numbers of start/end of each farming interval. 
    // E.g. the first farming interval is (distributionBlocks[0], distributionBlocks[1]].
    uint256[] public distributionBlocks;
    mapping(uint256=>uint256) public eligibleLiquidityPerPeriod;
    mapping(address=>LiquidityProvider) public liquidityProviders;
    uint256 public totalPoolBalance;
    uint256 public claimedIncentive;
    address public multisig;
    IERC20 public pool; 
    IERC20 public hopr; 

    event TokenAdded(address indexed provider, uint256 indexed period, uint256 amount);
    event TokenRemoved(address indexed provider, uint256 indexed period, uint256 amount);
    event IncentiveClaimed(address indexed provider, uint256 indexed until, uint256 amount);

    /**
     * @dev Modifier to check address is multisig
     */
    modifier onlyMultisig(address adr) {
        require(adr == multisig, "HoprFarm: Only DAO multisig");
        _;
    }

    /**
     * @dev provides the farming schedule.
     * @param _pool address Address of the HOPR-DAI uniswap pool.
     * @param _token address Address of the HOPR token.
     * @param _multisig address Address of the HOPR DAO multisig.
     */
    constructor(address _pool, address _token, address _multisig) public {
        require(IUniswapV2Pair(_pool).token0() == _token || IUniswapV2Pair(_pool).token1() == _token, "HoprFarm: wrong token address");
        pool = IERC20(_pool);
        hopr = IERC20(_token);
        multisig = _multisig;
        distributionBlocks.push(0);
        ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    /**
     * @dev ERC777 hook triggered when multisig send HOPR token to this contract.
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes hex string of the starting block number. e.g. "0xb66bbd" for 11955133. It should not be longer than 3 bytes
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        // solhint-disable-next-line no-unused-vars
        bytes calldata operatorData
    ) external override onlyMultisig(from) nonReentrant {
        require(msg.sender == address(hopr), "HoprFarm: Sender must be HOPR token");
        require(to == address(this), "HoprFarm: Must be sending tokens to HOPR farm");
        require(amount == TOTAL_INCENTIVE, "HoprFarm: Only accept 5 million HOPR token");
        // take block number from userData, varies from 0x000000 to 0xffffff.
        // This value is sufficient as 0xffff will be in March 2023.
        require(userData.length == 3, "HoprFarm: Start block number needs to have three bytes");
        require(distributionBlocks[0] == 0, "HoprFarm: Not initialized yet.");
        bytes32 m;
        assembly {
            // it first loads the userData at the position 228 = 4 + 32 * 7, 
            // where 4 is the method signature and 7 is the storage of userData
            // Then bit shift the right-padded bytes32 to remove all the padded zeros
            // Given the blocknumber is not longer than 3 bytes, bitwise it needs to shift
            // log2(16) * (32 - 3) * 2 = 232
            m := shr(232, calldataload(228))
        }
        // update distribution blocks
        uint256 startBlock = uint256(m);
        require(startBlock >= block.number, "HoprFarm: Start block number should be in the future");
        distributionBlocks[0] = startBlock;
        for (uint256 i = 1; i <= TOTAL_CLAIM_PERIOD; i++) {
            distributionBlocks.push(startBlock + i * WEEKLY_BLOCK_NUMBER);
        }
    }

    /**
     * @dev Multisig can recover tokens (pool tokens/hopr tokens/any other random tokens)
     * @param token Address of the token to be recovered.
     */
    function recoverToken(address token) external onlyMultisig(msg.sender) nonReentrant {
        if (token == address(hopr)) {
            hopr.safeTransfer(multisig, hopr.balanceOf(address(this)).add(claimedIncentive).sub(TOTAL_INCENTIVE));
        } else if (token == address(pool)) {
            pool.safeTransfer(multisig, pool.balanceOf(address(this)).sub(totalPoolBalance));
        } else {
            IERC20(token).safeTransfer(multisig, IERC20(token).balanceOf(address(this)));
        }
    }

    /**
     * @dev Claim incenvtives for an account. Update total claimed incentive.
     * @param provider Account of liquidity provider
     */
    function claimFor(address provider) external nonReentrant {
        uint256 currentPeriod = distributionBlocks.findUpperBound(block.number);
        _claimFor(currentPeriod, provider);
    }

    /**
     * @dev liquidity provider deposits their Uniswap HOPR-DAI tokens to the contract
     * It updates the current balance and the eligible farming balance
     * Thanks to `permit` function of UNI token (see below, link to source code), 
     * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
     * LPs do not need to call `approve` seperately. `spender` is this farm contract. 
     * This function can be called by anyone with a valid signature of liquidity provider.
     * @param amount Amount of pool token to be staked into the contract. It is also the amount in the signature.
     * @param owner Address of the liquidity provider.
     * @param deadline Timestamp after which the signature is no longer valid.
     * @param v ECDSA signature.
     * @param r ECDSA signature.
     * @param s ECDSA signature.
     */
    function openFarmWithPermit(uint256 amount, address owner, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        IUniswapV2Pair(address(pool)).permit(owner, address(this), amount, deadline, v, r, s);
        _openFarm(amount, owner);
    }

    /**
     * @dev Called by liquidty provider to deposit their Uniswap HOPR-DAI tokens to the contract
     * It updates the current balance and the eligible farming balance
     * @notice An `apprpove(<farm contract>, amount)` needs to be called prior to `openFarm`
     * @param amount Amount of pool token to be staked into the contract.
     */
    function openFarm(uint256 amount) external nonReentrant {
        _openFarm(amount, msg.sender);
    }

    /**
     * @dev Claims all the reward until current block number and close the farm.
     */
    function claimAndClose() external nonReentrant {
        // get current farm period
        uint256 currentPeriod = distributionBlocks.findUpperBound(block.number);
        _claimFor(currentPeriod, msg.sender);
        _closeFarm(currentPeriod, msg.sender, liquidityProviders[msg.sender].currentBalance);
    }

    /**
     * @dev liquidity provider removes their Uniswap HOPR-DAI tokens to the contract
     * It updates the current balance and the eligible farming balance
     * @param amount Amount of pool token to be removed from the contract.
     */
    function closeFarm(uint256 amount) external nonReentrant {
        // update balance to the right phase
        uint256 currentPeriod = distributionBlocks.findUpperBound(block.number);
        _closeFarm(currentPeriod, msg.sender, amount);
    }

    /**
     * @dev returns the first index that contains a value greater or equal to the current `block.number`
     * If all numbers are strictly below block.number, returns array length.
     * @notice get the current farm period. 0 means "not started", 1 means "1st period", ...
     * If the returned value is larger than `maxFarmPeriod`, it means farming is "closed"
     */
    function currentFarmPeriod() public view returns (uint256) {
        return distributionBlocks.findUpperBound(block.number);
    }

    /**
     * @dev calculate virtual return based on current staking. Amount of tokens one can claim in the next period.
     * @param amountToStake Amount of pool token that a liquidity provider would stake
     */
    function currentFarmIncentive(uint256 amountToStake) public view returns (uint256) {
        uint256 currentPeriod = distributionBlocks.findUpperBound(block.number);
        if (currentPeriod >= TOTAL_CLAIM_PERIOD) {
            return 0;            
        }
        return WEEKLY_INCENTIVE.mul(amountToStake).div(eligibleLiquidityPerPeriod[currentPeriod+1].add(amountToStake));
    }

    /**
     * @dev Get the total amount of incentive to be claimed by the liquidity provider.
     * @param provider Account of liquidity provider
     */
    function incentiveToBeClaimed(address provider) public view returns (uint256) {
        uint256 currentPeriod = distributionBlocks.findUpperBound(block.number);
        return _incentiveToBeClaimed(currentPeriod, provider);
    }

    /**
     * @dev update the liquidity token balance, of which is used for calculating the result of farming
     * It updates the balance for the following periods. For the previous period, if the balance reduces 
     * the eligible balance of the previous round reduces. If the balance increases, it only affects the
     * following rounds.
     * @param account Address of the liquidity provider
     * @param newBalance Latest balance
     * @param currentPeriod Index of the farming period at current block number.
     */
    function updateEligibleBalance(address account, uint256 newBalance, uint256 currentPeriod) internal {
        if (currentPeriod > 0) {
            uint256 balanceFromLastPeriod = liquidityProviders[account].eligibleBalance[currentPeriod - 1];
            if (balanceFromLastPeriod > newBalance) {
                liquidityProviders[account].eligibleBalance[currentPeriod - 1] = newBalance;
                eligibleLiquidityPerPeriod[currentPeriod - 1] = eligibleLiquidityPerPeriod[currentPeriod - 1].sub(balanceFromLastPeriod).add(newBalance);
            }
        }
        uint256 newEligibleLiquidityPerPeriod = eligibleLiquidityPerPeriod[currentPeriod].sub(liquidityProviders[account].eligibleBalance[currentPeriod]).add(newBalance);
        for (uint256 i = currentPeriod; i < TOTAL_CLAIM_PERIOD; i++) {
            liquidityProviders[account].eligibleBalance[i] = newBalance;
            eligibleLiquidityPerPeriod[i] = newEligibleLiquidityPerPeriod;
        }
    }

    /**
     * @dev liquidity provider deposits their Uniswap HOPR-DAI tokens to the contract
     * It updates the current balance and the eligible farming balance
     * @param amount Amount of pool token to be staked into the contract.
     * @param provider Address of the liquidity provider.
     */
    function _openFarm(uint256 amount, address provider) internal {
        // update balance to the right phase
        uint256 currentPeriod = distributionBlocks.findUpperBound(block.number);
        require(currentPeriod < TOTAL_CLAIM_PERIOD, "HoprFarm: Farming ended");
        // always add currentBalance
        uint256 newBalance = liquidityProviders[provider].currentBalance.add(amount);
        liquidityProviders[provider].currentBalance = newBalance;
        totalPoolBalance = totalPoolBalance.add(amount);      
        // update eligible balance
        updateEligibleBalance(provider, newBalance, currentPeriod);
        // transfer token
        pool.safeTransferFrom(provider, address(this), amount);
        // emit event
        emit TokenAdded(provider, currentPeriod, amount);
    }

    /**
     * @dev Claim incenvtives for an account. Update total claimed incentive.
     * @param currentPeriod Current farm period
     * @param provider Account of liquidity provider
     */
    function _claimFor(uint256 currentPeriod, address provider) internal {
        require(currentPeriod > 1, "HoprFarm: Too early to claim");
        uint256 farmed = _incentiveToBeClaimed(currentPeriod, provider);
        require(farmed > 0, "HoprFarm: Nothing to claim");
        liquidityProviders[provider].claimedUntil = currentPeriod - 1;
        claimedIncentive = claimedIncentive.add(farmed);
        // transfer farmed tokens to the provider
        hopr.safeTransfer(provider, farmed);
        emit IncentiveClaimed(provider, currentPeriod - 1, farmed);
    }

    /**
     * @dev liquidity provider removes their Uniswap HOPR-DAI tokens to the contract
     * It updates the current balance and the eligible farming balance
     * @param currentPeriod Current farm period
     * @param provider Account of liquidity provider
     * @param amount Amount of pool token to be removed from the contract.
     */
    function _closeFarm(uint256 currentPeriod, address provider, uint256 amount) internal {
        // always add currentBalance
        uint256 newBalance = liquidityProviders[provider].currentBalance.sub(amount);
        liquidityProviders[provider].currentBalance = newBalance;
        totalPoolBalance = totalPoolBalance.sub(amount);      
        // update eligible balance
        updateEligibleBalance(provider, newBalance, currentPeriod);
        // transfer token
        pool.safeTransfer(provider, amount);
        // emit event
        emit TokenRemoved(provider, currentPeriod, amount);
    }

    /**
     * @dev Private function that gets the total amount of incentive to be claimed by the liquidity provider.
     * @param currentPeriod Current farm period
     * @param provider Account of liquidity provider
     */
    function _incentiveToBeClaimed(uint256 currentPeriod, address provider) private view returns (uint256) {
        uint256 claimedPeriod = liquidityProviders[provider].claimedUntil;
        if (currentPeriod < 1 || claimedPeriod >= currentPeriod) {
            return 0;            
        }
        uint256 farmed;
        for (uint256 i = claimedPeriod; i < currentPeriod - 1; i++) {
            if (eligibleLiquidityPerPeriod[i] > 0) {
                farmed = farmed.add(WEEKLY_INCENTIVE.mul(liquidityProviders[provider].eligibleBalance[i]).div(eligibleLiquidityPerPeriod[i]));
            }
        }
        return farmed;
    }
}