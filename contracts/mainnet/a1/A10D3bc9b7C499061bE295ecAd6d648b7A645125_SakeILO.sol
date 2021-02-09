/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Pausable.sol


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

// File: contracts/sakeswap/interfaces/ISakeSwapFactory.sol

pragma solidity >=0.5.0;

interface ISakeSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// File: contracts/sakeswap/interfaces/ISakeSwapRouter.sol

pragma solidity >=0.6.2;

interface ISakeSwapRouter {
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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH
        );

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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB
        );

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
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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
        uint256 deadline,
        bool ifmint
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external;
}

// File: contracts/sakeswap/interfaces/ISakeSwapPair.sol

pragma solidity >=0.5.0;

interface ISakeSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function stoken() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function dealSlippageWithIn(address[] calldata path, uint amountIn, address to, bool ifmint) external returns (uint amountOut);
    function dealSlippageWithOut(address[] calldata path, uint amountOut, address to, bool ifmint) external returns (uint extra);
    function getAmountOutMarket(address token, uint amountIn) external view returns (uint _out, uint t0Price);
    function getAmountInMarket(address token, uint amountOut) external view returns (uint _in, uint t0Price);
    function getAmountOutFinal(address token, uint256 amountIn) external view returns (uint256 amountOut, uint256 stokenAmount);
    function getAmountInFinal(address token, uint256 amountOut) external view returns (uint256 amountIn, uint256 stokenAmount);
    function getTokenMarketPrice(address token) external view returns (uint price);
}

// File: contracts/sakeswap/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/sakeswap/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/ILO/SakeILO.sol

pragma solidity 0.6.12;












contract SakeILO is Ownable, Pausable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
   
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public SAKE = 0x066798d9ef0833ccc719076Dab77199eCbd178b0; 
    ISakeSwapFactory public sakeFactory = ISakeSwapFactory(0x75e48C954594d64ef9613AeEF97Ad85370F13807);
    ISakeSwapRouter public sakeRouter = ISakeSwapRouter(0x9C578b573EdE001b95d51a55A3FAfb45f5608b1f);

    IERC20 public projectPartyToken;
    IERC20 public contributionToken;

    uint256 public fundraisingStartTimestamp;
    uint256 public fundraisingDurationDays;

    uint256 public totalProjectPartyFund;   // amount of project party token, set ratio 
    uint256 public maxPoolContribution;     // hard cap
    uint256 public minPoolContribution;     // soft cap
    uint256 public minInvestorContribution; // min amount for each investor to contribute
    uint256 public maxInvestorContribution; // max amount for each investor to contribute
    uint256 public minSakeHolder;

    address public projectPartyAddress;
    bool public projectPartyFundDone = false;
    bool public projectPartyRefundDone = false; 
    uint256 public totalInvestorContributed = 0;
    mapping (address => uint256) public investorContributed; // how much each investor contributed
    uint256 public investorsCount;
    uint256 public transfersCount; 
 
    uint256 public lpLockPeriod;
    uint256 public lpUnlockFrequency;
    uint256 public lpUnlockFeeRatio;
    address public feeAddress;

    uint256 public totalLPCreated = 0;  // lp created amount by add liquidity to sakeswap  
    uint256 public perUnlockLP = 0;     // lp unlock amount each time
    uint256 public lpUnlockStartTimestamp = 0;
    mapping (address => uint256) public investorUnlockedLPTimes;  // how many times to unlock lp of each adddress  
    uint256 public projectPartUnlockedLPTimes;

    address public factory;

    event Contribution(address indexed user, uint256 value);
    event UnlockLP(address indexed user, uint256 lpAmount, uint256 feeAmount);
    event Refund(address indexed user, uint256 value);

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    constructor() public {
        factory = msg.sender;
    }

    function initialize(address _projectPartyToken, address _contributionToken, uint256 _fundraisingDurationDays, 
        uint256 _totalProjectPartyFund, uint256 _maxPoolContribution, uint256 _minPoolContribution, address _owner) external whenNotPaused {

        require(msg.sender == factory, "not factory address");
        projectPartyToken = IERC20(_projectPartyToken);
        contributionToken = IERC20(_contributionToken);
        fundraisingDurationDays = _fundraisingDurationDays * 1 days;
        totalProjectPartyFund = _totalProjectPartyFund;
        maxPoolContribution = _maxPoolContribution;
        minPoolContribution = _minPoolContribution;
        transferOwnership(_owner);
    }

    function setParams(uint256 minInContribution, uint256 maxInContribution, uint256 lockPeriod, uint256 unlockFrequency, uint256 feeRatio, 
        address feeTo, uint256 minSake, uint256 startTimestamp) external onlyOwner whenNotPaused {

        require(lpUnlockStartTimestamp == 0, "add liquidity finished");
        require(minInContribution <= maxInContribution && minInContribution > 0, "invalid investor contribution");
        require(lockPeriod > 0 && unlockFrequency > 0 , "zero period");
        require(lockPeriod >= unlockFrequency, "invalid period");
        require(startTimestamp > block.timestamp, "invalid start time");
        require(feeRatio >= 0 && feeRatio < 100, "invalid fee ratio");
        minInvestorContribution = minInContribution;
        maxInvestorContribution = maxInContribution;
        lpLockPeriod = lockPeriod * 1 days;
        lpUnlockFrequency = unlockFrequency * 1 days;
        lpUnlockFeeRatio = feeRatio; 
        feeAddress = feeTo;
        minSakeHolder = minSake;
        fundraisingStartTimestamp = startTimestamp;
    }

    function setPoolParams(uint256 _fundraisingDurationDays,  uint256 _totalProjectPartyFund, uint256 _maxPoolContribution, uint256 _minPoolContribution)  external onlyOwner whenNotPaused {
        require(projectPartyFundDone == false, "project party fund done");
        require(_totalProjectPartyFund > 0, "invalid project party fund");
        require(_maxPoolContribution >= _minPoolContribution && _minPoolContribution > 0, "invalid pool contribution");
        require(_fundraisingDurationDays > 0, "invalid period");

        fundraisingDurationDays = _fundraisingDurationDays * 1 days;
        totalProjectPartyFund = _totalProjectPartyFund;
        maxPoolContribution = _maxPoolContribution;
        minPoolContribution = _minPoolContribution;
    } 

    /**
     * @dev project party contribute token to contract
     * project party should appove token to contract in advance
     * project party must call this function before fundraising begin
     * Emits a {Contribution} event.
     */
    function projectPartyFund() external nonReentrant whenNotPaused {
        require(isFundraisingFinished() == false, "fundraising already finished");
        require(projectPartyFundDone == false, "repeatedly operation");
          
        projectPartyAddress = msg.sender;
        projectPartyFundDone = true;
        projectPartyToken.safeTransferFrom(msg.sender, address(this), totalProjectPartyFund);
        emit Contribution(msg.sender, totalProjectPartyFund);  
    }

    /**
     * @dev investor contribute eth to contract
     * Emits a {Contribution} event.
     * msg.value is amount to contribute
     */
    function contributeETH() external whenNotPaused nonReentrant  payable {
        require(WETH == address(contributionToken), "invalid token");
        uint256 cAmount =  contributeInternal(msg.value);
        IWETH(WETH).deposit{value: cAmount}();
        if (msg.value > cAmount){
            TransferHelper.safeTransferETH(msg.sender, msg.value.sub(cAmount));
        } 
        emit Contribution(msg.sender, cAmount);  
    }

    /**
     * @dev investor contribute eth to contract
     * investor should appove token to contract in advance
     * Emits a {Contribution} event.
     *
     * Parameters:
     * - `amount` is amount to contribute 
     */
    function contributeToken(uint256 amount) external nonReentrant whenNotPaused {
        require(WETH != address(contributionToken), "invalid token");
        uint256 cAmount = contributeInternal(amount);
        contributionToken.safeTransferFrom(msg.sender, address(this), cAmount);
        emit Contribution(msg.sender, cAmount);  
    }

    function contributeInternal(uint256 amount) internal returns (uint256)  {
        require(isFundraisingStarted() == true, "fundraising not started");
        require(isFundraisingFinished() == false, "fundraising already finished");
        uint256 contributed = investorContributed[msg.sender];
        require(contributed.add(amount) >= minInvestorContribution && contributed.add(amount) <= maxInvestorContribution, "invalid amount");
        if (minSakeHolder > 0) {
            uint256 sakeAmount = IERC20(SAKE).balanceOf(msg.sender);
            require(sakeAmount >= minSakeHolder, "sake insufficient");
        }
        if (contributed == 0) {
            investorsCount = investorsCount + 1; 
        }
        transfersCount = transfersCount + 1;  

        if (totalInvestorContributed.add(amount) <= maxPoolContribution) {
            investorContributed[msg.sender] = contributed.add(amount); 
            totalInvestorContributed = totalInvestorContributed.add(amount); 
            return amount;
        }else{
            uint256 cAmount = maxPoolContribution.sub(totalInvestorContributed);
            investorContributed[msg.sender] = contributed.add(cAmount); 
            totalInvestorContributed = maxPoolContribution;
            return cAmount;
        }
    }

    /**
     * @dev whether fundraising is started
     *
     */
    function isFundraisingStarted() public view returns (bool) {
        return projectPartyFundDone && block.timestamp >= fundraisingStartTimestamp; 
    }

    /**
     * @dev whether fundraising is finished
     *
     */
    function isFundraisingFinished()  public view returns (bool) {
        if (block.timestamp >= fundraisingStartTimestamp.add(fundraisingDurationDays)) {
            return true;
        }
        if (maxPoolContribution == totalInvestorContributed && projectPartyFundDone) {
            return true;
        }
        return false;
    }

    /**
     * @dev whether fundraising is succeed
     *
     */
    function isFundraisingSucceed()  public view returns (bool) {
        require(isFundraisingFinished() == true, "fundraising not finished");
        return projectPartyFundDone && totalInvestorContributed >= minPoolContribution;
    } 

    /**
     * @dev when fundraising is succeed, add liquidity to sakeswap
     * Only callable by the Owner.
     *
     */
    function addLiquidityToSakeSwap() external onlyOwner nonReentrant whenNotPaused {
        require(lpUnlockStartTimestamp == 0, "repeatedly operation");
        require(isFundraisingSucceed() == true, "fundraising not succeeded");

        lpUnlockStartTimestamp = block.timestamp;

        uint256 projectPartyAmount = 0;
        uint256 contributionAmount = 0;
        if (totalInvestorContributed == maxPoolContribution) {
            projectPartyAmount = totalProjectPartyFund;
            contributionAmount = maxPoolContribution; 
        }else{
            projectPartyAmount = totalProjectPartyFund.mul(totalInvestorContributed).div(maxPoolContribution);
            uint256 redundant = totalProjectPartyFund.sub(projectPartyAmount); 
            contributionAmount = totalInvestorContributed;
            projectPartyToken.transfer(projectPartyAddress, redundant);  
        }
        projectPartyToken.approve(address(sakeRouter), projectPartyAmount);
        contributionToken.approve(address(sakeRouter), contributionAmount);
        (, , totalLPCreated) = sakeRouter.addLiquidity(
            address(projectPartyToken),
            address(contributionToken),
            projectPartyAmount,
            contributionAmount,
            0,
            0,
            address(this),
            now + 60
        );
        require(totalLPCreated != 0 , "add liquidity failed");
        perUnlockLP = totalLPCreated.div(lpLockPeriod.div(lpUnlockFrequency));
    }

    function setSakeAddress(address _sakeRouter, address _sakeFactory, address _weth, address _sake) external onlyOwner {
        sakeFactory = ISakeSwapFactory(_sakeFactory);
        sakeRouter = ISakeSwapRouter(_sakeRouter);
        WETH = _weth;
        SAKE = _sake;
    } 

    /**
     * @dev if fundraising is fail, refund project party's token
     *
     */
    function projectPartyRefund() external nonReentrant whenNotPaused {
        require(msg.sender == projectPartyAddress, "invalid address");
        require(projectPartyRefundDone == false, "repeatedly operation");
        require(isFundraisingSucceed() == false, "fundraising succeed");
        projectPartyRefundDone = true;
        projectPartyToken.transfer(msg.sender, totalProjectPartyFund); 
    }

    /**
     * @dev if fundraising is fail, refund investor's token
     *
     */
    function investorRefund() external nonReentrant whenNotPaused {
        require(isFundraisingSucceed() == false, "fundraising succeed");

        uint256 amount = investorContributed[msg.sender];
        require(amount > 0, "zero amount");

        investorContributed[msg.sender] = 0; 
        if (WETH == address(contributionToken)){
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(msg.sender, amount);
        }else{
            contributionToken.transfer(msg.sender, amount);
        }
    }

    /**
     * @dev after add liquidity to sakeswap, project party unlock LP periodicity
     *
     */
    function projectPartyUnlockLP() external nonReentrant whenNotPaused {
        require(msg.sender == projectPartyAddress, "invalid address");
        (uint256 availableTimes, uint256 amount) = getUnlockLPAmount(false, msg.sender);
        projectPartUnlockedLPTimes = projectPartUnlockedLPTimes.add(availableTimes);
        unlockLP(amount);
    } 

    /**
     * @dev after investor to sakeswap, investor unlock LP periodicity
     *
     */
    function investorUnlockLP() external nonReentrant whenNotPaused {
        require(investorContributed[msg.sender] > 0, "invalid address");
        (uint256 availableTimes, uint256 amount) = getUnlockLPAmount(true, msg.sender);
        investorUnlockedLPTimes[msg.sender] = investorUnlockedLPTimes[msg.sender].add(availableTimes);
        unlockLP(amount);
    } 


    /**
     * @dev Get LP amount to unlock
     * Emits a {UnlockLP} event.
     *
     * Parameters:
     * - `isInvestor` whether caller is project party or investor
     *
     * Returns:
     * - `availableTimes` is frequency times to unlock
     * - `amount` is lp amount to unlock 
     */
    function getUnlockLPAmount(bool isInvestor, address user) public view returns (uint256 availableTimes, uint256 amount) {
        require(lpUnlockStartTimestamp > 0, "add liquidity not finished");

        uint256 totalTimes = 0; 
        if (block.timestamp > lpUnlockStartTimestamp.add(lpLockPeriod)){
            totalTimes = lpLockPeriod.div(lpUnlockFrequency);
        }else{
            totalTimes = (block.timestamp.sub(lpUnlockStartTimestamp)).div(lpUnlockFrequency);      
        }

        if (isInvestor){
            availableTimes = totalTimes.sub(investorUnlockedLPTimes[user]);
            require(availableTimes > 0, "zero amount to unlock");

            uint256 totalRelease = perUnlockLP.mul(availableTimes);
            amount = totalRelease.div(2).mul(investorContributed[user]).div(totalInvestorContributed);
        }else{
            availableTimes = totalTimes.sub(projectPartUnlockedLPTimes);
            require(availableTimes > 0, "zero amount to unlock");

            uint256 totalRelease = perUnlockLP.mul(availableTimes);
            amount = totalRelease.div(2);    
        }
    } 

    function unlockLP(uint256 amount) internal {
        uint256 feeAmount = amount.mul(lpUnlockFeeRatio).div(100);
        ISakeSwapPair pair = ISakeSwapPair(sakeFactory.getPair(address(projectPartyToken), address(contributionToken)));
        require(pair != ISakeSwapPair(address(0)), "invalid sake pair");
        require(pair.transfer(feeAddress, feeAmount), "transfer fee fail");
        require(pair.transfer(msg.sender, amount.sub(feeAmount)), "transfer fail");
        emit UnlockLP(msg.sender, amount.sub(feeAmount), feeAmount);
    }

    function setPaused(bool bPause) external nonReentrant onlyOwner {
        if(bPause){
            _pause();
        } else {
            _unpause();
        }
    }
}