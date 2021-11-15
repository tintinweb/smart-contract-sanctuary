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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Ownable {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        owner = _owner;
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");
        emit OwnerChanged(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnerChanged(owner, address(0));
        owner = address(0);
    }

    function nominateNewOwner(address newOwner) external onlyOwner {
        nominatedOwner = newOwner;
        emit OwnerNominated(newOwner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../../interfaces/IUniswapRouterV2.sol";
import "../../interfaces/ILon.sol";
import "../Ownable.sol";

contract RewardDistributor is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    uint256 private constant MAX_UINT = 2**256 - 1;
    address public immutable LON_TOKEN_ADDR;

    // Below are the variables which consume storage slots.
    uint32 public buybackInterval;
    uint8 public miningFactor;
    uint8 public numStrategyAddr;
    uint8 public numExchangeAddr;

    mapping(address => bool) public isOperator;
    address public treasury;
    address public lonStaking;
    address public miningTreasury;
    address public feeTokenRecipient;

    mapping(uint256 => address) public strategyAddrs;
    mapping(uint256 => address) public exchangeAddrs;
    mapping(address => FeeToken) public feeTokens;

    /* Struct and event declaration */
    struct FeeToken {
        uint8 exchangeIndex;
        uint8 LFactor; // Percentage of fee token reserved for feeTokenRecipient
        uint8 RFactor; // Percentage of buyback-ed lon token for treasury
        uint32 lastTimeBuyback;
        bool enable;
        uint256 minBuy;
        uint256 maxBuy;
        address[] path;
    }

    // Owner events
    
    event SetOperator(address operator, bool enable);
    event SetMiningFactor(uint8 miningFactor);
    event SetTreasury(address treasury);
    event SetLonStaking(address lonStaking);
    event SetMiningTreasury(address miningTreasury);
    event SetFeeTokenRecipient(address feeTokenRecipient);
    // Operator events
    event SetBuybackInterval(uint256 interval);
    event SetStrategy(uint256 index, address strategy);
    event SetExchange(uint256 index, address exchange);
    event EnableFeeToken(address feeToken, bool enable);
    event SetFeeToken(
        address feeToken,
        uint256 exchangeIndex,
        address[] path,
        uint256 LFactor,
        uint256 RFactor,
        uint256 minBuy,
        uint256 maxBuy
    );
    event SetFeeTokenFailure(address feeToken, string reason, bytes lowLevelData);

    event BuyBack(
        address feeToken,
        uint256 feeTokenAmount,
        uint256 swappedLonAmount,
        uint256 LFactor,
        uint256 RFactor,
        uint256 minBuy,
        uint256 maxBuy
    );
    event BuyBackFailure(address feeToken, uint256 feeTokenAmount, string reason, bytes lowLevelData);
    event DistributeLon(uint256 treasuryAmount, uint256 lonStakingAmount);
    event MintLon(uint256 mintedAmount);
    event Recovered(address token, uint256 amount);


    /************************************************************
    *                      Access control                       *
    *************************************************************/
    modifier only_Operator_or_Owner {
        require(_isAuthorized(msg.sender), "only operator or owner can call");
        _;
    }

    modifier only_Owner_or_Operator_or_Self {
        if (msg.sender != address(this)) {
            require(_isAuthorized(msg.sender), "only operator or owner can call");
        }
        _;
    }

    modifier only_EOA {
        require((msg.sender == tx.origin), "only EOA can call");
        _;
    }

    modifier only_EOA_or_Self {
        if (msg.sender != address(this)) {
            require((msg.sender == tx.origin), "only EOA can call");
        }
        _;
    }


    /************************************************************
    *                       Constructor                         *
    *************************************************************/
    constructor(
        address _LON_TOKEN_ADDR,
        address _owner,
        address _operator,
        uint32 _buyBackInterval,
        uint8 _miningFactor,
        address _treasury,
        address _lonStaking,
        address _miningTreasury,
        address _feeTokenRecipient
    ) Ownable(_owner) {
        LON_TOKEN_ADDR = _LON_TOKEN_ADDR;

        isOperator[_operator] = true;

        buybackInterval = _buyBackInterval;

        require(_miningFactor <= 100, "incorrect mining factor");
        miningFactor = _miningFactor;

        require(Address.isContract(_lonStaking), "Lon staking is not a contract");
        treasury = _treasury;
        lonStaking = _lonStaking;
        miningTreasury = _miningTreasury;
        feeTokenRecipient = _feeTokenRecipient;
    }

    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function getFeeTokenPath(address _feeTokenAddr) public view returns (address[] memory path) {
        return feeTokens[_feeTokenAddr].path;
    }

    /************************************************************
    *             Management functions for Owner                *
    *************************************************************/
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setOperator(address _operator, bool _enable) external onlyOwner {
        isOperator[_operator] = _enable;

        emit SetOperator(_operator, _enable);
    }

    function setMiningFactor(uint8 _miningFactor) external onlyOwner {
        require(_miningFactor <= 100, "incorrect mining factor");

        miningFactor = _miningFactor;
        emit SetMiningFactor(_miningFactor);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function setLonStaking(address _lonStaking) external onlyOwner {
        require(Address.isContract(_lonStaking), "Lon staking is not a contract");

        lonStaking = _lonStaking;
        emit SetLonStaking(_lonStaking);
    }

    function setMiningTreasury(address _miningTreasury) external onlyOwner {
        miningTreasury = _miningTreasury;
        emit SetMiningTreasury(_miningTreasury);
    }

    function setFeeTokenRecipient(address _feeTokenRecipient) external onlyOwner {
        feeTokenRecipient = _feeTokenRecipient;
        emit SetFeeTokenRecipient(_feeTokenRecipient);
    }

    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external only_Operator_or_Owner {
        IERC20(_tokenAddress).safeTransfer(owner, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function setBuybackInterval(uint32 _buyBackInterval) external only_Operator_or_Owner {
        require(_buyBackInterval >= 3600, "invalid buyback interval");

        buybackInterval = _buyBackInterval;
        emit SetBuybackInterval(_buyBackInterval);
    }

    function setStrategyAddrs(uint256[] calldata _indexes, address[] calldata _strategyAddrs) external only_Operator_or_Owner {
        require(_indexes.length == _strategyAddrs.length, "input not the same length");

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(Address.isContract(_strategyAddrs[i]), "strategy is not a contract");
            require(_indexes[i] <= numStrategyAddr, "index out of bound");

            strategyAddrs[_indexes[i]] = _strategyAddrs[i];
            if (_indexes[i] == numStrategyAddr) numStrategyAddr++;
            emit SetStrategy(_indexes[i], _strategyAddrs[i]);
        }
    }

    function setExchangeAddrs(uint256[] calldata _indexes, address[] calldata _exchangeAddrs) external only_Operator_or_Owner {
        require(_indexes.length == _exchangeAddrs.length, "input not the same length");

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(Address.isContract(_exchangeAddrs[i]), "exchange is not a contract");
            require(_indexes[i] <= numExchangeAddr, "index out of bound");

            exchangeAddrs[_indexes[i]] = _exchangeAddrs[i];
            if (_indexes[i] == numExchangeAddr) numExchangeAddr++;
            emit SetExchange(_indexes[i], _exchangeAddrs[i]);
        }
    }

    function setFeeToken(
        address _feeTokenAddr,
        uint8 _exchangeIndex,
        address[] calldata _path,
        uint8 _LFactor,
        uint8 _RFactor,
        bool _enable,
        uint256 _minBuy,
        uint256 _maxBuy
    ) external only_Owner_or_Operator_or_Self {
        // Validate fee token inputs
        require(Address.isContract(_feeTokenAddr), "fee token is not a contract");
        require(Address.isContract(exchangeAddrs[_exchangeIndex]), "exchange is not a contract");
        require(_path.length >= 2, "invalid swap path");
        require(_path[_path.length - 1] == LON_TOKEN_ADDR, "output token must be LON");
        require(_LFactor <= 100, "incorrect LFactor");
        require(_RFactor <= 100, "incorrect RFactor");
        require(_minBuy <= _maxBuy, "incorrect minBuy and maxBuy");

        FeeToken storage feeToken = feeTokens[_feeTokenAddr];
        feeToken.exchangeIndex = _exchangeIndex;
        feeToken.path = _path;
        feeToken.LFactor = _LFactor;
        feeToken.RFactor = _RFactor;
        if (feeToken.enable != _enable) {
            feeToken.enable = _enable;
            emit EnableFeeToken(_feeTokenAddr, _enable);
        }
        feeToken.minBuy = _minBuy;
        feeToken.maxBuy = _maxBuy;
        emit SetFeeToken(_feeTokenAddr, _exchangeIndex, _path, _LFactor, _RFactor, _minBuy, _maxBuy);
    }

    function setFeeTokens(
        address[] memory _feeTokenAddr,
        uint8[] memory _exchangeIndex,
        address[][] memory _path,
        uint8[] memory _LFactor,
        uint8[] memory _RFactor,
        bool[] memory _enable,
        uint256[] memory _minBuy,
        uint256[] memory _maxBuy
    ) external only_Operator_or_Owner {
        uint256 inputLength = _feeTokenAddr.length;
        require(
            (_exchangeIndex.length == inputLength) &&
                (_path.length == inputLength) &&
                (_LFactor.length == inputLength) &&
                (_RFactor.length == inputLength) &&
                (_enable.length == inputLength) &&
                (_minBuy.length == inputLength) &&
                (_maxBuy.length == inputLength),
            "input not the same length"
        );

        for (uint256 i = 0; i < inputLength; i++) {
            try
                this.setFeeToken(
                    _feeTokenAddr[i],
                    _exchangeIndex[i],
                    _path[i],
                    _LFactor[i],
                    _RFactor[i],
                    _enable[i],
                    _minBuy[i],
                    _maxBuy[i]
                )
            {
                continue;
            } catch Error(string memory reason) {
                emit SetFeeTokenFailure(_feeTokenAddr[i], reason, bytes(""));
            } catch (bytes memory lowLevelData) {
                emit SetFeeTokenFailure(_feeTokenAddr[i], "", lowLevelData);
            }
        }
    }

    function enableFeeToken(address _feeTokenAddr, bool _enable) external only_Operator_or_Owner {
        FeeToken storage feeToken = feeTokens[_feeTokenAddr];
        if (feeToken.enable != _enable) {
            feeToken.enable = _enable;
            emit EnableFeeToken(_feeTokenAddr, _enable);
        }
    }

    function enableFeeTokens(address[] calldata _feeTokenAddr, bool[] calldata _enable) external only_Operator_or_Owner {
        require(_feeTokenAddr.length == _enable.length, "input not the same length");

        for (uint256 i = 0; i < _feeTokenAddr.length; i++) {
            FeeToken storage feeToken = feeTokens[_feeTokenAddr[i]];
            if (feeToken.enable != _enable[i]) {
                feeToken.enable = _enable[i];
                emit EnableFeeToken(_feeTokenAddr[i], _enable[i]);
            }
        }
    }

    function _isAuthorized(address _account) internal view returns (bool) {
        if ((isOperator[_account]) || (_account == owner)) return true;
        else return false;
    }

    function _validate(
        FeeToken memory _feeToken,
        uint256 _amount
    ) internal view returns (uint256 amountFeeTokenToSwap, uint256 amountFeeTokenToTransfer) {
        require(_amount > 0, "zero fee token amount");
        if (!_isAuthorized(msg.sender)) {
            require(_feeToken.enable, "fee token is not enabled");
        }

        amountFeeTokenToTransfer = _amount.mul(_feeToken.LFactor).div(100);
        amountFeeTokenToSwap = _amount.sub(amountFeeTokenToTransfer);

        if (amountFeeTokenToSwap > 0) {
            require(amountFeeTokenToSwap >= _feeToken.minBuy, "amount less than min buy");
            require(amountFeeTokenToSwap <= _feeToken.maxBuy, "amount greater than max buy");
            require(block.timestamp > uint256(_feeToken.lastTimeBuyback).add(uint256(buybackInterval)), "already a buyback recently");
        }
    }

    function _transferFeeToken(
        address _feeTokenAddr,
        address _transferTo,
        uint256 _totalFeeTokenAmount
    ) internal {
        address strategyAddr;
        uint256 balanceInStrategy;
        uint256 amountToTransferFrom;
        uint256 cumulatedAmount;
        for (uint256 i = 0; i < numStrategyAddr; i++) {
            strategyAddr = strategyAddrs[i];
            balanceInStrategy = IERC20(_feeTokenAddr).balanceOf(strategyAddr);
            if (cumulatedAmount.add(balanceInStrategy) > _totalFeeTokenAmount) {
                amountToTransferFrom = _totalFeeTokenAmount.sub(cumulatedAmount);
            } else {
                amountToTransferFrom = balanceInStrategy;
            }
            if (amountToTransferFrom == 0) continue;
            IERC20(_feeTokenAddr).safeTransferFrom(strategyAddr, _transferTo, amountToTransferFrom);

            cumulatedAmount = cumulatedAmount.add(amountToTransferFrom);
            if (cumulatedAmount == _totalFeeTokenAmount) break;
        }
        require(cumulatedAmount == _totalFeeTokenAmount, "insufficient amount of fee tokens");
    }

    function _swap(
        address _feeTokenAddr,
        address _exchangeAddr,
        address[] memory _path,
        uint256 _amountFeeTokenToSwap,
        uint256 _minLonAmount
    ) internal returns (uint256 swappedLonAmount) {
        // Approve exchange contract
        IERC20(_feeTokenAddr).safeApprove(_exchangeAddr, MAX_UINT);

        // Swap fee token for Lon
        IUniswapRouterV2 router = IUniswapRouterV2(_exchangeAddr);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            _amountFeeTokenToSwap,
            _minLonAmount,  // Minimum amount of Lon expected to receive
            _path,
            address(this),
            block.timestamp + 60
        );
        swappedLonAmount = amounts[_path.length - 1];

        // Clear allowance for exchange contract
        IERC20(_feeTokenAddr).safeApprove(_exchangeAddr, 0);
    }

    function _distributeLon(
        FeeToken memory _feeToken, 
        uint256 swappedLonAmount
    ) internal {
        // To Treasury
        uint256 treasuryAmount = swappedLonAmount.mul(_feeToken.RFactor).div(100);
        if (treasuryAmount > 0) {
            IERC20(LON_TOKEN_ADDR).safeTransfer(treasury, treasuryAmount);
        }

        // To LonStaking
        uint256 lonStakingAmount = swappedLonAmount.sub(treasuryAmount);
        if (lonStakingAmount > 0) {
            IERC20(LON_TOKEN_ADDR).safeTransfer(lonStaking, lonStakingAmount);
        }

        emit DistributeLon(treasuryAmount, lonStakingAmount);
    }

    function _mintLon(uint256 swappedLonAmount) internal {
        // Mint Lon for MiningTreasury
        uint256 mintedAmount = swappedLonAmount.mul(uint256(miningFactor)).div(100);
        if (mintedAmount > 0) {
            ILon(LON_TOKEN_ADDR).mint(miningTreasury, mintedAmount);
            emit MintLon(mintedAmount);
        }
    }

    function _buyback(
        address _feeTokenAddr,
        FeeToken storage _feeToken,
        address _exchangeAddr,
        uint256 _amountFeeTokenToSwap,
        uint256 _minLonAmount
    ) internal {
        if (_amountFeeTokenToSwap > 0) {
            uint256 swappedLonAmount =
                _swap(_feeTokenAddr, _exchangeAddr, _feeToken.path, _amountFeeTokenToSwap, _minLonAmount);

            // Update fee token data
            _feeToken.lastTimeBuyback = uint32(block.timestamp);

            emit BuyBack(
                _feeTokenAddr,
                _amountFeeTokenToSwap,
                swappedLonAmount,
                _feeToken.LFactor,
                _feeToken.RFactor,
                _feeToken.minBuy,
                _feeToken.maxBuy
            );

            _distributeLon(_feeToken, swappedLonAmount);
            _mintLon(swappedLonAmount);
        }
    }

    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function buyback(address _feeTokenAddr, uint256 _amount, uint256 _minLonAmount) external whenNotPaused only_EOA_or_Self {
        FeeToken storage feeToken = feeTokens[_feeTokenAddr];

        // Distribute LON directly without swap
        if (_feeTokenAddr == LON_TOKEN_ADDR) {
            require(feeToken.enable, "fee token is not enabled");
            require(_amount >= feeToken.minBuy, "amount less than min buy");
            uint256 _lonToTreasury = _amount.mul(feeToken.RFactor).div(100);
            uint256 _lonToStaking = _amount.sub(_lonToTreasury);
            _transferFeeToken(LON_TOKEN_ADDR, treasury, _lonToTreasury);
            _transferFeeToken(LON_TOKEN_ADDR, lonStaking, _lonToStaking);
            emit DistributeLon(_lonToTreasury, _lonToStaking);
            _mintLon(_amount);

            // Update lastTimeBuyback
            feeToken.lastTimeBuyback = uint32(block.timestamp);
            return;
        }

        // Validate fee token data and input amount
        (uint256 amountFeeTokenToSwap, uint256 amountFeeTokenToTransfer) = _validate(feeToken, _amount);

        if (amountFeeTokenToSwap == 0) {
            // No need to swap, transfer feeToken directly
            _transferFeeToken(_feeTokenAddr, feeTokenRecipient, amountFeeTokenToTransfer);
        } else {
            // Transfer fee token from strategy contracts to distributor
            _transferFeeToken(_feeTokenAddr, address(this), _amount);

            // Buyback
            _buyback(_feeTokenAddr, feeToken, exchangeAddrs[feeToken.exchangeIndex], amountFeeTokenToSwap, _minLonAmount);

            // Transfer fee token from distributor to feeTokenRecipient
            if (amountFeeTokenToTransfer > 0) {
                IERC20(_feeTokenAddr).safeTransfer(feeTokenRecipient, amountFeeTokenToTransfer);
            }
        }
    }

    function batchBuyback(
        address[] calldata _feeTokenAddr,
        uint256[] calldata _amount,
        uint256[] calldata _minLonAmount
    ) external whenNotPaused only_EOA {
        uint256 inputLength = _feeTokenAddr.length;
        require(
            (_amount.length == inputLength) &&
            (_minLonAmount.length == inputLength),
            "input not the same length"
        );

        for (uint256 i = 0; i < inputLength; i++) {
            try this.buyback(_feeTokenAddr[i], _amount[i], _minLonAmount[i]) {
                continue;
            } catch Error(string memory reason) {
                emit BuyBackFailure(_feeTokenAddr[i], _amount[i], reason, bytes(""));
            } catch (bytes memory lowLevelData) {
                emit BuyBackFailure(_feeTokenAddr[i], _amount[i], "", lowLevelData);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEIP2612 is IERC20 {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function nonces(address owner) external view returns (uint256);
  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEmergency {
    function emergencyWithdraw(IERC20 token) external ;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IEmergency.sol";
import "./IEIP2612.sol";

interface ILon is IEmergency, IEIP2612 {
  function cap() external view returns(uint256);

  function mint(address to, uint256 amount) external; 

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IUniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

