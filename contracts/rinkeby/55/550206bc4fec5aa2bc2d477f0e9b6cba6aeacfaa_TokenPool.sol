/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";
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
    constructor () {
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


// Root file: contracts/TokenPool.sol

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract TokenPool is Ownable {
    using SafeMath for *;
    using SafeERC20 for IERC20Detailed;

    uint256 constant _SCALING_FACTOR = 10**18; // decimals

    // Contract state in terms of deposit
    enum ContractState {PENDING_SUPPLY, TOKENS_SUPPLIED, SALE_ENDED}

    // Participation structure
    struct Participation {
        uint256 amountBNBPaid;
        uint256 amountOfTokensReceived;
        uint256 timestamp;
        uint256 amountOfTokensWithdrawn;
    }

    // State in which is contract
    ContractState state;

    address[] whitelistedParticipants;
    mapping(address => bool) isParticipantWhitelisted;

    // List all participations
    Participation[] participations;

    // Mapping if user has participated in private/public sale or not
    mapping(address => bool) isParticipated;

    // Mapping user to his participation ids;
    mapping(address => uint256) userToParticipationId;

    // Total amount of tokens sold
    uint256 totalTokensSold;

    // Total BNB raised
    uint256 totalBNBRaised;

    // Public sale max participation
    uint256 publicMaxAllocation;

    // Timestamps for private sale
    uint256 salePrivateStartTime;
    uint256 salePrivateEndTime;

    // Timestamp for public sale
    uint256 salePublicStartTime;
    uint256 salePublicEndTime;

    // Token price is quoted against BNB token and represents how much 1 token is worth BNB
    // So, given example: If user wants to set token price to be 0.5 BNB tokens, the token price value will be
    // 0.5 ** 10**18
    uint256 tokenPrice;

    // Allocation for private sell
    uint256 privateSellAllocation;

    // Amount sold during private sell
    uint256 privateSellTokensSold;

    // Amount of tokens user wants to sell
    uint256 amountOfTokensToSell;

    // Time at which tokens are getting unlocked
    uint256 tokensUnlockingTime;

    // Token which is being sold
    IERC20Detailed tokenSold;

    // Token which user needs to hold to participate in the sale
    IERC20Detailed tokenHold;

    uint256 requiredHoldAmount;

    // Modifier checking if private sale is active
    modifier isPrivateSaleActive {
        require(
            block.timestamp >= salePrivateStartTime &&
                block.timestamp <= salePrivateEndTime
        );
        require(state == ContractState.TOKENS_SUPPLIED);
        _;
    }

    // Modifier checking if public sale is active
    modifier isPublicSaleActive {
        require(
            block.timestamp >= salePublicStartTime &&
                block.timestamp <= salePublicEndTime
        );
        require(state == ContractState.TOKENS_SUPPLIED);
        _;
    }

    modifier holdEnoughTokens {
        uint256 tokenHoldBalance = tokenHold.balanceOf(_msgSender());
        require(
            tokenHoldBalance >= requiredHoldAmount,
            "User does not hold enough token to participate."
        );
        _;
    }

    constructor(
        uint256 _salePrivateStartTime,
        uint256 _salePrivateEndTime,
        uint256 _salePublicStartTime,
        uint256 _salePublicEndTime,
        uint256 _tokensUnlockingTime,
        address _tokenAddress,
        address _tokenHoldAddress
    ) {
        // Private sale timestamps
        salePrivateStartTime = _salePrivateStartTime;
        salePrivateEndTime = _salePrivateEndTime;

        // Public sale timestamps
        salePublicStartTime = _salePublicStartTime;
        salePublicEndTime = _salePublicEndTime;

        // Set time after which tokens can be withdrawn
        tokensUnlockingTime = _tokensUnlockingTime;

        // Token price and amount of tokens selling
        tokenSold = IERC20Detailed(_tokenAddress);

        tokenHold = IERC20Detailed(_tokenHoldAddress);

        // Allow selling only tokens with 18 decimals
        require(tokenSold.decimals() == 18);

        // Set initial state to pending supply
        state = ContractState.PENDING_SUPPLY;
    }

    function depositTokensToSell(
        uint256 _amountOfTokensToSell,
        uint256 _tokenPrice,
        uint8 _privateSalePercent,
        uint256 _publicMaxAllocation,
        uint256 _minHoldAmount
    ) public onlyOwner {
        // This can be called only once, while contract is in the state of PENDING_SUPPLY
        require(
            state == ContractState.PENDING_SUPPLY,
            "Fund Contract : Must be in PENDING_SUPPLY state"
        );

        require(
            _amountOfTokensToSell > 0,
            "Amount of tokens to sell cannot be 0"
        );

        require(_tokenPrice > 0, "Token price cannot be 0");

        require(
            _privateSalePercent > 0 && _privateSalePercent <= 100,
            "Invalid private sale percentage"
        );

        amountOfTokensToSell = _amountOfTokensToSell;
        tokenPrice = _tokenPrice;

        // Setting how max tokens can be bought for public sale
        publicMaxAllocation = _publicMaxAllocation;

        // Setting how much tokens user needs to hold to participate
        requiredHoldAmount = _minHoldAmount;

        // Make sure all tokens to be sold are deposited to the contract
        tokenSold.safeTransfer(address(this), amountOfTokensToSell);

        // Compute private sale allocation
        privateSellAllocation = amountOfTokensToSell
            .mul(_privateSalePercent)
            .div(100);

        // Mark contract state to SUPPLIED
        state = ContractState.TOKENS_SUPPLIED;
    }

    // Function to participate in private sale
    function participatePrivateSale()
        public
        payable
        isPrivateSaleActive
        holdEnoughTokens
    {
        require(
            isParticipantWhitelisted[_msgSender()] == true,
            "Not whitelisted."
        );

        // amountOfTokens = purchaseAmount / tokenPrice
        uint256 amountOfTokensBuying =
            (msg.value).mul(_SCALING_FACTOR).div(tokenPrice);

        require(amountOfTokensBuying > 0, "Cannot buy 0");

        // Compute maximal participation for user
        uint256 maximalParticipationForUser =
            computeMaxPrivateParticipationAmount(_msgSender());

        if (isParticipated[_msgSender()]) {
            Participation memory p =
                participations[userToParticipationId[_msgSender()]];

            uint256 amountBought = p.amountOfTokensReceived;

            require(
                amountBought.add(amountOfTokensBuying) <=
                    maximalParticipationForUser,
                "Overflow -> Buying more than allowed"
            );
        }

        // Require user wants to participate with amount his staking weight allows him
        require(
            amountOfTokensBuying <= maximalParticipationForUser,
            "Overflow -> Weighting score"
        );
        // Require that there's enough tokens
        require(
            privateSellTokensSold.add(amountOfTokensBuying) <=
                privateSellAllocation,
            "Overflow -> Buying more than available"
        );
        // Account sold tokens
        privateSellTokensSold = privateSellTokensSold.add(amountOfTokensBuying);
        // Internal sell tokens function
        sellTokens(msg.value, amountOfTokensBuying);
    }

    // Function to participate in public sale
    function participatePublicSale()
        public
        payable
        isPublicSaleActive
        holdEnoughTokens
    {
        // amountOfTokens = purchaseAmount / tokenPrice
        uint256 amountOfTokensBuying =
            (msg.value).mul(_SCALING_FACTOR).div(tokenPrice);

        require(amountOfTokensBuying > 0, "Cannot buy 0");

        require(
            amountOfTokensBuying <= publicMaxAllocation,
            "Overflow -> Buying more than maximum allowed"
        );

        if (
            block.timestamp >= salePrivateStartTime &&
            block.timestamp <= salePrivateEndTime
        ) {
            require(
                amountOfTokensToSell.sub(totalTokensSold).sub(
                    privateSellAllocation
                ) > amountOfTokensBuying,
                "PRIVATE SALE IN PROGRESS: Overflow -> Buying more than available"
            );
        } else {
            // private sale ended, allow buying leftover
            require(
                amountOfTokensToSell.sub(totalTokensSold) >
                    amountOfTokensBuying,
                "PRIVATE SALE ENDED: Overflow -> Buying more than available"
            );
        }

        // Internal sell tokens function
        sellTokens(msg.value, amountOfTokensBuying);
    }

    // Internal function to handle selling tokens per given price
    function sellTokens(
        uint256 participationAmount,
        uint256 amountOfTokensBuying
    ) internal {
        // Add amount of tokens user is buying to total sold amount
        totalTokensSold = totalTokensSold.add(amountOfTokensBuying);

        // Add amount of BNBs raised
        totalBNBRaised = totalBNBRaised.add(participationAmount);

        if (isParticipated[_msgSender()] == true) {
            // If user has participated, update their data
            Participation storage p =
                participations[userToParticipationId[_msgSender()]];
            p.amountBNBPaid = p.amountBNBPaid.add(participationAmount);
            p.amountOfTokensReceived = p.amountOfTokensReceived.add(
                amountOfTokensBuying
            );
            p.timestamp = block.timestamp;
        } else {
            // Compute participation id
            uint256 participationId = participations.length;

            // Create participation object
            Participation memory p =
                Participation({
                    amountBNBPaid: participationAmount,
                    amountOfTokensReceived: amountOfTokensBuying,
                    timestamp: block.timestamp,
                    amountOfTokensWithdrawn: 0
                });

            // Push participation to array of all participations
            participations.push(p);

            // Map user to his participation ids
            userToParticipationId[_msgSender()] = participationId;

            // Mark that user have participated
            isParticipated[_msgSender()] = true;
        }
    }

    // Internal function to handle safe transfer
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    function withdrawEarningsAndLeftover() public onlyOwner {
        // Make sure both private and public sale expired
        require(
            block.timestamp >= salePublicEndTime &&
                block.timestamp >= salePrivateEndTime
        );

        // Earnings amount of the owner
        uint256 totalEarnings = address(this).balance;
        // Amount of tokens which are not sold
        uint256 leftover = amountOfTokensToSell.sub(totalTokensSold);

        safeTransferBNB(_msgSender(), totalEarnings);

        if (leftover > 0) {
            tokenSold.safeTransfer(_msgSender(), leftover);
        }

        // Set state of the contract to ENDED
        state = ContractState.SALE_ENDED;
    }

    // Function where user can withdraw tokens they have bought
    function withdrawTokens() public {
        require(
            isParticipated[_msgSender()] == true,
            "User is not participant."
        );
        require(
            block.timestamp > tokensUnlockingTime,
            "Tokens are not unlocked yet."
        );
        // Get user participation id
        uint256 participationId = userToParticipationId[_msgSender()];
        // Same unit can't be withdrawn twice
        Participation storage p = participations[participationId];

        uint256 availableToWithdraw =
            p.amountOfTokensReceived.sub(p.amountOfTokensWithdrawn);

        require(availableToWithdraw > 0, "Nothing to withdraw");
        // Transfer bought tokens to address
        tokenSold.safeTransfer(_msgSender(), availableToWithdraw);
        // Update withdrawn amount
        p.amountOfTokensWithdrawn = p.amountOfTokensWithdrawn.add(
            availableToWithdraw
        );
    }

    // Function to check user participation ids
    function getUserParticipationId(address user)
        public
        view
        returns (uint256)
    {
        return userToParticipationId[user];
    }

    // Function to return total number of participations
    function getNumberOfParticipations() public view returns (uint256) {
        return participations.length;
    }

    // Function to fetch high level overview of pool sale stats
    function getSaleStats() public view returns (uint256, uint256) {
        return (totalTokensSold, totalBNBRaised);
    }

    // Function to return when purchased tokens can be withdrawn
    function getTokensUnlockingTime() public view returns (uint256) {
        return tokensUnlockingTime;
    }

    // Function to compute maximal private sell participation amount based on the weighting score
    function computeMaxPrivateParticipationAmount(address user)
        public
        view
        returns (uint256)
    {
        uint256 tokenHoldBalance = tokenHold.balanceOf(_msgSender());
        if (tokenHoldBalance < requiredHoldAmount) {
            // User does not hold enough tokens
            return 0;
        }
        if (isParticipated[user] == true) {
            // User can participate only once
            return 0;
        }
        // Compute the maximum user can participate in the private sell
        uint256 maxParticipation =
            (privateSellAllocation).div(whitelistedParticipants.length);
        // Compute how much tokens are left in private sell allocation
        uint256 leftoverInPrivate =
            privateSellAllocation.sub(privateSellTokensSold);
        // Return
        return
            maxParticipation > leftoverInPrivate
                ? leftoverInPrivate
                : maxParticipation;
    }

    // Function to check in which state is the contract at the moment
    function getInventoryState() public view returns (string memory) {
        if (state == ContractState.PENDING_SUPPLY) {
            return "PENDING_SUPPLY";
        }
        return "TOKENS_SUPPLIED";
    }

    // Function to get pool state depending on time and allocation
    function getPoolState() public view returns (string memory) {
        if (
            state == ContractState.PENDING_SUPPLY &&
            block.timestamp < salePublicEndTime
        ) {
            return "UPCOMING";
        }
        if (block.timestamp < salePrivateStartTime) {
            return "UPCOMING";
        }
        if (totalTokensSold >= amountOfTokensToSell.mul(999).div(1000)) {
            return "FINISHED";
        } else if (block.timestamp < salePublicEndTime) {
            return "ONGOING";
        }
        return "FINISHED";
    }

    function getPoolInformation()
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool, // Is private sell active
            bool // is public sell active
        )
    {
        string memory tokenSymbol = tokenSold.symbol();
        bool isPrivateSellActive;
        bool isPublicSellActive;

        if (
            block.timestamp >= salePrivateStartTime &&
            block.timestamp <= salePrivateEndTime
        ) {
            isPrivateSellActive = true;
        } else if (
            block.timestamp >= salePublicStartTime &&
            block.timestamp <= salePublicEndTime
        ) {
            isPublicSellActive = true;
        }

        return (
            tokenSymbol,
            totalTokensSold,
            amountOfTokensToSell,
            salePrivateStartTime,
            salePrivateEndTime,
            salePublicStartTime,
            salePublicEndTime,
            tokenPrice,
            isPrivateSellActive,
            isPublicSellActive
        );
    }

    // Function to get participation for specific user.
    function getParticipation(address user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (isParticipated[user] == false) {
            return (0, 0, 0, 0, 0);
        }
        Participation memory p = participations[userToParticipationId[user]];

        return (
            p.amountBNBPaid,
            p.amountOfTokensReceived,
            p.amountOfTokensWithdrawn,
            p.timestamp,
            tokensUnlockingTime
        );
    }

    /**
     * @notice Function to whitelist participants for private sale
     */
    function whitelistParticipants(address[] memory participants)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < participants.length; i++) {
            // Avoid double whitelisting already whitelisted people
            if (!isParticipantWhitelisted[participants[i]]) {
                whitelistedParticipants.push(participants[i]);
                // Whitelist this participant
                isParticipantWhitelisted[participants[i]] = true;
            }
        }
    }

    function getNumberOfWhitelistedParticipants()
        public
        view
        returns (uint256)
    {
        return whitelistedParticipants.length;
    }

    function getWhitelistedParticipants(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (address[] memory)
    {
        if (startIndex == 0 && endIndex == 0) {
            return whitelistedParticipants;
        } else {
            uint256 len = endIndex - startIndex;
            address[] memory whitelistedParticipantsPart = new address[](len);

            uint256 counter = 0;
            for (uint256 i = startIndex; i < endIndex; i++) {
                whitelistedParticipantsPart[counter] = whitelistedParticipants[
                    i
                ];
                counter++;
            }

            return whitelistedParticipantsPart;
        }
    }

    receive() external payable {
        bool privateSaleActive =
            block.timestamp >= salePrivateStartTime &&
                block.timestamp <= salePrivateEndTime;
        if (isParticipantWhitelisted[_msgSender()] && privateSaleActive) {
            participatePrivateSale();
        } else {
            participatePublicSale();
        }
    }
}