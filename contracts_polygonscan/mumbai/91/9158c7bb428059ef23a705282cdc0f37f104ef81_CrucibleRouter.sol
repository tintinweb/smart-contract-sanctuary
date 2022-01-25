/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/common/uniswap/IUniswapV2Router01.sol

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// {"mode":"full","isActive":false}


// File contracts/common/uniswap/IUniswapV2Factory.sol


pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/common/uniswap/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/crucible/ICrucibleToken.sol


pragma solidity 0.8.2;

interface ICrucibleToken {
    enum OverrideState {
        Default,
        OverrideIn,
        OverrideOut,
        OverrideBoth
    }

    function deposit(address to) external returns (uint256);

    function withdraw(address to, uint256 amount)
        external
        returns (uint256, uint256);

    function baseToken() external returns (address);

    function overrideFee(
        address target,
        OverrideState overrideType,
        uint64 newFeeX10000
    ) external;

    function upgradeRouter(address router) external;
}


// File contracts/common/IStakeFor.sol


pragma solidity ^0.8.0;

interface IStakeFor {
    function stakeFor(address staker, address token) external returns (uint256);
}


// File @openzeppelin/contracts/security/[email protected]



pragma solidity ^0.8.0;

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

    constructor() {
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


// File contracts/common/IBurnable.sol


pragma solidity ^0.8.0;

interface IBurnable {
    function burn(uint256 amount) external;
}


// File contracts/common/IFerrumDeployer.sol


pragma solidity ^0.8.0;

interface IFerrumDeployer {
    function initData() external returns (bytes memory);
}


// File contracts/crucible/ICrucibleFactory.sol


pragma solidity 0.8.2;

interface ICrucibleFactory {
    function getCrucible(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external view returns (address);

    function router() external view returns (address);
}


// File contracts/crucible/ICrucibleTokenDeployer.sol


pragma solidity 0.8.2;

interface ICrucibleTokenDeployer {
    function parameters()
        external
        returns (
            address,
            address,
            uint64,
            uint64,
            string memory,
            string memory
        );
}


// File contracts/taxing/IHasTaxDistributor.sol


pragma solidity ^0.8.0;

interface IHasTaxDistributor {
	function taxDistributor() external returns (address);
}


// File contracts/taxing/IGeneralTaxDistributor.sol


pragma solidity ^0.8.0;

interface IGeneralTaxDistributor {
    function distributeTax(address token) external returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]



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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/common/ERC20/ERC20.sol


pragma solidity ^0.8.0;


abstract contract ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal virtual {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}


// File contracts/common/math/FullMath.sol


pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// File contracts/staking/library/TokenReceivable.sol


pragma solidity 0.8.2;


/**
 * @notice Library for handling safe token transactions including fee per transaction tokens.
 */
abstract contract TokenReceivable is ReentrancyGuard {
  using SafeERC20 for IERC20;
  mapping(address => uint256) public inventory; // Amount of received tokens that are accounted for

  /**
   @notice Sync the inventory of a token based on amount changed
   @param token The token address
   @return amount The changed amount
   */
  function sync(address token) internal returns (uint256 amount) {
    uint256 inv = inventory[token];
    uint256 balance = IERC20(token).balanceOf(address(this));
    amount = balance - inv;
    inventory[token] = balance;
  }

  /**
   @notice Safely sends a token out and updates the inventory
   @param token The token address
   @param payee The payee
   @param amount The amount
   */
  function sendToken(address token, address payee, uint256 amount) internal {
    inventory[token] = inventory[token] - amount;
    IERC20(token).safeTransfer(payee, amount);
  }
}


// File contracts/crucible/CrucibleToken.sol


pragma solidity 0.8.2;








contract CrucibleToken is ERC20, TokenReceivable, ICrucibleToken {
    uint256 constant MAX_FEE_X10k = 0.6 * 10000;

    struct FeeOverride {
        OverrideState over;
        uint64 feeX10000;
    }

    address public immutable factory;
    address public router;
    address public override baseToken; // Remocing immutables to allow etherscan verification to work. Hopefully etherscan gives us a solution
    uint64 public feeOnTransferX10000;
    uint64 public feeOnWithdrawX10000;
    mapping(address => FeeOverride) public feeOverrides;

    event Withdrawn(uint256 amount, uint256 fee, address from, address to);
    event Deposited(address token, uint256 amount, address to);
    event FeeSet(address target, OverrideState overrideType, uint64 feeX10k);

    modifier onlyRouter() {
        require(msg.sender == router, "CT: not allowed");
        _;
    }

    constructor() {
        address token;
        address fac;
        (
            fac,
            token,
            feeOnTransferX10000,
            feeOnWithdrawX10000,
            name,
            symbol
        ) = ICrucibleTokenDeployer(msg.sender).parameters();
        decimals = safeDecimals(token);
        baseToken = token;
        router = ICrucibleFactory(fac).router();
        factory = fac;
    }

    /**
     @notice Upgrades a router
     @param _router The new router
     @dev Can only be called by the current router
     */
    function upgradeRouter(address _router
    ) external override onlyRouter {
        require(_router != address(0), "CT: router required");
        router = _router;
    }

    /**
     @notice Overrides fee for a target
     @param target The target to be overriden
     @param overrideType The type of override
     @param newFeeX10000 The new fee
     @dev Can only be called by the router
     */
    function overrideFee(
        address target,
        OverrideState overrideType,
        uint64 newFeeX10000
    ) external override onlyRouter {
        require(newFeeX10000 < MAX_FEE_X10k, "CT: fee too large");
        feeOverrides[target] = FeeOverride({
            over: overrideType,
            feeX10000: newFeeX10000
        });
        emit FeeSet(target, overrideType, newFeeX10000);
    }

    /**
     @notice Deposits into the crucible
        Can only be called by the router
     @param to Receiver of minted tokens
     @return amount The deposited amount
     */
    function deposit(address to
    ) external override onlyRouter returns (uint256 amount) {
        amount = sync(baseToken);
        require(amount != 0, "CT: empty");
        _mint(to, amount);
        emit Deposited(baseToken, amount, to);
    }

    /**
     @notice Withdraws from the crucible
     @param to Receiver of minted tokens
     @param amount The amount to withdraw
     @return fee The fee
     @return withdrawn The withdrawn amounts
     */
    function withdraw(address to, uint256 amount
    ) external override returns (uint256 fee, uint256 withdrawn) {
        (fee, withdrawn) = _withdraw(msg.sender, to, amount);
    }

    /*
     @notice Burn the underlying asset. If not burnable, send to the factory.
     @param amount Amount to burn
     */
    function burn(uint256 amount
    ) external virtual {
        require(amount != 0, "CT: amount required");
        doBurn(msg.sender, amount);
    }

    /*
     @notice Burn the underlying asset. If not burnable, send to the factory.
     @param from The address to burn from
     @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount
    ) external virtual {
        require(from != address(0), "CT: from required");
        require(amount != 0, "CT: amount required");
        uint256 decreasedAllowance = allowance[from][msg.sender] - amount;

        _approve(from, msg.sender, decreasedAllowance);
        doBurn(from, amount);
    }

    /**
     @notice Withdraws from crucible
     @param from From address
     @param to To address
     @param amount The amount
     @return fee The fee
     @return withdrawn The withdrawn amount
     */
    function _withdraw(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (uint256 fee, uint256 withdrawn) {
        fee = calculateFeeX10000(amount, feeOnWithdrawX10000);
        withdrawn = amount - fee;
        address td = IHasTaxDistributor(router).taxDistributor();
        tax(from, td, fee);
        _burn(from, withdrawn);
        sendToken(baseToken, to, withdrawn);
        emit Withdrawn(amount, fee, from, to);
    }

    /**
     @notice Burns tokens. Send base tokens to factory to be locke or burned later
     @param from The from address
     @param amount The amount
     */
    function doBurn(address from, uint256 amount
    ) internal {
        sendToken(baseToken, factory, amount);
        _burn(from, amount);
    }

    /**
     @notice Overrides the ERC20 transfer method
     @param sender The sender
     @param recipient The recipient
     @param amount The amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        FeeOverride memory overFrom = feeOverrides[sender];
        FeeOverride memory overTo = feeOverrides[recipient];
        address td = IHasTaxDistributor(router).taxDistributor();
        if (sender == td || recipient == td) {
            _doTransfer(sender, recipient, amount);
            return;
        }

        uint256 feeRatioX10k = 0;
        bool overriden = false;
        if (
            overFrom.over == OverrideState.OverrideOut ||
            overFrom.over == OverrideState.OverrideBoth
        ) {
            feeRatioX10k = overFrom.feeX10000;
            overriden = true;
        }
        if (
            (overTo.over == OverrideState.OverrideIn ||
                overTo.over == OverrideState.OverrideBoth) &&
            overTo.feeX10000 >= feeRatioX10k
        ) {
            feeRatioX10k = overTo.feeX10000;
            overriden = true;
        }
        if (feeRatioX10k == 0 && !overriden) {
            feeRatioX10k = feeOnTransferX10000;
        }
        uint256 fee = feeRatioX10k == 0 ? 0 : calculateFeeX10000(amount, feeRatioX10k);
        amount = amount - fee;
        if (fee != 0) {
            tax(sender, td, fee);
        }
        _doTransfer(sender, recipient, amount);
    }

    /**
     @notice Just does the transfer
     @param sender The sender
     @param recipient The recipient
     @param amount The amount
     */
    function _doTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        ERC20._transfer(sender, recipient, amount);
    }

    /**
     @notice charges the tax
     @param from From address
     @param taxDist The tax distributor contract
     @param amount The tax amount
     */
    function tax(
        address from,
        address taxDist,
        uint256 amount
    ) internal {
        _doTransfer(from, taxDist, amount);
        IGeneralTaxDistributor(taxDist).distributeTax(address(this));
    }

    /**
     @notice Gets the decimals or default
     @param token The token
     @return The decimals
     */
    function safeDecimals(address token
    ) private view returns (uint8) {
        (bool succ, bytes memory data) = token.staticcall(
            abi.encodeWithSignature(("decimals()"))
        );
        if (succ) {
            return abi.decode(data, (uint8));
        } else {
            return 18;
        }
    }

    /**
     @notice Calculates the fee
     @param amount The amount
     @param feeX10000 The fee rate
     @return The fee amount
     */
    function calculateFeeX10000(uint256 amount, uint256 feeX10000
    ) private pure returns (uint256) {
        return FullMath.mulDiv(amount, feeX10000, 10000);
    }
}


// File contracts/crucible/CrucibleTokenDeployer.sol


pragma solidity 0.8.2;

abstract contract CrucibleTokenDeployer is ICrucibleTokenDeployer {
    struct Parameters {
        address factory;
        address baseToken;
        uint64 feeOnTransferX10000;
        uint64 feeOnWithdrawX10000;
        string name;
        string symbol;
    }

    Parameters public override parameters;

    /**
     @notice Deploys a crucible token
     @param factory The factory
     @param baseToken The base token
     @param feeOnTransferX10000 Fee on transfer rate per 10k
     @param feeOnWithdrawX10000 Fee on withdraw rate per 10k
     @param name The name
     @param symbol The symbol
     @return token The deployed token address
     */
    function deploy(
        address factory,
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000,
        string memory name,
        string memory symbol
    ) internal returns (address token) {
        parameters = Parameters({
            factory: factory,
            baseToken: baseToken,
            feeOnTransferX10000: feeOnTransferX10000,
            feeOnWithdrawX10000: feeOnWithdrawX10000,
            name: name,
            symbol: symbol
        });

        token = address(
            new CrucibleToken{
                salt: keccak256(
                    abi.encode(
                        baseToken,
                        feeOnTransferX10000,
                        feeOnWithdrawX10000
                    )
                )
            }()
        );
        delete parameters;
    }
}


// File contracts/staking/factory/NoDelegateCall.sol

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}


// File contracts/common/strings/StringLib.sol


pragma solidity ^0.8.0;

library StringLib {
	// Taken from: 
	// https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

	function strToB32(string memory s) internal pure returns (bytes32 len, bytes32 b1, bytes32 b2) {
		bytes memory t = bytes(s);
		assembly {
			len := mload(s)
			b1 := mload(add(s, 32))
		}
		if (t.length >= 16) {
			assembly {
				b2 := mload(add(s, 64))
			}
		} else {
			b2 = 0;
		}
	}

	function b32ToStr(bytes32 len, bytes32 b1, bytes32 b2, uint256 maxLen) internal pure returns (string memory str) {
		require(maxLen <= 64, "maxLen");
		bytes memory t;
		uint256 l = uint256(len);
		if (l > maxLen) {
			len = bytes32(maxLen);
		}
		assembly {
			mstore(t, len)
			mstore(add(t, 32), b1)
		}
		if (uint256(len) >= 16) {
			assembly {
				mstore(add(t, 64), b2)
			}
		}
		str = string(t);
	}
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/common/WithAdmin.sol


pragma solidity 0.8.2;

contract WithAdmin is Ownable {
	address public admin;
	event AdminSet(address admin);

	function setAdmin(address _admin) external onlyOwner {
		admin = _admin;
		emit AdminSet(_admin);
	}

	modifier onlyAdmin() {
		require(msg.sender == admin || msg.sender == owner(), "WA: not admin");
		_;
	}
}


// File contracts/crucible/CrucibleFactory.sol


pragma solidity 0.8.2;







/// @title Factory for generating crucible tokens
/// @author Ferrum Network
contract CrucibleFactory is
    CrucibleTokenDeployer,
    NoDelegateCall,
    ICrucibleFactory,
    WithAdmin
{
    uint64 constant MAX_FEE = 10000;
    address public immutable override router;
    mapping(bytes32 => address) private crucible;

    event CrucibleCreated(
        address token,
        address baseToken,
        uint256 feeOnTransferX10000,
        uint256 feeOnWithdrawX10000
    );

    constructor() {
        (router) = abi.decode(
            IFerrumDeployer(msg.sender).initData(),
            (address)
        );
    }

    /**
    @notice Returns the crucible address
    @param baseToken The base token address
    @param feeOnTransferX10000 Fee on transfer rate per 10k
    @param feeOnWithdrawX10000 Fee on withdraw rate per 10k
    @return The crucible address if any
     */
    function getCrucible(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external view override returns (address) {
        return
            crucible[
                crucibleKey(baseToken, feeOnTransferX10000, feeOnWithdrawX10000)
            ];
    }

    /**
    @notice Creates a crucible
    @param baseToken The base token address
    @param feeOnTransferX10000 Fee on transfer rate per 10k
    @param feeOnWithdrawX10000 Fee on withdraw rate per 10k
    @return token The created crucible address
     */
    function createCrucible(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external noDelegateCall returns (address token) {
        return
            _createCrucible(
                baseToken,
                safeName(baseToken),
                safeSymbol(baseToken),
                feeOnTransferX10000,
                feeOnWithdrawX10000
            );
    }

    /**
    @notice Creates a crucible directly
    @dev To be used only by contract admin in case normal crucible generation
         cannot succeed.
    @return token The created crucible token address
     */
    function createCrucibleDirect(
        address baseToken,
        string memory name,
        string memory symbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external onlyAdmin returns (address token) {
        bytes32 key = validateCrucible(
            baseToken,
            name,
            symbol,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
        return
            _createCrucibleWithName(
                key,
                baseToken,
                name,
                symbol,
                feeOnTransferX10000,
                feeOnWithdrawX10000
            );
    }

    /**
    @notice Tokens accumulated in the factory can be burned by anybody.
    @param token The token address
     */
    function burn(address token
    ) external {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IBurnable(token).burn(amount);
    }

    /**
     @notice Creats a crucible
     @param baseToken The base token
     @param name The name
     @param symbol The symbol
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     @return token The crucible token address
     */
    function _createCrucible(
        address baseToken,
        string memory name,
        string memory symbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) internal returns (address token) {
        bytes32 key = validateCrucible(
            baseToken,
            name,
            symbol,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
        string memory feeOnT = StringLib.uint2str(feeOnTransferX10000);
        string memory feeOnW = StringLib.uint2str(feeOnWithdrawX10000);
        string memory cName = string(
            abi.encodePacked("Crucible: ", name, " ", feeOnT, "X", feeOnW)
        );
        string memory cSymbol = string(
            abi.encodePacked(symbol, feeOnT, "X", feeOnW)
        );
        token = _createCrucibleWithName(
            key,
            baseToken,
            cName,
            cSymbol,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
    }

    /**
     @notice Validates crucible parameters
     @param baseToken The base token
     @param name The name
     @param symbol The symbol
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     */
    function validateCrucible(
        address baseToken,
        string memory name,
        string memory symbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) internal view returns (bytes32 key) {
        require(bytes(name).length != 0, "CF: name is required");
        require(bytes(symbol).length != 0, "CF: symbol is required");
        require(
            feeOnTransferX10000 != 0 || feeOnWithdrawX10000 != 0,
            "CF: at least one fee is required"
        );
        require(feeOnTransferX10000 < MAX_FEE, "CF: fee too high");
        require(feeOnWithdrawX10000 < MAX_FEE, "CF: fee too high");
        key = crucibleKey(baseToken, feeOnTransferX10000, feeOnWithdrawX10000);
        require(crucible[key] == address(0), "CF: already exists");
    }

    /**
     @notice Creates a crucible wit the given name
     @param key The crucible key
     @param baseToken The base token
     @param cName The name
     @param cSymbol The symbol
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     */
    function _createCrucibleWithName(
        bytes32 key,
        address baseToken,
        string memory cName,
        string memory cSymbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) internal returns (address token) {
        token = deploy(
            address(this),
            baseToken,
            feeOnTransferX10000,
            feeOnWithdrawX10000,
            cName,
            cSymbol
        );
        crucible[key] = token;
        emit CrucibleCreated(
            token,
            baseToken,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
    }

    /**
     @notice Returns a name or default
     @param token The token
     @return The name
     */
    function safeName(address token
    ) internal view returns (string memory) {
        (bool succ, bytes memory data) = token.staticcall(
            abi.encodeWithSignature(("name()"))
        );
        if (succ) {
            return abi.decode(data, (string));
        } else {
            return "Crucible";
        }
    }

    /**
     @notice returns the symbol or default
     @param token The token
     @return The symbol
     */
    function safeSymbol(address token
    ) internal view returns (string memory) {
        (bool succ, bytes memory data) = token.staticcall(
            abi.encodeWithSignature(("symbol()"))
        );
        require(succ, "CF: Token has no symbol");
        return abi.decode(data, (string));
    }

    /**
     @notice Creates a key for crucible
     @param baseToken The base token
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     @return The key
     */
    function crucibleKey(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    baseToken,
                    feeOnTransferX10000,
                    feeOnWithdrawX10000
                )
            );
    }
}


// File contracts/taxing/HasTaxDistributor.sol


pragma solidity ^0.8.0;


/**
 @notice A contract that uses tax distributer
 */
contract HasTaxDistributor is Ownable, IHasTaxDistributor {
	address public override taxDistributor;

    /**
     @notice Sets the tax distributor. Only owner can call this function
     @param _taxDistributor The tax distributor
     */
	function setTaxDistributor(address _taxDistributor) external onlyOwner {
		taxDistributor = _taxDistributor;
	}
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File hardhat/[email protected]


pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File contracts/common/signature/MultiSigLib.sol


pragma solidity 0.8.2;

library MultiSigLib {
	struct Sig { uint8 v; bytes32 r; bytes32 s; }

	/**
	 * Signature is encoded as below:
	 * every two bytes32, is an (r, s) pair.
	 * last bytes32 is the v's array.
	 * If we have more than 32 sigs, more
	 * bytes at the end are dedicated to vs.
	 */
	function parseSig(bytes memory multiSig)
	internal pure returns (Sig[] memory sigs) {
		uint cnt = multiSig.length / 32;
		cnt = cnt * 32 * 2 / (2*32+1);
		uint vLen = (multiSig.length / 32) - cnt;
		require(cnt - (cnt / 2 * 2) == 0, "MSL: Invalid sig size");
		sigs = new Sig[](cnt / 2);
		uint rPtr = 0x20;
		uint sPtr = 0x40;
		uint vPtr = multiSig.length - (vLen * 0x20) + 1;
		for (uint i=0; i<cnt / 2; i++) {
			bytes32 r;
			bytes32 s;
			uint8 v;
			assembly {
					r := mload(add(multiSig, rPtr))
					s := mload(add(multiSig, sPtr))
					v := mload(add(multiSig, vPtr))
			}
			rPtr = rPtr + 0x40;
			sPtr = sPtr + 0x40;
			vPtr = vPtr + 1;

			sigs[i].v = v;
			sigs[i].r = r;
			sigs[i].s = s;
		}
	}
}


// File contracts/common/signature/MultiSigCheckable.sol


pragma solidity 0.8.2;




/**
 @notice
    Base class for contracts handling multisig transactions
      Rules:
      - First set up the master governance quorum (groupId 1). onlyOwner
	  - Owner can remove public or custom quorums, but cannot remove governance
	  quorums.
	  - Once master governance is setup, governance can add / remove any quorums
	  - All actions can only be submitted to chain by admin or owner
 */
abstract contract MultiSigCheckable is WithAdmin, EIP712 {
    uint16 public constant GOVERNANCE_GROUP_ID_MAX = 256;
    uint32 constant WEEK = 3600 * 24 * 7;
    struct Quorum {
        address id;
        uint64 groupId; // GroupId: 0 => General, 1 => Governance, >1 => Custom
        uint16 minSignatures;
        // If the quorum is owned, only owner can change its config.
        // Owner must be a governence q (id <256)
        uint8 ownerGroupId;
    }
    event QuorumCreated(Quorum quorum);
    event QuorumUpdated(Quorum quorum);
    event AddedToQuorum(address quorumId, address subscriber);
    event RemovedFromQuorum(address quorumId, address subscriber);

    mapping(bytes32 => bool) public usedHashes;
    mapping(address => Quorum) public quorumSubscriptions; // Repeating quorum defs to reduce reads
    mapping(address => Quorum) public quorums;
    mapping(address => uint256) public quorumsSubscribers;
    address[] public quorumList; // Only for transparency. Not used. To sanity check quorums offchain

    modifier governanceGroupId(uint16 expectedGroupId) {
        require(
            expectedGroupId < GOVERNANCE_GROUP_ID_MAX,
            "MSC: must be governance"
        );
        _;
    }

    modifier expiryRange(uint64 expiry) {
        require(block.timestamp < expiry, "CR: signature timed out");
        require(expiry < block.timestamp + WEEK, "CR: expiry too far");
        _;
    }

    /**
     @notice Force remove from quorum (if managed)
        to allow last resort option in case a quorum
        goes rogue. Overwrite if you don't need an admin control
        No check on minSig so if the no of members drops below
        minSig, the quorum becomes unusable.
     @param _address The address to be removed from quorum
     */
    function forceRemoveFromQuorum(address _address)
        external
        virtual
        onlyAdmin
    {
        Quorum memory q = quorumSubscriptions[_address];
        require(q.id != address(0), "MSC: subscription not found");
        _removeFromQuorum(_address, q.id);
    }

    bytes32 constant REMOVE_FROM_QUORUM_METHOD =
        keccak256("RemoveFromQuorum(address _address,bytes32 salt,uint64 expiry)");

    /**
     @notice Removes an address from the quorum. Note the number of addresses 
      in the quorum cannot drop below minSignatures
     @param _address The address to remove
     @param salt The signature salt
     @param expiry The expiry
     @param multiSignature The multisig encoded signature
     */
    function removeFromQuorum(
        address _address,
        bytes32 salt,
        uint64 expiry,
        bytes memory multiSignature
    ) external expiryRange(expiry) {
        require(_address != address(0), "MSC: address required");
        require(salt != 0, "MSC: salt required");
        Quorum memory q = quorumSubscriptions[_address];
        require(q.id != address(0), "MSC: subscription not found");
        bytes32 message = keccak256(
            abi.encode(REMOVE_FROM_QUORUM_METHOD, _address, salt, expiry)
        );
        uint64 expectedGroupId = q.ownerGroupId != 0
            ? q.ownerGroupId
            : q.groupId;
        verifyUniqueSalt(message, salt, expectedGroupId, multiSignature);
        uint256 subs = quorumsSubscribers[q.id];
        require(subs >= q.minSignatures + 1, "MSC: quorum becomes ususable");
        _removeFromQuorum(_address, q.id);
    }

    bytes32 constant ADD_TO_QUORUM_METHOD =
        keccak256(
            "AddToQuorum(address _address,address quorumId,bytes32 salt,uint64 expiry)"
        );

    /**
     @notice Adds an address to the quorum
     @param _address The address to be added
     @param quorumId The quorum ID
     @param salt The signature salt
     @param expiry The expiry
     @param multiSignature The multisig encoded signature
     */
    function addToQuorum(
        address _address,
        address quorumId,
        bytes32 salt,
        uint64 expiry,
        bytes memory multiSignature
    ) external expiryRange(expiry) {
        require(quorumId != address(0), "MSC: quorumId required");
        require(_address != address(0), "MSC: address required");
        require(salt != 0, "MSC: salt required");
        bytes32 message = keccak256(
            abi.encode(ADD_TO_QUORUM_METHOD, _address, quorumId, salt, expiry)
        );
        Quorum memory q = quorums[quorumId];
        require(q.id != address(0), "MSC: quorum not found");
        uint64 expectedGroupId = q.ownerGroupId != 0
            ? q.ownerGroupId
            : q.groupId;
        verifyUniqueSalt(message, salt, expectedGroupId, multiSignature);
        quorumSubscriptions[_address] = q;
        quorumsSubscribers[q.id] += 1;
        emit AddedToQuorum(quorumId, _address);
    }

    bytes32 constant UPDATE_MIN_SIGNATURE_MEHTOD =
        keccak256(
            "UpdateMinSignature(address quorumId,uint16 minSignature,bytes32 salt,uint64 expiry)"
        );

    /**
     @notice Updates the min signature for a quorum
     @param quorumId The quorum ID
     @param minSignature The new minSignature
     @param salt The signature salt
     @param expiry The expiry
     @param multiSignature The multisig encoded signature
     */
    function updateMinSignature(
        address quorumId,
        uint16 minSignature,
        bytes32 salt,
        uint64 expiry,
        bytes memory multiSignature
    ) external expiryRange(expiry) {
        require(quorumId != address(0), "MSC: quorumId required");
        require(minSignature > 0, "MSC: minSignature required");
        require(salt != 0, "MSC: salt required");
        Quorum memory q = quorums[quorumId];
        require(q.id != address(0), "MSC: quorumId not found");
        require(
            quorumsSubscribers[q.id] >= minSignature,
            "MSC: minSignature is too large"
        );
        bytes32 message = keccak256(
            abi.encode(
                UPDATE_MIN_SIGNATURE_MEHTOD,
                quorumId,
                minSignature,
                salt,
                expiry
            )
        );
        uint64 expectedGroupId = q.ownerGroupId != 0
            ? q.ownerGroupId
            : q.groupId;
        verifyUniqueSalt(message, salt, expectedGroupId, multiSignature);
        quorums[quorumId].minSignatures = minSignature;
    }

    bytes32 constant CANCEL_SALTED_SIGNATURE =
        keccak256("CancelSaltedSignature(bytes32 salt)");

    /**
     @notice Cancel a salted signature
        Remove this method if public can create groupIds.
        People can write bots to prevent a person to execute a signed message.
        This is useful for cases that the signers have signed a message
        and decide to change it.
        They can cancel the salt first, then issue a new signed message.
     @param salt The signature salt
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
    */
    function cancelSaltedSignature(
        bytes32 salt,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) external virtual {
        require(salt != 0, "MSC: salt required");
        bytes32 message = keccak256(abi.encode(CANCEL_SALTED_SIGNATURE, salt));
        require(
            expectedGroupId != 0 && expectedGroupId < 256,
            "MSC: not governance groupId"
        );
        verifyUniqueSalt(message, salt, expectedGroupId, multiSignature);
    }

    /**
    @notice Initialize a quorum
        Override this to allow public creatig new quorums.
        If you allow public creating quorums, you MUST NOT have
        customized groupIds. Make sure groupId is created from
        hash of a quorum and is not duplicate.
    @param quorumId The unique quorumID
    @param groupId The groupID, which can be shared by quorums (if managed)
    @param minSignatures The minimum number of signatures for the quorum
    @param ownerGroupId The owner group ID. Can modify this quorum (if managed)
    @param addresses List of addresses in the quorum
    */
    function initialize(
        address quorumId,
        uint64 groupId,
        uint16 minSignatures,
        uint8 ownerGroupId,
        address[] calldata addresses
    ) public virtual onlyAdmin {
        _initialize(quorumId, groupId, minSignatures, ownerGroupId, addresses);
    }

    /**
     @notice Initializes a quorum
     @param quorumId The quorum ID
     @param groupId The group ID
     @param minSignatures The min signatures
     @param ownerGroupId The owner group ID
     @param addresses The initial addresses in the quorum
     */
    function _initialize(
        address quorumId,
        uint64 groupId,
        uint16 minSignatures,
        uint8 ownerGroupId,
        address[] calldata addresses
    ) internal virtual {
        require(quorumId != address(0), "MSC: quorumId required");
        require(addresses.length > 0, "MSC: addresses required");
        require(minSignatures != 0, "MSC: minSignatures required");
        require(
            minSignatures <= addresses.length,
            "MSC: minSignatures too large"
        );
        require(quorums[quorumId].id == address(0), "MSC: already initialized");
        Quorum memory q = Quorum({
            id: quorumId,
            groupId: groupId,
            minSignatures: minSignatures,
            ownerGroupId: ownerGroupId
        });
        quorums[quorumId] = q;
        quorumList.push(quorumId);
        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                quorumSubscriptions[addresses[i]].id == address(0),
                "MSC: only one quorum per subscriber"
            );
            quorumSubscriptions[addresses[i]] = q;
        }
        quorumsSubscribers[quorumId] = addresses.length;
        emit QuorumCreated(q);
    }

    /**
     @notice Remove an address from the quorum
     @param _address the address
     @param qId The quorum ID
     */
    function _removeFromQuorum(address _address, address qId) internal {
        delete quorumSubscriptions[_address];
        quorumsSubscribers[qId] = quorumsSubscribers[qId] - 1;
        emit RemovedFromQuorum(qId, _address);
    }

    /**
     @notice Checking salt's uniqueness because same message can be signed with different people.
     @param message The message to verify
     @param salt The salt to be unique
     @param expectedGroupId The expected group ID
     @param multiSignature The signatures formatted as a multisig
     */
    function verifyUniqueSalt(
        bytes32 message,
        bytes32 salt,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal {
        require(multiSignature.length != 0, "MSC: multiSignature required");
        (, bool result) = tryVerify(message, expectedGroupId, multiSignature);
        require(result, "MSC: Invalid signature");
        require(!usedHashes[salt], "MSC: Message already used");
        usedHashes[salt] = true;
    }

    /**
     @notice Verifies the a unique un-salted message
     @param message The message hash
     @param expectedGroupId The expected group ID
     @param multiSignature The signatures formatted as a multisig
     */
    function verifyUniqueMessageDigest(
        bytes32 message,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal {
        require(multiSignature.length != 0, "MSC: multiSignature required");
        (bytes32 salt, bool result) = tryVerify(
            message,
            expectedGroupId,
            multiSignature
        );
        require(result, "MSC: Invalid signature");
        require(!usedHashes[salt], "MSC: Message digest already used");
        usedHashes[salt] = true;
    }

    /**
     @notice Tries to verify a digest message
     @param digest The digest
     @param expectedGroupId The expected group ID
     @param multiSignature The signatures formatted as a multisig
     @return result Identifies success or failure
     */
    function tryVerifyDigest(
        bytes32 digest,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal view returns (bool result) {
        (result, ) = tryVerifyDigestWithAddress(
            digest,
            expectedGroupId,
            multiSignature
        );
    }

    /**
     @notice Returns if the digest can be verified
     @param digest The digest
     @param expectedGroupId The expected group ID
     @param multiSignature The signatures formatted as a multisig
     @return result Identifies success or failure
     @return signers Lis of signers
     */
    function tryVerifyDigestWithAddress(
        bytes32 digest,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal view returns (bool result, address[] memory signers) {
        require(multiSignature.length != 0, "MSC: multiSignature required");
        MultiSigLib.Sig[] memory signatures = MultiSigLib.parseSig(
            multiSignature
        );
        require(signatures.length > 0, "MSC: no zero len signatures");
        signers = new address[](signatures.length);

        address _signer = ECDSA.recover(
            digest,
            signatures[0].v,
            signatures[0].r,
            signatures[0].s
        );
        address quorumId = quorumSubscriptions[_signer].id;
        if (quorumId == address(0)) {
            return (false, new address[](0));
        }
        Quorum memory q = quorums[quorumId];
        for (uint256 i = 1; i < signatures.length; i++) {
            // console.log("About to do signature", i);
            // console.logBytes32(_domainSeparatorV4());
            // console.logBytes32(digest);
            _signer = ECDSA.recover(
                digest,
                signatures[i].v,
                signatures[i].r,
                signatures[i].s
            );
            // console.log("Signer", _signer);
            quorumId = quorumSubscriptions[_signer].id;
            if (quorumId == address(0)) {
                return (false, new address[](0));
            }
            require(
                q.id == quorumId,
                "MSC: all signers must be of same quorum"
            );

            require(
                expectedGroupId == 0 || q.groupId == expectedGroupId,
                "MSC: invalid groupId for signer"
            );
            signers[i] = _signer;
        }
        require(
            signatures.length >= q.minSignatures,
            "MSC: not enough signatures"
        );
        return (true, signers);
    }

    /**
     @notice Tries to verify a message hash
        @dev example message;

        bytes32 constant METHOD_SIG =
            keccak256("WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt)");
        bytes32 message = keccak256(abi.encode(
          METHOD_SIG,
          token,
          payee,
          amount,
          salt
     @param message The message
     @param expectedGroupId The expected group ID
     @param multiSignature The signatures formatted as a multisig
    */
    function tryVerify(
        bytes32 message,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal view returns (bytes32 digest, bool result) {
        digest = _hashTypedDataV4(message);
        result = tryVerifyDigest(digest, expectedGroupId, multiSignature);
    }
}


// File contracts/common/signature/SigCheckable.sol


pragma solidity ^0.8.0;


/**
 @dev Make sure to define method signatures
 */
abstract contract SigCheckable is EIP712 {
    mapping(bytes32=>bool) public usedHashes;

    function signerUnique(
        bytes32 message,
        bytes memory signature) internal returns (address _signer) {
        bytes32 digest;
        (digest, _signer) = signer(message, signature);
        require(!usedHashes[digest], "Message already used");
        usedHashes[digest] = true;
    }

    /*
        @dev example message;

        bytes32 constant METHOD_SIG =
            keccak256("WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt)");
        bytes32 message = keccak256(abi.encode(
          METHOD_SIG,
          token,
          payee,
          amount,
          salt
    */
    function signer(
        bytes32 message,
        bytes memory signature) internal view returns (bytes32 digest, address _signer) {
        digest = _hashTypedDataV4(message);
        _signer = ECDSA.recover(digest, signature);
    }
}


// File contracts/common/signature/Allocatable.sol


pragma solidity ^0.8.0;


abstract contract Allocatable is SigCheckable, WithAdmin {
    mapping(address => bool) public signers;

    function addSigner(address _signer) external onlyOwner() {
        require(_signer != address(0), "Bad signer");
        signers[_signer] = true;
    }

    function removeSigner(address _signer) external onlyOwner() {
        require(_signer != address(0), "Bad signer");
        delete signers[_signer];
    }

    bytes32 constant AMOUNT_SIGNED_METHOD =
        keccak256("AmountSigned(bytes4 method, address token,address payee,address to,uint256 amount,uint64 expiry,bytes32 salt)");
    function amountSignedMessage(
			bytes4 method,
            address token,
            address payee,
            address to,
            uint256 amount,
			uint64 expiry,
            bytes32 salt)
    internal pure returns (bytes32) {
        return keccak256(abi.encode(
          AMOUNT_SIGNED_METHOD,
		  method,
          token,
          payee,
		  to,
          amount,
		  expiry,
          salt));
    }

    function verifyAmountUnique(
			bytes4 method,
            address token,
            address payee,
            address to,
            uint256 amount,
            bytes32 salt,
			uint64 expiry,
            bytes memory signature)
    internal {
		require(expiry == 0 || block.timestamp > expiry, "Allocatable: sig expired");
        bytes32 message = amountSignedMessage(method, token, payee, to, amount, expiry, salt);
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "Allocatable: Invalid signer");
	}

    function verifyAmount(
			bytes4 method,
            address token,
            address payee,
            address to,
            uint256 amount,
            bytes32 salt,
			uint64 expiry,
            bytes memory signature)
    internal view {
		require(expiry == 0 || block.timestamp > expiry, "Allocatable: sig expired");
        bytes32 message = amountSignedMessage(method, token, payee, to, amount, expiry, salt);
        (,address _signer) = signer(message, signature);
        require(signers[_signer], "Allocatable: Invalid signer");
	}
}


// File contracts/common/SafeAmount.sol


pragma solidity 0.8.2;

library SafeAmount {
    using SafeERC20 for IERC20;

    /**
     @notice transfer tokens from. Incorporate fee on transfer tokens
     @param token The token
     @param from From address
     @param to To address
     @param amount The amount
     @return result The actual amount transferred
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount) internal returns (uint256 result) {
        uint256 preBalance = IERC20(token).balanceOf(to);
        IERC20(token).safeTransferFrom(from, to, amount);
        uint256 postBalance = IERC20(token).balanceOf(to);
        result = postBalance - preBalance;
        require(result <= amount, "SA: actual amount larger than transfer amount");
    }

    /**
     @notice Sends ETH
     @param to The to address
     @param value The amount
     */
	function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/crucible/CrucibleRouter.sol


pragma solidity 0.8.2;











/**
 @notice The Crucible Router
 @author Ferrum Network
 */
contract CrucibleRouter is MultiSigCheckable, HasTaxDistributor, ReentrancyGuard {
    using SafeERC20 for IERC20;
    string public constant NAME = "FERRUM_CRUCIBLE_ROUTER";
    string public constant VERSION = "000.001";

    // Using a struct to reduced number of variable in methods.
    struct Amounts {
        uint256 base;
        uint256 pair;
        bool isWeth;
    }

    mapping(address => uint256) public openCaps;
    mapping(address => uint16) public delegatedGroupIds;

    constructor() EIP712(NAME, VERSION) {}

    receive() external payable {
    }

    /**
     @notice Can upgrade router on a crucible
     @param crucible The crucible 
     @param newRouter The new router
     @dev Only callable by admin for router upgrade in future
     */
    function upgradeRouter(address crucible, address newRouter
    ) external onlyOwner {
        require(crucible != address(0), "CR: crucible required");
        require(newRouter != address(0), "CR: newRouter required");
        ICrucibleToken(crucible).upgradeRouter(newRouter);
    }

    bytes32 constant DELEGATE_GROUP_ID =
        keccak256("DelegateGroupId(address crucible,uint16 delegatedGroupId)");
    /**
     @notice Sets a delageted group ID. Once set this group ID can 
         produce signatures for allocations.
     @param crucible The crucible
     @param delegatedGroupId The delegated group ID
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     */
    function delegateGroupId(
        address crucible,
        uint16 delegatedGroupId,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) external expiryRange(expiry) {
        bytes32 message = keccak256(
            abi.encode(DELEGATE_GROUP_ID, crucible, delegatedGroupId, salt, expiry)
        );
        verifyUniqueSalt(
            message,
            salt,
            expectedGid(crucible, expectedGroupId),
            multiSignature
        );
        delegatedGroupIds[crucible] = delegatedGroupId;
    }

    bytes32 constant SET_OPEN_CAP =
        keccak256("SetOpenCap(address crucible,uint256 cap,bytes32 salt,uint64 expiry)");
    /**
     @notice Sets the open cap for a crucible
     @param crucible The crucible address
     @param cap The cap
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     */
    function setOpenCap(
        address crucible,
        uint256 cap,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) external expiryRange(expiry) {
        bytes32 message = keccak256(
            abi.encode(SET_OPEN_CAP, crucible, cap, salt, expiry)
        );
        verifyUniqueSalt(
            message,
            salt,
            expectedGid(crucible, expectedGroupId),
            multiSignature
        );
        openCaps[crucible] = cap;
    }

    bytes32 constant DEPOSIT_METHOD =
        keccak256(
            "Deposit(address to,address crucible,uint256 amount,bytes32 salt,uint64 expiry)"
        );
    /**
     @notice Deposits into a crucible
     @param to The receiver of crucible tokens
     @param crucible The crucible address
     @param amount The deposit amount
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     @return The amount deposited
     */
    function deposit(
        address to,
        address crucible,
        uint256 amount,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) external expiryRange(expiry) nonReentrant returns (uint256) {
        require(amount != 0, "CR: amount required");
        require(to != address(0), "CR: to required");
        require(crucible != address(0), "CR: crucible required");
        if (multiSignature.length != 0) {
            verifyDepositSignature(
                to,
                crucible,
                amount,
                salt,
                expiry,
                expectedGroupId,
                multiSignature
            );
        } else {
            amount = amountFromOpenCap(crucible, amount);
        }
        address token = ICrucibleToken(crucible).baseToken();
        require(SafeAmount.safeTransferFrom(token, msg.sender, crucible, amount) != 0, "CR: nothing transferred");
        return ICrucibleToken(crucible).deposit(to);
    }

    /**
     @notice Deposit into crucible without allocation
     @param to Address of the receiver of crucible
     @param crucible The crucible token
     @param amount The amount to be deposited
     @return The deposited amount
     */
    function depositOpen(
        address to,
        address crucible,
        uint256 amount
    ) external nonReentrant returns (uint256) {
        require(amount != 0, "CR: amount required");
        require(to != address(0), "CR: to required");
        require(crucible != address(0), "CR: crucible required");
        address token = ICrucibleToken(crucible).baseToken();
        amount = amountFromOpenCap(crucible, amount);
        require(SafeAmount.safeTransferFrom(token, msg.sender, crucible, amount) != 0, "CR: nothing transferred");
        return ICrucibleToken(crucible).deposit(to);
    }

    /**
     @notice Deposit and stake in one transaction
     @param to Address of the reciever of stake
     @param crucible The crucible address
     @param amount The amount to be deposited
     @param stake The staking contract address
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     */
    function depositAndStake(
        address to,
        address crucible,
        uint256 amount,
        address stake,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) nonReentrant external {
        require(amount != 0, "CR: amount required");
        require(to != address(0), "CR: to required");
        require(crucible != address(0), "CR: crucible required");
        require(stake != address(0), "CR: stake required");
        if (multiSignature.length != 0) {
            verifyDepositSignature(
                to,
                crucible,
                amount,
                salt,
                expiry,
                expectedGroupId,
                multiSignature
            );
        } else {
            amount = amountFromOpenCap(crucible, amount);
        }

        address token = ICrucibleToken(crucible).baseToken();
        require(SafeAmount.safeTransferFrom(token, msg.sender, crucible, amount) != 0, "CR: nothing transferred");
        require(ICrucibleToken(crucible).deposit(stake) != 0, "CR: nothing depositted");
        IStakeFor(stake).stakeFor(to, crucible);
    }

    /**
     @notice Deposit and add liquidity and stake the LP token in one transaction
     @param to Address of the reciever of stake
     @param crucible The crucible address
     @param pairToken The pair token for liquidity
     @param baseAmount The amount of the base token
     @param pairAmount The amount of the pair token
     @param ammRouter The UNIV2 compatible AMM router for liquidity adding
     @param stake The staking contract address
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     */
    function depositAddLiquidityStake(
        address to,
        address crucible,
        address pairToken,
        uint256 baseAmount,
        uint256 pairAmount,
        address ammRouter,
        address stake,
        bytes32 salt,
        uint64 expiry,
        uint256 deadline,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) nonReentrant external {
        if (multiSignature.length != 0) {
            verifyDepositSig(
                to,
                crucible,
                pairToken,
                baseAmount,
                pairAmount,
                ammRouter,
                stake,
                salt,
                expiry,
                expectedGroupId,
                multiSignature
            );
        } else {
            baseAmount = amountFromOpenCap(crucible, baseAmount);
        }
        {
        pairAmount = SafeAmount.safeTransferFrom(
            pairToken,
            msg.sender,
            address(this),
            pairAmount
        );
        baseAmount = _depositToken(crucible, baseAmount);
        Amounts memory amounts = Amounts({
            base: baseAmount,
            pair: pairAmount,
            isWeth: false
        });
        _addDepositToLiquidity(
            stake,
            crucible,
            pairToken,
            amounts,
            IUniswapV2Router01(ammRouter),
            deadline
        );
        }
        {
            address pool = IUniswapV2Factory(IUniswapV2Router01(ammRouter).factory())
                .getPair(pairToken, crucible);
            require(pool != address(0), "CR: pool does not exist");
            IStakeFor(stake).stakeFor(to, pool);
        }
    }

    /**
     @notice Deposit and add liquidity with ETH and stake the LP token in one transaction
     @param to Address of the reciever of stake
     @param crucible The crucible address
     @param baseAmount The amount of the base token
     @param ammRouter The UNIV2 compatible AMM router for liquidity adding
     @param stake The staking contract address
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     */
    function depositAddLiquidityStakeETH(
        address to,
        address crucible,
        uint256 baseAmount,
        address ammRouter,
        address stake,
        bytes32 salt,
        uint64 expiry,
        uint64 deadline,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) external nonReentrant payable {
        address weth = IUniswapV2Router01(ammRouter).WETH();
        if (multiSignature.length != 0) {
            verifyDepositSig(
                to,
                crucible,
                weth,
                baseAmount,
                msg.value,
                ammRouter,
                stake,
                salt,
                expiry,
                expectedGroupId,
                multiSignature
            );
        } else {
            baseAmount = amountFromOpenCap(crucible, baseAmount);
        }
        IWETH(weth).deposit{value: msg.value}();
        baseAmount = _depositToken(crucible, baseAmount);
        Amounts memory amounts = Amounts({
            base: baseAmount,
            pair: msg.value,
            isWeth: true
        });
        _addDepositToLiquidity(
            stake,
            crucible,
            weth,
            amounts,
            IUniswapV2Router01(ammRouter),
            deadline
        );
        {
            address pool = IUniswapV2Factory(IUniswapV2Router01(ammRouter).factory())
                .getPair(weth, crucible);
            require(pool != address(0), "CR: pool does not exist");
            IStakeFor(stake).stakeFor(to, pool);
        }
    }

    /**
     @notice Sakes for another address
     @dev Use this with crucible users to reduce the need for another approval request
     @param to Address of the reciever of stake
     @param token The token
     @param stake The staking contract address
     @param amount The amount of stake
     */
    function stakeFor(
        address to,
        address token,
        address stake,
        uint256 amount
    ) external {
        require(to != address(0), "CR: Invalid to");
        require(token != address(0), "CR: Invalid token");
        require(stake != address(0), "CR: Invalid stake");
        require(amount != 0, "CR: Invalid amount");
        require(SafeAmount.safeTransferFrom(token, msg.sender, stake, amount) != 0, "CR: nothing transferred");
        IStakeFor(stake).stakeFor(to, token);
    }

    bytes32 constant OVERRIDE_FEE_METHOD =
        keccak256(
            "OverrideFee(address crucible,address target,uint8 overrideType,uint64 newFeeX10000,bytes32 salt,uint64 expiry)"
        );
    /**
     @notice Overrides the fee for a given address
     @param crucible The crucible address
     @param target The fee target
     @param overrideType The type of override
     @param newFeeX10000 The new fee on the 10k basis
     @param salt The signature salt
     @param expiry Signature expiry
     @param expectedGroupId Expected group ID for the signature
     @param multiSignature The multisig encoded signature
     */
    function overrideFee(
        address crucible,
        address target,
        ICrucibleToken.OverrideState overrideType,
        uint64 newFeeX10000,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) external expiryRange(expiry) {
        bytes32 message = keccak256(
            abi.encode(
                OVERRIDE_FEE_METHOD,
                crucible,
                target,
                uint8(overrideType),
                newFeeX10000,
                salt,
                expiry
            )
        );
        verifyUniqueSalt(
            message,
            salt,
            expectedGid(crucible, expectedGroupId),
            multiSignature
        );
        ICrucibleToken(crucible).overrideFee(
            target,
            overrideType,
            newFeeX10000
        );
    }

    /**
     @notice Verifies the deposite signature
     @param to The to address
     @param crucible The crucible
     @param amount The amount
     @param salt The salt
     @param expiry The expiry
     @param expectedGroupId The expected group ID
     @param multiSignature The multisig encoded signature
     */
    function verifyDepositSignature(
        address to,
        address crucible,
        uint256 amount,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) private {
        bytes32 message = keccak256(
            abi.encode(DEPOSIT_METHOD, to, crucible, amount, salt, expiry)
        );
        verifyUniqueSalt(
            message,
            salt,
            expectedGid(crucible, expectedGroupId),
            multiSignature
        );
    }

    /**
     @notice Return amount left from the open cap
     @param crucible The crucible
     @param amount The amount
     @return The cap
     */
    function amountFromOpenCap(address crucible, uint256 amount
    ) private returns (uint256) {
        uint256 cap = openCaps[crucible];
        require(cap != 0, "CR: Crucible not open");
        if (cap > amount) {
            cap = cap - amount;
        } else {
            amount = cap;
            cap = 0;
        }
        openCaps[crucible] = cap;
        return amount;
    }

    /**
     @notice Adds deposit to liquidity
     @param to The to address
     @param crucible The crucible
     @param pairToken The pair token
     @param amounts The amounts array
     @param ammRouter The amm router
     @param deadline The deadline
     */
    function _addDepositToLiquidity(
        address to,
        address crucible,
        address pairToken,
        Amounts memory amounts,
        IUniswapV2Router01 ammRouter,
        uint256 deadline
    ) private {
        approveIfRequired(crucible, address(ammRouter), amounts.base);
        approveIfRequired(pairToken, address(ammRouter), amounts.pair);
        (uint256 amountA, uint256 amountB, ) = ammRouter.addLiquidity(
            crucible,
            pairToken,
            amounts.base,
            amounts.pair,
            0,
            0,
            to,
            deadline
        );
        uint256 crucibleLeft = amounts.base - amountA;
        if (crucibleLeft != 0) {
            IERC20(crucible).transfer(msg.sender, crucibleLeft);
        }
        uint256 pairLeft = amounts.pair - amountB;
        if (pairLeft != 0) {
            if (amounts.isWeth) {
                IWETH(pairToken).withdraw(pairLeft);
                SafeAmount.safeTransferETH(msg.sender, pairLeft); // refund dust eth, if any. No need to check the return value
            } else {
                IERC20(pairToken).safeTransfer(msg.sender, pairLeft);
            }
        }
    }

    bytes32 DEPOSIT_ADD_LIQUIDITY_STAKE_METHOD =
        keccak256(
            "DepositAddLiquidityStake(address to,address crucible,address pairToken,uint256 baseAmount,uint256 pairAmount,address ammRouter,address stake,bytes32 salt,uint64 expiry)"
        );
    /**
     @notice Verifies the deposite signature
     @param to The to address
     @param crucible The crucible
     @param pairToken The pair token
     @param baseAmount The base amount
     @param pairAmount The pair amount
     @param ammRouter The amm router
     @param stake The stake
     @param salt The salt
     @param expiry The expiry
     @param expectedGroupId The expected group ID
     @param multiSignature The multisig encoded signature
     */
    function verifyDepositSig(
        address to,
        address crucible,
        address pairToken,
        uint256 baseAmount,
        uint256 pairAmount,
        address ammRouter,
        address stake,
        bytes32 salt,
        uint64 expiry,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) private expiryRange(expiry) {
        bytes32 message = keccak256(
            abi.encode(
                DEPOSIT_ADD_LIQUIDITY_STAKE_METHOD,
                to,
                crucible,
                pairToken,
                baseAmount,
                pairAmount,
                ammRouter,
                stake,
                salt,
                expiry
            )
        );
        verifyUniqueMessageDigest(
            message,
            expectedGid(crucible, expectedGroupId),
            multiSignature
        );
    }

    /**
     @notice Approves the contract on the amm router if required
     @param token The token
     @param router The router
     @param amount The amount
     */
    function approveIfRequired(
        address token,
        address router,
        uint256 amount
    ) private {
        uint256 allowance = IERC20(token).allowance(address(this), router);
        if (allowance < amount) {
            if (allowance != 0) {
                IERC20(token).safeApprove(router, 0);
            }
            IERC20(token).safeApprove(router, type(uint256).max);
        }
    }

    /**
     @notice Deposits token into crucible
     @param crucible The crucible
     @param amount The amount
     @return The deposited amount
     */
    function _depositToken(address crucible, uint256 amount
    ) private returns (uint256) {
        address token = ICrucibleToken(crucible).baseToken();
        require(SafeAmount.safeTransferFrom(token, msg.sender, crucible, amount) != 0, "CR: nothing transferred");
        return ICrucibleToken(crucible).deposit(address(this));
    }

    /**
     @notice Returns the expected group ID
     @param crucible The crucible
     @param expected Initially expected group ID
     @return gid The expected group ID
     */
    function expectedGid(address crucible, uint64 expected
    ) private view returns (uint64 gid) {
        gid = expected;
        require(
            expected < 256 || delegatedGroupIds[crucible] == expected,
            "CR: bad groupId"
        );
        require(gid != 0, "CR: gov or delegate groupId required");
    }
}