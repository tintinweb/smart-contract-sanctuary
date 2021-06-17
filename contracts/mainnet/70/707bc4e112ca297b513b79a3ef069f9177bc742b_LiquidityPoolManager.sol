/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

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

pragma solidity 0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}

pragma solidity 0.7.6;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}


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

pragma solidity 0.7.6;

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
contract ReentrancyGuard {
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


pragma solidity >=0.6.0 <0.8.0;

// import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    event PauserChanged(
        address indexed previousPauser,
        address indexed newPauser
    );

    bool private _paused;
    address private _pauser;

    /**
     * @dev The pausable constructor sets the original `pauser` of the contract to the sender
     * account & Initializes the contract in unpaused state..
     */
    constructor(address pauser) public {
        _pauser = pauser;
        _paused = false;
    }

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        require(
            isPauser(),
            "Only pauser is allowed to perform this operation"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @return the address of the owner.
     */
    function pauser() public view returns (address) {
        return _pauser;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isPauser() public view returns (bool) {
        return msg.sender == _pauser;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Allows the current pauser to transfer control of the contract to a newPauser.
     * @param newPauser The address to transfer pauserShip to.
     */
    function changePauser(address newPauser) public onlyPauser {
        _changePauser(newPauser);
    }

    /**
     * @dev Transfers control of the contract to a newPauser.
     * @param newPauser The address to transfer ownership to.
     */
    function _changePauser(address newPauser) internal {
        require(newPauser != address(0));
        emit PauserChanged(_pauser, newPauser);
        _pauser = newPauser;
    }

    function renouncePauser() public onlyPauser {
        emit PauserChanged(_pauser, address(0));
        _pauser = address(0);
    }
    
    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_pauser);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_pauser);
    }
}


pragma solidity 0.7.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address owner) public {
        _owner = owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            isOwner(),
            "Only contract owner is allowed to perform this operation"
        );
        _;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity 0.7.6;

contract ExecutorManager is Ownable {
    address[] internal executors;
    mapping(address => bool) internal executorStatus;

    event ExecutorAdded(address executor, address owner);
    event ExecutorRemoved(address executor, address owner);

    // MODIFIERS
    modifier onlyExecutor() {
        require(
            executorStatus[msg.sender],
            "You are not allowed to perform this operation"
        );
        _;
    }

    constructor(address owner) public Ownable(owner) {
        require( owner != address(0), "owner cannot be zero");
    }

    function getExecutorStatus(address executor)
        public
        view
        returns (bool status)
    {
        status = executorStatus[executor];
    }

    function getAllExecutors() public view returns (address[] memory) {
        return executors;
    }

    //Register new Executors
    function addExecutors(address[] calldata executorArray) external onlyOwner {
        for (uint256 i = 0; i < executorArray.length; i++) {
            addExecutor(executorArray[i]);
        }
    }

    // Register single executor
    function addExecutor(address executorAddress) public onlyOwner {
        require(executorAddress != address(0), "executor address can not be 0");
        executors.push(executorAddress);
        executorStatus[executorAddress] = true;
        emit ExecutorAdded(executorAddress, msg.sender);
    }

    //Remove registered Executors
    function removeExecutors(address[] calldata executorArray) external onlyOwner {
        for (uint256 i = 0; i < executorArray.length; i++) {
            removeExecutor(executorArray[i]);
        }
    }

    // Remove Register single executor
    function removeExecutor(address executorAddress) public onlyOwner {
        require(executorAddress != address(0), "executor address can not be 0");
        executorStatus[executorAddress] = false;
        emit ExecutorRemoved(executorAddress, msg.sender);
    }
}


pragma solidity 0.7.6;







contract LiquidityPoolManager is ReentrancyGuard, Ownable, BaseRelayRecipient, Pausable {
    using SafeMath for uint256;

    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public baseGas;
    
    ExecutorManager private executorManager;
    uint256 public adminFee;

    struct TokenInfo {
        uint256 transferOverhead;
        bool supportedToken;
        uint256 minCap;
        uint256 maxCap;
        uint256 liquidity;
        mapping(address => uint256) liquidityProvider;
    }

    mapping(address => TokenInfo) public tokensInfo;
    mapping ( bytes32 => bool ) public processedHash;

    event AssetSent(address indexed asset, uint256 indexed amount, address indexed target);
    event Received(address indexed from, uint256 indexed amount);
    event Deposit(address indexed from, address indexed tokenAddress, address indexed receiver, uint256 toChainId, uint256 amount);
    event LiquidityAdded(address indexed from, address indexed tokenAddress, address indexed receiver, uint256 amount);
    event LiquidityRemoved(address indexed tokenAddress, uint256 indexed amount, address indexed sender);
    event fundsWithdraw(address indexed tokenAddress, address indexed owner,  uint256 indexed amount);
    
    // MODIFIERS
    modifier onlyExecutor() {
        require(executorManager.getExecutorStatus(_msgSender()),
            "You are not allowed to perform this operation"
        );
        _;
    }

    modifier tokenChecks(address tokenAddress){
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(tokensInfo[tokenAddress].supportedToken, "Token not supported");

        _;
    }

    constructor(address _executorManagerAddress, address owner, address pauser, address _trustedForwarder, uint256 _adminFee) public Ownable(owner) Pausable(pauser) {
        require(_executorManagerAddress != address(0), "ExecutorManager Contract Address cannot be 0");
        require(owner != address(0), "Owner Address cannot be 0");
        require(_trustedForwarder != address(0), "TrustedForwarder Contract Address cannot be 0");
        require(_adminFee != 0, "AdminFee cannot be 0");
        executorManager = ExecutorManager(_executorManagerAddress);
        trustedForwarder = _trustedForwarder;
        adminFee = _adminFee;
        baseGas = 21000;
    }

    function getAdminFee() public view returns (uint256 ) {
        return adminFee;
    }

    function changeAdminFee(uint256 newAdminFee) public onlyOwner whenNotPaused {
        require(newAdminFee != 0, "Admin Fee cannot be 0");
        adminFee = newAdminFee;
    }

    function versionRecipient() external override virtual view returns (string memory){
        return "1";
    }

    function setBaseGas(uint128 gas) external onlyOwner{
        baseGas = gas;
    }

    function getExecutorManager() public view returns (address){
        return address(executorManager);
    }

    function setExecutorManager(address _executorManagerAddress) public onlyOwner {
        require(_executorManagerAddress != address(0), "Executor Manager Address cannot be 0");
        executorManager = ExecutorManager(_executorManagerAddress);
    }

    function setTrustedForwarder( address forwarderAddress ) public onlyOwner {
        require(forwarderAddress != address(0), "Forwarder Address cannot be 0");
        trustedForwarder = forwarderAddress;
    }

    function setTokenTransferOverhead( address tokenAddress, uint256 gasOverhead ) public tokenChecks(tokenAddress) onlyOwner {
        tokensInfo[tokenAddress].transferOverhead = gasOverhead;
    }

    function addSupportedToken( address tokenAddress, uint256 minCapLimit, uint256 maxCapLimit ) public onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be 0");  
        require(maxCapLimit > minCapLimit, "maxCapLimit cannot be smaller than minCapLimit");        
        tokensInfo[tokenAddress].supportedToken = true;
        tokensInfo[tokenAddress].minCap = minCapLimit;
        tokensInfo[tokenAddress].maxCap = maxCapLimit;
    }

    function removeSupportedToken( address tokenAddress ) public tokenChecks(tokenAddress) onlyOwner {
        tokensInfo[tokenAddress].supportedToken = false;
    }

    function updateTokenCap( address tokenAddress, uint256 minCapLimit, uint256 maxCapLimit ) public tokenChecks(tokenAddress) onlyOwner {
        require(maxCapLimit > minCapLimit, "maxCapLimit cannot be smaller than minCapLimit");                
        tokensInfo[tokenAddress].minCap = minCapLimit;        
        tokensInfo[tokenAddress].maxCap = maxCapLimit;
    }

    function addNativeLiquidity() public payable whenNotPaused {
        require(msg.value > 0, "amount should be greater then 0");
        address payable sender = _msgSender();
        tokensInfo[NATIVE].liquidityProvider[sender] = tokensInfo[NATIVE].liquidityProvider[sender].add(msg.value);
        tokensInfo[NATIVE].liquidity = tokensInfo[NATIVE].liquidity.add(msg.value);

        emit LiquidityAdded(sender, NATIVE, address(this), msg.value);
    }

    function removeNativeLiquidity(uint256 amount) public whenNotPaused nonReentrant {
        require(amount != 0 , "Amount cannot be 0");
        address payable sender = _msgSender();
        require(tokensInfo[NATIVE].liquidityProvider[sender] >= amount, "Not enough balance");
        tokensInfo[NATIVE].liquidityProvider[sender] = tokensInfo[NATIVE].liquidityProvider[sender].sub(amount);
        tokensInfo[NATIVE].liquidity = tokensInfo[NATIVE].liquidity.sub(amount);
        
        (bool success, ) = sender.call{ value: amount }("");
        require(success, "Native Transfer Failed");

        emit LiquidityRemoved( NATIVE, amount, sender);
    }

    function addTokenLiquidity( address tokenAddress, uint256 amount ) public tokenChecks(tokenAddress) whenNotPaused {
        require(amount > 0, "amount should be greater then 0");
        address payable sender = _msgSender();
        tokensInfo[tokenAddress].liquidityProvider[sender] = tokensInfo[tokenAddress].liquidityProvider[sender].add(amount);
        tokensInfo[tokenAddress].liquidity = tokensInfo[tokenAddress].liquidity.add(amount);
        
        SafeERC20.safeTransferFrom(IERC20(tokenAddress), sender, address(this), amount);
        emit LiquidityAdded(sender, tokenAddress, address(this), amount);
    }

    function removeTokenLiquidity( address tokenAddress, uint256 amount ) public tokenChecks(tokenAddress) whenNotPaused {
        require(amount > 0, "amount should be greater then 0");
        address payable sender = _msgSender();
        require(tokensInfo[tokenAddress].liquidityProvider[sender] >= amount, "Not enough balance");

        tokensInfo[tokenAddress].liquidityProvider[sender] = tokensInfo[tokenAddress].liquidityProvider[sender].sub(amount);
        tokensInfo[tokenAddress].liquidity = tokensInfo[tokenAddress].liquidity.sub(amount);

        SafeERC20.safeTransfer(IERC20(tokenAddress), sender, amount);
        emit LiquidityRemoved( tokenAddress, amount, sender);

    }

    function getLiquidity(address liquidityProviderAddress, address tokenAddress) public view returns (uint256 ) {
        return tokensInfo[tokenAddress].liquidityProvider[liquidityProviderAddress];
    }

    function depositErc20( address tokenAddress, address receiver, uint256 amount, uint256 toChainId ) public tokenChecks(tokenAddress) whenNotPaused {
        require(tokensInfo[tokenAddress].minCap <= amount && tokensInfo[tokenAddress].maxCap >= amount, "Deposit amount should be within allowed Cap limits");
        require(receiver != address(0), "Receiver address cannot be 0");
        require(amount > 0, "amount should be greater then 0");

        address payable sender = _msgSender();

        SafeERC20.safeTransferFrom(IERC20(tokenAddress), sender, address(this),amount);
        emit Deposit(sender, tokenAddress, receiver, toChainId, amount);
    }

    function depositNative( address receiver, uint256 toChainId ) public whenNotPaused payable {
        require(tokensInfo[NATIVE].minCap <= msg.value && tokensInfo[NATIVE].maxCap >= msg.value, "Deposit amount should be within allowed Cap limit");
        require(receiver != address(0), "Receiver address cannot be 0");
        require(msg.value > 0, "amount should be greater then 0");

        emit Deposit(_msgSender(), NATIVE, receiver, toChainId, msg.value);
    }

    function sendFundsToUser( address tokenAddress, uint256 amount, address payable receiver, bytes memory depositHash, uint256 tokenGasPrice ) public nonReentrant onlyExecutor tokenChecks(tokenAddress) whenNotPaused {
        uint256 initialGas = gasleft();
        require(tokensInfo[tokenAddress].minCap <= amount && tokensInfo[tokenAddress].maxCap >= amount, "Withdraw amount should be within allowed Cap limits");
        require(receiver != address(0), "Bad receiver address");
        
        (bytes32 hashSendTransaction, bool status) = checkHashStatus(tokenAddress, amount, receiver, depositHash);

        require(!status, "Already Processed");
        processedHash[hashSendTransaction] = true;

        uint256 calculateAdminFee = amount.mul(adminFee).div(10000);
        uint256 totalGasUsed = (initialGas.sub(gasleft())).add(tokensInfo[tokenAddress].transferOverhead).add(baseGas);

        uint256 gasFeeInToken = totalGasUsed.mul(tokenGasPrice);
        uint256 amountToTransfer = amount.sub(calculateAdminFee.add(gasFeeInToken));

        if (tokenAddress == NATIVE) {
            require(address(this).balance >= amountToTransfer, "Not Enough Balance");
            (bool success, ) = receiver.call{ value: amount }("");
            require(success, "Native Transfer Failed");
        } else {
            require(IERC20(tokenAddress).balanceOf(address(this)) >= amountToTransfer, "Not Enough Balance");
            SafeERC20.safeTransfer(IERC20(tokenAddress), receiver, amountToTransfer);
        }

        emit AssetSent(tokenAddress, amountToTransfer, receiver);
    }

    function checkHashStatus(address tokenAddress, uint256 amount, address payable receiver, bytes memory depositHash) public view returns(bytes32 hashSendTransaction, bool status){
        hashSendTransaction = keccak256(
            abi.encode(
                tokenAddress,
                amount,
                receiver,
                keccak256(depositHash)
            )
        );

        status = processedHash[hashSendTransaction];
    }

    function withdrawErc20(address tokenAddress) public onlyOwner whenNotPaused {
        uint256 profitEarned = (IERC20(tokenAddress).balanceOf(address(this))).sub(tokensInfo[tokenAddress].liquidity);
        require(profitEarned > 0, "Profit earned is 0");
        address payable sender = _msgSender();

        SafeERC20.safeTransfer(IERC20(tokenAddress), sender, profitEarned);

        emit fundsWithdraw(tokenAddress, sender,  profitEarned);
    }

    function withdrawNative() public onlyOwner whenNotPaused {
        uint256 profitEarned = (address(this).balance).sub(tokensInfo[NATIVE].liquidity);
        require(profitEarned > 0, "Profit earned is 0");
        address payable sender = _msgSender();
        (bool success, ) = sender.call{ value: profitEarned }("");
        require(success, "Native Transfer Failed");
        
        emit fundsWithdraw(address(this), sender, profitEarned);
    }
}