/**
 *Submitted for verification at polygonscan.com on 2021-11-02
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/Address.sol
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/math/SafeMath.sol
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/IERC20.sol
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/GSN/Context.sol
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/SafeERC20.sol
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/Pausable.sol
pragma solidity ^0.6.0;
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/ReentrancyGuard.sol
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

// File: contracts/libs/IUniRouter01.sol
pragma solidity 0.6.12;

interface IUniRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/libs/IUniRouter02.sol
pragma solidity 0.6.12;

interface IUniRouter02 is IUniRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/libs/IUniPair.sol
pragma solidity 0.6.12;

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// File: contracts/libs/IDivPool.sol
pragma solidity 0.6.12;

interface IOctagonPool {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
  function emergencyWithdraw() external;
  function userInfo(address _address) external view returns (uint256, uint256);
  function startBlock() external view returns (uint256);
  // Get bonusEndBlock() which is the last value of poolInfo(0)
  function poolInfo(uint256 _pid) external view returns (address, uint256, uint256, uint256, uint16, uint256);
  function rewardPerBlock() external view returns (uint256);
}
// File: contracts/BaseDimStrategy.sol
pragma solidity 0.6.12;

abstract contract BaseDimStrategy is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant timeAddress = 0x5c59D7Cb794471a9633391c4927ADe06B8787a90; // TIME token contract

    address public wantAddress;
    address public transitAddress;
    address public earnedAddress;

    bool public wantIsTransferTax;
    bool public earnedIsTransferTax;

    address public earnedRouterAddress;
    address public wantRouterAddress;
    address public timeRouterAddress;
    address public constant feeAddress = 0x1F7c88A37f7d0B36E7547E3a79c2D04F90531E75; // Fee Address (held by devWallet)
    address public dimChefAddress;
    address public govAddress;

    uint256 public lastTunnelBlock = block.number;
    uint256 public sharesTotal = 0;

    address public constant treasuryAddress = 0x374BD17C475f972D6aF4EA0fAC0744B5500A959F; // Treasury Contract Address, behind 28-day Timelock
    address public constant masterchefAddress = 0x48b4316eBB5EDa7ecae2A4cEFBDFb66841e1EFA5; // TIME MasterChef contract
    address public constant dividendAddress = 0x52e4cf8B72bd0EE362666fc578dB916f20860bBf; // TIME Dividend Address
    address public constant panicTreasuryAddress = 0xA3bf56C34C0457cc3B01D04b624Fe3F66Cd2227e; // TIME Panic Treasury Address

    uint256 public controllerFee = 500;
    uint256 public dividendRate = 500;
    uint256 public buyBackRate = 500;
    uint256 public constant feeMaxTotal = 3000; // Max of 30% performance fees
    uint256 public constant feeMax = 10000;

    uint256 public withdrawFeeFactor = 9990; // 0.1% Withdrawal fees
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9900; // Max 1% withdrawal fee (lower limit)

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;
    uint256 public transferTaxSlippageFactor = 800; // 20% default slippage for transfer tax tokens

    address[] public earnedToWmaticPath;
    address[] public earnedToTransitPath;

    address[] public transitToTimePath;
    address[] public transitToWantPath;
    address[] public transitToEarnedPath;
    address[] public wantToTransitPath;

    event SetSettings(
      uint256 _controllerFee,
      uint256 _dividendRate,
      uint256 _buyBackRate,
      uint256 _withdrawFeeFactor,
      uint256 _slippageFactor
    );

    event ResetAllowances();
    event Pause();
    event Unpause();
    event Panic();
    event SetGov(
      address _govAddress
    );
    event SetTimeRouterAddress(
      address _timeRouterAddress
    );
    event SetWantRouterAddress(
      address _wantRouterAddress
    );
    event SetEarnedRouterAddress(
      address _earnedRouterAddress
    );


    modifier onlyGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }

    function _dimDeposit(uint256 _wantAmount) internal virtual;
    function _dimWithdraw(uint256 _wantAmount) internal virtual;
    function tunnel() external virtual;
    function totalInUnderlying() public virtual view returns (uint256);
    function wantLockedTotal() public virtual view returns (uint256);
    function _resetAllowances() internal virtual;
    function _emergencyDimWithdraw() internal virtual;

    function deposit(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {
        // Call must happen before transfer
        uint256 wantLockedBefore = wantLockedTotal();

        // Transfer from DimChef => DimStrat
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        // Proper deposit amount for tokens with fees, or vaults with deposit fees
        uint256 sharesAdded = _farm();

        if (sharesTotal > 0) {
            sharesAdded = sharesAdded.mul(sharesTotal).div(wantLockedBefore);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        return sharesAdded;
    }

    function _farm() internal returns (uint256) {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (wantAmt == 0) return 0;

        uint256 sharesBefore = totalInUnderlying();
        _dimDeposit(wantAmt);
        uint256 sharesAfter = totalInUnderlying();

        return sharesAfter.sub(sharesBefore);
    }

    function withdraw(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256, uint256) {
        require(_wantAmt > 0, "_wantAmt is 0");

        // Users withdraw shares based of farmedAmt
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));

        // Check if strategy has tokens from panic
        if (_wantAmt > wantAmt) {
            _dimWithdraw(_wantAmt.sub(wantAmt));
            wantAmt = IERC20(wantAddress).balanceOf(address(this));
        }

        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (_wantAmt > wantLockedTotal()) {
            _wantAmt = wantLockedTotal();
        }
        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal());
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);

        uint256 wantWithdrawn = _wantAmt.mul(withdrawFeeFactor).div(withdrawFeeFactorMax);
        uint256 wantFees = _wantAmt.sub(wantWithdrawn);

        if (wantFees > 0 && wantAddress != transitAddress && wantIsTransferTax == false) {
            // Swap withdrawal fees to transit via wantRouter
            _safeSwapWant(
                wantFees,
                wantToTransitPath,
                feeAddress
            );
        }

        if (wantFees > 0 && wantAddress != transitAddress && wantIsTransferTax == true) {
            // Swap withdrawal fees to transit via wantRouter
            _safeSwapWantTransferTaxTokens(
                wantFees,
                wantToTransitPath,
                feeAddress
            );
        }

        IERC20(wantAddress).safeTransfer(dimChefAddress, wantWithdrawn); // Transfer WantWithdrawn to WormChef

        return (sharesRemoved,wantWithdrawn);
    }

    // To pay for earn function, other operating costs that will further grow our protocol
    function distributeFees(uint256 _transitAmt) internal returns (uint256) {
        if (controllerFee > 0) {
            uint256 fee = _transitAmt.mul(controllerFee).div(feeMax);

            IERC20(transitAddress).safeTransferFrom(
                address(this),
                feeAddress,
                fee
            );

            _transitAmt = _transitAmt.sub(fee);
        }

        return _transitAmt;
    }

    // To pay for self-funded dividend pools
    function fundDividends(uint256 _transitAmt) internal returns (uint256) {
        if (dividendRate > 0) {
            uint256 dividend = _transitAmt.mul(dividendRate).div(feeMax);

            IERC20(transitAddress).safeTransferFrom(
                address(this),
                dividendAddress,
                dividend
            );

            _transitAmt = _transitAmt.sub(dividend);
        }

        return _transitAmt;
    }

    function buyBack(uint256 _transitAmt) internal virtual returns (uint256) {
        if (buyBackRate > 0) {
            uint256 buyBackAmt = _transitAmt.mul(buyBackRate).div(feeMax);

            _safeSwapTime(
              buyBackAmt,
              transitToTimePath,
              address(this)
            );

            uint256 timeAmt = IERC20(timeAddress).balanceOf(address(this));

            IERC20(timeAddress).safeTransfer(
                treasuryAddress,
                timeAmt.div(4) // 25% to treasuryAddress
            );

            IERC20(timeAddress).safeTransfer(
                masterchefAddress,
                timeAmt.mul(3).div(4) // 75% TIME to masterchefAddress
            );

            _transitAmt = _transitAmt.sub(buyBackAmt);
        }

        return _transitAmt;
    }

    function resetAllowances() external onlyGov {
        _resetAllowances();

        emit ResetAllowances();
    }

    function pause() external onlyGov {
        _pause();

        emit Pause();
    }

    function unpause() external onlyGov {
        _unpause();
        _farm();

        emit Unpause();
    }

    function panic() external onlyGov {
        _pause();
        _emergencyDimWithdraw();

        IERC20(wantAddress).safeApprove(wantRouterAddress, 0); // Revoke approval

        // Check Want balance in contract after emergencyWithdraw()
        uint256 emergencyWantAmt = IERC20(wantAddress).balanceOf(address(this));
        uint256 emergencyTransitAmt = IERC20(transitAddress).balanceOf(address(this));
        uint256 emergencyEarnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        // Transfer all want & farmed tokens into panic vault for further fair distribution
        if (emergencyWantAmt > 0) {
          IERC20(wantAddress).safeTransfer(panicTreasuryAddress, emergencyWantAmt); // Transfer all want tokens to Panic Treasury
        }
        if (emergencyTransitAmt > 0) {
          IERC20(transitAddress).safeTransfer(panicTreasuryAddress, emergencyTransitAmt); // Transfer all farmed tokens to Panic Treasury
        }
        if (emergencyEarnedAmt > 0) {
          IERC20(earnedAddress).safeTransfer(panicTreasuryAddress, emergencyEarnedAmt); // Transfer all farmed tokens to Panic Treasury
        }

        emit Panic();
    }

    function setGov(address _govAddress) external onlyGov {
        govAddress = _govAddress;

        emit SetGov(
          _govAddress
        );
    }

    function setSettings(
        uint256 _controllerFee,
        uint256 _dividendRate,
        uint256 _buyBackRate,
        uint256 _withdrawFeeFactor,
        uint256 _slippageFactor
    ) external onlyGov {
        require(_withdrawFeeFactor >= withdrawFeeFactorLL, "_withdrawFeeFactor too low");
        require(_withdrawFeeFactor <= withdrawFeeFactorMax, "_withdrawFeeFactor too high");
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");
        require(_controllerFee.add(_dividendRate).add(_buyBackRate) <= feeMaxTotal, "Performance Fees too high");

        controllerFee = _controllerFee;
        dividendRate = _dividendRate;
        buyBackRate = _buyBackRate;
        withdrawFeeFactor = _withdrawFeeFactor;
        slippageFactor = _slippageFactor;

        emit SetSettings(
            _controllerFee,
            _dividendRate,
            _buyBackRate,
            _withdrawFeeFactor,
            _slippageFactor
        );
    }

    function _safeSwapEarned(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(earnedRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        if (_amountIn > 0) {
          IUniRouter02(earnedRouterAddress).swapExactTokensForTokens(
              _amountIn,
              amountOut.mul(slippageFactor).div(1000),
              _path,
              _to,
              now
          );

        }
    }

    function _safeSwapWant(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(wantRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        if (_amountIn > 0) {
          IUniRouter02(wantRouterAddress).swapExactTokensForTokens(
              _amountIn,
              amountOut.mul(slippageFactor).div(1000),
              _path,
              _to,
              now
          );

        }
    }

    function _safeSwapTime(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(timeRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        if (_amountIn > 0) {
          IUniRouter02(timeRouterAddress).swapExactTokensForTokens(
              _amountIn,
              amountOut.mul(slippageFactor).div(1000),
              _path,
              _to,
              now
          );

        }
    }

    function _safeSwapEarnedTransferTaxTokens(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(earnedRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        if (_amountIn > 0) {
          IUniRouter02(earnedRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
              _amountIn,
              amountOut.mul(transferTaxSlippageFactor).div(1000),
              _path,
              _to,
              now
          );
        }
    }

    function _safeSwapWantTransferTaxTokens(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(wantRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        if (_amountIn > 0) {
          IUniRouter02(wantRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
              _amountIn,
              amountOut.mul(transferTaxSlippageFactor).div(1000),
              _path,
              _to,
              now
          );
        }
    }
}

// File: contracts/BaseStrategyLP.sol
pragma solidity 0.6.12;

abstract contract BaseDimStrategyLP is BaseDimStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Safety feature before launching contract
    function convertDustToTime() external nonReentrant whenNotPaused {

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAmt > 0 && earnedAddress != transitAddress && earnedIsTransferTax == false) {
            _safeSwapEarned(
                earnedAmt,
                earnedToTransitPath,
                address(this)
            );
        }

        if (earnedAmt > 0 && earnedAddress != transitAddress && earnedIsTransferTax == true) {
            _safeSwapEarnedTransferTaxTokens(
                earnedAmt,
                earnedToTransitPath,
                address(this)
            );
        }

        uint256 transitBal = IERC20(transitAddress).balanceOf(address(this));
        if (transitBal > 0 && transitAddress != timeAddress) {
            _safeSwapTime(
                transitBal,
                transitToTimePath,
                treasuryAddress
            );
        }

    }
}

// File: contracts/BaseStrategyLPSingle.sol
pragma solidity 0.6.12;

abstract contract BaseDimStrategyLPSingle is BaseDimStrategyLP {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function _dimHarvest() internal virtual;

    function tunnel() external override nonReentrant whenNotPaused onlyGov {
        // Harvest farmed tokens
        _dimHarvest();

        // Converts earned tokens into transit tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAmt > 0 && earnedIsTransferTax == false) {
            // Swap all earned to transit
            uint256 _transitBefore = IERC20(transitAddress).balanceOf(address(this));
            if (earnedAmt > 0 && earnedAddress != transitAddress) {
                // Swap all earned to want via earnedRouter
                _safeSwapEarned(
                    earnedAmt,
                    earnedToTransitPath,
                    address(this)
                );
            }
            uint256 transitAmt = IERC20(transitAddress).balanceOf(address(this)).sub(_transitBefore);

            // Start distributing performance fees
            if (transitAmt > 0) {
              transitAmt = distributeFees(transitAmt);
              transitAmt = fundDividends(transitAmt);
              transitAmt = buyBack(transitAmt);
            }

            // Swap transitAmt back to want, and then restake
            if (transitAmt > 0 && transitAddress != wantAddress && wantIsTransferTax == true) {
                // Swap all transit tokens to want tokens
                _safeSwapWantTransferTaxTokens(
                    transitAmt,
                    transitToWantPath,
                    address(this)
                );

                lastTunnelBlock = block.number;
                _farm();
            }

            // Swap transitAmt back to want, and then restake
            if (transitAmt > 0 && transitAddress != wantAddress && wantIsTransferTax == false) {
                // Swap all transit tokens to want tokens
                _safeSwapWant(
                    transitAmt,
                    transitToWantPath,
                    address(this)
                );

                lastTunnelBlock = block.number;
                _farm();
            }
        }

        if (earnedAmt > 0 && earnedIsTransferTax == true) {
            // Swap all earned to transit
            uint256 _transitBefore = IERC20(transitAddress).balanceOf(address(this));
            if (earnedAmt > 0 && earnedAddress != transitAddress) {
                // Swap all earned to want via earnedRouter
                _safeSwapEarnedTransferTaxTokens(
                    earnedAmt,
                    earnedToTransitPath,
                    address(this)
                );
            }
            uint256 transitAmt = IERC20(transitAddress).balanceOf(address(this)).sub(_transitBefore);

            // Start distributing performance fees
            if (transitAmt > 0) {
              transitAmt = distributeFees(transitAmt);
              transitAmt = fundDividends(transitAmt);
              transitAmt = buyBack(transitAmt);
            }

            // Swap transitAmt back to want, and then restake
            if (transitAmt > 0 && transitAddress != wantAddress && wantIsTransferTax == true) {
                // Swap all transit tokens to want tokens
                _safeSwapWantTransferTaxTokens(
                    transitAmt,
                    transitToWantPath,
                    address(this)
                );

                lastTunnelBlock = block.number;
                _farm();
            }

            // Swap transitAmt back to want, and then restake
            if (transitAmt > 0 && transitAddress != wantAddress && wantIsTransferTax == false) {
                // Swap all transit tokens to want tokens
                _safeSwapWant(
                    transitAmt,
                    transitToWantPath,
                    address(this)
                );

                lastTunnelBlock = block.number;
                _farm();
            }
        }
    }
}


// File: contracts/strategy/DimStrategySingle.sol
pragma solidity 0.6.12;

contract DimStrategyOctagonPear is BaseDimStrategyLPSingle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public stakingRewardsAddress;

    constructor(
        address _dimChefAddress,
        address _stakingRewardsAddress,

        address _earnedRouterAddress,
        address _wantRouterAddress,
        address _timeRouterAddress,

        address _wantAddress,
        address _transitAddress,
        address _earnedAddress,

        bool _wantIsTransferTax,
        bool _earnedIsTransferTax,

        address[] memory _earnedToWmaticPath,
        address[] memory _earnedToTransitPath,

        address[] memory _transitToTimePath,
        address[] memory _transitToWantPath,
        address[] memory _transitToEarnedPath,
        address[] memory _wantToTransitPath

    ) public {
        require(address(_wantAddress) != address(_earnedAddress), "wantAddress and earnedAddress cannot be the same");
        govAddress = msg.sender;
        dimChefAddress = _dimChefAddress;
        stakingRewardsAddress = _stakingRewardsAddress;

        earnedRouterAddress = _earnedRouterAddress;
        wantRouterAddress = _wantRouterAddress;
        timeRouterAddress = _timeRouterAddress;

        wantAddress = _wantAddress;
        transitAddress = _transitAddress;
        earnedAddress = _earnedAddress;

        wantIsTransferTax = _wantIsTransferTax;
        earnedIsTransferTax = _earnedIsTransferTax;

        // earned paths
        earnedToWmaticPath = _earnedToWmaticPath;
        earnedToTransitPath = _earnedToTransitPath;

        // Transit paths
        transitToTimePath = _transitToTimePath;
        transitToWantPath = _transitToWantPath;
        transitToEarnedPath = _transitToEarnedPath;
        wantToTransitPath = _wantToTransitPath;

        transferOwnership(dimChefAddress);

        _resetAllowances();
    }

    // Standard deposit, withdraw, emergencyWithdraw, harvest
    function _dimDeposit(uint256 _wantAmt) internal override {
        IOctagonPool(stakingRewardsAddress).deposit(_wantAmt);
    }

    function _dimWithdraw(uint256 _wantAmt) internal override {
        IOctagonPool(stakingRewardsAddress).withdraw(_wantAmt);
    }

    function _emergencyDimWithdraw() internal override {
        IOctagonPool(stakingRewardsAddress).emergencyWithdraw();
    }

    function _dimHarvest() internal override {
        IOctagonPool(stakingRewardsAddress).withdraw(0);
    }

    // View functions for other calculations
    function totalInUnderlying() public override view returns (uint256) {
        (uint256 wantAmount,) = IOctagonPool(stakingRewardsAddress).userInfo(address(this));
        return wantAmount;
    }

    function wantLockedTotal() public override view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this))
            .add(totalInUnderlying());
    }

    function earnedStartBlock() public view returns (uint256) {
      uint256 startBlock = IOctagonPool(stakingRewardsAddress).startBlock();
      return startBlock;
    }

    function earnedEndBlock() public view returns (uint256) {
      (,,,,,uint256 endBlock) = IOctagonPool(stakingRewardsAddress).poolInfo(0);
      return endBlock;
    }

    function earnedEmissionRate() public view returns (uint256) {
      uint256 emissionRate = IOctagonPool(stakingRewardsAddress).rewardPerBlock();
      return emissionRate;
    }

    function _resetAllowances() internal override {
        // For staking in Div pool
        IERC20(wantAddress).safeApprove(stakingRewardsAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            stakingRewardsAddress,
            uint256(-1)
        );

        // For tunnel() and dust conversion
        IERC20(earnedAddress).safeApprove(earnedRouterAddress, uint256(0));
        IERC20(earnedAddress).safeIncreaseAllowance(
            earnedRouterAddress,
            uint256(-1)
        );

        // For Convert Dust
        IERC20(wantAddress).safeApprove(wantRouterAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            wantRouterAddress,
            uint256(-1)
        );

        // For swapping of USDC or WMATIC to TIME
        IERC20(transitAddress).safeApprove(timeRouterAddress, uint256(0));
        IERC20(transitAddress).safeIncreaseAllowance(
            timeRouterAddress,
            uint256(-1)
        );
        IERC20(transitAddress).safeApprove(timeRouterAddress, uint256(0));
        IERC20(transitAddress).safeIncreaseAllowance(
            timeRouterAddress,
            uint256(-1)
        );

        // For swapping of USDC or WMATIC to want
        IERC20(transitAddress).safeApprove(wantRouterAddress, uint256(0));
        IERC20(transitAddress).safeIncreaseAllowance(
            wantRouterAddress,
            uint256(-1)
        );

        // For swapping of USDC or WMATIC to earned
        IERC20(transitAddress).safeApprove(earnedRouterAddress, uint256(0));
        IERC20(transitAddress).safeIncreaseAllowance(
            earnedRouterAddress,
            uint256(-1)
        );

    }

    function setTimeRouterAddress(address _timeRouterAddress) external onlyGov {
        timeRouterAddress = _timeRouterAddress;

        emit SetTimeRouterAddress(
            _timeRouterAddress
        );
    }

    function setWantRouterAddress(address _wantRouterAddress) external onlyGov {
        wantRouterAddress = _wantRouterAddress;

        emit SetWantRouterAddress(
            _wantRouterAddress
        );
    }

    function setEarnedRouterAddress(address _earnedRouterAddress) external onlyGov {
        earnedRouterAddress = _earnedRouterAddress;

        emit SetEarnedRouterAddress(
            _earnedRouterAddress
        );
    }
}