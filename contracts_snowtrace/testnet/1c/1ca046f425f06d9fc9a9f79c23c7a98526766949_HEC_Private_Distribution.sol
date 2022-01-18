/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Provides walletsrmation about the current execution context, including the
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
        return msg.data;
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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
 * @dev Heroes Chained base TimeLock Contract.
 *
 */
abstract contract HEC_Base_Distribution is Ownable, ReentrancyGuard {
    /* ====== INCLUDES ====== */
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ====== CONSTANTS ====== */
    uint256 internal constant SECONDS_PER_DAY        = 24 * 60 * 60;

    /* ====== EVENTS ====== */
    event RewardClaimed(address indexed user, uint256 amount);
    
    /* ====== VARIABLES ====== */
    address public immutable HeC;
    uint256 internal totalDebt;
    bool internal STOPPED = false;
    mapping( address => uint256 ) public walletIndices;
    WalletInfo[] public wallets;

    /* ====== STRUCTS ====== */        
    struct WalletInfo {
        address recipient;
        uint256 unlockedBalance;
        uint256 lockedBalance;
        uint256 initialBalance;
        uint256 releaseAmountPerDay;
        uint256 claimableEpochTime;
    }    
    
    /* ====== VIRTUAL FUNCTIONS ====== */        
    function getTGEEpochTime() internal virtual view returns(uint256);
    function getInitialContractBalance() internal virtual view returns(uint256);
    function getTGEUnlockPercentage()  internal virtual view returns(uint256);
    function getCliffEndEpochTime()    internal virtual view returns(uint256);
    function getVestingEndEpochTime()  internal virtual view returns(uint256);

    /* ====== CONSTRUCTOR ====== */
    constructor( address _hec) {
        require( _hec != address(0) );
        HeC = _hec;
        totalDebt = 0;
        STOPPED = false;
    }
    
    /* ====== FUNCTIONS ====== */

    /**
        @notice calculate and send claimable amount to the recipient as of call time
     */
    function claim() external nonReentrant {
        require(STOPPED == false, "Contract is in suspended state.");
        require(getTGEEpochTime() > 0, "Contract not initialized yet.");
        require(wallets.length > 0, "No recipients found.");
        require(uint256(block.timestamp) > getTGEEpochTime(), "Request not valid.");

        uint256 index = walletIndices[msg.sender];
        require(wallets[ index ].recipient == msg.sender, "Claim request is not valid.");
        require(wallets[ index ].lockedBalance.add( wallets[ index ].unlockedBalance ) > 0, "There is no balance left to claim.");
        
        uint256 valueToSendFromVesting = calculateClaimableAmountForVesting( index );
        uint256 valueToSendFromTGE = wallets[ index ].unlockedBalance;
        uint256 valueToSendTOTAL = valueToSendFromVesting.add(valueToSendFromTGE);

        require( valueToSendTOTAL > 0, "There is no balance to claim at the moment.");

        uint256 vestingDayCount = calculateVestingDayCount( wallets[ index ].claimableEpochTime, uint256(block.timestamp) );

        wallets[ index ].lockedBalance = wallets[ index ].lockedBalance.sub( valueToSendFromVesting );
        wallets[ index ].unlockedBalance = wallets[ index ].unlockedBalance.sub( valueToSendFromTGE );
        wallets[ index ].claimableEpochTime = wallets[ index ].claimableEpochTime.add( vestingDayCount.mul( SECONDS_PER_DAY ) );

        totalDebt = totalDebt.sub( valueToSendTOTAL );

        IERC20( HeC ).safeTransfer(msg.sender, valueToSendTOTAL);
        emit RewardClaimed( msg.sender, valueToSendTOTAL );
    }

    /**
        @notice calculate and return claimable amount as of call time
     */
    function claimable() external view returns (uint256) {
        require(STOPPED == false, "Contract is in suspended state.");
        require(getTGEEpochTime() > 0, "Contract not initialized yet.");
        require(wallets.length > 0, "No recipients found.");

        uint256 index = walletIndices[ msg.sender ];                
        require(wallets[ index ].recipient == msg.sender, "Request not valid.");

        if (uint256(block.timestamp) <= getTGEEpochTime())
            return 0;

        return wallets[ index ].unlockedBalance.add( calculateClaimableAmountForVesting( index ) );
    }

    /**
        @notice calculate claimable amount accoring to vesting conditions as of call time
        @param _index uint256
     */
    function calculateClaimableAmountForVesting( uint256 _index ) private view returns (uint256) {
        //initial value of current claimable time is the ending time of cliff/lock period
        //after first claim, this value is iterated forward by the time unit amount claimed.
        //Calculate the number of vesting days passed since the most recent claim time (or TGE time initially)
        //for instance, this calculations gives the number of days passed since last claim (or TGE time)
        //we use the number of seconds passed and divide it by number of seconds per day
        uint256 vestingDayCount = calculateVestingDayCount( wallets[ _index ].claimableEpochTime, uint256(block.timestamp) );
        uint256 valueToSendFromVesting = wallets[ _index ].releaseAmountPerDay.mul( vestingDayCount );

        //If claim time is after Vesting End Time, send all the remaining tokens.
        if (uint256(block.timestamp) > getVestingEndEpochTime())
            valueToSendFromVesting = wallets[ _index ].lockedBalance;

        if ( valueToSendFromVesting > wallets[ _index ].lockedBalance ) {
            valueToSendFromVesting = wallets[ _index ].lockedBalance;
        }

        return valueToSendFromVesting;
    }

    /**
        @notice calculate number of days between given dates
        @param _start_time uint256
        @param _end_time uint256
     */
    function calculateVestingDayCount( uint256 _start_time, uint256 _end_time ) private pure returns (uint256) {
        if (_end_time <= _start_time)
            return 0;

        return _end_time.sub(_start_time).div(SECONDS_PER_DAY);
    }

    /**
        @notice add a recipient to the contract.
        @param _recipient address
        @param _tokenAmount uint256
     */
    function _addRecipient( address _recipient, uint256 _tokenAmount ) private {
        uint256 index = walletIndices[ _recipient ];
        if (wallets.length > 0) {
            if (index > 0)
            {
                require(false, "Address already in list."); //Force throw exception
            }
            else
            {
                require(_recipient != wallets[0].recipient, "Address already in list.");
            }
        }

        require( _recipient != address(0), "Recipient address cannot be empty." );
        require( _tokenAmount > 0, "Token amount invalid." );
        require(totalDebt.add(_tokenAmount) <= getInitialContractBalance(), "Cannot add this debt amount due to the balance of this Contract.");
        
        uint256 vestingDayCount = calculateVestingDayCount( getCliffEndEpochTime(), getVestingEndEpochTime() );

        //This contract does not support cases where Cliff-End = Vesting-End, i.e. There's no vesting period
        require(vestingDayCount > 0, "Unexpected vesting day count.");

        uint256 _unlockedBalance = _tokenAmount.mul(getTGEUnlockPercentage()).div(100); 
        uint256 _lockedBalance = _tokenAmount.sub(_unlockedBalance);         
        uint256 _releaseAmountPerDay = _lockedBalance.div(vestingDayCount);

        wallets.push( WalletInfo({
                    recipient: _recipient,
                    unlockedBalance: _unlockedBalance,
                    lockedBalance: _lockedBalance,
                    initialBalance: _tokenAmount,
                    releaseAmountPerDay: _releaseAmountPerDay,
                    claimableEpochTime: getCliffEndEpochTime()
        }));

        walletIndices[_recipient] = wallets.length.sub(1);
        totalDebt = totalDebt.add(_tokenAmount);
    }

    /**
        @notice remove a recipient from contract
        @param _recipient address
     */
    function _removeRecipient( address _recipient ) private {
        uint256 _index = walletIndices[ _recipient ];
        require( _recipient == wallets[ _index ].recipient, "Recipient index does not match." );

        totalDebt = totalDebt.sub( wallets[ _index ].lockedBalance ).sub( wallets[ _index ].unlockedBalance );

        wallets[ _index ].recipient = address(0);
        wallets[ _index ].releaseAmountPerDay = 0;
        wallets[ _index ].claimableEpochTime = 0;
        wallets[ _index ].initialBalance = 0;
        wallets[ _index ].unlockedBalance = 0;
        wallets[ _index ].lockedBalance = 0;

        delete walletIndices[ _recipient ];
    }
    
    /**
        @notice batch add recipients to the contract.
        @param _recipients address[]
        @param _tokenAmounts uint256[]
    */
    function addRecipients(address[] memory _recipients, uint256[] memory _tokenAmounts) external nonReentrant onlyOwner returns (bool) {
        require( _recipients.length == _tokenAmounts.length, "Array sizes do not match.");
        require( _recipients.length > 0, "Array cannot be empty.");

        for( uint256 i = 0; i < _recipients.length; i++ ) {
            _addRecipient( _recipients[i], _tokenAmounts[i] );
        }

        return true;
    }    

    /**
        @notice batch remove recipients from contract
        @param _recipients address[]
    */
    function removeRecipients(address[] memory _recipients) external nonReentrant onlyOwner returns (bool) {
        require( _recipients.length > 0, "Array cannot be empty.");

        for( uint256 i = 0; i < _recipients.length; i++ ) {
            _removeRecipient( _recipients[i] );
        }

        return true;
    }

    /**
        @notice withdrawal of remaining tokens in case of emergency conditions
    */
    function emergencyWithdrawal() external nonReentrant onlyOwner {
        require(STOPPED, "Contract is not in suspended state.");

        uint256 total = IERC20( HeC ).balanceOf( address(this) );
        IERC20( HeC ).safeTransfer(msg.sender, total);
    }

    /**
        @notice temporarily stop contract operations in case of emergency conditions
    */
    function suspendOperations() external onlyOwner returns (bool) {
        STOPPED = true;
        return true;
    }

    /**
        @notice resume contract operations after emergency conditions
    */
    function resumeOperations() external onlyOwner returns (bool)  {
        STOPPED = false;
        return true;
    }

    /**
        @notice get remaining balance of this contract
    */
    function getRemainingBalance() external view onlyOwner returns (uint256) {
        return IERC20( HeC ).balanceOf( address(this) );
    }

    /**
        @notice return whether contract is suspended or not
    */
    function isSuspended() external onlyOwner view returns (bool)  {
        bool ret = STOPPED;
        return ret;
    }

    /**
        @notice get remaining debts of all recipients
    */
    function getRemainingDebt() external view onlyOwner returns (uint256) {
        uint256 remainingBalance = 0;
        for( uint256 i = 0; i < wallets.length; i++ ) {
            remainingBalance = remainingBalance.add( wallets[i].lockedBalance ).add( wallets[i].unlockedBalance );
        }

        return remainingBalance;
    }
}

/**
 * @dev Heroes Chained TimeLock Contract for Pre-Seed, Seed, Private, Team.
 *      LP, Foundation and Community & Marketing Contracts.
 */
contract HEC_Private_Distribution is HEC_Base_Distribution {
    /* ====== INCLUDES ====== */
    using SafeMath for uint256;

    //Properties - In accordance with Token Distribution Plan
    uint256 private INITIAL_CONTRACT_BALANCE = 0; //(X million tokens)
    uint256 private TGE_UNLOCK_PERCENTAGE  = 0; //X%
    uint256 private TGE_EPOCH_TIME         = 0;
    uint256 private CLIFF_END_EPOCH_TIME   = 0;
    uint256 private VESTING_END_EPOCH_TIME = 0; 

    /* ====== STRUCTS ====== */
    struct ContractInfo {
        uint256 TGEEpochTime;
        uint256 CliffEndEpochTime;
        uint256 VestingEndEpochTime;
        uint256 TGEUnlockPercentage;
        uint256 InitialContractBalance;
    }

    /* ====== CONSTRUCTOR ====== */
    constructor( address _hec ) HEC_Base_Distribution( _hec ) {
        require( _hec != address(0) );
    }
    
    /* ====== FUNCTIONS ====== */
    /**
        @notice get TGE, Cliff-End and Vesting-End and other properties
    */
    function getContractInfo() external view onlyOwner returns ( ContractInfo memory ) {
        ContractInfo memory ret = ContractInfo({
                    TGEEpochTime: TGE_EPOCH_TIME,
                    CliffEndEpochTime: CLIFF_END_EPOCH_TIME,
                    VestingEndEpochTime: VESTING_END_EPOCH_TIME,
                    TGEUnlockPercentage: TGE_UNLOCK_PERCENTAGE,
                    InitialContractBalance: INITIAL_CONTRACT_BALANCE
        });
        
        return ret;
    }
        
    function getTGEEpochTime() internal override view returns(uint256) {
        return TGE_EPOCH_TIME;
    }

    function getInitialContractBalance() internal override view returns(uint256) {
        return INITIAL_CONTRACT_BALANCE;
    }

    function getCliffEndEpochTime() internal override view returns(uint256){
        return CLIFF_END_EPOCH_TIME;
    }

    function getVestingEndEpochTime() internal override view returns(uint256){
        return VESTING_END_EPOCH_TIME;
    }

    function getTGEUnlockPercentage() internal override view returns(uint256){
        return TGE_UNLOCK_PERCENTAGE;
    }

    /**
        @notice set TGE, Cliff-End and Vesting-End dates and initialize the contract.
        @param _TGEEpochTime uint256
        @param _CliffEndEpochTime uint256
        @param _VestingEndEpochTime uint256
    */
    function setContractProperties( uint256 _InitialContractBalance, uint256 _TGEEpochTime, uint256 _TGEUnlockPercentage, uint256 _CliffEndEpochTime, uint256 _VestingEndEpochTime ) external onlyOwner returns (bool) {
        require(STOPPED, "Contract is not in suspended state.");
        require(_InitialContractBalance > 0, "Initial Contract Balance should be greater than 0.");
        require(_TGEUnlockPercentage <= 20, "TGE Unlock Percentage cannot be greater than 20% per HeC Tokenomics.");
        if (TGE_EPOCH_TIME > 0) {
            require(IERC20( HeC ).balanceOf( address(this) ) == 0, "Contract already has tokens and TGE already set. Cannot change dates at this moment.");
        }
        require(_TGEEpochTime >= uint256(block.timestamp), "TGE time cannot be earlier than now.");
        require(_CliffEndEpochTime >= _TGEEpochTime, "Cliff End time cannot be earlier than TGE time.");
        require(_VestingEndEpochTime >= _CliffEndEpochTime, "Vesting End time cannot be earlier than Cliff End time.");

        TGE_EPOCH_TIME = _TGEEpochTime;
        CLIFF_END_EPOCH_TIME = _CliffEndEpochTime;
        VESTING_END_EPOCH_TIME = _VestingEndEpochTime;
        INITIAL_CONTRACT_BALANCE = _InitialContractBalance;
        TGE_UNLOCK_PERCENTAGE = _TGEUnlockPercentage;

        return true;
    }
}