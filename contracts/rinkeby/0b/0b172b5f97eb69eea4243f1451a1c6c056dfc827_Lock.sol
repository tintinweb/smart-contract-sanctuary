/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


pragma solidity ^0.8.0;

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

// File: Lock.sol

pragma solidity 0.8.0;


/**
 * @dev This contract will hold user locked funds which will be unlocked after
 * lock-up period ends
 */
contract Lock is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum Status {OPEN, CLOSED}
    enum TokenStatus {ACTIVE, INACTIVE}

    struct Token {
        address tokenAddress;
        uint256 minAmount;
        bool emergencyUnlock;
        TokenStatus status;
    }

    Token[] private _tokens;

    //Keeps track of token index in above array
    mapping(address => uint256) private _tokenVsIndex;

    //Wallet where fees will go
    address payable public _wallet;
    
    //Token address for accepting fees
    address public _feeTokenAddress;

    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    struct LockedAsset {
        address token; // Token address
        uint256 amount; // Amount locked
        uint256 startDate; // Start date. We can remove this later
        uint256 endDate;
        uint256 lastLocked;
        Status status;
        address lockOwner;
    }

    //Global lockedasset id. Also give total number of lock-ups made so far
    uint256 private _lockId;

    //list of all asset ids for a user
    mapping(address => uint256[]) public _userVsLockIds;

    mapping(uint256 => LockedAsset) private _idVsLockedAsset;

    bool private _paused;
    uint256 public lockingFee;

    event TokenAdded(address indexed token);
    event TokenInactivated(address indexed token);
    event TokenActivated(address indexed token);
    event WalletChanged(address indexed wallet);
    event FeeChanged(uint256 fee);
    event FeeTokenChanged(address feeToken);
    event AssetLocked(
        address indexed token,
        address indexed sender,
        uint256 id,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 fee
    );
    event TokenUpdated(
        uint256 indexed id,
        address indexed token,
        uint256 minAmount,
        bool emergencyUnlock
    );
    event Paused();
    event Unpaused();

    event AssetClaimed(
        uint256 indexed id,
        address indexed user,
        address indexed token
    );

    event AmountAdded(address indexed user, uint256 id, uint256 amount);

    modifier tokenExist(address token) {
        require(_tokenVsIndex[token] > 0, "Lock: Token does not exist!!");
        _;
    }

    modifier tokenDoesNotExist(address token) {
        require(_tokenVsIndex[token] == 0, "Lock: Token already exist!!");
        _;
    }

    modifier canLockAsset(address token) {
        uint256 index = _tokenVsIndex[token];

        require(index > 0, "Lock: Token does not exist!!");

        require(
            _tokens[index.sub(1)].status == TokenStatus.ACTIVE,
            "Lock: Token not active!!"
        );

        require(
            !_tokens[index.sub(1)].emergencyUnlock,
            "Lock: Token is in emergency unlock state!!"
        );
        _;
    }

    modifier canClaim(uint256 id) {
        require(claimable(id), "Lock: Can't claim asset");
        require(_idVsLockedAsset[id].lockOwner == msg.sender, "Lock: Only Lock owner can claim asset");

        require(
            _idVsLockedAsset[id].status == Status.OPEN,
            "Lock: Unauthorized access!!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Lock: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Lock: not paused");
        _;
    }
    
    /**
     * @dev Modifier to check whether enough value is sent.
     */
    modifier _checkValidValue(uint256 value, uint256 amount, address tokenAddress, uint256 fee,bool feesInEth )
    {   
        bool amountinEth = false;
        if( ETH_ADDRESS == tokenAddress)
        {
            amountinEth = true;
        }
        if(amountinEth && feesInEth)
        {
            require(value >= amount.add(fee), "Lock: Value sent less than required.");
        }
        else if(amountinEth && !feesInEth)
        {
            require(value >= amount, "Lock: Value sent less than required.");
        }
        else if(!amountinEth && feesInEth)
        {
            require(value >= fee, "Lock: Value sent less than required.");
        }
        _;
        
    }

    /**
     * @dev Constructor
     * @param wallet Wallet address where fees will go
     */
    constructor(address payable wallet, address feeToken) {
        require(
            wallet != address(0) && feeToken != address(0),
            "Lock: Please provide valid wallet address!!"
        );
        _wallet = wallet;
        _feeTokenAddress = feeToken;
        lockingFee = 5;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns total token count
     */
    function getTokenCount() external view returns (uint256) {
        return _tokens.length;
    }

    /**
     * @dev Returns list of supported tokens
     * This will be a paginated method which will only send 15 tokens in one request
     * This is done to prevent infinite loops and overflow of gas limits
     * @param start start index for pagination
     * @param length Amount of tokens to fetch
     */
    function getTokens(uint256 start, uint256 length)
        external
        view
        returns (
            address[] memory tokenAddresses,
            uint256[] memory minAmounts,
            bool[] memory emergencyUnlocks,
            TokenStatus[] memory statuses
        )
    {
        tokenAddresses = new address[](length);
        minAmounts = new uint256[](length);
        emergencyUnlocks = new bool[](length);
        statuses = new TokenStatus[](length);

        require(start.add(length) <= _tokens.length, "Lock: Invalid input");
        require(length > 0 && length <= 15, "Lock: Invalid length");
        uint256 count = 0;
        for (uint256 i = start; i < start.add(length); i++) {
            tokenAddresses[count] = _tokens[i].tokenAddress;
            minAmounts[count] = _tokens[i].minAmount;
            emergencyUnlocks[count] = _tokens[i].emergencyUnlock;
            statuses[count] = _tokens[i].status;
            count = count.add(1);
        }

        return (tokenAddresses, minAmounts, emergencyUnlocks, statuses);
    }

    function getAssetIds(address user)
        external
        view
        returns (uint256[] memory ids)
    {
        return _userVsLockIds[user];
    }
    
    /**
     * @dev Returns information about specific token
     * @dev tokenAddress Address of the token
     */
    function getTokenInfo(address tokenAddress)
        external
        view
        returns (
            uint256 minAmount,
            bool emergencyUnlock,
            TokenStatus status
        )
    {
        uint256 index = _tokenVsIndex[tokenAddress];

        if (index > 0) {
            index = index.sub(1);
            Token memory token = _tokens[index];
            return (
                token.minAmount,
                token.emergencyUnlock,
                token.status
            );
        }
    }

    /**
     * @dev Returns information about a locked asset
     * @param id Asset id
     */
    function getLockedAsset(uint256 id)
        external
        view
        returns (
            address token,
            uint256 amount,
            uint256 startDate,
            uint256 endDate,
            uint256 lastLocked,
            Status status,
            address owner
        )
    {
        LockedAsset memory asset = _idVsLockedAsset[id];
        token = asset.token;
        amount = asset.amount;
        startDate = asset.startDate;
        endDate = asset.endDate;
        status = asset.status;
        lastLocked = asset.lastLocked;
        owner = asset.lockOwner;

        return (
            token,
            amount,
            startDate,
            endDate,
            lastLocked,
            status,
            owner
        );
    }

    /**
     * @dev Returns all asset ids for a user
     * @param user Address of the user
     */
    // function getAssetIds(address user)
    //     external
    //     view
    //     returns (uint256[] memory ids)
    // {
    //     return _userVsLockIds[user];
    // }

    /**
     * @dev Called by an admin to pause, triggers stopped state.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Called by an admin to unpause, returns to normal state.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }
    
    /**
     * @dev Allows admin to set fee
     * @param newFee New fees for locking
     */
    function setFee(uint256 newFee) external onlyOwner {
        lockingFee = newFee;
        emit FeeChanged(lockingFee);
    }
    
    /**
     * @dev Allows admin to set feeToken address
     * @param newFeeToken New fees token address for locking
     */
    function setFeeToken(address newFeeToken) external onlyOwner {
        _feeTokenAddress = newFeeToken;
        emit FeeTokenChanged(_feeTokenAddress);
    }

    /**
     * @dev Allows admin to set fee receiver wallet
     * @param wallet New wallet address
     */
    function setWallet(address payable wallet) external onlyOwner {
        require(
            wallet != address(0),
            "Lock: Please provider valid wallet address!!"
        );
        _wallet = wallet;

        emit WalletChanged(wallet);
    }

    /**
     * @dev Allows admin to update token info
     * @param tokenAddress Address of the token to be updated
     * @param minAmount Min amount of tokens required to lock
     * @param emergencyUnlock If token is in emergency unlock state
     */
    function updateToken(
        address tokenAddress,
        uint256 minAmount,
        bool emergencyUnlock
    ) external onlyOwner tokenExist(tokenAddress) {
       

        uint256 index = _tokenVsIndex[tokenAddress].sub(1);
        Token storage token = _tokens[index];
        token.minAmount = minAmount;
        token.emergencyUnlock = emergencyUnlock;
       
        emit TokenUpdated(
            index,
            tokenAddress,
            minAmount,
            emergencyUnlock
        );
    }

    /**
     * @dev Allows admin to add new token to the list
     * @param token Address of the token
     * @param minAmount Minimum amount of tokens to lock for this token
     */
    function addToken(
        address token,
        uint256 minAmount
    ) external onlyOwner tokenDoesNotExist(token) {
       
        _tokens.push(
            Token({
                tokenAddress: token,
                minAmount: minAmount,
                emergencyUnlock: false,
                status: TokenStatus.ACTIVE
            })
        );
        _tokenVsIndex[token] = _tokens.length;

        emit TokenAdded(token);
    }

    /**
     * @dev Allows admin to inactivate token
     * @param token Address of the token to be inactivated
     */
    function inactivateToken(address token)
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);

        require(
            _tokens[index].status == TokenStatus.ACTIVE,
            "Lock: Token already inactive!!"
        );

        _tokens[index].status = TokenStatus.INACTIVE;

        emit TokenInactivated(token);
    }

    /**
     * @dev Allows admin to activate any existing token
     * @param token Address of the token to be activated
     */
    function activateToken(address token) external onlyOwner tokenExist(token) {
        uint256 index = _tokenVsIndex[token].sub(1);

        require(
            _tokens[index].status == TokenStatus.INACTIVE,
            "Lock: Token already active!!"
        );

        _tokens[index].status = TokenStatus.ACTIVE;

        emit TokenActivated(token);
    }

    /**
     * @dev Allows user to lock asset. In case of ERC-20 token the user will
     * first have to approve the contract to spend on his/her behalf
     * @param tokenAddress Address of the token to be locked
     * @param amount Amount of tokens to lock
     * @param duration Duration for which tokens to be locked. In seconds
     */
    function lock(
        address tokenAddress,
        uint256 amount,
        bool feesInEth,
        uint256 duration
    ) external payable whenNotPaused canLockAsset(tokenAddress) {
        uint256 remValue =
            _lock(tokenAddress, amount, feesInEth, duration, msg.value);
        
        require(remValue < 10000000000, "Lock: Sent more ethers then required");
    }

    /**
     * @dev Allows user to lock asset. In case of ERC-20 token the user will
     * first have to approve the contract to spend on his/her behalf
     * @param tokenAddress Address of the token to be locked
     * @param amounts List of amount of tokens to lock
     * @param durations List of duration for which tokens to be locked. In seconds
     */
    function bulkLock(
        address tokenAddress,
        uint256[] calldata amounts,
        bool feesInEth,
        uint256[] calldata durations
    ) external payable whenNotPaused canLockAsset(tokenAddress) {
        uint256 remValue = msg.value;
        require(amounts.length == durations.length, "Lock: Invalid input");      

        for (uint256 i = 0; i < amounts.length; i++) {
            remValue = _lock(
                tokenAddress,
                amounts[i],
                feesInEth,
                durations[i],
                remValue
            );
        }

        require(remValue < 10000000000, "Lock: Sent more ethers then required");
    }

    /**
     * @dev Allows user to claim their asset after lock-up period ends
     * @param id Id of the locked asset
     */
    function claim(uint256 id) external canClaim(id) {
        LockedAsset memory lockedAsset = _idVsLockedAsset[id];
        if (ETH_ADDRESS == lockedAsset.token) {
            _claimETH(id);
        } else {
            _claimERC20(id);
        }

        emit AssetClaimed(id, msg.sender, lockedAsset.token);
    }

    /**
     * @dev Allows anyone to add more tokens in the existing lock
     * @param id id of the locked asset
     * @param amount Amount to be added
     */
    function addAmount(uint256 id, uint256 amount, bool feesInEth)
        external
        payable
        whenNotPaused
    {
        LockedAsset storage lockedAsset = _idVsLockedAsset[id];

        require(lockedAsset.status == Status.OPEN, "Lock: Lock is not open");

        uint256 fee = _calculateFee(amount);
        uint256 newAmount = msg.value - fee;
        address tokenAddress = lockedAsset.token;
        addCheckedAmount(amount, newAmount, fee, feesInEth,tokenAddress, msg.value);

        lockedAsset.amount = lockedAsset.amount.add(newAmount);
        lockedAsset.lastLocked = block.timestamp;

        emit AmountAdded(msg.sender, id, newAmount);
    }

    function addCheckedAmount(uint256 amount,uint256 newAmount,uint256 fee,bool feesInEth,address tokenAddress,uint256 value) 
    private
    _checkValidValue(value, amount, tokenAddress, fee, feesInEth)
    {
         if (ETH_ADDRESS == tokenAddress) 
        {
            _transferFee(fee, feesInEth);
        }
        else
        {   
            _transferFee(fee, feesInEth);
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                newAmount
            );
        }
    }

    /**
     * @dev Returns whether given asset can be claimed or not
     * @param id id of an asset
     */
    function claimable(uint256 id) public view returns (bool) {
        LockedAsset memory asset = _idVsLockedAsset[id];
       
        if (
            asset.status == Status.OPEN &&
            (asset.endDate <= block.timestamp ||
                _tokens[_tokenVsIndex[asset.token].sub(1)].emergencyUnlock )
        ) {
            return true;
        }
        return false;
    }

    /**
     * @dev Returns whether provided token is active or not
     * @param token Address of the token to be checked
     */
    function isActive(address token) public view returns (bool) {
        uint256 index = _tokenVsIndex[token];

        if (index > 0) {
            return (_tokens[index.sub(1)].status == TokenStatus.ACTIVE);
        }
        return false;
    }

    /**
     * @dev Helper method to lock asset
     */
    function _lock(
        address tokenAddress,
        uint256 amount,
        bool feesInEth,
        uint256 duration,
        uint256 value
    ) private returns (uint256) {
        Token memory token = _tokens[_tokenVsIndex[tokenAddress].sub(1)];
        uint256 newAmount = 0;
        require(
            amount >= token.minAmount,
            "Lock: Please provide minimum amount of tokens!!"
        );

        uint256 endDate = block.timestamp.add(duration);
        uint256 fee = _calculateFee(amount);
        uint256 remValue = value;
        
        
        if (ETH_ADDRESS == tokenAddress) {
            newAmount = value - fee;
            _lockETH(amount, fee, feesInEth, endDate, value);
            
            if(feesInEth){
                remValue = remValue.sub(amount.add(fee));
            }
            else{
                remValue = remValue.sub(amount);
            }
        } else {
            if(feesInEth){
                remValue = remValue.sub(fee);
            }
            _lockERC20(tokenAddress, amount, fee, feesInEth, endDate, value);
        }

        emit AssetLocked(
            tokenAddress,
            msg.sender,
            _lockId,
            newAmount,
            block.timestamp,
            endDate,
            fee
        );

        return remValue;
    }


    /**
     * @dev Helper method to lock ETH
     */
    function _lockETH(
        uint256 amount,
        uint256 fee,
        bool feesInEth,
        uint256 endDate,
        uint256 value
    ) private 
    _checkValidValue(value, amount, ETH_ADDRESS, fee, feesInEth){
        //Transferring fee to the wallet

        _transferFee(fee, feesInEth);
        
        _lockId = _lockId.add(1);
        
        _idVsLockedAsset[_lockId] = LockedAsset({
            token: ETH_ADDRESS,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            lastLocked: block.timestamp,
            status: Status.OPEN,
            lockOwner: msg.sender
        });
        _userVsLockIds[msg.sender].push(_lockId);
    }

    /**
     * @dev Helper method to lock ERC-20 tokens
     */
    function _lockERC20(
        address token,
        uint256 amount,
        uint256 fee,
        bool feesInEth,
        uint256 endDate,
        uint256 value
    ) private 
      _checkValidValue(value, amount, token, fee, feesInEth){
        //Transfer fee to the wallet
        
        _transferFee(fee, feesInEth);
        
        //Transfer required amount of tokens to the contract from user balance
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        _lockId = _lockId.add(1);

        _idVsLockedAsset[_lockId] = LockedAsset({
            token: token,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            status: Status.OPEN,
            lastLocked: block.timestamp,
            lockOwner: msg.sender
        });

        _userVsLockIds[msg.sender].push(_lockId);
    }

    /**
     * @dev Helper method to claim ETH
     */
    function _claimETH(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        (bool success, ) = msg.sender.call{value: asset.amount}("");
        require(success, "Lock: Failed to transfer eth!!");
    }

    /**
     * @dev Helper method to claim ERC-20
     */
    function _claimERC20(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        IERC20(asset.token).safeTransfer(msg.sender, asset.amount);
    }
    
    
    function _calculateFee(uint256 amount)
    private
    view
    returns (uint256 feeCalculated)
    {
        feeCalculated = amount.mul(lockingFee).div(10000);
    }

    function _transferFee(uint256 fee,bool feesInEth )
    private
    {   
        if(feesInEth)
        {
            (bool success, ) = _wallet.call{value: fee}("");
            require(success, "");
        }
        else
        {
            IERC20(_feeTokenAddress).safeTransferFrom(msg.sender, _wallet, fee);
        }
    }
  
}