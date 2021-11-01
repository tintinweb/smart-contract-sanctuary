/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

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

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/libraries/MathExt.sol

pragma solidity 0.6.12;


library MathExt {
    using SafeMath for uint256;

    uint256 public constant PRECISION = (10**18);

    /// @dev Returns x*y in precision
    function mulInPrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / PRECISION;
    }

    /// @dev source: dsMath
    /// @param xInPrecision should be < PRECISION, so this can not overflow
    /// @return zInPrecision = (x/PRECISION) ^k * PRECISION
    function unsafePowInPrecision(uint256 xInPrecision, uint256 k)
        internal
        pure
        returns (uint256 zInPrecision)
    {
        require(xInPrecision <= PRECISION, "MathExt: x > PRECISION");
        zInPrecision = k % 2 != 0 ? xInPrecision : PRECISION;

        for (k /= 2; k != 0; k /= 2) {
            xInPrecision = (xInPrecision * xInPrecision) / PRECISION;

            if (k % 2 != 0) {
                zInPrecision = (zInPrecision * xInPrecision) / PRECISION;
            }
        }
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/interfaces/IDMMFactory.sol

pragma solidity 0.6.12;


interface IDMMFactory {
    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function setFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

    function setFeeToSetter(address) external;

    function getFeeConfiguration() external view returns (address feeTo, uint16 governmentFeeBps);

    function feeToSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function getUnamplifiedPool(IERC20 token0, IERC20 token1) external view returns (address);

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools);

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external view returns (bool);
}

// File: contracts/interfaces/IDMMPool.sol

pragma solidity 0.6.12;



interface IDMMPool {
    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getTradeInfo()
        external
        view
        returns (
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint112 reserve0,
            uint112 reserve1,
            uint256 feeInPrecision
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function ampBps() external view returns (uint32);

    function factory() external view returns (IDMMFactory);

    function kLast() external view returns (uint256);
}

// File: contracts/libraries/DMMLibrary.sol

pragma solidity 0.6.12;




library DMMLibrary {
    using SafeMath for uint256;

    uint256 public constant PRECISION = 1e18;

    // returns sorted token addresses, used to handle return values from pools sorted in this order
    function sortTokens(IERC20 tokenA, IERC20 tokenB)
        internal
        pure
        returns (IERC20 token0, IERC20 token1)
    {
        require(tokenA != tokenB, "DMMLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(address(token0) != address(0), "DMMLibrary: ZERO_ADDRESS");
    }

    /// @dev fetch the reserves and fee for a pool, used for trading purposes
    function getTradeInfo(
        address pool,
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            uint256 vReserveA,
            uint256 vReserveB,
            uint256 feeInPrecision
        )
    {
        (IERC20 token0, ) = sortTokens(tokenA, tokenB);
        uint256 reserve0;
        uint256 reserve1;
        uint256 vReserve0;
        uint256 vReserve1;
        (reserve0, reserve1, vReserve0, vReserve1, feeInPrecision) = IDMMPool(pool).getTradeInfo();
        (reserveA, reserveB, vReserveA, vReserveB) = tokenA == token0
            ? (reserve0, reserve1, vReserve0, vReserve1)
            : (reserve1, reserve0, vReserve1, vReserve0);
    }

    /// @dev fetches the reserves for a pool, used for liquidity adding
    function getReserves(
        address pool,
        IERC20 tokenA,
        IERC20 tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (IERC20 token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IDMMPool(pool).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pool reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "DMMLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pool reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 feeInPrecision
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "DMMLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(PRECISION.sub(feeInPrecision)).div(PRECISION);
        uint256 numerator = amountInWithFee.mul(vReserveOut);
        uint256 denominator = vReserveIn.add(amountInWithFee);
        amountOut = numerator.div(denominator);
        require(reserveOut > amountOut, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
    }

    // given an output amount of an asset and pool reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 feeInPrecision
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "DMMLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > amountOut, "DMMLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = vReserveIn.mul(amountOut);
        uint256 denominator = vReserveOut.sub(amountOut);
        amountIn = numerator.div(denominator).add(1);
        // amountIn = floor(amountIN *PRECISION / (PRECISION - feeInPrecision));
        numerator = amountIn.mul(PRECISION);
        denominator = PRECISION.sub(feeInPrecision);
        amountIn = numerator.add(denominator - 1).div(denominator);
    }

    // performs chained getAmountOut calculations on any number of pools
    function getAmountsOut(
        uint256 amountIn,
        address[] memory poolsPath,
        IERC20[] memory path
    ) internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint256 vReserveIn,
                uint256 vReserveOut,
                uint256 feeInPrecision
            ) = getTradeInfo(poolsPath[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                vReserveIn,
                vReserveOut,
                feeInPrecision
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pools
    function getAmountsIn(
        uint256 amountOut,
        address[] memory poolsPath,
        IERC20[] memory path
    ) internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint256 vReserveIn,
                uint256 vReserveOut,
                uint256 feeInPrecision
            ) = getTradeInfo(poolsPath[i - 1], path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                vReserveIn,
                vReserveOut,
                feeInPrecision
            );
        }
    }
}

// File: contracts/interfaces/IWETH.sol

pragma solidity 0.6.12;


interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// File: contracts/periphery/ZapIn.sol

pragma solidity 0.6.12;









/// @dev detail here: https://hackmd.io/vdqxJx8STNqPm0LG8vGWaw
contract ZapIn {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private constant PRECISION = 1e18;
    uint256 internal constant Q112 = 2**112;

    IDMMFactory public immutable factory;
    address public immutable weth;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DMMRouter: EXPIRED");
        _;
    }

    constructor(IDMMFactory _factory, address _weth) public {
        factory = _factory;
        weth = _weth;
    }

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    /// @dev swap eth to token and then add liquidity to a pool with token-weth
    /// @param tokenOut another token of the pool - not weth
    /// @param pool address of the pool
    /// @param minLpQty min of lp token after swap
    /// @param deadline the last time the transaction can be executed
    function zapInEth(
        IERC20 tokenOut,
        address pool,
        uint256 minLpQty,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256 lpQty) {
        IWETH(weth).deposit{value: msg.value}();
        (uint256 amountSwap, uint256 amountOutput) = calculateSwapAmounts(
            IERC20(weth),
            tokenOut,
            pool,
            msg.value
        );
        IERC20(weth).safeTransfer(pool, amountSwap);
        _swap(amountOutput, IERC20(weth), tokenOut, pool, address(this));

        IERC20(weth).safeTransfer(pool, msg.value.sub(amountSwap));
        tokenOut.safeTransfer(pool, amountOutput);

        lpQty = IDMMPool(pool).mint(msg.sender);
        require(lpQty >= minLpQty, "DMMRouter: INSUFFICIENT_MINT_QTY");
    }

    /// @dev swap and add liquidity to a pool with token-weth
    /// @param tokenIn the input token
    /// @param tokenOut another token of the pool
    /// @param pool address of the pool
    /// @param userIn amount of input token
    /// @param minLpQty min of lp token after swap
    /// @param deadline the last time the transaction can be executed
    function zapIn(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 userIn,
        address pool,
        uint256 minLpQty,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 lpQty) {
        (uint256 amountSwap, uint256 amountOutput) = calculateSwapAmounts(
            tokenIn,
            tokenOut,
            pool,
            userIn
        );

        tokenIn.safeTransferFrom(msg.sender, pool, amountSwap);
        _swap(amountOutput, tokenIn, tokenOut, pool, address(this));
        tokenIn.safeTransferFrom(msg.sender, pool, userIn.sub(amountSwap));
        tokenOut.safeTransfer(pool, amountOutput);

        lpQty = IDMMPool(pool).mint(msg.sender);
        require(lpQty >= minLpQty, "INSUFFICIENT_MINT_QTY");
    }

    function zapOut(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 liquidity,
        address pool,
        address to,
        uint256 minTokenOut,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountOut) {
        amountOut = _zapOut(tokenIn, tokenOut, liquidity, pool, minTokenOut);
        tokenOut.safeTransfer(to, amountOut);
    }

    function zapOutEth(
        IERC20 tokenIn,
        uint256 liquidity,
        address pool,
        address to,
        uint256 minTokenOut,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountOut) {
        amountOut = _zapOut(tokenIn, IERC20(weth), liquidity, pool, minTokenOut);
        IWETH(weth).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function calculateZapInAmounts(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address pool,
        uint256 userIn
    ) external view returns (uint256 tokenInAmount, uint256 tokenOutAmount) {
        uint256 amountSwap;
        (amountSwap, tokenOutAmount) = calculateSwapAmounts(tokenIn, tokenOut, pool, userIn);
        tokenInAmount = userIn.sub(amountSwap);
    }

    function calculateSwapAmounts(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address pool,
        uint256 userIn
    ) public view returns (uint256 amountSwap, uint256 amountOutput) {
        require(factory.isPool(tokenIn, tokenOut, pool), "INVALID_POOL");
        (uint256 rIn, uint256 rOut, uint256 vIn, uint256 vOut, uint256 feeInPrecision) = DMMLibrary
            .getTradeInfo(pool, tokenIn, tokenOut);
        amountSwap = _calculateSwapInAmount(rIn, rOut, vIn, vOut, feeInPrecision, userIn);
        amountOutput = DMMLibrary.getAmountOut(amountSwap, rIn, rOut, vIn, vOut, feeInPrecision);
    }

    function _swap(
        uint256 amountOut,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address pool,
        address to
    ) internal {
        (IERC20 token0, ) = DMMLibrary.sortTokens(tokenIn, tokenOut);
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        IDMMPool(pool).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function _zapOut(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 liquidity,
        address pool,
        uint256 minTokenOut
    ) internal returns (uint256 amountOut) {
        uint256 amountIn;
        {
            require(factory.isPool(tokenIn, tokenOut, pool), "INVALID_POOL");
            IERC20(pool).safeTransferFrom(msg.sender, pool, liquidity); // send liquidity to pool
            (uint256 amount0, uint256 amount1) = IDMMPool(pool).burn(address(this));
            (IERC20 token0, ) = DMMLibrary.sortTokens(tokenIn, tokenOut);
            (amountIn, amountOut) = tokenIn == token0 ? (amount0, amount1) : (amount1, amount0);
        }
        uint256 swapAmount;
        {
            (
                uint256 rIn,
                uint256 rOut,
                uint256 vIn,
                uint256 vOut,
                uint256 feeInPrecision
            ) = DMMLibrary.getTradeInfo(pool, tokenIn, tokenOut);
            swapAmount = DMMLibrary.getAmountOut(amountIn, rIn, rOut, vIn, vOut, feeInPrecision);
        }
        tokenIn.safeTransfer(pool, amountIn);
        _swap(swapAmount, tokenIn, tokenOut, pool, address(this));
        amountOut += swapAmount;
        require(amountOut >= minTokenOut, "INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function _calculateSwapInAmount(
        uint256 rIn,
        uint256 rOut,
        uint256 vIn,
        uint256 vOut,
        uint256 feeInPrecision,
        uint256 userIn
    ) internal pure returns (uint256) {
        uint256 r = PRECISION - feeInPrecision;
        // b = (vOut * rIn + userIn * (vOut - rOut)) * r / PRECISION / rOut+ vIN
        uint256 b;
        {
            uint256 tmp = userIn.mul(vOut.sub(rOut));
            tmp = tmp.add(vOut.mul(rIn));
            b = tmp.div(rOut).mul(r) / PRECISION;
            b = b.add(vIn);
        }
        uint256 inverseC = vIn.mul(userIn);
        // numerator = sqrt(b^2 -4ac) - b
        uint256 numerator = MathExt.sqrt(b.mul(b).add(inverseC.mul(4 * r) / PRECISION)).sub(b);
        return numerator.mul(PRECISION) / (2 * r);
    }
}