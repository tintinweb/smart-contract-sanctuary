// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

    constructor () internal {
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libraries/SafeMath96.sol";
import "./libraries/SafeMath32.sol";

// Archbishop will crown the King and he is a fair guy...
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once $KING is sufficiently
// distributed and the community can show to govern itself.
contract ArchbishopV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;

    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 wAmount; // Weighted amount = lptAmount + (stAmount * pool.sTokenWeight)
        uint256 stAmount; // How many S tokens the user has provided
        uint256 lptAmount; // How many LP tokens the user has provided
        uint96 pendingKing; // $KING tokens pending to be given to user
        uint96 rewardDebt; // Reward debt (see explanation below)
        uint32 lastWithdrawBlock; // User last withdraw time

        // We do some fancy math here. Basically, any point in time, the amount of $KINGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.wAmount * pool.accKingPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKingPerShare` (and `lastRewardBlock`) gets updated
        //   2. User receives the pending reward sent to his/her address
        //   3. User's `wAmount` gets updated
        //   4. User's `rewardDebt` gets updated
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract
        uint32 allocPoint; // Allocation points assigned to this pool (for $KINGs distribution)
        uint32 lastRewardBlock; // Last block number that $KINGs distribution occurs
        uint32 sTokenWeight; // "Weight" of LP token in SToken, times 1e8
        IERC20 sToken; // Address of S token contract
        bool kingLock; // if true, withdraw interval, or withdraw fees otherwise, applied on $KING withdrawals
        uint256 accKingPerShare; // Accumulated $KINGs per share, times 1e12 (see above)
    }

    // The $KING token contract
    address public king;

    // The kingServant contract (that receives LP token fees)
    address public kingServant;
    // fees on LP token withdrawals, in percents
    uint8 public lpFeePct = 0;

    // The courtJester address (that receives $KING fees)
    address public courtJester;
    // fees on $KING withdrawals, in percents (charged if `pool.kingLock` is `false`)
    uint8 public kingFeePct = 0;
    // Withdraw interval, in blocks, takes effect if pool.kingLock is `true`
    uint32 public withdrawInterval;

    // $KING token amount distributed every block of LP token farming
    uint96 public kingPerLptFarmingBlock;
    // $KING token amount distributed every block of S token farming
    uint96 public kingPerStFarmingBlock;
    // The sum of allocation points in all pools
    uint32 public totalAllocPoint;

    // The block when yield and trade farming starts
    uint32 public startBlock;
    // Block when LP token farming ends
    uint32 public lptFarmingEndBlock;
    // Block when S token farming ends
    uint32 public stFarmingEndBlock;

    // Info of each pool
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount,
        uint256 stAmount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount
    );

    constructor(
        address _king,
        address _kingServant,
        address _courtJester,
        uint256 _startBlock,
        uint256 _withdrawInterval
    ) public {
        king = _nonZeroAddr(_king);
        kingServant = _nonZeroAddr(_kingServant);
        courtJester = _nonZeroAddr(_courtJester);
        startBlock = SafeMath32.fromUint(_startBlock);
        withdrawInterval = SafeMath32.fromUint(_withdrawInterval);
    }

    function setFarmingParams(
        uint256 _kingPerLptFarmingBlock,
        uint256 _kingPerStFarmingBlock,
        uint256 _lptFarmingEndBlock,
        uint256 _stFarmingEndBlock
    ) external onlyOwner {
        uint32 _startBlock = startBlock;
        require(_lptFarmingEndBlock >= _startBlock, "ArchV2:INVALID_lptFarmEndBlock");
        require(_stFarmingEndBlock >= _startBlock, "ArchV2:INVALID_stFarmEndBlock");
        _setFarmingParams(
            SafeMath96.fromUint(_kingPerLptFarmingBlock),
            SafeMath96.fromUint(_kingPerStFarmingBlock),
            SafeMath32.fromUint(_lptFarmingEndBlock),
            SafeMath32.fromUint(_stFarmingEndBlock)
        );
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new LP pool. Owner only may call.
    function add(
        uint256 allocPoint,
        uint256 sTokenWeight,
        IERC20 lpToken,
        IERC20 sToken,
        bool withUpdate
    ) public onlyOwner {
        require(_isMissingPool(lpToken, sToken), "ArchV2::add:POOL_EXISTS");
        uint32 _allocPoint = SafeMath32.fromUint(allocPoint);

        if (withUpdate) massUpdatePools();

        uint32 curBlock = curBlock();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken,
                sToken: sToken,
                allocPoint: SafeMath32.fromUint(_allocPoint),
                sTokenWeight: SafeMath32.fromUint(sTokenWeight),
                lastRewardBlock: curBlock > startBlock ? curBlock : startBlock,
                accKingPerShare: 0,
                kingLock: true
            })
        );
    }

    // Update the given pool's $KING allocation point. Owner only may call.
    function setAllocation(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        uint32 _allocPoint = SafeMath32.fromUint(allocPoint);

        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[pid].allocPoint = _allocPoint;
    }

    function setSTokenWeight(
        uint256 pid,
        uint256 sTokenWeight,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        poolInfo[pid].sTokenWeight = SafeMath32.fromUint(sTokenWeight);
    }

    function setKingLock(
        uint256 pid,
        bool _kingLock,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        poolInfo[pid].kingLock = _kingLock;
    }

    // Return reward multipliers for LP and S tokens over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to)
        public
        view
        returns (uint256 lpt, uint256 st)
    {
        (uint32 _lpt, uint32 _st) = _getMultiplier(
            SafeMath32.fromUint(from),
            SafeMath32.fromUint(to)
        );
        lpt = uint256(_lpt);
        st = uint256(_st);
    }

    function getKingPerBlock(uint256 blockNum) public view returns (uint256) {
        return
            (blockNum > stFarmingEndBlock ? 0 : kingPerStFarmingBlock).add(
                blockNum > lptFarmingEndBlock ? 0 : kingPerLptFarmingBlock
            );
    }

    // View function to see pending $KINGs on frontend.
    function pendingKing(uint256 pid, address _user)
        external
        view
        returns (uint256)
    {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 kingPerShare = pool.accKingPerShare;

        uint32 curBlock = curBlock();
        uint256 lptSupply = pool.lpToken.balanceOf(address(this));

        if (curBlock > pool.lastRewardBlock && lptSupply != 0) {
            (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
                pool.lastRewardBlock,
                curBlock
            );
            uint96 kingReward = _kingReward(
                lptFactor,
                stFactor,
                pool.allocPoint
            );
            if (kingReward != 0) {
                uint256 stSupply = pool.sToken.balanceOf(address(this));
                uint256 wSupply = _weighted(
                    lptSupply,
                    stSupply,
                    pool.sTokenWeight
                );
                kingPerShare = _accShare(kingPerShare, kingReward, wSupply);
            }
        }

        return
            _accPending(
                user.pendingKing,
                user.wAmount,
                user.rewardDebt,
                kingPerShare
            );
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool
    function updatePool(uint256 pid) public {
        _validatePid(pid);
        _updatePool(pid);
    }

    // Deposit lptAmount of LP token and stAmount of S token to mine $KING,
    // (it sends to msg.sender $KINGs pending by then)
    function deposit(
        uint256 pid,
        uint256 lptAmount,
        uint256 stAmount
    ) public nonReentrant {
        require(lptAmount != 0, "deposit: zero LP token amount");
        _validatePid(pid);

        _updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 oldStAmount = user.stAmount;
        uint96 pendingKingAmount = _accPending(
            user.pendingKing,
            user.wAmount,
            user.rewardDebt,
            pool.accKingPerShare
        );
        user.lptAmount = user.lptAmount.add(lptAmount);
        user.stAmount = user.stAmount.add(stAmount);
        user.wAmount = _accWeighted(
            user.wAmount,
            lptAmount,
            stAmount,
            pool.sTokenWeight
        );

        uint32 curBlock = curBlock();
        if (
            _sendKingToken(
                msg.sender,
                pendingKingAmount,
                pool.kingLock,
                curBlock.sub(user.lastWithdrawBlock)
            )
        ) {
            user.lastWithdrawBlock = curBlock;
            user.pendingKing = 0;
            pool.sToken.safeTransfer(address(1), oldStAmount);
        } else {
            user.pendingKing = pendingKingAmount;
        }
        user.rewardDebt = _pending(user.wAmount, 0, pool.accKingPerShare);

        pool.lpToken.safeTransferFrom(msg.sender, address(this), lptAmount);
        if (stAmount != 0)
            pool.sToken.safeTransferFrom(msg.sender, address(this), stAmount);

        emit Deposit(msg.sender, pid, lptAmount, stAmount);
    }

    // Withdraw lptAmount of LP token and all pending $KING tokens
    // (it burns all S tokens)
    function withdraw(uint256 pid, uint256 lptAmount) public nonReentrant {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 preLptAmount = user.wAmount;
        require(preLptAmount >= lptAmount, "withdraw: LP amount not enough");

        user.lptAmount = preLptAmount.sub(lptAmount);
        uint256 stAmount = user.stAmount;

        _updatePool(pid);
        uint96 pendingKingAmount = _accPending(
            user.pendingKing,
            user.wAmount,
            user.rewardDebt,
            pool.accKingPerShare
        );
        user.wAmount = user.lptAmount;
        user.rewardDebt = _pending(user.wAmount, 0, pool.accKingPerShare);
        user.stAmount = 0;
        uint32 curBlock = curBlock();

        if (
            _sendKingToken(
                msg.sender,
                pendingKingAmount,
                pool.kingLock,
                curBlock.sub(user.lastWithdrawBlock)
            )
        ) {
            user.lastWithdrawBlock = curBlock;
            user.pendingKing = 0;
        } else {
            user.pendingKing = pendingKingAmount;
        }

        uint256 sentLptAmount = lptAmount == 0
            ? 0
            : _sendLptAndBurnSt(msg.sender, pool, lptAmount, stAmount);
        emit Withdraw(msg.sender, pid, sentLptAmount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // (it clears all pending $KINGs and burns all S tokens)
    function emergencyWithdraw(uint256 pid) public {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 lptAmount = user.lptAmount;
        user.lptAmount = 0; // serves as "non-reentrant"
        require(lptAmount > 0, "withdraw: zero LP token amount");

        uint32 curBlock = curBlock();
        uint256 stAmount = user.stAmount;
        user.wAmount = 0;
        user.stAmount = 0;
        user.rewardDebt = 0;
        user.pendingKing = 0;
        user.lastWithdrawBlock = curBlock;

        uint256 sentLptAmount = _sendLptAndBurnSt(
            msg.sender,
            pool,
            lptAmount,
            stAmount
        );
        emit EmergencyWithdraw(msg.sender, pid, sentLptAmount);
    }

    function setKingServant(address _kingServant) public onlyOwner {
        kingServant = _nonZeroAddr(_kingServant);
    }

    function setCourtJester(address _courtJester) public onlyOwner {
        courtJester = _nonZeroAddr(_courtJester);
    }

    function setKingFeePct(uint256 newPercent) public onlyOwner {
        kingFeePct = _validPercent(newPercent);
    }

    function setLpFeePct(uint256 newPercent) public onlyOwner {
        lpFeePct = _validPercent(newPercent);
    }

    function setWithdrawInterval(uint256 _blocks) public onlyOwner {
        withdrawInterval = SafeMath32.fromUint(_blocks);
    }

    function _updatePool(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        uint32 lastUpdateBlock = pool.lastRewardBlock;

        uint32 curBlock = curBlock();
        if (curBlock <= lastUpdateBlock) return;
        pool.lastRewardBlock = curBlock;

        (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
            lastUpdateBlock,
            curBlock
        );
        if (lptFactor == 0 && stFactor == 0) return;

        uint256 lptSupply = pool.lpToken.balanceOf(address(this));
        if (lptSupply == 0) return;

        uint256 stSupply = pool.sToken.balanceOf(address(this));
        uint256 wSupply = _weighted(lptSupply, stSupply, pool.sTokenWeight);

        uint96 kingReward = _kingReward(lptFactor, stFactor, pool.allocPoint);
        pool.accKingPerShare = _accShare(
            pool.accKingPerShare,
            kingReward,
            wSupply
        );
    }

    function _sendKingToken(
        address user,
        uint96 amount,
        bool kingLock,
        uint32 blocksSinceLastWithdraw
    ) internal returns (bool isSent) {
        isSent = true;
        if (amount == 0) return isSent;

        uint256 feeAmount = 0;
        uint256 userAmount = 0;

        if (!kingLock) {
            userAmount = amount;
            if (kingFeePct != 0) {
                feeAmount = uint256(amount).mul(kingFeePct).div(100);
                userAmount = userAmount.sub(feeAmount);

                IERC20(king).safeTransfer(courtJester, feeAmount);
            }
        } else if (blocksSinceLastWithdraw > withdrawInterval) {
            userAmount = amount;
        } else {
            return isSent = false;
        }

        uint256 balance = IERC20(king).balanceOf(address(this));
        IERC20(king).safeTransfer(
            user,
            // if balance lacks some tiny $KING amount due to imprecise rounding
            userAmount > balance ? balance : userAmount
        );
    }

    function _sendLptAndBurnSt(
        address user,
        PoolInfo storage pool,
        uint256 lptAmount,
        uint256 stAmount
    ) internal returns (uint256) {
        uint256 userLptAmount = lptAmount;

        if (curBlock() < stFarmingEndBlock && lpFeePct != 0) {
            uint256 lptFee = lptAmount.mul(lpFeePct).div(100);
            userLptAmount = userLptAmount.sub(lptFee);

            pool.lpToken.safeTransfer(kingServant, lptFee);
        }

        if (userLptAmount != 0) pool.lpToken.safeTransfer(user, userLptAmount);
        if (stAmount != 0) pool.sToken.safeTransfer(address(1), stAmount);

        return userLptAmount;
    }

    function _safeKingTransfer(address _to, uint256 _amount) internal {
        uint256 kingBal = IERC20(king).balanceOf(address(this));
        // if pool lacks some tiny $KING amount due to imprecise rounding
        IERC20(king).safeTransfer(_to, _amount > kingBal ? kingBal : _amount);
    }

    function _setFarmingParams(
        uint96 _kingPerLptFarmingBlock,
        uint96 _kingPerStFarmingBlock,
        uint32 _lptFarmingEndBlock,
        uint32 _stFarmingEndBlock
    ) internal {
        require(
            _lptFarmingEndBlock >= lptFarmingEndBlock,
            "ArchV2::lptFarmingEndBlock"
        );
        require(
            _stFarmingEndBlock >= stFarmingEndBlock,
            "ArchV2::stFarmingEndBlock"
        );

        if (lptFarmingEndBlock != _lptFarmingEndBlock)
            lptFarmingEndBlock = _lptFarmingEndBlock;
        if (stFarmingEndBlock != _stFarmingEndBlock)
            stFarmingEndBlock = _stFarmingEndBlock;

        (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
            curBlock(),
            2**32 - 1
        );
        uint256 minBalance = (
            uint256(_kingPerLptFarmingBlock).mul(uint256(stFactor))
        )
            .add(uint256(_kingPerStFarmingBlock).mul(uint256(lptFactor)));
        require(
            IERC20(king).balanceOf(address(this)) >= minBalance,
            "ArchV2::LOW_$KING_BALANCE"
        );

        kingPerLptFarmingBlock = _kingPerLptFarmingBlock;
        kingPerStFarmingBlock = _kingPerStFarmingBlock;
    }

    // Revert if the LP token has been already added.
    function _isMissingPool(IERC20 lpToken, IERC20 sToken)
        internal
        view
        returns (bool)
    {
        _revertZeroAddress(address(lpToken));
        _revertZeroAddress(address(lpToken));
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (
                poolInfo[i].lpToken == lpToken || poolInfo[i].sToken == sToken
            ) {
                return false;
            }
        }
        return true;
    }

    function _getMultiplier(uint32 _from, uint32 _to)
        internal
        view
        returns (uint32 lpt, uint32 st)
    {
        uint32 start = _from > startBlock ? _from : startBlock;

        // LP token farming multiplier
        uint32 end = _to > lptFarmingEndBlock ? lptFarmingEndBlock : _to;
        lpt = _from < lptFarmingEndBlock ? end.sub(start) : 0;

        // S token farming multiplier
        end = _to > stFarmingEndBlock ? stFarmingEndBlock : _to;
        st = _from < stFarmingEndBlock ? end.sub(start) : 0;
    }

    function _accPending(
        uint96 prevPending,
        uint256 amount,
        uint96 rewardDebt,
        uint256 accPerShare
    ) internal pure returns (uint96) {
        return
            amount == 0
                ? prevPending
                : prevPending.add(_pending(amount, rewardDebt, accPerShare));
    }

    function _pending(
        uint256 amount,
        uint96 rewardDebt,
        uint256 accPerShare
    ) internal pure returns (uint96) {
        return
            amount == 0
                ? 0
                : SafeMath96.fromUint(
                    amount.mul(accPerShare).div(1e12).sub(uint256(rewardDebt)),
                    "ArchV2::pending:overflow"
                );
    }

    function _kingReward(
        uint32 lptFactor,
        uint32 stFactor,
        uint32 allocPoint
    ) internal view returns (uint96) {
        uint32 _totalAllocPoint = totalAllocPoint;
        uint96 lptReward = _reward(
            lptFactor,
            kingPerLptFarmingBlock,
            allocPoint,
            _totalAllocPoint
        );
        if (stFactor == 0) return lptReward;

        uint96 stReward = _reward(
            stFactor,
            kingPerStFarmingBlock,
            allocPoint,
            _totalAllocPoint
        );
        return lptReward.add(stReward);
    }

    function _reward(
        uint32 factor,
        uint96 rewardPerBlock,
        uint32 allocPoint,
        uint32 _totalAllocPoint
    ) internal pure returns (uint96) {
        return
            SafeMath96.fromUint(
                uint256(factor)
                    .mul(uint256(rewardPerBlock))
                    .mul(uint256(allocPoint))
                    .div(uint256(_totalAllocPoint))
            );
    }

    function _accShare(
        uint256 prevShare,
        uint96 reward,
        uint256 supply
    ) internal pure returns (uint256) {
        return prevShare.add(uint256(reward).mul(1e12).div(supply));
    }

    function _accWeighted(
        uint256 prevAmount,
        uint256 lptAmount,
        uint256 stAmount,
        uint32 sTokenWeight
    ) internal pure returns (uint256) {
        return prevAmount.add(_weighted(lptAmount, stAmount, sTokenWeight));
    }

    function _weighted(
        uint256 lptAmount,
        uint256 stAmount,
        uint32 sTokenWeight
    ) internal pure returns (uint256) {
        if (stAmount == 0 || sTokenWeight == 0) {
            return lptAmount;
        }
        return lptAmount.add(stAmount.mul(sTokenWeight).div(1e8));
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function curBlock() private view returns (uint32) {
        return SafeMath32.fromUint(block.number);
    }

    function _validPercent(uint256 percent) private pure returns (uint8) {
        require(percent <= 100, "ArchV2::INVALID_PERCENT");
        return uint8(percent);
    }

    function _revertZeroAddress(address _address) internal pure {
        require(_address != address(0), "ArchV2::ZERO_ADDRESS");
    }

    function _validatePid(uint256 pid) private view returns (uint256) {
        require(pid < poolInfo.length, "ArchV2::INVALID_POOL_ID");
        return pid;
    }
}

pragma solidity 0.6.12;

library SafeMath32 {

    function add(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return add(a, b, "SafeMath32: addition overflow");
    }

    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath32: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function fromUint(uint n) internal pure returns (uint32) {
        return fromUint(n, "SafeMath32: exceeds 32 bits");
    }
}

pragma solidity 0.6.12;

library SafeMath96 {

    function add(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        return add(a, b, "SafeMath96: addition overflow");
    }

    function sub(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        return sub(a, b, "SafeMath96: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function fromUint(uint n) internal pure returns (uint96) {
        return fromUint(n, "SafeMath96: exceeds 96 bits");
    }
}

