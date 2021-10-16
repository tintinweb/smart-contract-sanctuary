/**
 *Submitted for verification at polygonscan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


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
    constructor() internal {
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
    function decentralizeXVMC() public virtual {
        require(block.timestamp > 1635678000, "31 October");
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

// File: @openzeppelin/contracts/math/SafeMath.sol


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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
    
    function burnFrom(address account, uint256 amount) external;
    function mint(address to, uint256 amount) external;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File: @openzeppelin/contracts/utils/Pausable.sol


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
    constructor() internal {
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

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingEgg(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}


interface IacPool {
    function hopDeposit(uint256 _amount, address _recipientAddress, uint256 previousLastDepositedTime) external;
    function getUserShares(address wallet) external view returns (uint256);
}

interface IGovernance {
    function rebalancePools() external;
}


/**
 * XVMC time-locked deposit
 * 6 Month Deposit
 * Auto-compounding pool
 */
contract XVMCtimeDeposit is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 cakeAtLastUserAction; // keeps track of XVMC deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
        uint256 delegatingSharesToProposalID; //the proposal ID the user is voting for
    }
    struct ProposalVotes {
        uint256 value; // number of shares the vote has received
    }

    IERC20 public immutable token; // XVMC token
    
    IERC20 public immutable dummyToken; // Dummy token that we keep 1:1 reserve to XVMC

    IMasterChef public immutable masterchef;

    uint256 public immutable poolID;   
    
    uint256 public immutable withdrawFeePeriod = 177 days; // roughly half year


    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => ProposalVotes) public totalVotesForID;
    
    address governanceContract; // our governing contract

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    address public admin;
    address public treasury;

    address public trustedSender1;
    address public trustedSender2;
    
    address public trustedPool4;
    address public trustedPool5;
    address public trustedPool6;

    //no performance fees
    uint256 public constant MAX_CALL_FEE = 100; // 1%

    uint256 public callFee = 25; // 0.25%
    uint256 public callFeeWithBonus = 50; // bonus for rebalancing pools in governance contract

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event GiftDeposit(address indexed sender, address indexed recipient, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 penalty, uint256 shares);
    event TransferStake(address indexed sender, address indexed recipient, uint256 shares);
    event HopPool(address indexed sender, uint256 XVMCamount, uint256 shares, address indexed newPool, address indexed recipient);
    event HopDeposit(address indexed recipient, uint256 amount, uint256 shares, uint256 previousLastDepositedTime);
    event Harvest(address indexed sender, uint256 callFee, bool withBonus);
    event RemoveVotes(address indexed voter, uint256 proposalID, uint256 change);
    event AddVotes(address indexed voter, uint256 proposalID, uint256 change);
    event Allowance(address trustedPool);
    event Pause();
    event Unpause();


    /**
     * @notice Constructor
     * @param _token: Cake token contract
     * @param _dummyToken: Syrup token contract
     * @param _masterchef: MasterChef contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _token,
        IERC20 _dummyToken,
        IMasterChef _masterchef,
        address _admin,
        address _treasury,
        uint256 _poolID
    ) public {
        token = _token;
        dummyToken = _dummyToken;
        masterchef = _masterchef;
        admin = _admin;
        treasury = _treasury;
        poolID = _poolID;

        // Infinite approve
        IERC20(_token).safeApprove(address(_masterchef), uint256(-1));
        IERC20(_dummyToken).safeApprove(address(_masterchef), uint256(-1));
        IERC20(_dummyToken).safeApprove(address(this), uint256(-1));
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }


    /**
     * @notice Checks if the msg.sender is the owner or admin
     */
    modifier adminOrOwner() {
        require(msg.sender == admin || msg.sender == owner(), "admin: wut?");
        _;
    }
    
    
    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }
    

    /**
     * @notice Checks if the msg.sender is a proxy
     */
    modifier notProxy() {
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Deposits funds into the XVMC time-locked vault
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in XVMC)
     */
    function deposit(uint256 _amount) external whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }
        UserInfo storage user = userInfo[msg.sender];

        user.shares = user.shares.add(currentShares);
        user.lastDepositedTime = block.timestamp;

        totalShares = totalShares.add(currentShares);

        user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        user.lastUserActionTime = block.timestamp;
        
        if(user.delegatingSharesToProposalID != 0) {
            _updateVotingAddDiff(msg.sender, user.delegatingSharesToProposalID, currentShares);
        }

        _earn(); 

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }
    
    
    /**
     * Equivalent to Deposit
     * Instead of crediting the msg.sender, it credits custom recipient
     * A mechanism to gift a time-locked stake to another wallet
     * The recipient must have no active stake
     */
    function giftDeposit(uint256 _amount, address _recipientAddress) external whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");
        
        UserInfo storage user = userInfo[_recipientAddress];
        require(user.shares == 0, "User already has an active stake");
        
        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }

        user.shares = currentShares;
        user.lastDepositedTime = block.timestamp;

        totalShares = totalShares.add(currentShares);

        user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit GiftDeposit(msg.sender, _recipientAddress, _amount, currentShares, block.timestamp);
    }
    
    
    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external notProxy {
        withdraw(userInfo[msg.sender].shares);
    }


    /**
     * @notice Backs dummyToken 1:1 to XVMC and re-deposits into masterchef
     * @dev Only possible when contract not paused.
     */
    function harvest() external notContract whenNotPaused {
        IMasterChef(masterchef).withdraw(poolID, 0); 

        uint256 bal = available(); 

        uint256 currentCallFee = bal.mul(callFee).div(10000);
        token.safeTransfer(msg.sender, currentCallFee);

        _earn();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentCallFee, false);
    }


    /**
     * Equivalent to harvest, but gives user the bonus
     * for paying transaction fees for rebalancing the pools
     */
    function harvestWithRebalance() external notContract whenNotPaused {
        IMasterChef(masterchef).withdraw(poolID, 0);

        uint256 bal = available(); 

        uint256 currentCallFee = bal.mul(callFeeWithBonus).div(10000);
        IGovernance(governanceContract).rebalancePools(); 

        token.safeTransfer(msg.sender, currentCallFee);

        _earn();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentCallFee, true);
    }
    
    
    /**
     * @notice Sets admin address
     * @dev Only callable by the contract admin or owner.
     */
    function setAdmin(address _admin) external adminOrOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }


    /**
     * @notice Sets treasury address and governance address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external adminOrOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        governanceContract = _treasury;
    }


    /**
     * @notice Sets call fee and call fee with bonus
     * @dev Only callable by the contract admin.
     */
    function setCallFee(uint256 _callFee, uint256 _callFeeWithBonus) external adminOrOwner {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        require(_callFeeWithBonus <= 2 * MAX_CALL_FEE);
        callFee = _callFee;
        callFeeWithBonus = _callFeeWithBonus;
    }


     /**
     * set trusted pools, the smart contracts that we can send the tokens to without penalty
     */
    function setTrustedPools(address _pool6, address _pool5, address _pool4) external adminOrOwner {
        trustedPool6 = _pool6;
        trustedPool5 = _pool5;
        trustedPool4 = _pool4;
        
        /**
         * approval is needed for hopping stakes between pools
         * dummies on Twitter will FUD and call it "an exploit"
         * Context matters: Only possible until 31 October
         * After ownership is renounced, "hole" will cease to exist
         * emits an event when allowance is granted for extra transparency
         */
        if(IERC20(token).allowance(address(this), _pool6) != uint256(-1)) {
            IERC20(token).safeApprove(_pool6, uint256(-1));
            
            emit Allowance(_pool6);
        }
        if(IERC20(token).allowance(address(this), _pool5) != uint256(-1)) {
            IERC20(token).safeApprove(_pool5, uint256(-1));
            
            emit Allowance(_pool5);
        }
        if(IERC20(token).allowance(address(this), _pool4) != uint256(-1)) {
            IERC20(token).safeApprove(_pool4, uint256(-1));
            
            emit Allowance(_pool4);
        }
    }


     /**
     * set trusted senders, other pools that we can receive from
     * that are guaranteed to be trusted (they rely lastDepositTime)
     */
    function setTrustedSenders(address _sender1, address _sender2) external adminOrOwner {
        trustedSender1 = _sender1;
        trustedSender2 = _sender2;
    }


    /**
     * @notice Withdraws from MasterChef to Vault without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract admin.
     */
    function emergencyWithdraw() external adminOrOwner {
        IMasterChef(masterchef).emergencyWithdraw(poolID);
    }

    /**
     * @notice Withdraw unexpected tokens sent to the Cake Vault
     */
    function inCaseTokensGetStuck(address _token) external adminOrOwner {
        require(_token != address(token), "Token cannot be same as deposit token");
        require(_token != address(dummyToken), "Token cannot be same as receipt token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external adminOrOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external adminOrOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice Calculates the expected harvest reward from third party
     * @return Expected reward to collect in CAKE
     */
    function calculateHarvestCakeRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this));
        amount = amount.add(available());
        uint256 currentCallFee = amount.mul(callFee).div(10000);

        return currentCallFee;
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending cake rewards
     */
    function calculateTotalPendingCakeRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this));
        amount = amount.add(available());

        return amount;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
    }
    
    /**
     * @notice returns shares for user
     */
    function getUserShares(address wallet) public view returns (uint256) {
        UserInfo storage user = userInfo[wallet];
        return user.shares;
    }

    /**
     * @notice Withdraws from funds from the XVMC time-locked vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public notContract {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 burnAmount = currentAmount;
        IMasterChef(masterchef).withdraw(poolID, currentAmount);
        
        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 withdrawFee = uint256(42).sub(((block.timestamp - user.lastDepositedTime).div(86400)).mul(236).div(1000));
            uint256 currentWithdrawFee = currentAmount.mul(withdrawFee).div(100);
            token.safeTransfer(treasury, currentWithdrawFee); 
            currentAmount = currentAmount.sub(currentWithdrawFee);
        } 

        if (user.shares > 0) {
            user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        } else {
            user.cakeAtLastUserAction = 0;
        }
        user.lastUserActionTime = block.timestamp;
        
        if(user.delegatingSharesToProposalID != 0) {
            _updateVotingSubDiff(msg.sender, user.delegatingSharesToProposalID, _shares);
        }

        IERC20(dummyToken).burnFrom(address(this), burnAmount); 
        token.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, (burnAmount - currentAmount), _shares);
    }


    
    /**
     * Transfer stake to another account(another wallet address)
     * Note: Voting does not get transferred
     */
    function transferStakeToAnotherWallet(uint256 _shares, address _recipientAddress) public notProxy {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        
        UserInfo storage recipient = userInfo[_recipientAddress];
        require(recipient.shares == 0, "Must have no active stake");

        user.shares = user.shares.sub(_shares);
        
        recipient.shares = _shares;
        recipient.lastDepositedTime = user.lastDepositedTime;
        recipient.lastUserActionTime = block.timestamp;
        
        user.lastUserActionTime = block.timestamp;


        if (user.shares > 0) {
            user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        } else {
            user.cakeAtLastUserAction = 0;
        }
        
        if(user.delegatingSharesToProposalID != 0) {
            _updateVotingSubDiff(msg.sender, user.delegatingSharesToProposalID, _shares);
        }
        
        recipient.cakeAtLastUserAction = recipient.shares.mul(balanceOf()).div(totalShares);
        

        emit TransferStake(msg.sender, _recipientAddress, _shares);
    }
    
    
    /**
     * Users can transfer their stake to another pool
     * Can only transfer to pool with longer lock-up period(trusted pools)
     * Equivalent to withdrawing, but it deposits the stake into another pool as hopDeposit
     * Users can transfer stake without penalty
     * Time served gets transferred 
     * The pool is "registered" as a "trustedSender" to another pool
     */
    function hopStakeToAnotherPool(uint256 _shares, address _poolAddress) public notContract {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        
        require(
            (_poolAddress == trustedPool4 || _poolAddress == trustedPool5 || _poolAddress == trustedPool6),
            "can only hop into pre-set Pools"
        );
        require(IacPool(_poolAddress).getUserShares(msg.sender) == 0, "can only hop if no activeStake");

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);
        user.lastUserActionTime = block.timestamp;

        IMasterChef(masterchef).withdraw(poolID, currentAmount);

        if (user.shares > 0) {
            user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        } else {
            user.cakeAtLastUserAction = 0;
        }
        
        if(user.delegatingSharesToProposalID != 0) {
            _updateVotingSubDiff(msg.sender, user.delegatingSharesToProposalID, _shares);
        }

        IERC20(dummyToken).burnFrom(address(this), currentAmount); 
        IacPool(_poolAddress).hopDeposit(currentAmount, msg.sender, user.lastDepositedTime);
        
        emit HopPool(msg.sender, currentAmount, _shares, _poolAddress, msg.sender);
    }

    
    /**
     * hopDeposit is equivalent to gift deposit, exception being that the time served can be passed
     * The msg.sender can only be a trusted contract
     * The checks are already made in the hopStakeToAnotherPool function
     */
    function hopDeposit(uint256 _amount, address _recipientAddress, uint256 previousLastDepositedTime) external whenNotPaused {
        require(msg.sender == trustedSender1 || msg.sender == trustedSender2, "only trusted senders(other pools)");
        
        UserInfo storage user = userInfo[_recipientAddress];
        
        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }

        user.shares = currentShares;
        user.lastDepositedTime = previousLastDepositedTime;
        totalShares = totalShares.add(currentShares);

        user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit HopDeposit(_recipientAddress, _amount, currentShares, previousLastDepositedTime);
    }


    /**
     * user delegates their shares to cast a vote on a proposal
     */
    function voteForProposal(uint256 proposalID) external notContract {
        UserInfo storage user = userInfo[msg.sender];
        
        require(user.shares > 0, "must have shares to vote");
        require(
            proposalID != user.delegatingSharesToProposalID, 
            "Already delegating to this proposalID"
            );

        if(user.delegatingSharesToProposalID != 0) {
            _updateVotingSub(msg.sender, user.delegatingSharesToProposalID, user.shares, 0);
            _updateVotingAdd(msg.sender, proposalID, 0, user.shares);
            user.delegatingSharesToProposalID = proposalID;
        } else {
            user.delegatingSharesToProposalID = proposalID;
            totalVotesForID[proposalID].value = totalVotesForID[proposalID].value.add(user.shares);
            
            emit AddVotes(msg.sender, proposalID, user.shares);
        }
    }

    
    /**
     * @notice Custom logic for how much the vault allows to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).sub(dummyToken.totalSupply());
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterChef
     */
    function balanceOf() public view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this)); 
        return token.balanceOf(address(this)).add(amount); 
    }

    /**
     * @notice Deposits tokens into MasterChef to earn staking rewards
     */
    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            IERC20(dummyToken).mint(address(this), bal); 
            IMasterChef(masterchef).deposit(poolID, bal); 
        }
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    
    /**
     * Returns votes for a proposal ID
     */
    function totalVotesFor(uint256 proposalID) external view returns (uint256) {
        return totalVotesForID[proposalID].value;
    }
    

    /**
     * updates votes(whenever there is transfer of funds)
     */
    function _updateVotingAdd(address voter, uint256 proposalID, uint256 oldShares, uint256 newShares) private {
        require(oldShares != newShares, "must change");
        uint256 diff = newShares.sub(oldShares);
        totalVotesForID[proposalID].value = totalVotesForID[proposalID].value.add(diff);
        
        emit AddVotes(voter, proposalID, diff);
    }
    function _updateVotingSub(address voter, uint256 proposalID, uint256 oldShares, uint256 newShares) private {
        require(oldShares != newShares, "must change");
        uint256 diff = oldShares.sub(newShares);
        totalVotesForID[proposalID].value = totalVotesForID[proposalID].value.sub(diff);
        
        emit RemoveVotes(voter, proposalID, diff);
    }
    function _updateVotingAddDiff(address voter, uint256 proposalID, uint256 diff) private {
        totalVotesForID[proposalID].value = totalVotesForID[proposalID].value.add(diff);
        
        emit AddVotes(voter, proposalID, diff);
    }
    function _updateVotingSubDiff(address voter, uint256 proposalID, uint256 diff) private {
        totalVotesForID[proposalID].value = totalVotesForID[proposalID].value.sub(diff);
        
        emit RemoveVotes(voter, proposalID, diff);
    }
}