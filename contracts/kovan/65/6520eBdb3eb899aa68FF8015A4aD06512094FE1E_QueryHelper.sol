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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


import "./liquidity/LPoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


library Types {
    using SafeERC20 for IERC20;

    struct Market {// Market info
        LPoolInterface pool0;       // Lending Pool 0
        LPoolInterface pool1;       // Lending Pool 1
        address token0;              // Lending Token 0
        address token1;              // Lending Token 1
        uint16 marginLimit;         // Margin ratio limit for specific trading pair. Two decimal in percentage, ex. 15.32% => 1532
        uint16 feesRate;            // feesRate 30=>0.3%
        uint16 priceDiffientRatio;
        address priceUpdater;
        uint pool0Insurance;        // Insurance balance for token 0
        uint pool1Insurance;        // Insurance balance for token 1
        uint32[] dexs;
    }

    struct Trade {// Trade storage
        uint deposited;             // Balance of deposit token
        uint held;                  // Balance of held position
        bool depositToken;          // Indicate if the deposit token is token 0 or token 1
        uint128 lastBlockNum;       // Block number when the trade was touched last time, to prevent more than one operation within same block
    }

    struct MarketVars {// A variables holder for market info
        LPoolInterface buyPool;     // Lending pool address of the token to buy. It's a calculated field on open or close trade.
        LPoolInterface sellPool;    // Lending pool address of the token to sell. It's a calculated field on open or close trade.
        IERC20 buyToken;            // Token to buy
        IERC20 sellToken;           // Token to sell
        uint buyPoolInsurance;      // Insurance balance of token to buy
        uint sellPoolInsurance;     // Insurance balance of token to sell
        uint16 marginLimit;         // Margin Ratio Limit for specific trading pair.
        uint16 priceDiffientRatio;
        uint32[] dexs;
    }

    struct TradeVars {// A variables holder for trade info
        uint depositValue;          // Deposit value
        IERC20 depositErc20;        // Deposit Token address
        uint fees;                  // Fees value
        uint depositAfterFees;      // Deposit minus fees
        uint tradeSize;             // Trade amount to be swap on DEX
        uint newHeld;               // Latest held position
        uint borrowValue;
        uint token0Price;
        uint32 dexDetail;
    }

    struct CloseTradeVars {// A variables holder for close trade info
        uint16 marketId;
        bool longToken;
        bool depositToken;
        uint closeRatio;          // Close ratio
        bool isPartialClose;        // Is partial close
        uint closeAmountAfterFees;  // Close amount sub Fees value
        uint repayAmount;           // Repay to pool value
        uint depositDecrease;       // Deposit decrease
        uint depositReturn;         // Deposit actual returns
        uint sellAmount;
        uint receiveAmount;
        uint token0Price;
        uint fees;                  // Fees value
        uint32 dexDetail;
    }


    struct LiquidateVars {// A variable holder for liquidation process
        uint16 marketId;
        bool longToken;
        uint borrowed;              // Total borrowed balance of trade
        uint fees;                  // Fees for liquidation process
        uint penalty;               // Penalty
        uint remainHeldAfterFees;   // Held-fees-penalty
        bool isSellAllHeld;         // Is need sell all held
        uint depositDecrease;       // Deposit decrease
        uint depositReturn;         // Deposit actual returns
        uint sellAmount;
        uint receiveAmount;
        uint token0Price;
        uint outstandingAmount;
        uint32 dexDetail;
    }

    struct MarginRatioVars {
        address heldToken;
        address sellToken;
        address owner;
        uint held;
        bytes dexData;
        uint16 multiplier;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;


library DexData {
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;


    uint constant dexNameStart = 0;
    uint constant dexNameLength = 1;
    uint constant feeStart = 1;
    uint constant feeLength = 3;
    uint constant uniV3QuoteFlagStart = 4;
    uint constant uniV3QuoteFlagLength = 1;

    uint8 constant DEX_UNIV2 = 1;
    uint8 constant DEX_UNIV3 = 2;
    bytes constant UNIV2 = hex"01";
    //    bytes constant UNIV3_FEE0 = hex"02000000";

    struct V3PoolData {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    function toDex(bytes memory data) internal pure returns (uint8) {
        require(data.length >= dexNameLength, 'dex error');
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, dexNameStart))))
        }
        return temp;
    }

    function toFee(bytes memory data) internal pure returns (uint24) {
        require(data.length >= dexNameLength + feeLength, 'fee error');
        uint temp;
        assembly {
            temp := mload(add(data, add(0x20, feeStart)))
        }
        return uint24(temp >> (256 - (feeLength * 8)));
    }

    function toDexDetail(bytes memory data) internal pure returns (uint32) {
        if (data.length == dexNameLength) {
            uint8 temp;
            assembly {
                temp := byte(0, mload(add(data, add(0x20, dexNameStart))))
            }
            return uint32(temp);
        } else {
            uint temp;
            assembly {
                temp := mload(add(data, add(0x20, dexNameStart)))
            }
            return uint32(temp >> (256 - ((feeLength + dexNameLength) * 8)));
        }
    }
    // true ,sell all
    function toUniV3QuoteFlag(bytes memory data) internal pure returns (bool) {
        require(data.length >= dexNameLength + feeLength + uniV3QuoteFlagLength, 'v3flag error');
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, uniV3QuoteFlagStart))))
        }
        return temp > 0;
    }
    // univ2 class
    function isUniV2Class(bytes memory data) internal pure returns (bool) {
        return (data.length - dexNameLength) % 20 == 0;
    }
    // v2 path
    function toUniV2Path(bytes memory data) internal pure returns (address[] memory path) {
        data = slice(data, dexNameLength, data.length - dexNameLength);
        uint pathLength = data.length / 20;
        path = new address[](pathLength);
        for (uint i = 0; i < pathLength; i++) {
            path[i] = toAddress(data, 20 * i);
        }
    }

    // v3 path
    function toUniV3Path(bytes memory data) internal pure returns (V3PoolData[] memory path) {
        data = slice(data, uniV3QuoteFlagStart + uniV3QuoteFlagLength, data.length - (uniV3QuoteFlagStart + uniV3QuoteFlagLength));
        uint pathLength = numPools(data);
        path = new V3PoolData[](pathLength);
        for (uint i = 0; i < pathLength; i++) {
            V3PoolData memory pool;
            if (i != 0) {
                data = slice(data, NEXT_OFFSET, data.length - NEXT_OFFSET);
            }
            pool.tokenA = toAddress(data, 0);
            pool.fee = toUint24(data, ADDR_SIZE);
            pool.tokenB = toAddress(data, NEXT_OFFSET);
            path[i] = pool;
        }
    }

    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }
        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }


    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


abstract contract LPoolStorage {

    //Guard variable for re-entrancy checks
    bool internal _notEntered;

    /**
     * EIP-20 token name for this token
     */
    string public name;

    /**
     * EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
    * Total number of tokens in circulation
    */
    uint public totalSupply;


    //Official record of token balances for each account
    mapping(address => uint) internal accountTokens;

    //Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint)) internal transferAllowances;


    //Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
    * Maximum fraction of borrower cap(80%)
    */
    uint public  borrowCapFactorMantissa;
    /**
     * Contract which oversees inter-lToken operations
     */
    address public controller;


    // Initial exchange rate used when minting the first lTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
    * @notice Fraction of interest currently set aside for reserves 20%
    */
    uint public reserveFactorMantissa;


    uint public totalReserves;


    address public underlying;

    bool public isWethPool;

    /**
     * Container for borrow balance information
     * principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    uint256 public baseRatePerBlock;
    uint256 public multiplierPerBlock;
    uint256 public jumpMultiplierPerBlock;
    uint256 public kink;

    // Mapping of account addresses to outstanding borrow balances

    mapping(address => BorrowSnapshot) internal accountBorrows;


    /*** Token Events ***/

    /**
    * Event emitted when tokens are minted
    */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** Market Events ***/

    /**
     * Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, address payee, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint badDebtsAmount, uint accountBorrows, uint totalBorrows);

    /*** Admin Events ***/

    /**
     * Event emitted when controller is changed
     */
    event NewController(address oldController, address newController);

    /**
     * Event emitted when interestParam is changed
     */
    event NewInterestParam(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink);

    /**
    * @notice Event emitted when the reserve factor is changed
    */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address to, uint reduceAmount, uint newTotalReserves);

    event NewBorrowCapFactorMantissa(uint oldBorrowCapFactorMantissa, uint newBorrowCapFactorMantissa);

}

abstract contract LPoolInterface is LPoolStorage {


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);

    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);

    function approve(address spender, uint amount) external virtual returns (bool);

    function allowance(address owner, address spender) external virtual view returns (uint);

    function balanceOf(address owner) external virtual view returns (uint);

    function balanceOfUnderlying(address owner) external virtual returns (uint);

    /*** Lender & Borrower Functions ***/

    function mint(uint mintAmount) external virtual;

    function mintEth() external payable virtual;

    function redeem(uint redeemTokens) external virtual;

    function redeemUnderlying(uint redeemAmount) external virtual;

    function borrowBehalf(address borrower, uint borrowAmount) external virtual;

    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual;

    function repayBorrowEndByOpenLev(address borrower, uint repayAmount) external virtual;

    function availableForBorrow() external view virtual returns (uint);

    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint);

    function borrowRatePerBlock() external virtual view returns (uint);

    function supplyRatePerBlock() external virtual view returns (uint);

    function totalBorrowsCurrent() external virtual view returns (uint);

    function borrowBalanceCurrent(address account) external virtual view returns (uint);

    function borrowBalanceStored(address account) external virtual view returns (uint);

    function exchangeRateCurrent() public virtual returns (uint);

    function exchangeRateStored() public virtual view returns (uint);

    function getCash() external view virtual returns (uint);

    function accrueInterest() public virtual;


    /*** Admin Functions ***/

    function setController(address newController) external virtual;

    function setBorrowCapFactorMantissa(uint newBorrowCapFactorMantissa) external virtual;

    function setInterestParams(uint baseRatePerBlock_, uint multiplierPerBlock_, uint jumpMultiplierPerBlock_, uint kink_) external virtual;

    function setReserveFactor(uint newReserveFactorMantissa) external virtual;

    function addReserves(uint addAmount) external virtual;

    function reduceReserves(address payable to, uint reduceAmount) external virtual;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../Types.sol";
import "../lib/DexData.sol";


contract QueryHelper {
    using DexData for bytes;
    using SafeMath for uint;

    constructor ()
    {

    }
    struct PositionVars {
        uint deposited;
        uint held;
        uint borrowed;
        uint marginRatio;
        uint32 marginLimit;
    }
    enum LiqStatus{
        HEALTHY, // Do nothing
        UPDATE, // Need update price
        WAITING, // Waiting
        LIQ, // Can liquidate
        NOP// No position
    }

    struct LiqVars {
        LiqStatus status;
        uint lastUpdateTime;
        uint currentMarginRatio;
        uint cAvgMarginRatio;
        uint hAvgMarginRatio;
        uint32 marginLimit;
    }

    struct PoolVars {
        uint totalBorrows;
        uint cash;
        uint totalReserves;
        uint availableForBorrow;
        uint insurance;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint exchangeRate;
        uint baseRatePerBlock;
        uint multiplierPerBlock;
        uint jumpMultiplierPerBlock;
        uint kink;
    }

    struct XOLEVars {
        uint totalStaked;
        uint totalShared;
        uint tranferedToAccount;
        uint devFund;
        uint balanceOf;
    }

    function getTraderPositons(IOpenLev openLev, uint16 marketId, address[] calldata traders, bool[] calldata longTokens, bytes calldata dexData) external view returns (PositionVars[] memory results){
        results = new PositionVars[](traders.length);
        IOpenLev.MarketVar memory market = openLev.markets(marketId);
        for (uint i = 0; i < traders.length; i++) {
            PositionVars memory item;
            Types.Trade memory trade = openLev.activeTrades(traders[i], marketId, longTokens[i]);
            if (trade.held == 0) {
                results[i] = item;
                continue;
            }
            item.held = trade.held;
            item.deposited = trade.deposited;
            (item.marginRatio,,,item.marginLimit) = openLev.marginRatio(traders[i], marketId, longTokens[i], dexData);
            item.borrowed = longTokens[i] ? market.pool0.borrowBalanceCurrent(traders[i]) : market.pool1.borrowBalanceCurrent(traders[i]);
            results[i] = item;
        }
        return results;
    }

    struct LiqReqVars {
        IOpenLev openLev;
        address owner;
        uint16 marketId;
        bool longToken;
        uint256 token0price;
        uint256 token0cAvgPrice;
        uint256 token1price;
        uint256 token1cAvgPrice;
        uint256 timestamp;
        bytes dexData;
    }

    function getTraderLiqs(IOpenLev openLev, uint16 marketId, address[] calldata traders, bool[] calldata longTokens, bytes calldata dexData) external view returns (LiqVars[] memory results){
        results = new LiqVars[](traders.length);
        LiqReqVars memory reqVar;
        reqVar.openLev = openLev;
        reqVar.marketId = marketId;
        reqVar.dexData = dexData;
        IOpenLev.MarketVar memory market = reqVar.openLev.markets(reqVar.marketId);
        IOpenLev.AddressConfig memory adrConf = reqVar.openLev.addressConfig();
        IOpenLev.CalculateConfig memory calConf = reqVar.openLev.getCalculateConfig();
        (reqVar.token0price, reqVar.token0cAvgPrice,,,reqVar.timestamp) = adrConf.dexAggregator.getPriceCAvgPriceHAvgPrice(market.token0, market.token1, calConf.twapDuration, reqVar.dexData);
        (reqVar.token1price, reqVar.token1cAvgPrice,,,) = adrConf.dexAggregator.getPriceCAvgPriceHAvgPrice(market.token1, market.token0, calConf.twapDuration, reqVar.dexData);

        for (uint i = 0; i < traders.length; i++) {
            reqVar.owner = traders[i];
            reqVar.longToken = longTokens[i];
            LiqVars memory item;
            Types.Trade memory trade = reqVar.openLev.activeTrades(reqVar.owner, reqVar.marketId, reqVar.longToken);
            if (trade.held == 0) {
                item.status = LiqStatus.NOP;
                results[i] = item;
                continue;
            }
            item.lastUpdateTime = reqVar.timestamp;
            (item.currentMarginRatio, item.cAvgMarginRatio, item.hAvgMarginRatio, item.marginLimit) = reqVar.openLev.marginRatio(reqVar.owner, reqVar.marketId, reqVar.longToken, reqVar.dexData);
            if (item.currentMarginRatio > item.marginLimit && item.cAvgMarginRatio > item.marginLimit && item.hAvgMarginRatio > item.marginLimit) {
                item.status = LiqStatus.HEALTHY;
            }
            else if (item.currentMarginRatio < item.marginLimit && item.cAvgMarginRatio > item.marginLimit && item.hAvgMarginRatio > item.marginLimit) {
                if (dexData.isUniV2Class()) {
                    if (block.timestamp - calConf.twapDuration > item.lastUpdateTime) {
                        item.status = LiqStatus.UPDATE;
                    } else {
                        item.status = LiqStatus.WAITING;
                    }
                } else {
                    item.status = LiqStatus.WAITING;
                }
            } else if (item.currentMarginRatio < item.marginLimit && item.cAvgMarginRatio < item.marginLimit) {
                //Liq
                if (block.timestamp - calConf.twapDuration > item.lastUpdateTime || item.hAvgMarginRatio < item.marginLimit) {
                    // cAvgRatio diff currentRatio >+-5% ,waiting
                    if ((longTokens[i] == false && reqVar.token0cAvgPrice > reqVar.token0price && reqVar.token0cAvgPrice.mul(100).div(reqVar.token0price) - 100 >= calConf.maxLiquidationPriceDiffientRatio)
                        || (longTokens[i] == true && reqVar.token1cAvgPrice > reqVar.token1price && reqVar.token1cAvgPrice.mul(100).div(reqVar.token1price) - 100 >= calConf.maxLiquidationPriceDiffientRatio)) {
                        if (dexData.isUniV2Class()) {
                            item.status = LiqStatus.UPDATE;
                        } else {
                            item.status = LiqStatus.WAITING;
                        }
                    } else {
                        item.status = LiqStatus.LIQ;
                    }
                } else {
                    item.status = LiqStatus.WAITING;
                }
            }
            results[i] = item;
        }
        return results;
    }

    struct LiqCallVars {
        uint defaultFees;
        uint newFees;
        uint penalty;
        uint heldAfterFees;
        uint borrows;
        uint currentBuyAmount;
        uint currentSellAmount;
        bool canRepayBorrows;
    }
    //slippage 10%=>100
    function getLiqCallData(IOpenLev openLev, IV3Quoter v3Quoter, uint16 marketId, uint16 slippage, address trader, bool longToken, bytes memory dexData) external returns (uint minOrMaxAmount,
        bytes memory callDexData)
    {
        IOpenLev.MarketVar memory market = openLev.markets(marketId);
        Types.Trade memory trade = openLev.activeTrades(trader, marketId, longToken);
        LiqCallVars memory callVars;
        // cal remain held after fees and penalty
        callVars.defaultFees = trade.held.mul(market.feesRate).div(10000);
        callVars.newFees = callVars.defaultFees;
        IOpenLev.AddressConfig memory adrConf = openLev.addressConfig();
        IOpenLev.CalculateConfig memory calConf = openLev.getCalculateConfig();
        // if trader holds more xOLE, then should enjoy trading discount.
        if (IXOLE(adrConf.xOLE).balanceOf(trader) > calConf.feesDiscountThreshold) {
            callVars.newFees = callVars.defaultFees.sub(callVars.defaultFees.mul(calConf.feesDiscount).div(100));
        }
        // if trader update price, then should enjoy trading discount.
        if (market.priceUpdater == trader) {
            callVars.newFees = callVars.newFees.sub(callVars.defaultFees.mul(calConf.updatePriceDiscount).div(100));
        }
        callVars.penalty = trade.held.mul(calConf.penaltyRatio).div(10000);
        callVars.heldAfterFees = trade.held.sub(callVars.penalty).sub(callVars.newFees);
        callVars.borrows = longToken ? market.pool0.borrowBalanceCurrent(trader) : market.pool1.borrowBalanceCurrent(trader);

        callVars.currentBuyAmount = dexData.isUniV2Class() ?
        adrConf.dexAggregator.calBuyAmount(longToken ?
            market.token0 : market.token1, longToken ? market.token1 : market.token0, callVars.heldAfterFees, dexData) :
        v3Quoter.quoteExactInputSingle(longToken ? market.token1 : market.token0, longToken ? market.token0 : market.token1, dexData.toFee(), callVars.heldAfterFees, 0);
        callVars.canRepayBorrows = callVars.currentBuyAmount >= callVars.borrows;
        //flash sell,cal minBuyAmount
        if (trade.depositToken != longToken || !callVars.canRepayBorrows) {
            minOrMaxAmount = callVars.currentBuyAmount.sub(callVars.currentBuyAmount.mul(slippage).div(1000));
            callDexData = dexData.isUniV2Class() ? dexData : abi.encodePacked(dexData, hex"01");
        }
        // flash buy,cal maxSellAmount
        else {
            callVars.currentSellAmount = dexData.isUniV2Class() ?
            adrConf.dexAggregator.calSellAmount(longToken ?
                market.token0 : market.token1, longToken ? market.token1 : market.token0, callVars.borrows, dexData) :
            v3Quoter.quoteExactOutputSingle(longToken ? market.token1 : market.token0, longToken ? market.token0 : market.token1, dexData.toFee(), callVars.borrows, 0);
            minOrMaxAmount = callVars.currentSellAmount.add(callVars.currentSellAmount.mul(slippage).div(1000));
            callDexData = dexData.isUniV2Class() ? dexData : abi.encodePacked(dexData, hex"00");
        }
    }

    function getPoolDetails(IOpenLev openLev, uint16[] calldata marketIds, LPoolInterface[] calldata pools) external view returns (PoolVars[] memory results){
        results = new PoolVars[](pools.length);
        for (uint i = 0; i < pools.length; i++) {
            LPoolInterface pool = pools[i];
            IOpenLev.MarketVar memory market = openLev.markets(marketIds[i]);
            PoolVars memory item;
            item.insurance = address(market.pool0) == address(pool) ? market.pool0Insurance : market.pool1Insurance;
            item.cash = pool.getCash();
            item.totalBorrows = pool.totalBorrowsCurrent();
            item.totalReserves = pool.totalReserves();
            item.availableForBorrow = pool.availableForBorrow();
            item.supplyRatePerBlock = pool.supplyRatePerBlock();
            item.borrowRatePerBlock = pool.borrowRatePerBlock();
            item.reserveFactorMantissa = pool.reserveFactorMantissa();
            item.exchangeRate = pool.exchangeRateStored();
            item.baseRatePerBlock = pool.baseRatePerBlock();
            item.multiplierPerBlock = pool.multiplierPerBlock();
            item.jumpMultiplierPerBlock = pool.jumpMultiplierPerBlock();
            item.kink = pool.kink();
            results[i] = item;
        }
        return results;
    }

    function getXOLEDetail(IXOLE xole, IERC20 balanceOfToken) external view returns (XOLEVars memory vars){
        vars.totalStaked = xole.totalLocked();
        vars.totalShared = xole.totalRewarded();
        vars.tranferedToAccount = xole.withdrewReward();
        vars.devFund = xole.devFund();
        if (address(0) != address(balanceOfToken)) {
            vars.balanceOf = balanceOfToken.balanceOf(address(xole));
        }
    }
}

interface IXOLE {
    function totalLocked() external view returns (uint256);

    function totalRewarded() external view returns (uint256);

    function withdrewReward() external view returns (uint256);

    function devFund() external view returns (uint256);

    function balanceOf(address addr) external view returns (uint256);


}

interface DexAggregatorInterface {
    function calBuyAmount(address buyToken, address sellToken, uint sellAmount, bytes memory data) external view returns (uint);

    function calSellAmount(address buyToken, address sellToken, uint buyAmount, bytes memory data) external view returns (uint);

    function getPriceCAvgPriceHAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory dexData) external view returns (uint price, uint cAvgPrice, uint256 hAvgPrice, uint8 decimals, uint256 timestamp);
}

interface IV3Quoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

interface IOpenLev {
    struct MarketVar {// Market info
        LPoolInterface pool0;       // Lending Pool 0
        LPoolInterface pool1;       // Lending Pool 1
        address token0;              // Lending Token 0
        address token1;              // Lending Token 1
        uint16 marginLimit;         // Margin ratio limit for specific trading pair. Two decimal in percentage, ex. 15.32% => 1532
        uint16 feesRate;            // feesRate 30=>0.3%
        uint16 priceDiffientRatio;
        address priceUpdater;
        uint pool0Insurance;        // Insurance balance for token 0
        uint pool1Insurance;        // Insurance balance for token 1
    }

    struct AddressConfig {
        DexAggregatorInterface dexAggregator;
        address controller;
        address wETH;
        address xOLE;
    }

    struct CalculateConfig {
        uint16 defaultFeesRate; // 30 =>0.003
        uint8 insuranceRatio; // 33=>33%
        uint16 defaultMarginLimit; // 3000=>30%
        uint16 priceDiffientRatio; //10=>10%
        uint16 updatePriceDiscount;//25=>25%
        uint16 feesDiscount; // 25=>25%
        uint128 feesDiscountThreshold; //  30 * (10 ** 18) minimal holding of xOLE to enjoy fees discount
        uint16 penaltyRatio;//100=>1%
        uint8 maxLiquidationPriceDiffientRatio;//30=>30%
        uint16 twapDuration;//28=>28s
    }

    function activeTrades(address owner, uint16 marketId, bool longToken) external view returns (Types.Trade memory);

    function marginRatio(address owner, uint16 marketId, bool longToken, bytes memory dexData) external view returns (uint current, uint cAvg, uint hAvg, uint32 limit);

    function markets(uint16 marketId) external view returns (MarketVar memory);

    function getMarketSupportDexs(uint16 marketId) external view returns (uint32[] memory);

    function addressConfig() external view returns (AddressConfig memory);

    function getCalculateConfig() external view returns (CalculateConfig memory);


}