/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
        assembly {
            codehash := extcodehash(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
abstract contract ReentrancyGuard {
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

    constructor() internal {
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

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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

    uint256[49] private __gap;
}

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IRewardPool {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
}

library DexAndFarmHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== FARMING ========== */

    function depositToPool(
        address _pool,
        uint256 _pid,
        address _lpAdd,
        uint256 _lpAmount
    ) internal {
        if (_lpAmount > 0) {
            IERC20(_lpAdd).safeIncreaseAllowance(_pool, _lpAmount);
            IRewardPool(_pool).deposit(_pid, _lpAmount);
        }
    }

    function depositToPoolMax(
        address _pool,
        uint256 _pid,
        address _lpAdd
    ) internal {
        depositToPool(_pool, _pid, _lpAdd, IERC20(_lpAdd).balanceOf(address(this)));
    }

    function withdrawFromPool(
        address _pool,
        uint256 _pid,
        uint256 _lpAmount
    ) internal {
        IRewardPool(_pool).withdraw(_pid, _lpAmount);
    }

    function withdrawFromPoolMax(address _pool, uint256 _pid) internal {
        withdrawFromPool(_pool, _pid, stakeAmountFromPool(_pool, _pid));
    }

    function claimFromPool(address _pool, uint256 _pid) internal {
        IRewardPool(_pool).withdraw(_pid, 0);
    }

    function stakeAmountFromPool(address _pool, uint256 _pid) internal view returns (uint256 _stakedAmount) {
        (_stakedAmount, ) = IRewardPool(_pool).userInfo(_pid, address(this));
    }

    /* ========== DEX FUNCTIONS ========== */

    function swapToken(
        address _router,
        address _inputToken,
        address _outputToken,
        address[] memory _path,
        uint256 _amount
    ) internal returns (uint256 _outputAmount) {
        if (_amount > 0) {
            if (_path.length == 0) {
                _path = new address[](2);
                _path[0] = _inputToken;
                _path[1] = _outputToken;
            }
            IERC20(_inputToken).safeIncreaseAllowance(address(_router), _amount);
            uint256 _before = IERC20(_outputToken).balanceOf(address(this));
            IUniswapV2Router(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 1, _path, address(this), now.add(60));
            _outputAmount = IERC20(_outputToken).balanceOf(address(this)).sub(_before);
        }
    }

    function addLiquidity(
        address _router,
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) internal {
        IERC20(_tokenA).safeIncreaseAllowance(address(_router), _amountADesired);
        IERC20(_tokenB).safeIncreaseAllowance(address(_router), _amountBDesired);
        IUniswapV2Router(_router).addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired, 0, 0, address(this), now.add(60));
    }

    function addLiquidityMax(
        address _router,
        address _tokenA,
        address _tokenB
    ) internal {
        addLiquidity(_router, _tokenA, _tokenB, IERC20(_tokenA).balanceOf(address(this)), IERC20(_tokenB).balanceOf(address(this)));
    }

    function removeLiquidity(
        address _router,
        address _lpAdd,
        uint256 _liquidity
    ) internal {
        address _tokenA = IUniswapV2Pair(_lpAdd).token0();
        address _tokenB = IUniswapV2Pair(_lpAdd).token1();
        IERC20(_lpAdd).safeIncreaseAllowance(address(_router), _liquidity);
        IUniswapV2Router(_router).removeLiquidity(_tokenA, _tokenB, _liquidity, 1, 1, address(this), now.add(60));
    }

    function removeLiquidityMax(address _router, address _lpAdd) internal {
        removeLiquidity(_router, _lpAdd, IERC20(_lpAdd).balanceOf(address(this)));
    }
}

contract ShareTaxWorker is OwnableUpgradeSafe, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant dollar = address(0x66C59Dded4EF01a3412a8B019B6e41D4a8C49A35);
    address public constant share = address(0xAB72EE159Ff70b64beEcBbB0FbBE58b372391C54);
    address public constant usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    address private constant shareRewardBank = address(0x69E7Bbe85db0364397378364458952bEcB886920);
    address private constant dollarUsdcPair = address(0x6649F12E210862e0045B3dFe7E6eA1F8F0565049);
    address private constant shareUsdcPair = address(0x46A30dFece0E0fc0977eefd15bd0595fdDe15a10);
    uint256 private constant dollarUsdcPairPid = 2;
    uint256 private constant shareUsdcPairPid = 0;

    address public quickRouter;
    mapping(address => mapping(address => address[])) public quickPaths;

    bool public notPublic = false; // allow public to call earn() function
    uint256 public maxShareAmountToSell;
    uint256 public lastTradeTime;

    /* ========== EVENTS ========== */

    event TransferTo(address indexed token, address receiver, uint256 amount);
    event SwapToken(address inputToken, address outputToken, uint256 amount, uint256 amountReceived);
    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    /* ========== Modifiers =============== */

    modifier checkPublicAllow() {
        require(!notPublic || msg.sender == owner(), "!owner nor !publicAllowed");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize() external initializer {
        OwnableUpgradeSafe.__Ownable_init();

        quickRouter = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // QuickSwap
        maxShareAmountToSell = 50 ether;
        notPublic = false; // allow public to call

        quickPaths[share][usdc] = [share, usdc];
        quickPaths[usdc][dollar] = [usdc, dollar];
    }

    /* ========== VIEWS ================ */

    function pendingFromPool(address _pool, uint256 _pid) public view returns (uint256) {
        return IRewardPool(_pool).pendingReward(_pid, address(this));
    }

    function pendingFromShareRewardBank() external view returns (uint256) {
        uint256 _pendingDollarUsdcPairReward = pendingFromPool(shareRewardBank, dollarUsdcPairPid);
        uint256 _pendingShareUsdcPairReward = pendingFromPool(shareRewardBank, shareUsdcPairPid);
        return _pendingDollarUsdcPairReward.add(_pendingShareUsdcPairReward);
    }

    function stakeAmountFromPool(address _pool, uint256 _pid) public view returns (uint256) {
        return DexAndFarmHelper.stakeAmountFromPool(_pool, _pid);
    }

    function stakeAmountFromShareRewardBank(uint256 _pid) external view returns (uint256) {
        return stakeAmountFromPool(shareRewardBank, _pid);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function collectShareRewards() public checkPublicAllow nonReentrant {
        if (pendingFromPool(shareRewardBank, dollarUsdcPairPid) > 0) {
            DexAndFarmHelper.claimFromPool(shareRewardBank, dollarUsdcPairPid);
        }
        if (pendingFromPool(shareRewardBank, shareUsdcPairPid) > 0) {
            DexAndFarmHelper.claimFromPool(shareRewardBank, shareUsdcPairPid);
        }
    }

    function rebalance() public checkPublicAllow nonReentrant {
        if (lastTradeTime.add(10 minutes) <= now) {
            uint256 _shareAmount = IERC20(share).balanceOf(address(this));
            uint256 _maxShareAmountToSell = maxShareAmountToSell;
            if (_shareAmount > _maxShareAmountToSell) {
                _shareAmount > _maxShareAmountToSell;
            }
            if (_shareAmount > 0) {
                lastTradeTime = now;
                address _router = quickRouter;
                uint256 _shareAmtToUsdc = _shareAmount.mul(75).div(100); // 75% -> USDC
                uint256 _shareAmtToAddLiquidity = _shareAmount.sub(_shareAmtToUsdc);
                DexAndFarmHelper.swapToken(_router, share, usdc, quickPaths[share][usdc], _shareAmtToUsdc);
                DexAndFarmHelper.addLiquidity(_router, share, usdc, _shareAmtToAddLiquidity, IERC20(usdc).balanceOf(address(this))); // 25% + USDC -> Liquidity
                uint256 _usdcAmount = IERC20(usdc).balanceOf(address(this));
                DexAndFarmHelper.swapToken(_router, usdc, dollar, quickPaths[usdc][dollar], _usdcAmount.mul(49).div(100));
                DexAndFarmHelper.addLiquidityMax(_router, dollar, usdc); // (25% -> USDC) + SDO -> Liquidity
            }
        }
    }

    function depositToShareRewardBank() public checkPublicAllow nonReentrant {
        DexAndFarmHelper.depositToPoolMax(shareRewardBank, dollarUsdcPairPid, dollarUsdcPair);
        DexAndFarmHelper.depositToPoolMax(shareRewardBank, shareUsdcPairPid, shareUsdcPair);
    }

    function workForDaoFund() external checkPublicAllow {
        collectShareRewards();
        rebalance();
        depositToShareRewardBank();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setNotPublic(bool _notPublic) external onlyOwner {
        notPublic = _notPublic;
    }

    function setMaxShareAmountToSell(uint256 _maxShareAmountToSell) external onlyOwner {
        maxShareAmountToSell = _maxShareAmountToSell;
    }

    function setQuickRouter(address _quickRouter) external onlyOwner {
        quickRouter = _quickRouter;
    }

    function setMainPaths(address[] memory _shareToUsdcPath, address[] memory _usdcToDollarPath) external onlyOwner {
        quickPaths[share][usdc] = _shareToUsdcPath;
        quickPaths[usdc][dollar] = _usdcToDollarPath;
    }

    function setPath(
        address _inputToken,
        address _outputToken,
        address[] memory _path
    ) external onlyOwner {
        quickPaths[_inputToken][_outputToken] = _path;
    }

    function adminDepositToPool(
        address _pool,
        uint256 _pid,
        address _lpAdd,
        uint256 _lpAmount
    ) external onlyOwner {
        if (_lpAmount > 0) {
            IERC20(_lpAdd).safeIncreaseAllowance(_pool, _lpAmount);
            IRewardPool(_pool).deposit(_pid, _lpAmount);
        }
    }

    function adminDepositToPoolMax(
        address _pool,
        uint256 _pid,
        address _lpAdd
    ) external onlyOwner {
        DexAndFarmHelper.depositToPoolMax(_pool, _pid, _lpAdd);
    }

    function adminWithdrawFromPool(
        address _pool,
        uint256 _pid,
        uint256 _lpAmount
    ) external onlyOwner {
        DexAndFarmHelper.withdrawFromPool(_pool, _pid, _lpAmount);
    }

    function adminWithdrawFromPoolMax(address _pool, uint256 _pid) external onlyOwner {
        DexAndFarmHelper.withdrawFromPoolMax(_pool, _pid);
    }

    function adminClaimFromPool(address _pool, uint256 _pid) external onlyOwner {
        DexAndFarmHelper.claimFromPool(_pool, _pid);
    }

    function adminSwapToken(
        address _inputToken,
        address _outputToken,
        uint256 _amount
    ) external onlyOwner {
        DexAndFarmHelper.swapToken(quickRouter, _inputToken, _outputToken, quickPaths[_inputToken][_outputToken], _amount);
    }

    function adminAddLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) external onlyOwner {
        DexAndFarmHelper.addLiquidity(quickRouter, _tokenA, _tokenB, _amountADesired, _amountBDesired);
    }

    function adminAddLiquidityMax(address _tokenA, address _tokenB) external onlyOwner {
        DexAndFarmHelper.addLiquidityMax(quickRouter, _tokenA, _tokenB);
    }

    function adminRemoveLiquidity(address _lpAdd, uint256 _liquidity) external onlyOwner {
        DexAndFarmHelper.removeLiquidity(quickRouter, _lpAdd, _liquidity);
    }

    function adminRemoveLiquidityMax(address _lpAdd) external onlyOwner {
        DexAndFarmHelper.removeLiquidityMax(quickRouter, _lpAdd);
    }

    /* ========== EMERGENCY ========== */

    function rescueStuckErc20(address _token) external onlyOwner {
        require(_token != dollar && _token != share, "core");
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyOwner returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string("ShareTaxWorker::executeTransaction: Transaction execution reverted."));

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}