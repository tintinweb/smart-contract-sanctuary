/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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

// File: contracts/core/access/VaultRoles.sol

abstract contract VaultRoles
{
    //========================
    // ATTRIBUTES
    //========================

    //roles
    bytes32 public constant ROLE_SUPER_ADMIN = keccak256("ROLE_SUPER_ADMIN"); //role management + admin
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN"); //highest security. required to change important settings (security risk)
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER"); //required to change settings to optimize behaviour (no security risk, but trust is required)
    bytes32 public constant ROLE_SECURITY_ADMIN = keccak256("ROLE_SECURITY_ADMIN"); //can pause and unpause (no security risk, but trust is required)
    bytes32 public constant ROLE_SECURITY_MOD = keccak256("ROLE_SECURITY_MOD"); //can pause but not unpause (no security risk, minimal trust required)
    bytes32 public constant ROLE_DEPLOYER = keccak256("ROLE_DEPLOYER"); //can deploy vaults, should be a trusted developer
    bytes32 public constant ROLE_COMPOUNDER = keccak256("ROLE_COMPOUNDER"); //compounders are always allowed to compound (no security risk)
}

// File: contracts/core/access/VaultAccessManager.sol

abstract contract VaultAccessManager is VaultRoles
{
    //========================
    // ATTRIBUTES
    //========================
    
    IVaultChef public immutable vaultChef;
    address public owner;

    //========================
    // CONSTRUCT
    //========================

    constructor(
        IVaultChef _vaultChef, 
        address _owner
    )
    {   
        vaultChef = _vaultChef;
        owner = _owner;
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function isOwner() internal view returns (bool)
    {
        return (owner == msg.sender);
    }

    function requireOwner() internal view
    {
        require(
            isOwner(),
            "User is not Owner");
    }

    function requireAdmin() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireAdmin(msg.sender);
        }
    }

    function requireManager() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireManager(msg.sender);
        }
    }

    function requireDeployer() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireDeployer(msg.sender);
        }
    }

    function requireSecurityAdmin() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireSecurityAdmin(msg.sender);
        }
    }

    function requireSecurityMod() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireSecurityMod(msg.sender);
        }
    }
}

// File: contracts/interfaces/IVaultStrategy.sol

interface IVaultStrategy
{
    //========================
    // CONSTANTS
    //========================
	
	function VERSION() external view returns (string memory);
    function BASE_VERSION() external view returns (string memory);

    //========================
    // ATTRIBUTES
    //========================

    function vault() external view returns (IVault);    

    //used tokens
    function depositToken() external view returns (IToken);
    function rewardToken() external view returns (IToken);
    function additionalRewardToken() external view returns (IToken);
    function lpToken0() external view returns (IToken);
    function lpToken1() external view returns (IToken); 

    //min swap amounts
    function minAdditionalRewardToReward() external view returns (uint256);
    function minRewardToDeposit() external view returns (uint256);
    function minDustToken0() external view returns (uint256);
    function minDustToken1() external view returns (uint256);

    //auto actions
    function autoConvertDust() external view returns (bool);
    function autoCompoundBeforeDeposit() external view returns (bool);
    function autoCompoundBeforeWithdraw() external view returns (bool);

    //pause
    function pauseDeposit() external view returns (bool);
    function pauseWithdraw() external view returns (bool);
    function pauseCompound() external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================  

    function deposit() external;
    function withdraw(address _user, uint256 _amount) external;
    function compound(address _user, bool _revertOnFail) external returns (bool compounded, uint256 rewardAmount, uint256 dustAmount);

    //========================
    // OVERRIDE FUNCTIONS
    //========================
    
    function beforeDeposit() external;
    function beforeWithdraw() external;

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function balanceOf() external view returns (uint256);
    function balanceOfStrategy() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfReward() external view returns (uint256);
    function balanceOfDust() external view returns (uint256, uint256);

    function poolCompoundReward() external view returns (uint256);
    function poolPending() external view returns (uint256);
    function poolDepositFee() external view returns (uint256);
    function poolWithdrawFee() external view returns (uint256);
    function poolAllocPoints() external view returns (uint256);
    function poolStartBlock() external view returns (uint256);
    function poolEndBlock() external view returns (uint256);
    function poolEndTime() external view returns (uint256);
    function poolHarvestLockUntil() external view returns (uint256);
    function poolHarvestLockDelay() external view returns (uint256);
    function isPoolFarmable() external view returns (bool);

    //========================
    // STRATEGY RETIRE FUNCTIONS
    //========================

    function retireStrategy() external;

    //========================
    // EMERGENCY FUNCTIONS
    //========================

    function panic() external;
    function pause(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseCompound) external;
    function unpause(bool _unpauseDeposit, bool _unpauseWithdraw, bool _unpauseCompound) external;
}

// File: contracts/interfaces/IVault.sol

interface IVault
{
    //========================
    // CONSTANTS
    //========================

    function VERSION() external view returns (string memory);

    //========================
    // ATTRIBUTES
    //========================

    function strategy() external view returns (IVaultStrategy);

    function totalShares() external view returns (uint256);
    function lastCompound() external view returns (uint256);

    //========================
    // VAULT INFO FUNCTIONS
    //========================

    function depositToken() external view returns (IToken);
    function rewardToken() external view returns (IToken);
    function balance() external view returns (uint256);

    //========================
    // USER INFO FUNCTIONS
    //========================    

    function checkApproved(address _user) external view returns (bool);
    function balanceOf(address _user) external view returns (uint256);
    function userPending(address _user) external view returns (uint256);

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function poolCompoundReward() external view returns (uint256);
    function poolPending() external view returns (uint256);
    function poolDepositFee() external view returns (uint256);
    function poolWithdrawFee() external view returns (uint256);
    function poolAllocPoints() external view returns (uint256);
    function poolStartBlock() external view returns (uint256);
    function poolEndBlock() external view returns (uint256);
    function poolEndTime() external view returns (uint256);
    function poolHarvestLockUntil() external view returns (uint256);
    function poolHarvestLockDelay() external view returns (uint256);
    function isPoolFarmable() external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function depositAll(address _user) external;
    function deposit(address _user, uint256 _amount) external;
    function withdrawAll(address _user) external;
    function withdraw(address _user, uint256 _amount) external;
    function compound(address _user) external;
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/interfaces/IVaultChef.sol

interface IVaultChef is IAccessControl
{
    //========================
    // CONSTANTS
    //========================

    function VERSION() external view returns (string memory);
    function PERCENT_FACTOR() external view returns (uint256);

    //========================
    // ATTRIBUTES
    //========================

    function wrappedCoin() external view returns (IToken);

    function compoundRewardFee() external view returns (uint256);
    function nativeLiquidityFee() external view returns (uint256);
    function nativePoolFee() external view returns (uint256);
    function withdrawalFee() external view returns (uint256);

    function nativeLiquidityAddress() external view returns (address);
    function nativePoolAddress() external view returns (address);

    function compoundRewardNative() external view returns (bool);
    function allowUserCompound() external view returns (bool);    

    //========================
    // VAULT INFO FUNCTIONS
    //========================

    function vaultLength() external view returns(uint256);		
	function getVault(uint256 _vid) external view returns(IVault);
    function checkVaultApproved(uint _vid, address _user) external view returns(bool);

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function compound(uint256 _vid) external;
    function deposit(uint256 _vid, uint256 _amount) external;
    function withdraw(uint256 _vid, uint256 _amount) external;	
	function emergencyWithdraw(uint256 _vid) external;
	
	//========================
    // MISC FUNCTIONS
    //========================
	
	function setReferrer(address _referrer) external;
    function getReferralInfo(address _user) external view returns (address, uint256);

    //========================
    // SECURITY FUNCTIONS
    //========================

    function requireAdmin(address _user) external view;
    function requireDeployer(address _user) external view;
    function requireCompounder(address _user) external view;
    function requireManager(address _user) external view;
    function requireSecurityAdmin(address _user) external view;
    function requireSecurityMod(address _user) external view;
    function requireAllowedContract(address _user) external view;    
}

// File: contracts/interfaces/IToken.sol

interface IToken is IERC20
{
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
}

// File: contracts/VaultV1.sol

contract VaultV1 is IVault, VaultAccessManager, ReentrancyGuard
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;
    using SafeMath for uint256;

    //========================
    // STRUCTS
    //========================

    struct StrategyCandidate
    {
        IVaultStrategy implementation;
        uint256 proposedTime;
    }

    struct UserInfo
    {
        uint256 shares; //shares of the user
        uint256 lastDepositOrWithdrawBlock; //for block lock against flashloan
    }

    //========================
    // CONSTANTS
    //========================
	
	string public constant override VERSION = "1.0.0";
    uint256 public constant STRATEGY_APPROVAL_DELAY = 1 days; //minimum time required before upgrade is allowed

    //========================
    // ATTRIBUTES
    //========================

    IVaultStrategy public override strategy; //current strategy    
    StrategyCandidate public strategyCandidate; //last proposed strategy      

    mapping(address => UserInfo) public userMap;
    uint256 public override totalShares;
    uint256 public override lastCompound;

    //========================
    // EVENTS
    //========================

    event NewStrategyCandidate(IVaultStrategy _implementation);
    event UpgradeStrategy(IVaultStrategy _implementation);
    event Deposit(address indexed _user, uint256 _amount, uint256 _depositedAmount, uint256 _userDepositBefore, uint256 _userDepositAfter, uint256 _totalDepositAfter);
    event Withdraw(address indexed _user, uint256 _amount, uint256 _withdrawnAmount, uint256 _userDepositBefore, uint256 _userDepositAfter, uint256 _totalDepositAfter);
    event Compound(address indexed _user, uint256 _totalDepositBefore, uint256 _totalDepositAfter, uint256 _reward, uint256 _dust);
    event Pause(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event Unpause(address indexed _user, bool _deposit, bool _withdraw, bool _compound);

    //========================
    // CREATE
    //========================

    constructor(
        IVaultChef _vaultChef
    )
    VaultAccessManager(_vaultChef, address(_vaultChef))
    {

    }

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function poolCompoundReward() external view override returns (uint256)
    {
        return strategy.poolCompoundReward();
    }

    function poolPending() public view override returns (uint256)
    {
        return strategy.poolPending();
    }

    function poolDepositFee() external view override returns (uint256)
    {
        return strategy.poolDepositFee();
    }

    function poolWithdrawFee() external view override returns (uint256)
    {
        return strategy.poolWithdrawFee();
    }

    function poolAllocPoints() external view override returns (uint256)
    {
        return strategy.poolAllocPoints();
    }

    function poolStartBlock() external view override returns (uint256)
    {
        return strategy.poolStartBlock();
    }

    function poolEndBlock() external view override returns (uint256)
    {
        return strategy.poolEndBlock();
    }

    function poolEndTime() external view override returns (uint256)
    {
        return strategy.poolEndTime();
    }

    function poolHarvestLockUntil() external view override returns (uint256)
    {
        return strategy.poolHarvestLockUntil();
    }

    function poolHarvestLockDelay() external view override returns (uint256)
    {
        return strategy.poolHarvestLockDelay();
    }

    function isPoolFarmable() external view override returns (bool)
    {
        return strategy.isPoolFarmable();
    }

    //========================
    // VAULT INFO FUNCTIONS
    //========================

    function depositToken() public view override returns (IToken)
    {
        return IToken(strategy.depositToken());
    }

    function rewardToken() public view override returns (IToken)
    {
        return IToken(strategy.rewardToken());
    }

    function balance() public view override returns (uint256)
    {
        return balanceOfVault().add(balanceOfStrategy());
    }

    function balanceOfStrategy() public view returns (uint256)
    {
        return strategy.balanceOf();
    }

    function balanceOfVault() public view returns (uint256)
    {
        return depositToken().balanceOf(address(this));
    }

    //========================
    // USER INFO FUNCTIONS
    //========================

    function checkApproved(address _user) external view override returns (bool)
    {
        return (depositToken().allowance(_user, address(this)) != 0);
    }

    function balanceOf(address _user) public view override returns (uint256)
    {
        return userShare(_user, balance());
    }

    function userPending(address _user) public view override returns (uint256)
    {
        return userShare(_user, poolPending());
    }

    function userShare(address _user, uint256 _total) internal view returns (uint256)
    {
        UserInfo storage user = userMap[_user];
        if (totalShares == 0)
        {
            return 0;
        }
        return _total.mul(user.shares).div(totalShares);
    }

    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function depositAll(address _user) external override
    {
        deposit(_user, depositToken().balanceOf(_user));
    }

    function deposit(address _user, uint256 _amount) public virtual override nonReentrant
    {
        //check
        requireOwner();

        //check for auto compound
        if (strategy.autoCompoundBeforeDeposit()
            && balance() > 0)
        {
            compoundStrategy(_user, false);
        }

        //before deposit
        strategy.beforeDeposit();

        //deposit into pool
        uint256 balanceBefore = balance();
        uint256 userBalanceBefore = balanceOf(_user);        
        farm(_user, _amount);

        //check real transfered amount
        uint256 balanceAfter = balance();
        uint256 userDeposit = balanceAfter.sub(balanceBefore); //check for taxes

        //handle shares & user
        UserInfo storage user = userMap[_user];
        uint256 depositShares = userDeposit;
        if (totalShares != 0)
        {          
            depositShares = userDeposit.mul(totalShares).div(balanceBefore);
        }
        totalShares = totalShares.add(depositShares);
        user.shares = user.shares.add(depositShares);

        //block lock
        require(user.lastDepositOrWithdrawBlock != block.number, "Block lock");
        user.lastDepositOrWithdrawBlock = block.number;

        //event
        emit Deposit(_user, _amount, userDeposit, userBalanceBefore, balanceOf(_user), balance());
    }

    //========================
    // WITHDRAW FUNCTIONS
    //========================

    function withdrawAll(address _user) override external
    {
        withdraw(_user, type(uint256).max);
    }

    function withdraw(address _user, uint256 _amount) public virtual override nonReentrant
    {
        //check
        requireOwner();
        require(_amount > 0, "Nothing to withdraw");
        require(!strategy.pauseWithdraw(), "Withdraw paused!");

        //check for auto compound
        if (strategy.autoCompoundBeforeWithdraw()
            && balance() > 0)
        {
            compoundStrategy(_user, false);
        }

        //before withdraw
        strategy.beforeWithdraw();

        //check shares        
        UserInfo storage user = userMap[_user];
        uint256 userBalanceBefore = balanceOf(_user);       
        uint256 withdrawShares = user.shares; 
        if (_amount > userBalanceBefore) 
        {            
            //user wants to withdraw more than his balance, so adjust withdraw amount
            _amount = userBalanceBefore;
        }
        else
        {
            //user wants to withdraw a part of his balance, so calculate share
            withdrawShares = totalShares.mul(_amount).div(balance());
        }
        require(withdrawShares > 0, "Nothing to withdraw");

        //handle shares
        user.shares = user.shares.sub(withdrawShares);
        totalShares = totalShares.sub(withdrawShares);

        //block lock
        require(user.lastDepositOrWithdrawBlock != block.number, "Block lock");
        user.lastDepositOrWithdrawBlock = block.number;

        //withdraw from stategy
        withdrawFromStrategy(_user, _amount, userBalanceBefore);
    }

    function withdrawFromStrategy(address _user, uint256 _amount, uint256 _userBalanceBefore) internal virtual
    {
        //withdraw (first from vault, then from strategy)
        uint256 withdrawAmount = _amount;
        uint256 realWithdrawnAmount = 0;                
        uint256 balanceVaultBefore = balanceOfVault();

        //withdraw from vault
        if (balanceVaultBefore > 0)
        {            
            uint256 withdrawFromVault = withdrawAmount;
            if (withdrawFromVault > balanceVaultBefore)
            {
                withdrawFromVault = balanceVaultBefore;
            }
            depositToken().safeTransfer(_user, withdrawFromVault);
            uint256 balanceVaultAfter = balanceOfVault();
            withdrawAmount = withdrawAmount.sub(withdrawFromVault);
            realWithdrawnAmount = balanceVaultAfter.sub(balanceVaultBefore);            
        }

        //withdraw remaining amount from strategy
        if (withdrawAmount > 0)
        {            
            uint256 balanceUserWalletBefore = depositToken().balanceOf(_user);
            strategy.withdraw(_user, withdrawAmount);
            uint256 balanceUserWalletAfter = depositToken().balanceOf(_user);
            realWithdrawnAmount = realWithdrawnAmount.add(balanceUserWalletAfter.sub(balanceUserWalletBefore));  
        }

        //event
        emit Withdraw(_user, _amount, realWithdrawnAmount, _userBalanceBefore, balanceOf(_user), balance());
    }

    //========================
    // COMPOUND FUNCTIONS
    //========================

    function compound(address _user) public override nonReentrant
    {
        //check
        requireOwner();

        //compound
        compoundStrategy(_user, true);
    }

    //========================
    // MISC FUNCTIONS
    //========================

    function compoundStrategy(address _user, bool _revertOnFail) internal virtual
    {
        //compound
        uint256 totalDepositBefore = balance();
        (bool compounded, uint256 rewardAmount, uint256 dustAmount) = strategy.compound(_user, _revertOnFail);

        if (compounded)
        {
            lastCompound = block.timestamp;

            //event
            emit Compound(_user, totalDepositBefore, balance(), rewardAmount, dustAmount);
        }
    }

    function farm(address _from, uint256 _amount) internal
    {
        if (address(strategy) == address(0))
        {
            //no strategy, so only into vault
            depositToken().safeTransferFrom(_from, address(this), _amount);
            return;
        }
        
        if (_amount > 0)
        {
            //from user to strategy (this way transaction tax is reduced)
            depositToken().safeTransferFrom(_from, address(strategy), _amount); 
        }
        if (balanceOfVault() > 0)
        {
            //from vault to strategy (if there is any)
            depositToken().safeTransfer(address(strategy), balanceOfVault());
        }
        strategy.deposit();
    }

    //========================
    // STRATEGY UPGRADE FUNCTIONS
    //========================

    function proposeStrategy(IVaultStrategy _implementation) external
    {
        //check                
        if (address(strategy) != address(0))
        {            
            requireAdmin();
            require(strategy.depositToken() == _implementation.depositToken(), "Proposal has different deposit token");
        }
        else
        {
            //deployers can set inital proposal
            requireDeployer();            
        }
        require(address(this) == address(_implementation.vault()), "Proposal not valid for this Vault");

        //check for initial proposal
        if (address(strategy) == address(0))
        {
            strategy = _implementation;
            emit UpgradeStrategy(strategy);
            return;
        }
        
        //propose
        strategyCandidate = StrategyCandidate(
        {
            implementation: _implementation,
            proposedTime: block.timestamp
        });
        emit NewStrategyCandidate(_implementation);
    }

    function upgradeStrat() external
    {
        //check
        requireAdmin();
        require(address(strategyCandidate.implementation) != address(0), "There is no candidate");
        require(strategyCandidate.proposedTime.add(STRATEGY_APPROVAL_DELAY) < block.timestamp, "Delay has not passed");

        //upgrade
        strategy.retireStrategy();
        strategy = strategyCandidate.implementation;
        strategyCandidate.implementation = IVaultStrategy(address(0));
        strategyCandidate.proposedTime = 5000000000;
        emit UpgradeStrategy(strategy);

        //farm
        farm(address(this), 0);
    }

    //========================
    // EMERGENCY FUNCTIONS
    //========================

    function inCaseTokensGetStuck(IToken _token) external
    {
        //check
        requireSecurityAdmin();
        require(_token != depositToken(), "Access to deposit is forbidden!");

        //send
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    function pause(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseCompound) external
    {
        //check
        requireSecurityMod();

        //pause
        strategy.pause(_pauseDeposit, _pauseWithdraw, _pauseCompound);
        emit Pause(msg.sender, _pauseDeposit, _pauseWithdraw, _pauseCompound);
    }

    function unpause(bool _unpauseDeposit, bool _unpauseWithdraw, bool _unpauseCompound) external
    {
        //check
        requireSecurityAdmin();

        //unpause
        strategy.unpause(_unpauseDeposit, _unpauseWithdraw, _unpauseCompound);
        emit Unpause(msg.sender, _unpauseDeposit, _unpauseWithdraw, _unpauseCompound);
    }    

    function panic() external
    {
        //check
        requireAdmin();
        
        //panic
        strategy.panic();
    } 
}