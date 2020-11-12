// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/utils/Babylonian.sol

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";

pragma solidity ^0.6.12;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// File: interfaces/IUniswapV2Router.sol


pragma solidity ^0.6.12;

interface IUniswapV2Router {
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
    function approve(address guy, uint wad) external returns (bool);
}

// File: interfaces/IUniswapV2Factory.sol

pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

// File: interfaces/IUniswapV2Pair.sol

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address owner) external view returns (uint);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

// File: interfaces/TransferHelper.sol

pragma solidity ^0.6.12;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

// File: contracts/ReefUniswap.sol

pragma solidity ^0.6.12;

library ReefUniswap {
    using SafeMath for uint256;
    using Address for address;

    address public constant uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router private constant uniswapV2Router = IUniswapV2Router(
        uniswapV2RouterAddress
    );

    IUniswapV2Factory private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );


    function _investIntoUniswapPool(
        address _FromTokenContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        address _toAccount,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 token0Bought;
        uint256 token1Bought;

        if (canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)) {
            (token0Bought, token1Bought) = exchangeTokensV2(
                _FromTokenContractAddress,
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                _amount
            );
        }

        require(token0Bought > 0 && token1Bought > 0, "Could not exchange");

        TransferHelper.safeApprove(
            _ToUnipoolToken0,
            address(uniswapV2Router),
            token0Bought
        );

        TransferHelper.safeApprove(
            _ToUnipoolToken1,
            address(uniswapV2Router),
            token1Bought
        );

        (uint256 amountA, uint256 amountB, uint256 LP) = uniswapV2Router
            .addLiquidity(
            _ToUnipoolToken0,
            _ToUnipoolToken1,
            token0Bought,
            token1Bought,
            1,
            1,
            _toAccount,
            now + 60
        );

        uint256 residue;
        if (SafeMath.sub(token0Bought, amountA) > 0) {
            if (canSwapFromV2(_ToUnipoolToken0, _FromTokenContractAddress)) {
                residue = swapFromV2(
                    _ToUnipoolToken0,
                    _FromTokenContractAddress,
                    SafeMath.sub(token0Bought, amountA)
                );
            } else {
                TransferHelper.safeTransfer(
                    _ToUnipoolToken0,
                    msg.sender,
                    SafeMath.sub(token0Bought, amountA)
                );
            }
        }

        if (SafeMath.sub(token1Bought, amountB) > 0) {
            if (canSwapFromV2(_ToUnipoolToken1, _FromTokenContractAddress)) {
                residue += swapFromV2(
                    _ToUnipoolToken1,
                    _FromTokenContractAddress,
                    SafeMath.sub(token1Bought, amountB)
                );
            } else {
                TransferHelper.safeTransfer(
                    _ToUnipoolToken1,
                    msg.sender,
                    SafeMath.sub(token1Bought, amountB)
                );
            }
        }

        if (residue > 0) {
            TransferHelper.safeTransfer(
                _FromTokenContractAddress,
                msg.sender,
                residue
            );
        }

        return LP;
    }

    /**
    @notice This function is used to zapout of given Uniswap pair in the bounded tokens
    @param _token0 Token 0 address
    @param _token1 Token 1 address
    @param _IncomingLP The amount of LP
    @return amountA the amount of first token received after zapout
    @return amountB the amount of second token received after zapout
     */
    function _disinvestFromUniswapPool(
        address _ToTokenContractAddress,
        address _token0,
        address _token1,
        uint256 _IncomingLP
    ) internal returns (uint256 amountA, uint256 amountB) {
        address _FromUniPoolAddress = UniSwapV2FactoryAddress.getPair(
            _token0,
            _token1
        );
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);
        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        TransferHelper.safeApprove(
            _FromUniPoolAddress,
            address(uniswapV2Router),
            _IncomingLP
        );

        if (_token0 == wethTokenAddress || _token1 == wethTokenAddress) {
            address _token = _token0 == wethTokenAddress ? _token1 : _token0;
            address _wethToken = _token0 != wethTokenAddress
                ? _token1
                : _token0;
            (amountA, amountB) = uniswapV2Router.removeLiquidityETH(
                _token,
                _IncomingLP,
                1,
                1,
                address(this),
                now + 60
            );

            if (canSwapFromV2(_token1, _ToTokenContractAddress)) {
                swapFromV2(_token, _ToTokenContractAddress, amountA);
            } else {
                TransferHelper.safeTransfer(_token, msg.sender, amountA);
            }
        } else {
            (amountA, amountB) = uniswapV2Router.removeLiquidity(
                _token0,
                _token1,
                _IncomingLP,
                1,
                1,
                address(this),
                now + 60
            );

            if (canSwapFromV2(_token0, _ToTokenContractAddress)) {
                swapFromV2(_token0, _ToTokenContractAddress, amountA);
            } else {
                TransferHelper.safeTransfer(_token0, msg.sender, amountA);
            }

            if (canSwapFromV2(_token1, _ToTokenContractAddress)) {
                swapFromV2(_token1, _ToTokenContractAddress, amountB);
            } else {
                TransferHelper.safeTransfer(_token1, msg.sender, amountB);
            }
        }
    }


    function exchangeTokensV2(
        address _FromTokenContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
        );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (
            canSwapFromV2(_FromTokenContractAddress, _ToUnipoolToken0) &&
            canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)
        ) {
            token0Bought = swapFromV2(
                _FromTokenContractAddress,
                _ToUnipoolToken0,
                _amount
            );
            uint256 amountToSwap = calculateSwapInAmount(res0, token0Bought);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token0Bought, 2);
            token1Bought = swapFromV2(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = SafeMath.sub(token0Bought, amountToSwap);
        } else if (
            canSwapFromV2(_FromTokenContractAddress, _ToUnipoolToken1) &&
            canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)
        ) {
            token1Bought = swapFromV2(
                _FromTokenContractAddress,
                _ToUnipoolToken1,
                _amount
            );
            uint256 amountToSwap = calculateSwapInAmount(res1, token1Bought);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token1Bought, 2);
            token0Bought = swapFromV2(
                _ToUnipoolToken1,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = SafeMath.sub(token1Bought, amountToSwap);
        }
    }

    function canSwapFromV2(address _fromToken, address _toToken)
        public
        view
        returns (bool)
    {
        require(
            _fromToken != address(0) || _toToken != address(0),
            "Invalid Exchange values"
        );

        if (_fromToken == _toToken) return true;

        if (_fromToken == address(0) || _fromToken == wethTokenAddress) {
            if (_toToken == wethTokenAddress || _toToken == address(0))
                return true;
            IUniswapV2Pair pair = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)
            );
            if (_haveReserve(pair)) return true;
        } else if (_toToken == address(0) || _toToken == wethTokenAddress) {
            if (_fromToken == wethTokenAddress || _fromToken == address(0))
                return true;
            IUniswapV2Pair pair = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)
            );
            if (_haveReserve(pair)) return true;
        } else {
            IUniswapV2Pair pair1 = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)
            );
            IUniswapV2Pair pair2 = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)
            );
            IUniswapV2Pair pair3 = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_fromToken, _toToken)
            );
            if (_haveReserve(pair1) && _haveReserve(pair2)) return true;
            if (_haveReserve(pair3)) return true;
        }
        return false;
    }

    //checks if the UNI v2 contract have reserves to swap tokens
    function _haveReserve(IUniswapV2Pair pair) internal view returns (bool) {
        if (address(pair) != address(0)) {
            (uint256 res0, uint256 res1, ) = pair.getReserves();
            if (res0 > 0 && res1 > 0) {
                return true;
            }
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        public
        pure
        returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    //swaps _fromToken for _toToken
    //for eth, address(0) otherwise ERC token address
    function swapFromV2(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) internal returns (uint256) {
        require(
            _fromToken != address(0) || _toToken != address(0),
            "Invalid Exchange values"
        );
        if (_fromToken == _toToken) return amount;

        require(canSwapFromV2(_fromToken, _toToken), "Cannot be exchanged");
        require(amount > 0, "Invalid amount");

        if (_fromToken == address(0)) {
            if (_toToken == wethTokenAddress) {
                IWETH(wethTokenAddress).deposit{value: amount}();
                return amount;
            }
            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _toToken;

            uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{
                value: amount
            }(0, path, address(this), now + 180);
            return amounts[1];
        } else if (_toToken == address(0)) {
            if (_fromToken == wethTokenAddress) {
                IWETH(wethTokenAddress).withdraw(amount);
                return amount;
            }
            address[] memory path = new address[](2);
            TransferHelper.safeApprove(
                _fromToken,
                address(uniswapV2Router),
                amount
            );
            path[0] = _fromToken;
            path[1] = wethTokenAddress;

            uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(
                amount,
                0,
                path,
                address(this),
                now + 180
            );
            return amounts[1];
        } else {
            TransferHelper.safeApprove(
                _fromToken,
                address(uniswapV2Router),
                amount
            );
            uint256 returnedAmount = _swapTokenToTokenV2(
                _fromToken,
                _toToken,
                amount
            );
            require(returnedAmount > 0, "Error in swap");
            return returnedAmount;
        }
    }

    //swaps 2 ERC tokens (UniV2)
    function _swapTokenToTokenV2(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) internal returns (uint256) {
        IUniswapV2Pair pair1 = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)
        );
        IUniswapV2Pair pair2 = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)
        );
        IUniswapV2Pair pair3 = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_fromToken, _toToken)
        );

        uint256[] memory amounts;

        if (_haveReserve(pair3)) {
            address[] memory path = new address[](2);
            path[0] = _fromToken;
            path[1] = _toToken;

            amounts = uniswapV2Router.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                now + 180
            );
            return amounts[1];
        } else if (_haveReserve(pair1) && _haveReserve(pair2)) {
            address[] memory path = new address[](3);
            path[0] = _fromToken;
            path[1] = wethTokenAddress;
            path[2] = _toToken;

            amounts = uniswapV2Router.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                now + 180
            );
            return amounts[2];
        }
        return 0;
    }
}

// File: interfaces/IyVault.sol


pragma solidity ^0.6.12;

interface IyVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function balanceOf(address whom) external view returns (uint);
    function approve(address dst, uint amt) external returns (bool);
}

interface ICurveZapInGeneral {
    function ZapIn(
        address _toWhomToIssue,
        address _IncomingTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _IncomingTokenQty,
        uint256 _minPoolTokens
    ) external payable returns (uint256 crvTokensBought);
}

interface ICurveZapOutGeneral {
    function ZapOut(
        address payable _toWhomToIssue,
        address _curveExchangeAddress,
        uint256 _tokenCount,
        uint256 _IncomingCRV,
        address _ToTokenAddress,
        uint256 _minToTokens
    ) external returns (uint256 ToTokensBought);
}

interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAaveLendingPool {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;
}

interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

// File: contracts/ReefVaultsBasket.sol

///@author Zapper, modified by REEF
///@notice This contract adds/removes liquidity to/from yEarn Vaults using ETH or ERC20 Tokens.

pragma solidity ^0.6.12;









contract ReefVaultsBasket is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    bool public stopped = false;

    uint16 public protocolTokenDisinvestPercentage;
    address public protocolTokenAddress;
    uint256 public minimalInvestment = 1 ether;

    // Limit how much funds we can handle
    uint256 public maxInvestedFunds = 100 ether;
    uint256 public currentInvestedFunds;

    ICurveZapInGeneral public CurveZapInGeneral = ICurveZapInGeneral(
        0xcCdd1f20Fd50DD63849A87994bdD11806e4363De
    );
    ICurveZapOutGeneral public CurveZapOutGeneral = ICurveZapOutGeneral(
        0x4bF331Aa2BfB0869315fB81a350d109F4839f81b
    );

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider = IAaveLendingPoolAddressesProvider(
        0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
    );

    address
        private constant yCurveExchangeAddress = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    address
        private constant sBtcCurveExchangeAddress = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address
        private constant bUSDCurveExchangeAddress = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;

    address
        private constant threeCurveExchangeAddress = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    address
        private constant yCurvePoolTokenAddress = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address
        private constant sBtcCurvePoolTokenAddress = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address
        private constant bUSDCurvePoolTokenAddress = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;

    address
        private constant threeCurvePoolTokenAddress = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    mapping(address => address) internal token2Exchange;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    address wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct Vault {
        uint8 weight;
        address vaultAddress;
        uint8 vaultType;
    }

    struct Basket {
        string name;
        address referrer;
        Vault[] vaults;
    }

    struct BasketBalance {
        uint256 investedAmount;
        mapping(uint256 => uint256) vaults;
    }

    struct UserBalance {
        mapping(uint256 => BasketBalance) basketBalances;
    }

    event Invest(
        address indexed user,
        uint256 indexed basketId,
        uint256 investedAmount
    );

    event Disinvest(
        address indexed user,
        uint256 indexed basketId,
        uint256 disinvestedAmount
    );

    event BasketCreated(uint256 indexed basketId, address indexed user);

    uint256 public availableBasketsSize;
    mapping(uint256 => Basket) public availableBaskets;

    mapping(address => UserBalance) private userBalance;

    constructor(
        uint16 _protocolTokenDisinvestPercentage,
        address _protocolTokenAddress
    ) public {
        protocolTokenDisinvestPercentage = _protocolTokenDisinvestPercentage;
        protocolTokenAddress = _protocolTokenAddress;

        token2Exchange[yCurvePoolTokenAddress] = yCurveExchangeAddress;
        token2Exchange[bUSDCurvePoolTokenAddress] = bUSDCurveExchangeAddress;
        token2Exchange[sBtcCurvePoolTokenAddress] = sBtcCurveExchangeAddress;
    }

    function investedAmountInBasket(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256)
    {
        return userBalance[_owner].basketBalances[_basketIndex].investedAmount;
    }

    function balanceOfVaults(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        uint256[] memory vaultBalances = new uint256[](basket.vaults.length);
        for (uint256 i = 0; i < basket.vaults.length; i++) {
            vaultBalances[i] = userBalance[_owner].basketBalances[_basketIndex]
                .vaults[i];
        }

        return vaultBalances;
    }

    function getAvailableBasketVaults(uint256 _basketIndex)
        public
        view
        returns (
            address[] memory,
            uint8[] memory,
            uint8[] memory
        )
    {
        Basket storage basket = availableBaskets[_basketIndex];

        address[] memory vaults = new address[](basket.vaults.length);
        uint8[] memory vaultsWeights = new uint8[](basket.vaults.length);
        uint8[] memory vaultsTypes = new uint8[](basket.vaults.length);
        for (uint256 i = 0; i < basket.vaults.length; i++) {
            vaults[i] = basket.vaults[i].vaultAddress;

            vaultsWeights[i] = basket.vaults[i].weight;
            vaultsTypes[i] = basket.vaults[i].vaultType;
        }

        return (vaults, vaultsWeights, vaultsTypes);
    }

    function createBasket(
        string memory _name,
        address[] memory _vaults,
        uint8[] memory _vaultsWeights,
        uint8[] memory _vaultsType
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        require(_vaultsWeights.length > 0, "0 assets given");
        require(_vaults.length == _vaultsWeights.length);
        require(_vaults.length == _vaultsType.length);

        Basket storage basket = availableBaskets[availableBasketsSize];
        availableBasketsSize++;

        basket.name = _name;
        basket.referrer = msg.sender;

        uint256 totalWeights;
        for (uint256 i = 0; i < _vaultsWeights.length; i++) {
            totalWeights = (totalWeights).add(_vaultsWeights[i]);
        }

        require(totalWeights == 100, "Basket weights have to sum up to 100.");

        for (uint256 i = 0; i < _vaults.length; i++) {
            Vault memory vault = Vault(
                _vaultsWeights[i],
                _vaults[i],
                _vaultsType[i]
            );

            basket.vaults.push(vault);
        }

        emit BasketCreated(availableBasketsSize - 1, msg.sender);

        uint256[] memory baskets = new uint256[](1);
        uint256[] memory weights = new uint256[](1);
        baskets[0] = availableBasketsSize - 1;
        weights[0] = 100;

        return _multiInvest(baskets, weights, 1);
    }

    /**
    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens
    @param _basketIndexes basket indexes to invest into
    @param _weights corresponding basket weights (percentage) how much to invest
    @param _minPoolTokens Reverts if less tokens received than this
    @return Amount of LP bought
     */
    function invest(
        uint256[] memory _basketIndexes,
        uint256[] memory _weights,
        uint256 _minPoolTokens
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        return _multiInvest(_basketIndexes, _weights, _minPoolTokens);
    }

    function _multiInvest(
        uint256[] memory _basketIndexes,
        uint256[] memory _weights,
        uint256 _minPoolTokens
    ) internal returns (uint256) {
        require(msg.value > 0, "Error: ETH not sent");

        // Check weights
        require(_basketIndexes.length == _weights.length);
        uint256 totalWeights;
        for (uint256 i = 0; i < _weights.length; i++) {
            totalWeights = (totalWeights).add(_weights[i]);
        }

        for (uint256 i = 0; i < _weights.length; i++) {
            uint256 basketInvestAmount = (msg.value).mul(_weights[i]).div(100);
            require(
                basketInvestAmount >= minimalInvestment,
                "Too low invest amount."
            );

            _invest(_basketIndexes[i], basketInvestAmount, _minPoolTokens);
        }

        // Return change
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
    }

    function _invest(
        uint256 _basketIndex,
        uint256 _amount,
        uint256 _minTokens
    ) internal returns (uint256) {
        require(
            _basketIndex < availableBasketsSize,
            "Error: basket index out of bounds"
        );
        uint256 startBalance = address(this).balance;

        // Invest into vaults
        for (
            uint256 i = 0;
            i < availableBaskets[_basketIndex].vaults.length;
            i++
        ) {
            Vault memory vault = availableBaskets[_basketIndex].vaults[i];
            uint256 investAmount = (_amount).mul(vault.weight).div(100);

            uint256 yTokensRec = _investIntoYFIVault(
                address(this),
                vault.vaultAddress,
                vault.vaultType,
                address(0),
                investAmount,
                _minTokens
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .vaults[i] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .vaults[i]
                .add(yTokensRec);
        }

        // Update user balance
        uint256 diffBalance = startBalance.sub(address(this).balance);

        userBalance[msg.sender].basketBalances[_basketIndex]
            .investedAmount = userBalance[msg.sender]
            .basketBalances[_basketIndex]
            .investedAmount
            .add(diffBalance);

        // Update current funds
        currentInvestedFunds = currentInvestedFunds.add(diffBalance);
        require(
            currentInvestedFunds <= maxInvestedFunds,
            "Max invested funds exceeded"
        );

        emit Invest(
            msg.sender,
            _basketIndex,
            userBalance[msg.sender].basketBalances[_basketIndex].investedAmount
        );

        return
            userBalance[msg.sender].basketBalances[_basketIndex].investedAmount;
    }

    function disinvest(
        uint256 _basketIndex,
        uint256 _percent,
        uint256 _protocolYieldRatio,
        bool shouldRestake
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        require(
            _basketIndex < availableBasketsSize,
            "Basket index out of bounds"
        );

        require(
            _percent > 0 && _percent <= 100,
            "Percent has to in interval (0, 100]"
        );
        require(
            _protocolYieldRatio <= 100,
            "Protocol yield ratio not in interval (0, 100]"
        );

        // Disinvest Vaults
        for (
            uint256 b = 0;
            b < availableBaskets[_basketIndex].vaults.length;
            b++
        ) {
            require(
                userBalance[msg.sender].basketBalances[_basketIndex].vaults[b] >
                    0,
                "balance must be positive"
            );

            uint256 disinvestAmount = (
                userBalance[msg.sender].basketBalances[_basketIndex].vaults[b]
            )
                .mul(_percent)
                .div(100);

            // TODO: figure out slippage
            uint256 yTokens = _disinvestFromYFIVault(
                payable(address(this)),
                address(0),
                availableBaskets[_basketIndex].vaults[b].vaultAddress,
                availableBaskets[_basketIndex].vaults[b].vaultType,
                disinvestAmount,
                1
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .vaults[b] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .vaults[b]
                .sub(disinvestAmount);
        }

        // Update user balance
        uint256 basketDisinvestAmount = (
            userBalance[msg.sender].basketBalances[_basketIndex].investedAmount
        )
            .mul(_percent)
            .div(100);

        userBalance[msg.sender].basketBalances[_basketIndex]
            .investedAmount = userBalance[msg.sender]
            .basketBalances[_basketIndex]
            .investedAmount
            .sub(basketDisinvestAmount);

        emit Disinvest(msg.sender, _basketIndex, basketDisinvestAmount);

        // Update current funds
        currentInvestedFunds = currentInvestedFunds.sub(basketDisinvestAmount);

        // Stake the profit into REEF tokens
        if (address(this).balance > basketDisinvestAmount) {
            uint256 profit = address(this).balance - basketDisinvestAmount;

            // Return the liquidation
            uint256 yieldRatio = protocolTokenDisinvestPercentage >
                _protocolYieldRatio
                ? protocolTokenDisinvestPercentage
                : _protocolYieldRatio;

            if (yieldRatio > 0) {
                // Check if we restake into the ETH/protocolToken pool
                if (shouldRestake) {
                    ReefUniswap._investIntoUniswapPool(
                        address(0),
                        wethTokenAddress,
                        protocolTokenAddress,
                        msg.sender,
                        profit.mul(yieldRatio).div(100)
                    );
                } else {
                    uint256 protocolTokenAmount = ReefUniswap.swapFromV2(
                        address(0),
                        protocolTokenAddress,
                        profit.mul(yieldRatio).div(100)
                    );

                    if (protocolTokenAmount > 0) {
                        TransferHelper.safeTransfer(
                            protocolTokenAddress,
                            msg.sender,
                            protocolTokenAmount
                        );
                    }
                }
            }
        }

        // Return the remaining ETH
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
    }

    function updateCurveZapIn(address CurveZapInGeneralAddress)
        public
        onlyOwner
    {
        require(CurveZapInGeneralAddress != address(0), "Invalid Address");
        CurveZapInGeneral = ICurveZapInGeneral(CurveZapInGeneralAddress);
    }

    function updateCurveZapOut(address CurveZapOutGeneralAddress)
        public
        onlyOwner
    {
        require(CurveZapOutGeneralAddress != address(0), "Invalid Address");
        CurveZapOutGeneral = ICurveZapOutGeneral(CurveZapOutGeneralAddress);
    }

    function addNewCurveExchange(
        address curvePoolToken,
        address curveExchangeAddress
    ) public onlyOwner {
        require(
            curvePoolToken != address(0) && curveExchangeAddress != address(0),
            "Invalid Address"
        );
        token2Exchange[curvePoolToken] = curveExchangeAddress;
    }

    /**
    @notice This function is used to add liquidity to yVaults
    @param _toWhomToIssue recipient address
    @param _toYVaultAddress The address of vault to add liquidity to
    @param _vaultType Type of underlying token: 0 token; 1 aToken; 2 LP token
    @param _fromTokenAddress The token used for investment (address(0x00) if ether)
    @param _amount The amount of ERC to invest
    @param _minYTokens for slippage
    @return yTokensRec
     */
    function _investIntoYFIVault(
        address _toWhomToIssue,
        address _toYVaultAddress,
        uint16 _vaultType,
        address _fromTokenAddress,
        uint256 _amount,
        uint256 _minYTokens
    ) internal returns (uint256) {
        IyVault vaultToEnter = IyVault(_toYVaultAddress);
        address underlyingVaultToken = vaultToEnter.token();

        uint256 iniYTokensBal = IERC20(address(vaultToEnter)).balanceOf(
            address(this)
        );

        if (underlyingVaultToken == _fromTokenAddress) {
            IERC20(underlyingVaultToken).safeApprove(
                address(vaultToEnter),
                _amount
            );
            vaultToEnter.deposit(_amount);
        } else {
            // Curve Vaults
            if (_vaultType == 2) {

                    address curveExchangeAddr
                 = token2Exchange[underlyingVaultToken];

                uint256 tokensBought;
                if (_fromTokenAddress == address(0)) {
                    tokensBought = CurveZapInGeneral.ZapIn{value: _amount}(
                        address(this),
                        address(0),
                        curveExchangeAddr,
                        _amount,
                        0
                    );
                } else {
                    IERC20(_fromTokenAddress).safeApprove(
                        address(CurveZapInGeneral),
                        _amount
                    );
                    tokensBought = CurveZapInGeneral.ZapIn(
                        address(this),
                        _fromTokenAddress,
                        curveExchangeAddr,
                        _amount,
                        0
                    );
                }

                IERC20(underlyingVaultToken).safeApprove(
                    address(vaultToEnter),
                    tokensBought
                );
                vaultToEnter.deposit(tokensBought);
            } else if (_vaultType == 1) {
                address underlyingAsset = IAToken(underlyingVaultToken)
                    .underlyingAssetAddress();

                uint256 tokensBought = ReefUniswap.swapFromV2(
                    _fromTokenAddress,
                    underlyingAsset,
                    _amount
                );

                IERC20(underlyingAsset).safeApprove(
                    lendingPoolAddressProvider.getLendingPoolCore(),
                    tokensBought
                );

                IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                    .deposit(underlyingAsset, tokensBought, 0);

                uint256 aTokensBought = IERC20(underlyingVaultToken).balanceOf(
                    address(this)
                );
                IERC20(underlyingVaultToken).safeApprove(
                    address(vaultToEnter),
                    aTokensBought
                );
                vaultToEnter.deposit(aTokensBought);
            } else {
                uint256 tokensBought = ReefUniswap.swapFromV2(
                    _fromTokenAddress,
                    underlyingVaultToken,
                    _amount
                );

                IERC20(underlyingVaultToken).safeApprove(
                    address(vaultToEnter),
                    tokensBought
                );
                vaultToEnter.deposit(tokensBought);
            }
        }

        uint256 yTokensRec = IERC20(address(vaultToEnter))
            .balanceOf(address(this))
            .sub(iniYTokensBal);
        require(yTokensRec >= _minYTokens, "High Slippage");

        IERC20(address(vaultToEnter)).safeTransfer(_toWhomToIssue, yTokensRec);

        return yTokensRec;
    }

    /**
    @notice This function is used to remove liquidity from yVaults
    @param _toWhomToIssue recipient address
    @param _ToTokenContractAddress The address of the token to withdraw
    @param _fromYVaultAddress The address of the vault to exit
    @param _vaultType Type of underlying token: 0 token; 1 aToken; 2 LP token
    @param _IncomingAmt The amount of vault tokens removed
    @param _minTokensRec for slippage
    @return toTokensReceived
     */
    function _disinvestFromYFIVault(
        address _toWhomToIssue,
        address _ToTokenContractAddress,
        address _fromYVaultAddress,
        uint16 _vaultType,
        uint256 _IncomingAmt,
        uint256 _minTokensRec
    ) internal returns (uint256) {
        IyVault vaultToExit = IyVault(_fromYVaultAddress);
        address underlyingVaultToken = vaultToExit.token();

        vaultToExit.withdraw(_IncomingAmt);
        uint256 underlyingReceived = IERC20(underlyingVaultToken).balanceOf(
            address(this)
        );

        uint256 toTokensReceived;
        if (_ToTokenContractAddress == underlyingVaultToken) {
            IERC20(underlyingVaultToken).safeTransfer(
                _toWhomToIssue,
                underlyingReceived
            );
            toTokensReceived = underlyingReceived;
        } else {
            if (_vaultType == 2) {
                toTokensReceived = _withdrawFromCurve(
                    underlyingVaultToken,
                    underlyingReceived,
                    _toWhomToIssue,
                    _ToTokenContractAddress,
                    0
                );
            } else if (_vaultType == 1) {
                // unwrap atoken
                IAToken(underlyingVaultToken).redeem(underlyingReceived);
                address underlyingAsset = IAToken(underlyingVaultToken)
                    .underlyingAssetAddress();

                // swap
                toTokensReceived = ReefUniswap.swapFromV2(
                    underlyingAsset,
                    _ToTokenContractAddress,
                    underlyingReceived
                );
                if (_ToTokenContractAddress == address(0)) {
                    payable(_toWhomToIssue).transfer(toTokensReceived);
                } else {
                    IERC20(_ToTokenContractAddress).safeTransfer(
                        _toWhomToIssue,
                        toTokensReceived
                    );
                }
            } else {
                toTokensReceived = ReefUniswap.swapFromV2(
                    underlyingVaultToken,
                    _ToTokenContractAddress,
                    underlyingReceived
                );
                if (_ToTokenContractAddress == address(0)) {
                    payable(_toWhomToIssue).transfer(toTokensReceived);
                } else {
                    IERC20(_ToTokenContractAddress).safeTransfer(
                        _toWhomToIssue,
                        toTokensReceived
                    );
                }
            }
        }

        require(toTokensReceived >= _minTokensRec, "High Slippage");

        return toTokensReceived;
    }

    function _withdrawFromCurve(
        address _CurvePoolToken,
        uint256 _tokenAmt,
        address _toWhomToIssue,
        address _ToTokenContractAddress,
        uint256 _minTokensRec
    ) internal returns (uint256) {
        IERC20(_CurvePoolToken).safeApprove(
            address(CurveZapOutGeneral),
            _tokenAmt
        );

        address curveExchangeAddr = token2Exchange[_CurvePoolToken];
        uint256 tokenCount = 4;

        if (curveExchangeAddr == sBtcCurveExchangeAddress) {
            tokenCount = 3;
        }

        return (
            CurveZapOutGeneral.ZapOut(
                payable(_toWhomToIssue),
                curveExchangeAddr,
                tokenCount,
                _tokenAmt,
                _ToTokenContractAddress,
                _minTokensRec
            )
        );
    }

    function setProtocolTokenDisinvestPercentage(uint16 _newPercentage)
        public
        onlyOwner
    {
        require(
            _newPercentage >= 0 && _newPercentage < 100,
            "_newPercentage must be between 0 and 100."
        );
        protocolTokenDisinvestPercentage = _newPercentage;
    }

    function setProtocolTokenAddress(address _newProtocolTokenAddress)
        public
        onlyOwner
    {
        protocolTokenAddress = _newProtocolTokenAddress;
    }

    function setMinimalInvestment(uint256 _minimalInvestment) public onlyOwner {
        minimalInvestment = _minimalInvestment;
    }

    function setMaxInvestedFunds(uint256 _maxInvestedFunds) public onlyOwner {
        require(
            _maxInvestedFunds >= currentInvestedFunds,
            "Max funds lower than current funds."
        );
        maxInvestedFunds = _maxInvestedFunds;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        IERC20(address(_TokenAddress)).safeTransfer(owner(), qty);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = payable(owner());
        _to.transfer(contractBalance);
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}