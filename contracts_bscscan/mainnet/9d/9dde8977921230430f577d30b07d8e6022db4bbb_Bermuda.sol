/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

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


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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


// File: @openzeppelin/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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


// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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


// File: @openzeppelin/contracts/GSN/Context.sol

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


// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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


// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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


// File: contracts/IStaking.sol

/*
Staking interface
EIP-900 staking interface
https://github.com/gysr-io/core
h/t https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
*/

pragma solidity ^0.6.12;

interface IStaking {
    // events
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );

    /**
     * @notice stakes a certain amount of tokens, transferring this amount from
     the user to the contract
     * @param amount number of tokens to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice stakes a certain amount of tokens for an address, transfering this
     amount from the caller to the contract, on behalf of the specified address
     * @param user beneficiary address
     * @param amount number of tokens to stake
     */
    function stakeFor(
        address user,
        uint256 amount
    ) external;

    /**
     * @notice unstakes a certain amount of tokens, returning these tokens
     to the user
     * @param amount number of tokens to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @param addr the address of interest
     * @return the current total of tokens staked for an address
     */
    function totalStakedFor(address addr) external view returns (uint256);

    /**
     * @return the current total amount of tokens staked by all users
     */
    function totalStaked() external view returns (uint256);

    /**
     * @return the staking token for this staking contract
     */
    function token() external view returns (address);

    /**
     * @return true if the staking contract support history
     */
    function supportsHistory() external pure returns (bool);
}


// File: contracts/IBermuda.sol


/*
Bermuda interface
This defines the core Bermuda contract interface as an extension to the
standard IStaking interface
*/

pragma solidity ^0.6.12;

/**
 * @title Bermuda interface
 */
abstract contract IBermuda is IStaking, Ownable {
    // events
    event RewardsDistributed(address indexed user, uint256 amount);
    event RewardsFunded(
        uint256 amount,
        uint256 duration,
        uint256 start,
        uint256 total
    );
    event RewardsUnlocked(uint256 amount, uint256 total);
    event RewardsExpired(uint256 amount, uint256 duration, uint256 start);
    event TakoSpent(address indexed user, uint256 amount);
    event TakoWithdrawn(uint256 amount);

    // IStaking
    /**
     * @notice no support for history
     * @return false
     */
    function supportsHistory() external override pure returns (bool) {
        return false;
    }

    // IBermuda
    /**
     * @return staking token for this Bermuda
     */
    function stakingToken() external virtual view returns (address);

    /**
     * @return reward token for this Bermuda
     */
    function rewardToken() external virtual view returns (address);

    /**
     * @notice fund Bermuda by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     */
    function fund(uint256 amount, uint256 duration) external virtual;

    /**
     * @notice fund Bermuda by locking up reward tokens for future distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function fund(
        uint256 amount,
        uint256 duration,
        uint256 start
    ) external virtual;

    /**
     * @notice withdraw TAKO tokens applied during unstaking
     * @param amount number of TAKO to withdraw
     */
    function withdraw(uint256 amount) external virtual;

    /**
     * @notice unstake while applying TAKO token for boosted rewards
     * @param amount number of tokens to unstake
     * @param tako number of TAKO tokens to apply for boost
     */
    function unstake(
        uint256 amount,
        uint256 tako
    ) external virtual;

    /**
     * @notice update accounting, unlock tokens, etc.
     */
    function update() external virtual;

    /**
     * @notice clean Bermuda, expire old fundings, etc.
     */
    function clean() external virtual;
}


// File: contracts/BermudaPool.sol


/*
Bermuda token pool
Simple contract to implement token pool of arbitrary ERC20 token.
This is owned and used by a parent Bermuda
*/

pragma solidity ^0.6.12;

contract BermudaPool is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(address token_) public {
        token = IERC20(token_);
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value) external onlyOwner {
        token.safeTransfer(to, value);
    }
}

// File: contracts/MathUtils.sol

/*
Math utilities
This library implements various logarithmic math utilies which support
other contracts and specifically the GYSR multiplier calculation
https://github.com/gysr-io/core
h/t https://github.com/abdk-consulting/abdk-libraries-solidity
*/

pragma solidity ^0.6.12;

library MathUtils {
    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function logbase2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << (127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * @notice calculate natural logarithm of x
     * @dev magic constant comes from ln(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                (uint256(logbase2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >>
                    128
            );
    }

    /**
     * @notice calculate logarithm base 10 of x
     * @dev magic constant comes from log10(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase10(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                (uint256(logbase2(x)) * 0x4d104d427de7fce20a6e420e02236748) >>
                    128
            );
    }

    // wrapper functions to allow testing
    function testlogbase2(int128 x) public pure returns (int128) {
        return logbase2(x);
    }

    function testlogbase10(int128 x) public pure returns (int128) {
        return logbase10(x);
    }
}


// File: contracts/Geyser.sol

/*
Bermuda
This implements the core Bermuda contract, which allows for generalized
staking, yield farming, and token distribution. This also implements
the TAKO spending mechanic for boosted reward distribution.
*/

pragma solidity ^0.6.12;

/**
 * @title Bermuda
 */
contract Bermuda is IBermuda, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using MathUtils for int128;

    // single stake by user
    struct Stake {
        uint256 shares;
        uint256 timestamp;
    }

    // summary of total user stake/shares
    struct User {
        uint256 shares;
        uint256 shareSeconds;
        uint256 lastUpdated;
    }

    // single funding/reward schedule
    struct Funding {
        uint256 amount;
        uint256 shares;
        uint256 unlocked;
        uint256 lastUpdated;
        uint256 start;
        uint256 end;
        uint256 duration;
    }

    // constants
    uint256 public constant BONUS_DECIMALS = 18;
    uint256 public constant INITIAL_SHARES_PER_TOKEN = 10**6;
    uint256 public constant MAX_ACTIVE_FUNDINGS = 16;

    // token pool fields
    BermudaPool private immutable _stakingPool;
    BermudaPool private immutable _unlockedPool;
    BermudaPool private immutable _lockedPool;
    Funding[] public fundings;

    // user staking fields
    mapping(address => User) public userTotals;
    mapping(address => Stake[]) public userStakes;

    // time bonus fields
    uint256 public immutable bonusMin;
    uint256 public immutable bonusMax;
    uint256 public immutable bonusPeriod;

    // global state fields
    uint256 public totalLockedShares;
    uint256 public totalStakingShares;
    uint256 public totalRewards;
    uint256 public totalTakoRewards;
    uint256 public totalStakingShareSeconds;
    uint256 public lastUpdated;

    // tako fields
    IERC20 private immutable _tako;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public BURN_FEE = 0; // 0%

    /**
     * @param stakingToken_ the token that will be staked
     * @param rewardToken_ the token distributed to users as they unstake
     * @param bonusMin_ initial time bonus
     * @param bonusMax_ maximum time bonus
     * @param bonusPeriod_ period (in seconds) over which time bonus grows to max
     * @param tako_ address for Tako token
     */
    constructor(
        address stakingToken_,
        address rewardToken_,
        uint256 bonusMin_,
        uint256 bonusMax_,
        uint256 bonusPeriod_,
        address tako_
    ) public {
        require(
            bonusMin_ <= bonusMax_,
            "Bermuda: initial time bonus greater than max"
        );

        _stakingPool = new BermudaPool(stakingToken_);
        _unlockedPool = new BermudaPool(rewardToken_);
        _lockedPool = new BermudaPool(rewardToken_);

        bonusMin = bonusMin_;
        bonusMax = bonusMax_;
        bonusPeriod = bonusPeriod_;

        _tako = IERC20(tako_);

        lastUpdated = block.timestamp;
    }

    // IStaking

    /**
     * @inheritdoc IStaking
     */
    function stake(uint256 amount) external override {
        _stake(msg.sender, msg.sender, amount);
    }

    /**
     * @inheritdoc IStaking
     */
    function stakeFor(
        address user,
        uint256 amount
    ) external override {
        _stake(msg.sender, user, amount);
    }

    /**
     * @inheritdoc IStaking
     */
    function unstake(uint256 amount) external override {
        _unstake(amount, 0);
    }

    /**
     * @inheritdoc IStaking
     */
    function totalStakedFor(address addr)
        public
        override
        view
        returns (uint256)
    {
        if (totalStakingShares == 0) {
            return 0;
        }
        return
            totalStaked().mul(userTotals[addr].shares).div(totalStakingShares);
    }

    /**
     * @inheritdoc IStaking
     */
    function totalStaked() public override view returns (uint256) {
        return _stakingPool.balance();
    }

    /**
     * @inheritdoc IStaking
     * @dev redundant with stakingToken() in order to implement IStaking (EIP-900)
     */
    function token() external override view returns (address) {
        return address(_stakingPool.token());
    }

    // IBermuda

    /**
     * @inheritdoc IBermuda
     */
    function stakingToken() public override view returns (address) {
        return address(_stakingPool.token());
    }

    /**
     * @inheritdoc IBermuda
     */
    function rewardToken() public override view returns (address) {
        return address(_unlockedPool.token());
    }

    /**
     * @inheritdoc IBermuda
     */
    function fund(uint256 amount, uint256 duration) public override {
        fund(amount, duration, block.timestamp);
    }

    /**
     * @inheritdoc IBermuda
     */
    function fund(
        uint256 amount,
        uint256 duration,
        uint256 start
    ) public override onlyOwner {
        // validate
        require(amount > 0, "Bermuda: funding amount is zero");
        require(start >= block.timestamp, "Bermuda: funding start is past");
        require(
            fundings.length < MAX_ACTIVE_FUNDINGS,
            "Bermuda: exceeds max active funding schedules"
        );

        // update bookkeeping
        _update(msg.sender);

        // mint shares at current rate
        uint256 lockedTokens = totalLocked();
        uint256 mintedLockedShares = (lockedTokens > 0)
            ? totalLockedShares.mul(amount).div(lockedTokens)
            : amount.mul(INITIAL_SHARES_PER_TOKEN);

        totalLockedShares = totalLockedShares.add(mintedLockedShares);

        // create new funding
        fundings.push(
            Funding({
                amount: amount,
                shares: mintedLockedShares,
                unlocked: 0,
                lastUpdated: start,
                start: start,
                end: start.add(duration),
                duration: duration
            })
        );

        // do transfer of funding
        _lockedPool.token().safeTransferFrom(
            msg.sender,
            address(_lockedPool),
            amount
        );
        emit RewardsFunded(amount, duration, start, totalLocked());
    }

    /**
     * @inheritdoc IBermuda
     */
    function withdraw(uint256 amount) external override onlyOwner {
        require(amount > 0, "Bermuda: withdraw amount is zero");
        require(
            amount <= _tako.balanceOf(address(this)),
            "Bermuda: withdraw amount exceeds balance"
        );
        // do transfer
        //Burn a third part of tokens and rest transfer to owner address
        uint256 burnedToken = amount.div(3);
        _tako.safeTransfer(burnAddress, burnedToken);
        _tako.safeTransfer(msg.sender, burnedToken.mul(2));

        emit TakoWithdrawn(amount);
    }

    /**
     * @inheritdoc IBermuda
     */
    function unstake(
        uint256 amount,
        uint256 tako
    ) external override {
        _unstake(amount, tako);
    }

    /**
     * @inheritdoc IBermuda
     */
    function update() external override nonReentrant {
        _update(msg.sender);
    }

    /**
     * @inheritdoc IBermuda
     */
    function clean() external override onlyOwner {
        // update bookkeeping
        _update(msg.sender);

        // check for stale funding schedules to expire
        uint256 removed = 0;
        uint256 originalSize = fundings.length;
        for (uint256 i = 0; i < originalSize; i++) {
            Funding storage funding = fundings[i.sub(removed)];
            uint256 idx = i.sub(removed);

            if (_unlockable(idx) == 0 && block.timestamp >= funding.end) {
                emit RewardsExpired(
                    funding.amount,
                    funding.duration,
                    funding.start
                );

                // remove at idx by copying last element here, then popping off last
                // (we don't care about order)
                fundings[idx] = fundings[fundings.length.sub(1)];
                fundings.pop();
                removed = removed.add(1);
            }
        }
    }

    // Bermuda

    /**
     * @dev internal implementation of staking methods
     * @param staker address to do deposit of staking tokens
     * @param beneficiary address to gain credit for this stake operation
     * @param amount number of staking tokens to deposit
     */
    function _stake(
        address staker,
        address beneficiary,
        uint256 amount
    ) private nonReentrant {
        // validate
        require(amount > 0, "Bermuda: stake amount is zero");
        require(
            beneficiary != address(0),
            "Bermuda: beneficiary is zero address"
        );
        uint256 amountAfterBurn = amount; 

        // mint staking shares at current rate
        uint256 mintedStakingShares = (totalStakingShares > 0)
            ? totalStakingShares.mul(amountAfterBurn).div(totalStaked())
            : amountAfterBurn.mul(INITIAL_SHARES_PER_TOKEN);
        require(mintedStakingShares > 0, "Bermuda: stake amount too small");

        // update bookkeeping
        _update(beneficiary);

        // update user staking info
        User storage user = userTotals[beneficiary];
        user.shares = user.shares.add(mintedStakingShares);
        user.lastUpdated = block.timestamp;

        userStakes[beneficiary].push(
            Stake(mintedStakingShares, block.timestamp)
        );

        // add newly minted shares to global total
        totalStakingShares = totalStakingShares.add(mintedStakingShares);

        // transactions
        _stakingPool.token().safeTransferFrom(
            staker,
            address(_stakingPool),
            amountAfterBurn
        );

        emit Staked(beneficiary, amountAfterBurn, totalStakedFor(beneficiary), "");
    }

    /**
     * @dev internal implementation of unstaking methods
     * @param amount number of tokens to unstake
     * @param tako number of TAKO tokens applied to unstaking operation
     * @return number of reward tokens distributed
     */
    function _unstake(uint256 amount, uint256 tako)
        private
        nonReentrant
        returns (uint256)
    {
        // validate
        require(amount > 0, "Bermuda: unstake amount is zero");
        require(
            totalStakedFor(msg.sender) >= amount,
            "Bermuda: unstake amount exceeds balance"
        );

        // update bookkeeping
        _update(msg.sender);

        // do unstaking, first-in last-out, respecting time bonus
        uint256 timeWeightedShareSeconds = _unstakeFirstInLastOut(amount);

        // compute and apply TAKO token bonus
        uint256 takoWeightedShareSeconds = takoBonus(tako)
            .mul(timeWeightedShareSeconds)
            .div(10**BONUS_DECIMALS);

        uint256 rewardAmount = totalUnlocked()
            .mul(takoWeightedShareSeconds)
            .div(totalStakingShareSeconds.add(takoWeightedShareSeconds));

        // update global stats for distributions
        if (tako > 0) {
            totalTakoRewards = totalTakoRewards.add(rewardAmount);
        }
        totalRewards = totalRewards.add(rewardAmount);

        // transactions
        _stakingPool.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), "");
        if (rewardAmount > 0) {
            _unlockedPool.transfer(msg.sender, rewardAmount);
            emit RewardsDistributed(msg.sender, rewardAmount);
        }
        if (tako > 0) {
            _tako.safeTransferFrom(msg.sender, address(this), tako);
            emit TakoSpent(msg.sender, tako);
        }
        return rewardAmount;
    }

    /**
     * @dev helper function to actually execute unstaking, first-in last-out, 
     while computing and applying time bonus. This function also updates
     user and global totals for shares and share-seconds.
     * @param amount number of staking tokens to withdraw
     * @return time bonus weighted staking share seconds
     */
    function _unstakeFirstInLastOut(uint256 amount) private returns (uint256) {
        uint256 stakingSharesToBurn = totalStakingShares.mul(amount).div(
            totalStaked()
        );
        require(stakingSharesToBurn > 0, "Bermuda: unstake amount too small");

        // redeem from most recent stake and go backwards in time.
        uint256 shareSecondsToBurn = 0;
        uint256 sharesLeftToBurn = stakingSharesToBurn;
        uint256 bonusWeightedShareSeconds = 0;
        Stake[] storage stakes = userStakes[msg.sender];
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = stakes[stakes.length - 1];
            uint256 stakeTime = block.timestamp.sub(lastStake.timestamp);

            uint256 bonus = timeBonus(stakeTime);

            if (lastStake.shares <= sharesLeftToBurn) {
                // fully redeem a past stake
                bonusWeightedShareSeconds = bonusWeightedShareSeconds.add(
                    lastStake.shares.mul(stakeTime).mul(bonus).div(
                        10**BONUS_DECIMALS
                    )
                );
                shareSecondsToBurn = shareSecondsToBurn.add(
                    lastStake.shares.mul(stakeTime)
                );
                sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.shares);
                stakes.pop();
            } else {
                // partially redeem a past stake
                bonusWeightedShareSeconds = bonusWeightedShareSeconds.add(
                    sharesLeftToBurn.mul(stakeTime).mul(bonus).div(
                        10**BONUS_DECIMALS
                    )
                );
                shareSecondsToBurn = shareSecondsToBurn.add(
                    sharesLeftToBurn.mul(stakeTime)
                );
                lastStake.shares = lastStake.shares.sub(sharesLeftToBurn);
                sharesLeftToBurn = 0;
            }
        }
        // update user totals
        User storage user = userTotals[msg.sender];
        user.shareSeconds = user.shareSeconds.sub(shareSecondsToBurn);
        user.shares = user.shares.sub(stakingSharesToBurn);
        user.lastUpdated = block.timestamp;

        // update global totals
        totalStakingShareSeconds = totalStakingShareSeconds.sub(
            shareSecondsToBurn
        );
        totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);

        return bonusWeightedShareSeconds;
    }

    /**
     * @dev internal implementation of update method
     * @param addr address for user accounting update
     */
    function _update(address addr) private {
        _unlockTokens();

        // global accounting
        uint256 deltaTotalShareSeconds = (block.timestamp.sub(lastUpdated)).mul(
            totalStakingShares
        );
        totalStakingShareSeconds = totalStakingShareSeconds.add(
            deltaTotalShareSeconds
        );
        lastUpdated = block.timestamp;

        // user accounting
        User storage user = userTotals[addr];
        uint256 deltaUserShareSeconds = (block.timestamp.sub(user.lastUpdated))
            .mul(user.shares);
        user.shareSeconds = user.shareSeconds.add(deltaUserShareSeconds);
        user.lastUpdated = block.timestamp;
    }

    /**
     * @dev unlocks reward tokens based on funding schedules
     */
    function _unlockTokens() private {
        uint256 tokensToUnlock = 0;
        uint256 lockedTokens = totalLocked();

        if (totalLockedShares == 0) {
            // handle any leftover
            tokensToUnlock = lockedTokens;
        } else {
            // normal case: unlock some shares from each funding schedule
            uint256 sharesToUnlock = 0;
            for (uint256 i = 0; i < fundings.length; i++) {
                uint256 shares = _unlockable(i);
                Funding storage funding = fundings[i];
                if (shares > 0) {
                    funding.unlocked = funding.unlocked.add(shares);
                    funding.lastUpdated = block.timestamp;
                    sharesToUnlock = sharesToUnlock.add(shares);
                }
            }
            tokensToUnlock = sharesToUnlock.mul(lockedTokens).div(
                totalLockedShares
            );
            totalLockedShares = totalLockedShares.sub(sharesToUnlock);
        }

        if (tokensToUnlock > 0) {
            _lockedPool.transfer(address(_unlockedPool), tokensToUnlock);
            emit RewardsUnlocked(tokensToUnlock, totalUnlocked());
        }
    }

    /**
     * @dev helper function to compute updates to funding schedules
     * @param idx index of the funding
     * @return the number of unlockable shares
     */
    function _unlockable(uint256 idx) private view returns (uint256) {
        Funding storage funding = fundings[idx];

        // funding schedule is in future
        if (block.timestamp < funding.start) {
            return 0;
        }
        // empty
        if (funding.unlocked >= funding.shares) {
            return 0;
        }
        // handle zero-duration period or leftover dust from integer division
        if (block.timestamp >= funding.end) {
            return funding.shares.sub(funding.unlocked);
        }

        return
            (block.timestamp.sub(funding.lastUpdated)).mul(funding.shares).div(
                funding.duration
            );
    }

    /**
     * @notice compute time bonus earned as a function of staking time
     * @param time length of time for which the tokens have been staked
     * @return bonus multiplier for time
     */
    function timeBonus(uint256 time) public view returns (uint256) {
        if (time >= bonusPeriod) {
            return uint256(10**BONUS_DECIMALS).add(bonusMax);
        }

        // linearly interpolate between bonus min and bonus max
        uint256 bonus = bonusMin.add(
            (bonusMax.sub(bonusMin)).mul(time).div(bonusPeriod)
        );
        return uint256(10**BONUS_DECIMALS).add(bonus);
    }

    /**
     * @notice compute TAKO bonus as a function of usage ratio and TAKO spent
     * @param tako number of TAKO token applied to bonus
     * @return multiplier value
     */
    function takoBonus(uint256 tako) public view returns (uint256) {
        if (tako == 0) {
            return 10**BONUS_DECIMALS;
        }
        require(
            tako >= 10**BONUS_DECIMALS,
            "BERMUDA: TAKO amount is between 0 and 1"
        );

        uint256 buffer = uint256(10**(BONUS_DECIMALS - 2)); // 0.01
        uint256 r = ratio().add(buffer);
        uint256 x = tako.add(buffer);

        return
            uint256(10**BONUS_DECIMALS).add(
                uint256(int128(x.mul(2**64).div(r)).logbase10())
                    .mul(10**BONUS_DECIMALS)
                    .div(2**64)
            );
    }

    /**
     * @return portion of rewards which have been boosted by TAKO token
     */
    function ratio() public view returns (uint256) {
        if (totalRewards == 0) {
            return 0;
        }
        return totalTakoRewards.mul(10**BONUS_DECIMALS).div(totalRewards);
    }

    // Bermuda -- informational functions

    /**
     * @return total number of locked reward tokens
     */
    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }

    /**
     * @return total number of unlocked reward tokens
     */
    function totalUnlocked() public view returns (uint256) {
        return _unlockedPool.balance();
    }

    /**
     * @return number of active funding schedules
     */
    function fundingCount() public view returns (uint256) {
        return fundings.length;
    }

    /**
     * @param addr address of interest
     * @return number of active stakes for user
     */
    function stakeCount(address addr) public view returns (uint256) {
        return userStakes[addr].length;
    }

    /**
     * @notice preview estimated reward distribution for full unstake with no TAKO applied
     * @return estimated reward
     * @return estimated overall multiplier
     * @return estimated raw user share seconds that would be burned
     * @return estimated total unlocked rewards
     */
    function preview()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return preview(msg.sender, totalStakedFor(msg.sender), 0);
    }

    /**
     * @notice preview estimated reward distribution for unstaking
     * @param addr address of interest for preview
     * @param amount number of tokens that would be unstaked
     * @param tako number of TAKO tokens that would be applied
     * @return estimated reward
     * @return estimated overall multiplier
     * @return estimated raw user share seconds that would be burned
     * @return estimated total unlocked rewards
     */
    function preview(
        address addr,
        uint256 amount,
        uint256 tako
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // compute expected updates to global totals
        uint256 deltaUnlocked = 0;
        if (totalLockedShares != 0) {
            uint256 sharesToUnlock = 0;
            for (uint256 i = 0; i < fundings.length; i++) {
                sharesToUnlock = sharesToUnlock.add(_unlockable(i));
            }
            deltaUnlocked = sharesToUnlock.mul(totalLocked()).div(
                totalLockedShares
            );
        }

        // no need for unstaking/rewards computation
        if (amount == 0) {
            return (0, 0, 0, totalUnlocked().add(deltaUnlocked));
        }

        // check unstake amount
        require(
            amount <= totalStakedFor(addr),
            "Bermuda: preview amount exceeds balance"
        );

        // compute unstake amount in shares
        uint256 shares = totalStakingShares.mul(amount).div(totalStaked());
        require(shares > 0, "Bermuda: preview amount too small");

        uint256 rawShareSeconds = 0;
        uint256 timeBonusShareSeconds = 0;

        // compute first-in-last-out, time bonus weighted, share seconds
        uint256 i = userStakes[addr].length.sub(1);
        while (shares > 0) {
            Stake storage s = userStakes[addr][i];
            uint256 time = block.timestamp.sub(s.timestamp);

            if (s.shares < shares) {
                rawShareSeconds = rawShareSeconds.add(s.shares.mul(time));
                timeBonusShareSeconds = timeBonusShareSeconds.add(
                    s.shares.mul(time).mul(timeBonus(time)).div(
                        10**BONUS_DECIMALS
                    )
                );
                shares = shares.sub(s.shares);
            } else {
                rawShareSeconds = rawShareSeconds.add(shares.mul(time));
                timeBonusShareSeconds = timeBonusShareSeconds.add(
                    shares.mul(time).mul(timeBonus(time)).div(
                        10**BONUS_DECIMALS
                    )
                );
                break;
            }
            // this will throw on underflow
            i = i.sub(1);
        }

        // apply tako bonus
        uint256 takoBonusShareSeconds = takoBonus(tako)
            .mul(timeBonusShareSeconds)
            .div(10**BONUS_DECIMALS);

        // compute rewards based on expected updates
        uint256 expectedTotalShareSeconds = totalStakingShareSeconds
            .add((block.timestamp.sub(lastUpdated)).mul(totalStakingShares))
            .add(takoBonusShareSeconds)
            .sub(rawShareSeconds);

        uint256 reward = (totalUnlocked().add(deltaUnlocked))
            .mul(takoBonusShareSeconds)
            .div(expectedTotalShareSeconds);

        // compute effective bonus
        uint256 bonus = uint256(10**BONUS_DECIMALS)
            .mul(takoBonusShareSeconds)
            .div(rawShareSeconds);

        return (
            reward,
            bonus,
            rawShareSeconds,
            totalUnlocked().add(deltaUnlocked)
        );
    }

    function unlockFundInSec(uint256 timestamp) external view returns (uint256 unlockAmount) {
        unlockAmount = 0;
        uint256 fundingLen = fundings.length;
        for (uint8 i=0; i<fundingLen; i++) {
            Funding storage funding = fundings[i];
            if (timestamp < funding.end) {
                unlockAmount = unlockAmount.add((funding.shares).div(funding.duration));
            }
        }
    }
}