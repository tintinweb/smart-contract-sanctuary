/**
 *Submitted for verification at FtmScan.com on 2022-01-22
*/

// File: ..\Contracts\libraries\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// File: ..\Contracts\libraries\Address.sol


pragma solidity 0.6.12;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: ..\Contracts\interfaces\IERC20.sol


pragma solidity 0.6.12;

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

// File: ..\Contracts\libraries\SafeERC20.sol


pragma solidity 0.6.12;



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

// File: ..\Contracts\Timelock.sol


pragma solidity 0.6.12;



contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 24 hours;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;
    bool public admin_initialized;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(address admin_, uint delay_) public {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
        admin_initialized = false;
    }

    receive() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (admin_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin_initialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint _value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, _value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value:_value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, _value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

// File: ..\Contracts\Adapter.sol


pragma solidity 0.6.12;


contract Target{}

library Adapter {
    // Pool info
    function lockableToken(Target target, uint256 poolId) external view returns (IERC20) {
        (bool success, bytes memory result) = address(target).staticcall(abi.encodeWithSignature("lockableToken(uint256)", poolId));
        require(success, "lockableToken(uint256 poolId) staticcall failed.");
        return abi.decode(result, (IERC20));
    }

    function lockedAmount(Target target, uint256 poolId) external view returns (uint256) {
        // note the impersonation
        (bool success, bytes memory result) = address(target).staticcall(abi.encodeWithSignature("lockedAmount(address,uint256)", address(this), poolId));
        require(success, "lockedAmount(uint256 poolId) staticcall failed.");
        return abi.decode(result, (uint256));
    }

    // Pool actions
    function deposit(Target target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("deposit(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "deposit(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function withdraw(Target target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("withdraw(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "withdraw(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function claimReward(Target target, uint256 poolId) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("claimReward(address,uint256)", address(target), poolId));
        require(success, "claimReward(uint256 poolId) delegatecall failed.");
    }

    function poolUpdate(Target target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("poolUpdate(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "poolUpdate(uint256 poolId, uint256 amount) delegatecall failed.");
    }

}

// File: ..\Contracts\IAdapter.sol


pragma solidity >= 0.6.12;


interface IAdapter {
    // Victim info
    function rewardTokenCount() external view returns (uint256);
    function rewardToken(uint256 id) external view returns (IERC20);
    function defaultToken() external view returns (IERC20);
    function poolCount() external view returns (uint256);

    function zapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _zapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function unzapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _unzapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function zapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _zapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function unzapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _unzapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);

    // Pool info
    function lockableToken(uint256 poolId) external view returns (IERC20);
    function lockedAmount(address user, uint256 poolId) external view returns (uint256);

    // Service methods
    function poolAddress(uint256 poolId) external view returns (address);
    function earnedReward(address _adapter, uint256 poolId, address user, uint256 tokenId) external view returns (uint256);
    
}

// File: ..\Contracts\libraries\ReentrancyGuard.sol


pragma solidity 0.6.12;

contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: ..\Contracts\libraries\Ownable.sol


pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () internal {
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

// File: ..\Contracts\MasterMind.sol


pragma solidity 0.6.12;






interface IRewarder {
    function onReward(uint256 pid, address user, uint256 SushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 SushiAmount) external view returns (IERC20[] memory, uint256[] memory);
    function claim(uint256 _pid, address _user, uint256 _averageDeposit, address to) external returns(uint256);
}

contract MasterMind is Ownable, Timelock, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Adapter for Target;

    struct UserInfo {
        uint256 shares;
        uint256 averageBlockDeposit;
        uint256 lastDeposit;
    }

    uint256 constant BASE = 10000;
    uint256 public coolDown = 260000;
    uint256 public withdrawalFee = 50;
    struct PoolInfo {
        Target target;
        address adapter;
        uint256 targetPoolId;
        uint256 drainModifier;
        uint256 totalShares;
        uint256 totalDeposits;
        uint256 entranceFee;
    }

    address public drainAddress; 
    address public custodianAddress;
    address public serviceAddress;
    bool public drainProtection;
    IRewarder public rewarder;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ZapAndDeposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed token, uint256 lpTokens);
    event ZapAndDepositRouted(address indexed user, uint256 indexed pid, uint256 amount, address indexed token, uint256 lpTokens);
    event WithdrawAndUnzap(address indexed user, uint256 indexed pid, uint256 amount, address indexed token, uint256 lpTokens);
    event WithdrawAndUnzapRouted(address indexed user, uint256 indexed pid, uint256 amount, address indexed token, uint256 lpTokens);
    event Drain(uint256 indexed _pid, uint256 lpTokens);
    event Add(uint256 indexed _pid);
    event AddBulk(uint256 indexed start, uint256 indexed finish);
    event UpdateTargetInfo(uint256 indexed _pid);
    event UpdateAdapter(uint256 indexed _pid);

    modifier onlyService() {    //no Timelock
        require(serviceAddress == _msgSender() || owner() == _msgSender(), "not service");
        _;
    }

    constructor(
        address _drainAddress
    ) public Timelock(msg.sender, 24 hours) {
        drainAddress = _drainAddress;
        custodianAddress = msg.sender;
    }

    function userDeposits(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        Target target = pool.target;
        uint256 totalDeposits = target.lockedAmount(pool.targetPoolId);
        if (pool.totalShares != 0) {
            return (user.shares.mul(totalDeposits)).div(pool.totalShares);
        }
        return 0; 
    }

    function userShares(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.shares; 
    }

    function claim(uint256 _pid, address _to) external  {
        UserInfo storage user = userInfo[_pid][msg.sender];
        rewarder.onReward(_pid, msg.sender,  user.averageBlockDeposit, user.shares);
        rewarder.claim(_pid, msg.sender, user.averageBlockDeposit, _to);
    }

    function earnedRewards(uint256 _pid, address _user) external view returns (address[] memory, uint256[] memory) {
        PoolInfo storage pool = poolInfo[_pid];
        IAdapter target = IAdapter(address(pool.adapter));
        uint256[] memory amounts = new uint256[](target.rewardTokenCount());
        address[] memory tokens = new address[](target.rewardTokenCount());
        for (uint i = 0; i < target.rewardTokenCount(); i++) {
            amounts[i] = target.earnedReward(address(pool.adapter), pool.targetPoolId, _user, i);
            tokens[i] = address(target.rewardToken(i));
        }
        return (tokens, amounts); 
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addBulk(Target _target, address _adapter, uint256[] memory targetPids, uint256[] memory drainModifiers, uint256[] memory entranceFees) external onlyOwner {
        for (uint i = 0; i < targetPids.length; i++) {
            poolInfo.push(PoolInfo({
                target: _target,
                adapter: _adapter,
                targetPoolId: targetPids[i],
                drainModifier: drainModifiers[i],
                totalShares: 0,
                totalDeposits: 0,
                entranceFee: entranceFees[i]
            }));
        }
        emit AddBulk(poolInfo.length.sub(targetPids.length), poolInfo.length.sub(1));
    }


    function updateService(address _serviceAddress) external onlyService {
        serviceAddress = _serviceAddress;
    }

    function updateProtection(bool _drainProtection) external onlyService {
        drainProtection = _drainProtection;
    }

    function updateRewarder(address _rewarder) external onlyOwner {
        rewarder = IRewarder(_rewarder);
    }

    function poolUpdate(uint256 _pid, uint256 _amount) external onlyService {   
        PoolInfo storage pool = poolInfo[_pid];
        Target target = pool.target;
        target.poolUpdate(_pid, _amount);
    }

    function updateTargetInfo(uint256 _pid, address _target, address _adapter, uint256 _targetPoolId, bool restake) public onlyOwner {
        Target poolAdapter = Target(_target);
        if (restake) {
            PoolInfo storage pool = poolInfo[_pid];
            pool.target.withdraw(pool.targetPoolId, pool.totalDeposits);
            poolAdapter.deposit(_targetPoolId, poolAdapter.lockableToken(_targetPoolId).balanceOf(address(this)));
            Target target = pool.target;
            pool.totalDeposits = target.lockedAmount(pool.targetPoolId);
        }
        poolInfo[_pid].targetPoolId = _targetPoolId;
        poolInfo[_pid].target = poolAdapter;
        poolInfo[_pid].adapter = _adapter;
        emit UpdateTargetInfo(_pid);
    }

    function massUpdateTarget(uint256[] memory _pids, address[] memory _targets, address[] memory _adapters, uint256[] memory _targetPoolIds, bool[] memory restake) external onlyOwner {
        for (uint i = 0; i < _pids.length; i++) {
            updateTargetInfo(_pids[i], _targets[i], _adapters[i], _targetPoolIds[i], restake[i]);
        }
    }
    function massUpdateAdapter(uint256[] memory _pids, address _adapter) public onlyService {
        for (uint i = 0; i < _pids.length; i++) {
            poolInfo[_pids[i]].adapter = _adapter;
            emit UpdateAdapter(_pids[i]);
        }
    }

    function updatePoolModifiers(uint256 _pid, uint256 _drainModifier, uint256 _entranceFee) external onlyService {
        poolInfo[_pid].drainModifier = _drainModifier;
        poolInfo[_pid].entranceFee = _entranceFee;
    }

    function updateDrainAddress(address _drainAddress) external onlyOwner {
        drainAddress = _drainAddress;
    }

    function updateWithdrawalConst(uint256 _Cooldown,  uint256 _withdrawalFee) external onlyOwner {
        coolDown = _Cooldown;
        withdrawalFee = _withdrawalFee;
    }

    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, "amount must be greater than zero");
        PoolInfo storage pool = poolInfo[_pid];
        pool.target.lockableToken(pool.targetPoolId).safeTransferFrom(address(msg.sender), address(this), _amount);
        _deposit(_pid, _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function _deposit(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Target target = pool.target;
        if (pool.entranceFee>0){
            uint256 feeAmount = _amount.mul(pool.entranceFee).div(BASE);
            pool.target.lockableToken(pool.targetPoolId).safeTransfer(drainAddress, feeAmount);
            _amount = _amount.sub(feeAmount);
        }
        uint256 depositsBefore = target.lockedAmount(pool.targetPoolId);
        uint256 oldShares = user.shares;
        pool.target.deposit(pool.targetPoolId, _amount);
        uint256 depositsAfter = target.lockedAmount(pool.targetPoolId);
        uint256 newshares = depositsAfter;
        if (pool.totalShares != 0) {
            uint256 change = depositsAfter.sub(depositsBefore);
            newshares = (change.mul(pool.totalShares)).div(depositsBefore);
        }
        user.shares = user.shares.add(newshares);
        pool.totalShares = pool.totalShares.add(newshares);
        pool.totalDeposits = depositsAfter;
        if (address(rewarder) != address(0)) {
            rewarder.claim(_pid, msg.sender, user.averageBlockDeposit, msg.sender);
        }
        user.averageBlockDeposit = ((user.averageBlockDeposit.mul(oldShares)).add(block.number.mul(newshares))).div(user.shares);
        user.lastDeposit = block.number;
    }

    function zapAndDeposit(address token, uint256 _pid, uint256 _amount, uint256 min_out) external nonReentrant { //hardcoded routes
        _zapAndDeposit(token, _pid, _amount, min_out, msg.sender);
    }

    function _zapAndDeposit(address token, uint256 _pid, uint256 _amount, uint256 min_out, address _user) internal { //hardcoded routes
        PoolInfo storage pool = poolInfo[_pid];
        IERC20(token).safeTransferFrom(address(msg.sender), address(pool.adapter), _amount);
        uint256 lpTokens = IAdapter(address(pool.adapter))._zapAny(token, pool.targetPoolId, _amount, min_out, address(this));
        require(lpTokens >= min_out, "amount must be greater than minimum");
        _deposit(_pid, lpTokens);
        emit ZapAndDeposit(_user, _pid, _amount, token, lpTokens);
    }

    function zapAndDepositRouted(address token, bytes calldata call, uint256 _pid, uint256 _amount, uint256 min_out) external nonReentrant {
        _zapAndDepositRouted(token, call, _pid, _amount, min_out, msg.sender);
    }

    function _zapAndDepositRouted(address token, bytes calldata call, uint256 _pid, uint256 _amount, uint256 min_out, address _user) internal {
        PoolInfo storage pool = poolInfo[_pid];
        IERC20(token).safeTransferFrom(address(msg.sender), address(pool.adapter), _amount);
        uint256 lpTokens = IAdapter(address(pool.adapter))._zapAnyRouted(token, call, pool.targetPoolId, _amount, min_out, address(this));
        require(lpTokens >= min_out, "amount must be greater than minimum");
        _deposit(_pid, lpTokens);
        emit ZapAndDepositRouted(_user, _pid, _amount, token, lpTokens);
    }

    function withdrawAndUnzapRouted(address token, bytes calldata call, uint256 _pid, uint256 _amount, uint256 min_out) external nonReentrant {  
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Target target = pool.target;
        uint256 depositsBefore = target.lockedAmount(pool.targetPoolId);
        pool.target.withdraw(pool.targetPoolId, _amount);
        uint256 depositsAfter = target.lockedAmount(pool.targetPoolId);
        uint256 sharesToBurn = ((depositsBefore.sub(depositsAfter)).mul(pool.totalShares)).div(depositsBefore);
        require(user.shares >= sharesToBurn,  "withdraw: not good");
        user.shares = user.shares.sub(sharesToBurn); 
        pool.totalShares = pool.totalShares.sub(sharesToBurn);
        pool.totalDeposits = depositsAfter;
        if (block.number - user.lastDeposit < coolDown) {
            uint256 fee = _amount.mul(withdrawalFee).div(BASE);
            pool.target.lockableToken(pool.targetPoolId).safeTransfer(drainAddress, fee);
            _amount = _amount.sub(fee);
        }
        pool.target.lockableToken(pool.targetPoolId).safeTransfer(address(pool.adapter), _amount);
        uint256 lpTokens = IAdapter(address(pool.adapter))._unzapAnyRouted(token, call, _pid, _amount, min_out, msg.sender);
        if (address(rewarder) != address(0)) {
            rewarder.onReward(_pid, msg.sender, user.averageBlockDeposit, user.shares);
        }
        user.averageBlockDeposit = block.number;
        require(lpTokens >= min_out, "amount must be greater than minimum");
        emit WithdrawAndUnzapRouted(msg.sender, _pid, _amount, token, lpTokens);
        }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, "amount must be greater than zero");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        Target target = pool.target;
        uint256 depositsBefore = target.lockedAmount(pool.targetPoolId);
        pool.target.withdraw(pool.targetPoolId, _amount);
        uint256 depositsAfter = target.lockedAmount(pool.targetPoolId);
        uint256 sharesToBurn = ((depositsBefore.sub(depositsAfter)).mul(pool.totalShares)).div(depositsBefore);
        require(user.shares >= sharesToBurn,  "withdraw: not good");
        user.shares = user.shares.sub(sharesToBurn); 
        pool.totalShares = pool.totalShares.sub(sharesToBurn);
        pool.totalDeposits = depositsAfter;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(_pid, msg.sender, user.averageBlockDeposit, user.shares);
        }
        if (block.number - user.lastDeposit < coolDown) {
            uint256 fee = _amount.mul(withdrawalFee).div(BASE);
            pool.target.lockableToken(pool.targetPoolId).safeTransfer(drainAddress, fee);
            _amount = _amount.sub(fee);
        }
        pool.target.lockableToken(pool.targetPoolId).safeTransfer(address(msg.sender), _amount);
        user.averageBlockDeposit = block.number;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function drain(uint256 _pid, uint256[] memory amounts) external {
        if (drainProtection){
            require(serviceAddress == msg.sender || custodianAddress == msg.sender || drainAddress == msg.sender, "not updater");
        }
        PoolInfo storage pool = poolInfo[_pid];
        Target target = pool.target;
        uint256 targetPoolId = pool.targetPoolId;
        target.claimReward(targetPoolId);
        for (uint i = 0; i < IAdapter(address(pool.adapter)).rewardTokenCount(); i++) {
            IERC20 rewardToken =  IAdapter(address(pool.adapter)).rewardToken(i);
            uint256 claimedReward = rewardToken.balanceOf(address(this));
            require(amounts[i] <= claimedReward, "Not enough rewards");
            if (claimedReward != 0 && amounts[i] != 0) {
                claimedReward = amounts[i];
                uint256 feeAmount = claimedReward.mul(pool.drainModifier).div(BASE);
                claimedReward = claimedReward.sub(feeAmount);
                rewardToken.safeTransfer(drainAddress, feeAmount);
                rewardToken.safeTransfer(address(pool.adapter), claimedReward);
                uint256 lpTokens = IAdapter(address(pool.adapter))._zapAny(address(rewardToken), pool.targetPoolId, claimedReward, 0, address(this));
                pool.target.deposit(pool.targetPoolId, lpTokens);
                pool.totalDeposits = target.lockedAmount(pool.targetPoolId);
                emit Drain(_pid, lpTokens);
            }
        }
    }
}