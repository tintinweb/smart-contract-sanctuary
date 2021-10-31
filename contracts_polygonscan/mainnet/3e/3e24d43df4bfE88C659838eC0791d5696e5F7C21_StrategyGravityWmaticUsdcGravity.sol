/**
 *Submitted for verification at polygonscan.com on 2021-10-30
*/

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// File: @openzeppelin\contracts\access\Ownable.sol

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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

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

// File: @openzeppelin\contracts\utils\Pausable.sol

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

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol

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

// File: Vault\libs\IGravity.sol

// For interacting with masterchef
interface IGravity {
    // Transfer want tokens vault -> masterchef
    function deposit(uint256 _amount) external;
    
    // Transfer want tokens masterchef -> vault
    function withdraw(uint256 _amount) external;

    //get the amount staked and reward debt for user
    function userInfo(address _address) external view returns (uint256, uint256);
    
    //Emergency withdraw from the pools leaving out any pending harvest
    function emergencyWithdraw() external;
}

// File: Vault\libs\IUniPair.sol

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// File: Vault\libs\IUniRouter01.sol

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

// File: Vault\libs\IUniRouter02.sol

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

// File: Vault\libs\IStrategySirius.sol

interface IStrategySirius {
    function depositReward(uint256 _depositAmt) external returns (bool);
}

// File: Vault\Operators.sol

contract Operators is Ownable {
    mapping(address => bool) public operators;

    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }
}

// File: Vault\StrategyFeesBase.sol

abstract contract StrategyFeesBase is Ownable, ReentrancyGuard, Pausable, Operators {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public wantAddress;
    address public earnedAddress;    
    address public uniRouterAddress;

    address public constant quickRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address public constant siriusAddress = address(0x00b1289f48e8d8ad1532e83a8961f6e8b5a134661d);
    address public constant wmaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    
    address public constant rewardAddress = 0x87C1Fb68428756CDd04709910AFa601F7DDd5a31;
    address public constant vaultAddress = 0x3c746568A42DaB6f576B94734D0C2199b486F916;
    address public constant feeAddress = 0xC5be13105b002aC1fcA10C066893be051Bbb90d3;

    address public vaultChefAddress = 0x2e620B2844E43004d095959A31B7ae9f9dbbb830;

    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;
	address public constant zeroAddress = 0x0000000000000000000000000000000000000000;

    uint256 public controllerFee = 25; //0.25%
    uint256 public rewardRate = 0; //0%
    uint256 public buyBackRate = 75; //0.75%
    uint256 public constant feeMaxTotal = 1000;
    uint256 public constant feeMax = 10000; // 100 = 1%
	
    //Withdrawal fees in BP
    uint256 public withdrawalFee = 0; // 0% withdraw fee
    uint256 public constant maxWithdrawalFee = 100; //1%

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public liquiditySlippageFactor = 600; // 40% default liqidity add slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address[] public earnedToWmaticPath;
    address[] public earnedToUsdcPath;
    address[] public earnedToSiriusPath;

    address[] public wmaticToSiriusPath = [address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270), 0xB1289f48E8d8Ad1532e83A8961f6E8b5a134661D];
    address[] public wmaticToUsdcPath =[address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270), address(0x002791bca1f2de4661ed88a30c99a7a9449aa84174)];

    uint256 public  minWMaticAmountToCompound = 1e17;
    uint256 public minEarnedAmountToCompound = 1e17;
    uint256 public deadline = 600;
	
	bool public isBurning = false;

    event DeadlineChanged(uint256 oldDeadline, uint256 newDeadline);
    event SetSettings(
        uint256 controllerFee,
        uint256 rewardRate,
        uint256 buyBackRate,
        uint256 withdrawalFee,
        uint256 slippageFactor,
        uint256 liquiditySlippageFactor
    );

    function changeMinCompoundAmount(uint256 _minWMaticAmountToCompound, uint256 _minEarnedAmountToCompound) external onlyOperator{
        minEarnedAmountToCompound = _minEarnedAmountToCompound;
        minWMaticAmountToCompound = _minWMaticAmountToCompound;
    }
    
    constructor(
        address _wantAddress,
        address _earnedAddress,
        address _uniRouterAddress,
		bool _isBurning
    )  public {

        wantAddress = _wantAddress;
        earnedAddress = _earnedAddress;
        uniRouterAddress = _uniRouterAddress;
		
		isBurning = _isBurning;

        transferOwnership(vaultChefAddress);
    }

    // To pay for earn function
    function distributeFees(address _earnedAddress) internal {
        uint256 earnedAmt = IERC20(_earnedAddress).balanceOf(address(this));
        
        if (controllerFee > 0 && earnedAmt >0) {
            uint256 fee = earnedAmt.mul(controllerFee).div(feeMax);

            if (_earnedAddress == wmaticAddress) {
                IWETH(wmaticAddress).withdraw(fee);
                safeTransferETH(feeAddress, fee);
            } else {
                _safeSwap(
                    fee,
                    earnedToWmaticPath,
                    feeAddress
                );
            }
        }
    }

    function distributeRewards(address _earnedAddress) internal {
        uint256 earnedAmt = IERC20(_earnedAddress).balanceOf(address(this));
        
        if (rewardRate > 0 && earnedAmt > 0) {
            uint256 fee = earnedAmt.mul(rewardRate).div(feeMax);
    
            uint256 usdcBefore = IERC20(usdcAddress).balanceOf(address(this));
            _safeSwap(
                fee,
                _earnedAddress == wmaticAddress ? wmaticToUsdcPath : earnedToUsdcPath,
                address(this)
            );
            
            uint256 usdcConverted = IERC20(usdcAddress).balanceOf(address(this)).sub(usdcBefore);
            
            approve(usdcAddress, rewardAddress, usdcConverted);
            IStrategySirius(rewardAddress).depositReward(usdcConverted);
        }
    }

    function buyBack(address _earnedAddress) internal {
        uint256 earnedAmt = IERC20(_earnedAddress).balanceOf(address(this));
        
        if (buyBackRate > 0 && earnedAmt > 0) {
            uint256 buyBackAmt = earnedAmt.mul(buyBackRate).div(feeMax);
            if(_earnedAddress == siriusAddress){
                IERC20(siriusAddress).transfer(buyBackAddress, buyBackAmt);
				return;
            }
			
			if(!isBurning){
				//Send to vault address. Used to setup the burning vault
				IERC20(_earnedAddress).transfer(vaultAddress, buyBackAmt);
				return;				
			}			
			
			//Convert earned to wmatic using uniRouter if earned is not wmatic
			if(_earnedAddress != wmaticAddress){
			    uint256 wmaticBefore = IERC20(wmaticAddress).balanceOf(address(this));
			    _safeSwap(
                    buyBackAmt,
					earnedToWmaticPath,
                    address(this)
                );
				uint256 wmaticAfter = IERC20(wmaticAddress).balanceOf(address(this));
				buyBackAmt = wmaticAfter.sub(wmaticBefore);
			}
			
			//Buy SIRIUS using quick router. Because our main liquidity is with quickswap and uniRouter 
            //may not be same as quickRouter
            _safeSwapQuick(
                buyBackAmt,
                wmaticToSiriusPath,
                buyBackAddress
            );
        }
    }

   
    function setSettings(
        uint256 _controllerFee,
        uint256 _rewardRate,
        uint256 _buyBackRate,
        uint256 _withdrawalFee,
        uint256 _slippageFactor,
        uint256 _liquiditySlippageFactor
    ) external virtual onlyOperator {
        if(!isBurning){		    
			require(_controllerFee.add(_rewardRate).add(_buyBackRate) <= feeMaxTotal, "Max fee of 10%");
		}else{
			//Burning vaults can have up to 100% buybackRate
			require(_controllerFee.add(_rewardRate).add(_buyBackRate) <= 10000, "Max fee of 100%");
		}
        require(_withdrawalFee <= maxWithdrawalFee, "_withdrawFee > maxWithdrawalFee!");
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");
        require(_liquiditySlippageFactor <= slippageFactorUL, "_liquiditySlippageFactor too high");
        controllerFee = _controllerFee;
        rewardRate = _rewardRate;
        buyBackRate = _buyBackRate;
        withdrawalFee = _withdrawalFee;
        slippageFactor = _slippageFactor;
        liquiditySlippageFactor = _liquiditySlippageFactor;

        emit SetSettings(
            _controllerFee,
            _rewardRate,
            _buyBackRate,
            _withdrawalFee,
            _slippageFactor,
            _liquiditySlippageFactor
        );
    }

    function setDeadline(uint256 _deadline) external onlyOperator{
        require(_deadline > 10, 'setDeadline: too small');
        emit DeadlineChanged(deadline, _deadline);
        deadline = _deadline;
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {

        approve(_path[0], uniRouterAddress, _amountIn);

        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(uniRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(deadline)
        );
    }

    function _safeSwapQuick(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        
        approve(_path[0], quickRouterAddress, _amountIn);
        
        uint256[] memory amounts = IUniRouter02(quickRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];
        
        IUniRouter02(quickRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(deadline)
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
	
	function approve(address tokenAddress, address spenderAddress, uint256 amount) internal {
	    IERC20(tokenAddress).safeApprove(spenderAddress, uint256(0));
        IERC20(tokenAddress).safeIncreaseAllowance(
            spenderAddress,
            amount
        );
	}

    receive() external payable {}
}

// File: Vault\libs\IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: Vault\StrategyBase.sol

abstract contract StrategyBase is StrategyFeesBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //For masterchef requiring referrer
    address internal constant referralAddress = 0x97Ddc7d5737A11AF922898312Cc15bf7dA3b4dF9;

    uint256 public lastEarnBlock = block.number;
    uint256 public sharesTotal = 0;

    //Virtual functions specific to each masterchef
    function stake(uint256 _wantAmount)  internal virtual;
    function harvest() internal virtual;
    function unstake(uint256 _amount) internal virtual;
    function earnedToWant() internal virtual;
    function wmaticToWant() internal virtual;
    function emergencyWithdraw() internal virtual;
    function vaultSharesTotal() virtual public view returns (uint256);

    //Masterchef address
    address public masterChef;
    uint256 public pid;
    
    //Minimum interval between for the optimised earn call. uint256(-1) means no earn is called
    uint256 public compoundCycle = 100; 
    
    constructor(
        address _wantAddress,
        address _earnedAddress,
        address _uniRouterAddress,
        address _masterChef,
        uint256 _pid,
		bool _isBurning
    ) StrategyFeesBase(
        _wantAddress,
        _earnedAddress,
        _uniRouterAddress,
		_isBurning
    )  public {        
        masterChef = _masterChef;
        pid = _pid;
    }

    event CompoundCycleChanged(uint256 indexed oldCycle, uint256 indexed newCycle);
    
    function changeCompoundCycle(uint256 _compoundCycle) external onlyOperator nonReentrant whenNotPaused {
        emit CompoundCycleChanged(compoundCycle, _compoundCycle);
        compoundCycle = _compoundCycle;
    }
    
    function deposit(uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {
        // Call must happen before transfer
        uint256 wantLockedBefore = wantLockedTotal();
        
        uint256 balanceBefore = IERC20(wantAddress).balanceOf(address(this));
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );
        uint256 balanceAfter = IERC20(wantAddress).balanceOf(address(this));

        uint256 balanceChange = balanceAfter.sub(balanceBefore);
        if(_wantAmt > balanceChange){
            _wantAmt = balanceChange;
        }

        // Proper deposit amount for tokens with fees, or vaults with deposit fees
        uint256 sharesAdded = _farm(_wantAmt);
        if (sharesTotal > 0) {
            sharesAdded = sharesAdded.mul(sharesTotal).div(wantLockedBefore);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        return sharesAdded;
    }

    function _farm(uint256 _wantAmt) internal returns (uint256) {
        if (_wantAmt == 0) return 0;
        
        uint256 sharesBefore = vaultSharesTotal();
        approve(wantAddress, masterChef, _wantAmt);        
        stake(_wantAmt);
        uint256 sharesAfter = vaultSharesTotal();
        
        return sharesAfter.sub(sharesBefore);
    }

    function withdraw(uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "_wantAmt is 0");
        
        uint256 balance = IERC20(wantAddress).balanceOf(address(this));
        
        // Check if strategy has tokens from panic
        if (_wantAmt > balance) {
            unstake(_wantAmt.sub(balance));
            balance = IERC20(wantAddress).balanceOf(address(this));
        }

        if (_wantAmt > balance) {
            _wantAmt = balance;
        }

        if (_wantAmt > wantLockedTotal()) {
            _wantAmt = wantLockedTotal();
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal());
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        
        // Withdraw fee
        uint256 withdrawFee = _wantAmt
            .mul(withdrawalFee)
            .div(10000);

        IERC20(wantAddress).safeTransfer(vaultAddress, withdrawFee);  
        _wantAmt = _wantAmt.sub(withdrawFee);
        IERC20(wantAddress).safeTransfer(vaultChefAddress, _wantAmt);

        return sharesRemoved;
    }

    //To be called from vault chef for bulk earn to save gas fees and optimise returns
    function optimisedEarn() external nonReentrant whenNotPaused onlyOwner {
        //optimisedEarn disabled
        if(compoundCycle == uint256(-1)){
            return;
        }
        if(block.number > lastEarnBlock.add(compoundCycle)){
            _earn();
        }
    }

    //Calling directly by operator, for individual calls of the compound function
    function earn() external nonReentrant whenNotPaused onlyOperator{
        _earn();
    }

    function _earn() internal {
        harvest();

        //Convert wmatic token to want
        uint256 wmaticAmt = IERC20(wmaticAddress).balanceOf(address(this));
		uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
		
		//The second check to avoid ditributing fees, rewards and buyback multiple times
        if (wmaticAmt > minWMaticAmountToCompound && earnedAmt > minEarnedAmountToCompound) {
            //distribute fees and buy back
            distributeFees(wmaticAddress);
            distributeRewards(wmaticAddress);
            buyBack(wmaticAddress);

            //convert wmatic token to want token
            wmaticToWant();
        }

        //Convert earned token to want        
        if (earnedAmt > minEarnedAmountToCompound) {
            //distribute fees and buy back
            distributeFees(earnedAddress);
            distributeRewards(earnedAddress);
            buyBack(earnedAddress);

            //convert earned token to want token
            earnedToWant();
        }
    
        lastEarnBlock = block.number;
        
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        _farm(wantAmt);
    }

    // Emergency!!
    function pause() external onlyOperator {
        _pause();
    }

    // False alarm
    function unpause() external onlyOperator {
        _unpause();
    }   

    function wantLockedTotal() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this))
        .add(vaultSharesTotal());
    }

    function panic() external onlyOperator {
        _pause();
        unstake(vaultSharesTotal());
    }

    function emergencyPanic() external  virtual onlyOperator {
        _pause();
        emergencyWithdraw();
    }

    function unpanic() external onlyOperator {
        _unpause();
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        _farm(wantAmt);
    }
}

// File: Vault\StrategyLPBase.sol

abstract contract StrategyLPBase is StrategyBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public token0Address;
    address public token1Address;

    
    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;
    address[] public wmaticToToken0Path;
    address[] public wmaticToToken1Path;

    constructor(
        address _wantAddress,
        address _earnedAddress,
        address _uniRouterAddress,
        address _masterChef,
        uint256 _pid,
		bool _isBurning
    ) StrategyBase(
        _wantAddress,
        _earnedAddress,
        _uniRouterAddress,
        _masterChef,
        _pid,
		_isBurning
    )  public {
        token0Address = IUniPair(wantAddress).token0();
        token1Address = IUniPair(wantAddress).token1();
    }

    function wmaticToWant() internal virtual override{
        uint256 wmaticAmt = IERC20(wmaticAddress).balanceOf(address(this));
        if (wmaticAddress != token0Address) {
            // Swap half of wmatic to token0
            _safeSwap(
                    wmaticAmt.div(2),
                    wmaticToToken0Path,
                    address(this)
            );
        }
    
        if (wmaticAddress != token1Address) {
            // Swap half earned to token1
            _safeSwap(
                wmaticAmt.div(2),
                wmaticToToken1Path,
                address(this)
            );
        }
        //No need to add liquidity here. This will be picked up by calls in earnedToWant
    }
    
    function earnedToWant() internal virtual override{
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if(earnedAmt > 0){
            if (earnedAddress != token0Address) {
                // Swap half earned to token0
                _safeSwap(
                    earnedAmt.div(2),
                    earnedToToken0Path,
                    address(this)
                );
            }
    
            if (earnedAddress != token1Address) {
                // Swap half earned to token1
                _safeSwap(
                    earnedAmt.div(2),
                    earnedToToken1Path,
                    address(this)
                );
            }
    
            // Get want tokens, ie. add liquidity
            uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
            uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
            approve(token0Address, uniRouterAddress, token0Amt);
            approve(token1Address, uniRouterAddress, token1Amt);

            if (token0Amt > 0 && token1Amt > 0) {            
                 IUniRouter02(uniRouterAddress).addLiquidity(
                    token0Address,
                    token1Address,
                    token0Amt,
                    token1Amt,
                    token0Amt.mul(liquiditySlippageFactor).div(1000),
                    token1Amt.mul(liquiditySlippageFactor).div(1000), 
                    address(this),
                    now.add(deadline)
                );
            }
        }
    }

    function convertDustToEarned() external nonReentrant whenNotPaused {
        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        if (token0Amt > 0 && token0Address != earnedAddress) {
            // Swap all dust tokens to earned tokens
            _safeSwap(
                token0Amt,
                token0ToEarnedPath,
                address(this)
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token1Amt > 0 && token1Address != earnedAddress) {
            // Swap all dust tokens to earned tokens
           _safeSwap(
                token1Amt,
                token1ToEarnedPath,
                address(this)
            );
        }
    }    
}

// File: Vault\StrategyGravityWmaticUsdcGravity.sol

// openzeppelin v3.1.0

contract StrategyGravityWmaticUsdcGravity is StrategyLPBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(
        address _wantAddress,
        address _earnedAddress,
        address _uniRouterAddress,
        address _masterChef,
        uint256 _pid,
		bool _isBurning
    ) StrategyLPBase(
        _wantAddress,
        _earnedAddress,
        _uniRouterAddress,
        _masterChef,
        _pid,
		_isBurning
    ) public {
	
	    //Only the paths, constructor arguments and possibly the masterChef interface differ for each farm
        earnedToWmaticPath = [address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381), address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270)];        
        earnedToUsdcPath = [address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381), address(0x002791bca1f2de4661ed88a30c99a7a9449aa84174)];
        earnedToSiriusPath = [address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381), address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270), address(0x00b1289f48e8d8ad1532e83a8961f6e8b5a134661d)];
        earnedToToken0Path = [address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381), address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270)];
        earnedToToken1Path = [address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381), address(0x002791bca1f2de4661ed88a30c99a7a9449aa84174)];
        token0ToEarnedPath = [address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270), address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381)];
        token1ToEarnedPath = [address(0x002791bca1f2de4661ed88a30c99a7a9449aa84174), address(0x00874e178a2f3f3f9d34db862453cd756e7eab0381)];
        wmaticToToken0Path = [address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270)];
        wmaticToToken1Path = [address(0x000d500b1d8e8ef31e21c99d1db9a6444d3adf1270), address(0x002791bca1f2de4661ed88a30c99a7a9449aa84174)];
    }
    
    function stake(uint256 _wantAmount) internal virtual override{
        IGravity(masterChef).deposit(_wantAmount);
    }

    function harvest() internal virtual override{
        IGravity(masterChef).deposit(0);
    }

    function unstake(uint256 _amount) internal virtual override{
        IGravity(masterChef).withdraw(_amount);
    } 
    function emergencyWithdraw() internal virtual override onlyOperator {
        IGravity(masterChef).emergencyWithdraw();
    }   
    
    function vaultSharesTotal() public virtual override view returns (uint256) {
        (uint256 balance,) = IGravity(masterChef).userInfo(address(this));
        return balance;
    } 
}