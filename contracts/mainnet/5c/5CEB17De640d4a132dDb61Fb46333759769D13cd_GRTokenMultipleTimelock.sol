/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/IAdminController.sol

pragma solidity 0.6.12;

/**
 * @dev Interface of AdminContoller Contract
 *
 * AdminController must be implement isAdmin() function to return the caller is admin ot not as boolean value.
 * If the caller is the admin, then return true. If not, return false.
 */
interface IAdminController {

    /**
     * @dev Return the caller is admin ot not as boolean value.
     * Second argument is expected to be used for future extension.
     */
    function isAdmin(address caller, bytes memory data) external view returns (bool);
}

// File: contracts/GRTokenMultipleTimelock.sol

pragma solidity 0.6.12;





contract GRTokenMultipleTimelock {
    using SafeERC20 for IERC20;

    event Created (
        uint256 indexed id,
        address beneficiary,
        uint256 amount, 
        uint256 releaseTime
    );

    event Released (
        uint256 indexed id,
        address beneficiary,
        uint256 amount
    );

    event Deleted (
        uint256 indexed id
    );

    event Updated (
        uint256 indexed id,
        address beneficiary,
        uint256 amount, 
        uint256 releaseTime
    );

    // Lock elements
    struct Lock {
        address beneficiary;
        bool isReleased;
        uint256 amount;
        uint256 releaseTime;
    }

    // Locks (id => Lock)
    mapping (uint256 => Lock) private _locks; 

    // GR token
    IERC20 private _grToken;

    // Admin Controller
    IAdminController private _adminController;

    /**
     * @dev Check permission of administrator. Implementation is within the AdminController contract.
     * Data will be used for future extension.
     */
    modifier onlyAdmin(bytes memory data) {
        require(_adminController.isAdmin(msg.sender, data), "Caller is not the Admin");
        _;
    }


    /**
     * @dev Constuctor
     * 
     * Arguments:
     *  - grToken_: Contract address of GR token
     *  - adminController_: Contract address of AdminController
     */    
    constructor(IERC20 grToken_, IAdminController adminController_) public {
        _grToken = grToken_;
        _adminController = adminController_;
    }

    /**
     * @dev Change the Admin Controller Contract.
     * 
     * The target controller must implement IAdminController interface to check whether the caller is admin or not.
     */    
    function setAdminContoller(IAdminController adminController_, bytes memory data) public onlyAdmin(data) {
        _adminController = adminController_;
    }

    /**
     * @dev Create new lock.
     * 
     * Arguments
     *   - id: identifier of the lock. Any locks must have different id.
     *   - beneficiary: address where the token will be transfered when the lock is released.
     *   - amount: amount of the token to be transfered
     *   - releaseTime: Until this time, lock cannot be released. Specify in unixtime.
     */
    function lock(uint256 id, address beneficiary, uint256 amount, uint256 releaseTime, bytes memory data) public onlyAdmin(data) {
        // Argument validations
        _validateLockParameters(beneficiary, amount, releaseTime);
        require(!_isLockExists(id), "Token lock already exists");

        // Transfer the specified amount of token to this contract
        _grToken.safeTransferFrom(msg.sender, address(this), amount);

        // Save lock information
        // isReleased is set to false
        _locks[id] = Lock(beneficiary, false, amount, releaseTime);

        // Emit create event
        emit Created(id, beneficiary, amount, releaseTime);
    }

    /**
     * @dev Release the designated lock.
     * Once release succeed, locked amount is transfered to the recipient which specified in the lock.
     * Anyone can release any locks, but current timestamp must exceed the release time of the target lock
     */
    function release(uint256 id) public {
        // Argument validations
        require(_isLockExists(id), "Token lock does not exist");
        require(!_isReleased(id), "Specified lock has already been released");

        Lock storage currentLock = _locks[id];

        // Check whether current timestamp must exceed the release time of the target lock 
        require(block.timestamp >= currentLock.releaseTime, "current time is before release time");

        // Lock status update
        currentLock.isReleased = true;

        // Transfer token to the specified recipient
        _transferGrToken(currentLock.beneficiary, currentLock.amount);

        // Emit release event
        emit Released(id, currentLock.beneficiary, currentLock.amount);
    }

    /**
     * @dev Change the designated lock.
     * Compare between new amount and current amount, and then transfer the difference to the appropriate address.
     *
     * OnlyAdmin can execute the function
     */
    function change(uint256 id, address newBeneficiary, uint256 newAmount, uint256 newReleaseTime, bytes memory data) public onlyAdmin(data) {
        // Argument validations
        require(_isLockExists(id), "Token lock does not exist");
        require(!_isReleased(id), "Specified lock has already been released");
        _validateLockParameters(newBeneficiary, newAmount, newReleaseTime);

        Lock storage currentLock = _locks[id];

        // Compare between new amount and current amount.
        if (newAmount > currentLock.amount) {
            // Additional token must be transfered to this contract because new amount is greater than current amount.
            _grToken.safeTransferFrom(msg.sender, address(this), newAmount - currentLock.amount);
        } else if (newAmount < currentLock.amount) {
            // Additional token must be transfered to the admin because new amount is less than current amount.
            _transferGrToken(msg.sender, currentLock.amount - newAmount);
        }

        // Save lock information
        _locks[id] = Lock(newBeneficiary, false, newAmount, newReleaseTime);

        // Emit update event
        emit Updated(id, newBeneficiary, newAmount, newReleaseTime);
    }

    /**
     * @dev Remove the designated lock.
     *
     * OnlyAdmin can execute the function
     */
    function remove(uint256 id, bytes memory data) public onlyAdmin(data) {
        // Argument validations
        require(_isLockExists(id), "Token lock does not exist");
        require(!_isReleased(id), "Specified lock has already been released");

        // Transfer removed amount to the msg.sender
        _transferGrToken(msg.sender, _locks[id].amount);

        // Delete lock object
        // After the deletion, _locks[id].beneficiary will be address(0).
        delete(_locks[id]);

        // Emit delete event
        emit Deleted(id);
    }

    /**
     * @dev View the designated Lock
     */
    function lockOf(uint256 id) public view returns (uint256, address, uint256, uint256, bool) {
        require(_isLockExists(id), "Token lock does not exist");
        return (
            id,
            _locks[id].beneficiary,
            _locks[id].amount,
            _locks[id].releaseTime,
            _locks[id].isReleased
        );
    }


    // =================================
    //       Private functions
    // =================================

    /**
     * @dev Transfer designated amount of GRtoken to designated recipient from this contract.
     * If this contract do not have sufficient balance to transfer, transaction will be reverted.
     */
    function _transferGrToken(address recipient, uint256 amount) private {
        _grToken.safeTransfer(recipient, amount);
    }

    /**
     * @dev Check whether the designated Lock exists or not.
     * If exists, return true.
     */
    function _isLockExists(uint256 id) private view returns (bool) {
        return _locks[id].beneficiary != address(0); 
    }

    /**
     * @dev Check whether the designated Lock is already released or not.
     * If already released, return true.
     */
    function _isReleased(uint256 id) private view returns (bool) {
        return _locks[id].isReleased;
    }

    /**
     * @dev Check whether this contract has sufficient token balance for token transfer
     */
    function _hasSufficientBalance(uint256 amount) private view returns (bool) {
        return _grToken.balanceOf(address(this)) >= amount;
    }

    /**
     * @dev Lock parameters validation
     */
    function _validateLockParameters(address beneficiary, uint256 amount, uint256 releaseTime) private view {
        require(beneficiary != address(0), "Could not specify Zero address as a beneficiary");
        require(amount != 0, "Could not specify 0 as a amount to be locked");
        require(releaseTime >= block.timestamp, "Could not specify 0 as release time");
    }
}