/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// File: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/interfaces/IUniswapV2.sol


pragma solidity ^0.6.0;


interface IUniRouter {
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
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

    function getPair(IERC20 tokenA, IERC20 tokenB)
        external
        view
        returns (IUniswapV2Exchange pair);
}

interface IUniswapV2Exchange {
    //event Approval(address indexed owner, address indexed spender, uint value);
    //event Transfer(address indexed from, address indexed to, uint value);

    //function name() external pure returns (string memory);
    //function symbol() external pure returns (string memory);
    //function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    //function allowance(address owner, address spender) external view returns (uint);
    //function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);

    //function transferFrom(address from, address to, uint value) external returns (bool);
    //function DOMAIN_SEPARATOR() external view returns (bytes32);
    //function PERMIT_TYPEHASH() external pure returns (bytes32);
    //function nonces(address owner) external view returns (uint);

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    //event Mint(address indexed sender, uint amount0, uint amount1);
    //event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    /*event Swap(
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

function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    */
}

// File: contracts/interfaces/IExternalPool.sol


pragma solidity ^0.6.0;

abstract contract IExternalPool {
    address public enterToken;

    function getPoolValue(address denominator)
        external
        view
        virtual
        returns (uint256);

    function getTokenStaked() external view virtual returns (uint256);

    function addPosition() external virtual returns (uint256);

    function exitPosition(uint256 amount) external virtual;

    function claimValue() external virtual;

    function transferTokenTo(
        address TokenAddress,
        address recipient,
        uint256 amount
    ) external virtual returns (uint256);
}

// File: contracts/interfaces/ISFToken.sol


pragma solidity ^0.6.0;

interface ISFToken {
    function rebase(uint256 totalSupply) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/interfaces/ICHI.sol


pragma solidity ^0.6.12;

interface ICHI {
    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256);

    function freeUpTo(uint256 value) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(uint256 value) external;
}

// File: contracts/CHIBurner.sol


pragma solidity ^0.6.12;


contract CHIBurner {
    address internal constant CHI_ADDRESS =
        0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    ICHI internal constant chi = ICHI(CHI_ADDRESS);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;

        uint256 gasLeft = gasleft();
        uint256 gasSpent = 21000 + gasStart - gasLeft + 16 * msg.data.length;

        chi.freeUpTo((gasSpent + 14154) / 41947);
    }
}

// File: contracts/utils/SafeERC20.sol

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol


pragma solidity ^0.6.12;


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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token != IERC20(0)) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            require(
                from == msg.sender && msg.value >= amount,
                "msg.value is zero"
            );
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

// File: contracts/interfaces/IXChanger.sol


pragma solidity ^0.6.0;


interface XChanger {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) external payable returns (uint256 result);

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256[3] memory swapAmountsIn,
            uint256[3] memory swapAmountsOut,
            bool swapVia
        );

    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    )
        external
        view
        returns (
            uint256 inputAmount,
            uint256[3] memory swapAmountsIn,
            uint256[3] memory swapAmountsOut,
            bool swapVia
        );
}

// File: contracts/XChangerUser.sol


pragma solidity ^0.6.12;



/**
 * @dev Helper contract to communicate to XChanger(XTrinity) contract to obtain prices and change tokens as needed
 */
contract XChangerUser {
    using UniversalERC20 for IERC20;

    XChanger public xchanger;

    /**
     * @dev get a price of one token amount in another
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken
     */

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            try xchanger.quote(fromToken, toToken, amount) returns (
                uint256 _returnAmount,
                uint256[3] memory, //swapAmountsIn,
                uint256[3] memory, //swapAmountsOut,
                bool //swapVia
            ) {
                returnAmount = _returnAmount;
            } catch {}
        }
    }

    /**
     * @dev get a reverse price of one token amount in another
     * the opposite of above 'quote' method when we need to understand how much we need to spend actually
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param returnAmount - of the toToken
     */
    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    ) public view returns (uint256 inputAmount) {
        if (fromToken == toToken) {
            inputAmount = returnAmount;
        } else {
            try
                xchanger.reverseQuote(fromToken, toToken, returnAmount)
            returns (
                uint256 _inputAmount,
                uint256[3] memory, //swapAmountsIn,
                uint256[3] memory, //swapAmountsOut,
                bool // swapVia
            ) {
                inputAmount = _inputAmount;
                inputAmount += 1; // Curve requires this
            } catch {}
        }
    }

    /**
     * @dev swap one token to another given the amount we want to spend
     
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken we are spending
     * @param slipProtect - flag to ensure the transaction will be performed if the received amount is not less than expected within the given slip %% range (like 1%)
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable returns (uint256 returnAmount) {
        if (fromToken.allowance(address(this), address(xchanger)) < amount) {
            fromToken.universalApprove(address(xchanger), 0);
            fromToken.universalApprove(address(xchanger), uint256(-1));
        }

        returnAmount = xchanger.swap(fromToken, toToken, amount, slipProtect);
    }
}

// File: contracts/interfaces/IWETH.sol


pragma solidity ^0.6.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// File: contracts/access/Context.sol


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

// File: contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    function initialize() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

    /**
     * @dev useful addon to limit one call per block - to be used with multiple different excluding methods - e.g. mint and burn
     *
     */

    mapping(address => uint256) public lastblock;

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

        /**
         * @dev useful addon to limit one call per block - to be used with multiple different excluding methods - e.g. mint and burn
         *
         */
        require(
            lastblock[tx.origin] != block.number,
            "Reentrancy: this block is used"
        );
        lastblock[tx.origin] = block.number;

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/ValueHolder.sol


pragma solidity ^0.6.12;









/**
 * @title ValueHolder main administrative contract
 * @dev Main contract controlling the Mint/Burn/Rebase operations of a token.
 * Retrieves values from a multiple external/internal (Uni) pools in denominated [DAI] tokens
 */
contract ValueHolder is Ownable, CHIBurner, XChangerUser, ReentrancyGuard {
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;

    mapping(uint256 => address) public uniPools;
    mapping(uint256 => address) public externalPools;

    uint256 public uniLen;
    uint256 public extLen;

    address public SFToken;
    address public denominateTo;
    uint8 private denominateDecimals;
    uint8 private sfDecimals;

    address public votedPool;
    enum PoolType {EXT, UNI}
    PoolType public votedPoolType;

    uint256 public votedFee; // 1% = 100
    uint256 public votedPerformanceFee; // 1% = 100
    uint256 public votedChi; // number of Chi to hold

    uint256 private constant fpDigits = 8;
    uint256 private constant fpNumbers = 10**fpDigits;

    event LogValueManagerUpdated(address Manager);
    event LogVoterUpdated(address Voter);
    event LogVotedExtPoolUpdated(address pool, PoolType poolType);
    event LogVotedUniPoolUpdated(address pool);
    event LogSFTokenUpdated(address _NewSFToken);
    event LogXChangerUpdated(address _NewXChanger);
    event LogFeeUpdated(uint256 newFee);
    event LogPerformanceFeeUpdated(uint256 newFee);
    event LogFeeTaken(uint256 feeAmount);
    event LogMintTaken(uint256 fromTokenAmount);
    event LogBurnGiven(uint256 toTokenAmount);
    event LogChiToppedUpdated(uint256 spendAmount);
    address public ValueManager;

    //address private constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IERC20 private constant WETH_ADDRESS =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    bool private initialized;

    /**
     * @dev some functions should be available only to Value Manager address
     */
    modifier onlyValueManager() {
        require(msg.sender == ValueManager, "Not Value Manager");
        _;
    }

    /**
     * @dev some functions should be available only to Voter address - separate contract is TBD
     */
    address public Voter;
    modifier onlyVoter() {
        require(msg.sender == Voter, "Not Voter");
        _;
    }

    /**
     * @dev for some methods we are not interested in being accessed by attacking contracts. Yes, we know this is not a useful pattern.
     * But why? We love the idea of using EOA, contracts need to have a clear use case.
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    /**
     * @dev initializer method instead of a constructor - to be used behind a proxy
     */
    function init(
        address _votePool,
        PoolType _votePoolType,
        address _sfToken,
        address _Xchanger
    ) public {
        //XChanger._init();
        require(!initialized, "Initialized");
        initialized = true;
        _initVariables(_votePool, _votePoolType, _sfToken, _Xchanger);
        Ownable.initialize(); // Do not forget this call!
    }

    /**
     * @dev internal variable initialization
     * @param _votePool - main pool to add value by default
     * @param _votePoolType - main pool type (External or Uni)
     * @param _sfToken - main S/F ERC20 token
     * @param _Xchanger - XChanger(XTrinity) contract to be used for quotes and swaps
     */
    function _initVariables(
        address _votePool,
        PoolType _votePoolType,
        address _sfToken,
        address _Xchanger
    ) internal {
        uniLen = 0;
        extLen = 0;
        //0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f UNI

        externalPools[extLen] = _votePool;
        extLen++;

        votedPool = _votePool;
        votedPoolType = _votePoolType;
        if (votedPoolType == PoolType.UNI) {
            uniPools[uniLen] = _votePool;
            uniLen++;
        }

        emit LogVotedExtPoolUpdated(_votePool, _votePoolType);

        denominateTo = DAI_ADDRESS; //0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        denominateDecimals = IERC20(denominateTo).decimals();
        SFToken = _sfToken;
        sfDecimals = IERC20(_sfToken).decimals();
        ValueManager = msg.sender;
        Voter = msg.sender;
        xchanger = XChanger(_Xchanger);
        votedFee = 200;
        votedChi = 10;
        votedPerformanceFee = 1000;
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit(
        address _extPool,
        PoolType _votePoolType,
        address _sfToken,
        address _Xchanger
    ) public onlyOwner {
        _initVariables(_extPool, _votePoolType, _sfToken, _Xchanger);
    }

    /**
     * @dev set a new S/F ERC20 token address - only if we need to
     *
     */
    function setSFToken(address _NewSFToken) public onlyVoter {
        SFToken = _NewSFToken;
        sfDecimals = IERC20(_NewSFToken).decimals();
        emit LogSFTokenUpdated(_NewSFToken);
    }

    /**
     * @dev set new Value Manager address
     */
    function setValueManager(address _ValueManager) external onlyOwner {
        ValueManager = _ValueManager;
        emit LogValueManagerUpdated(_ValueManager);
    }

    /**
     * @dev set new Voter address
     */
    function setVoter(address _Voter) external onlyOwner {
        Voter = _Voter;
        emit LogVoterUpdated(_Voter);
    }

    /**
     * @dev set new XChanger/XTrinity address
     */
    function setXChangerImpl(address _Xchanger) external onlyVoter {
        xchanger = XChanger(_Xchanger);
        emit LogSFTokenUpdated(_Xchanger);
    }

    /**
     * @dev set new Voted (default) pool for adding value
     */
    function setVotedPool(address pool, PoolType poolType) public onlyVoter {
        votedPool = pool;
        votedPoolType = poolType;
        emit LogVotedExtPoolUpdated(pool, poolType);
    }

    /**
     * @dev set new fee amount - used upon exit. value 200 = 2% fee
     */
    function setVotedFee(uint256 _votedFee) public onlyVoter {
        votedFee = _votedFee;
        emit LogFeeUpdated(_votedFee);
    }

    /**
     * @dev set new fee amount - used upon exit. value 200 = 2% fee
     */
    function setVotedPerformanceFee(uint256 _votedPerformanceFee)
        public
        onlyVoter
    {
        votedPerformanceFee = _votedPerformanceFee;
        emit LogPerformanceFeeUpdated(_votedPerformanceFee);
    }

    /**
     * @dev set new Chi amount to hold in the contract to save gas for mint/burn TXs
     */
    function setVotedChi(uint256 _votedChi) public onlyVoter {
        votedChi = _votedChi;
    }

    /**
     * @dev Value Manager can only access the tokens at this contract. Normally it is not used in the workflow.
     */
    function retrieveToken(address TokenAddress)
        external
        onlyValueManager
        returns (uint256)
    {
        IERC20 Token = IERC20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        Token.universalTransfer(msg.sender, balance);
        return balance;
    }

    /**
     * @dev Check if we have enough CHi token in the contract and obtain some by minting or using exchanges
     * TODO: check if msg.sender can give us some too
     */
    function topUpChi(IERC20 Token, uint256 amountAvailable)
        public
        returns (uint256 spendAmount)
    {
        uint256 currentChi = chi.balanceOf(address(this));
        if (currentChi < votedChi) {
            uint256 getChi = votedChi.div(2);

            if (tx.gasprice < 30000000000) {
                //cheap gas -> we can mint instead of buying
                chi.mint(getChi);
            } else {
                IERC20 _Chi = IERC20(CHI_ADDRESS);
                //top up 1/2 votedChi
                spendAmount = reverseQuote(Token, _Chi, getChi);

                if (amountAvailable >= spendAmount && spendAmount > 0) {
                    swap(Token, _Chi, spendAmount, false);
                    LogChiToppedUpdated(spendAmount);
                } else {
                    chi.mint(getChi);
                }
            }
        }
    }

    /**
     * @dev Method to tell us roughly how much resulting S/F token will be minted from the token given
     * TODO: implement UNI pools
     */
    function mintQuote(address fromToken, uint256 amount)
        external
        view
        returns (uint256 returnAmount)
    {
        require(votedPool != address(0), "No voted pool available");

        returnAmount = mintQuoteAt(fromToken, amount, votedPool, votedPoolType);
    }

    function mintQuoteAt(
        address fromToken,
        uint256 amount,
        address pool,
        PoolType poolType
    ) public view returns (uint256 returnAmount) {
        if (poolType == PoolType.EXT) {
            IERC20 _fromToken = IERC20(fromToken);
            IERC20 _toToken = IERC20(IExternalPool(pool).enterToken());

            (returnAmount) = quote(_fromToken, _toToken, amount);

            (returnAmount) = quote(
                _toToken,
                IERC20(denominateTo),
                returnAmount
            );
        } else {
            revert("Other not yet implemented");
        }
    }

    /**
     * @dev payable fallback aka mint from eth to default
     */
        receive() external payable {
    }

    /**
     * @dev Generic Mint to the Voted Pool
     */
    function mint(address fromToken, uint256 amount)
        external
        payable
        returns (uint256 toMint)
    {
        require(votedPool != address(0), "No voted pool available");
        toMint = mint(votedPool, votedPoolType, fromToken, amount);
    }

    /**
     * @dev Main mint S/F token method
     * takes any token, converts it as required and puts it into a default (Voted) pool
     * resulting additional value is minted as S/F tokens (denominated in [DAI])
     * some Chi may be taken from the input value to make the transaction cheaper and
     * leave some Chi for future transactions
     */

    function mint(
        address _pool,
        PoolType _poolType,
        address fromToken,
        uint256 amount
    ) public payable discountCHI onlyEOA nonReentrant returns (uint256 toMint) {
        require(amount > 0, "Mint does not make sense");

        IERC20 _fromToken = IERC20(fromToken);
        uint256 balanceBefore;

        if (fromToken != address(0)) {
            require(
                _fromToken.allowance(msg.sender, address(this)) >= amount,
                "Allowance is not enough"
            );
            balanceBefore = _fromToken.balanceOf(address(this));
            _fromToken.universalTransferFrom(msg.sender, address(this), amount);
            //confirmed amount
            amount = _fromToken.balanceOf(address(this)).sub(balanceBefore);
        } else {
            //convert to WETH
            fromToken = address(WETH_ADDRESS);
            _fromToken = WETH_ADDRESS;
            balanceBefore = _fromToken.balanceOf(address(this));
            IWETH(address(WETH_ADDRESS)).deposit{value: msg.value}();
            amount = _fromToken.balanceOf(address(this)).sub(balanceBefore);
        }
        emit LogMintTaken(amount);

        if (votedChi > 0) {
            amount = amount.sub(topUpChi(_fromToken, amount));
        }

        if (_poolType == PoolType.EXT) {
            //check if _pool is legitimate
            require(checkLegitPool(externalPools, extLen, _pool), "Wrong pool");

            //External pool flow - standard methods should be used to get the enter token and add to position
            IExternalPool extPool = IExternalPool(_pool);
            IERC20 _toToken = IERC20(extPool.enterToken());

            uint256 returnAmount = swap(_fromToken, _toToken, amount, false);

            _toToken.universalTransfer(
                _pool,
                _toToken.balanceOf(address(this))
            );
            extPool.addPosition();

            // convert return amount to [denominateTo], if _toToken = denominateTo then amount is the same
            toMint = quote(_toToken, IERC20(denominateTo), returnAmount);
        } else {
            require(checkLegitPool(uniPools, uniLen, _pool), "Wrong pool");

            //Uniswap pool flow - we need to split the token into 2 parts and change accordingly to add to UNI LP
            IUniswapV2Exchange pair = IUniswapV2Exchange(_pool);

            (uint256 I0, uint256 I1, address token0, address token1) =
                getUniSplit(amount, pair, _fromToken, false);

            uint256 amount0 = swap(_fromToken, IERC20(token0), I0, false);
            uint256 amount1 = swap(_fromToken, IERC20(token1), I1, false);

            IERC20(token0).universalTransfer(address(pair), amount0);
            IERC20(token1).universalTransfer(address(pair), amount1);

            pair.mint(address(this));

            toMint = quote(IERC20(token0), IERC20(denominateTo), amount0);
            toMint += quote(IERC20(token1), IERC20(denominateTo), amount1);
        }

        // mint that amount to sender
        require(toMint > 0, "Nothing to mint");
        toMint = toSFDecimals(toMint);
        ISFToken(SFToken).mint(msg.sender, toMint);
    }

    /**
     * @dev Internal function to check if selected pool was added to the config (by voting)
     */
    function checkLegitPool(
        mapping(uint256 => address) storage somePools,
        uint256 poolLen,
        address _pool
    ) internal view returns (bool poolLegit) {
        poolLegit = false;
        for (uint256 i = 0; i < poolLen; i++) {
            if (somePools[i] == _pool) {
                poolLegit = true;
                break;
            }
        }
    }

    /**
     * @dev Internal function to help calculating a multiplier for Uni pools
     */
    function _P(
        uint256 Q0,
        uint256 Q1,
        IUniswapV2Exchange pair
    ) internal view returns (uint256 P) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        require(reserve0 > 0 && reserve1 > 0, "UNI pool is empty");

        P = (reserve0.mul(Q1).mul(10**fpDigits)).div(reserve1.mul(Q0));
    }

    /**
     * @dev Internal function to help calculating an input amount for Uni Pools
     */
    function _I0(uint256 P, uint256 Q) internal pure returns (uint256 I0) {
        I0 = Q.mul(fpNumbers**2).div(P.add(fpNumbers)).div(fpNumbers);
    }

    /**
     * @dev Internal function to help calculating a proper split between tokens for a given Uni pool,
     * @param Q - input token quantity
     * @param pair - Uni/Sushi liquidity pool
     * @param fromToken - ERC20 token to convert and add to LP
     * @param reverse - if we need to extract value from the pool, not add
     */
    function getUniSplit(
        uint256 Q,
        IUniswapV2Exchange pair,
        IERC20 fromToken,
        bool reverse
    )
        internal
        view
        returns (
            uint256 I0,
            uint256 I1,
            address token0,
            address token1
        )
    {
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 I = Q.div(2);

        uint256 Q0;
        uint256 Q1;

        if (reverse) {
            Q0 = reverseQuote(IERC20(token0), fromToken, I);
            Q1 = reverseQuote(IERC20(token1), fromToken, I);
        } else {
            Q0 = quote(fromToken, IERC20(token0), I);
            Q1 = quote(fromToken, IERC20(token1), I);
        }

        uint256 P = _P(Q0, Q1, pair);

        I0 = _I0(P, Q);
        I1 = Q - I0;

        if (reverse) {
            I0 = reverseQuote(IERC20(token0), fromToken, I0);
            I1 = reverseQuote(IERC20(token1), fromToken, I1);
        }
    }

    /**
     * @dev Method to pick a suitable Uni/External pool to extract the required value for burning
     */
    function pickPoolToExtract(uint256 amount)
        public
        view
        returns (address pool, PoolType poolType)
    {
        //check UNI pool values
        for (uint256 i = 0; i < uniLen; i++) {
            address uniAddress = uniPools[i];

            uint256 PairReserve;
            if (uniAddress != address(0)) {
                IUniswapV2Exchange uniPool = IUniswapV2Exchange(uniAddress);
                (uint256 myreserve0, uint256 myreserve1) =
                    getDenominatedValue(uniPool);

                PairReserve += myreserve0;
                PairReserve += myreserve1;

                if (PairReserve >= amount) {
                    return (uniAddress, PoolType.UNI);
                }
            }
        }

        for (uint256 i = 0; i < extLen; i++) {
            address extAddress = externalPools[i];

            if (extAddress != address(0)) {
                // get quote to denominateTo
                IExternalPool extPool = IExternalPool(extAddress);
                uint256 poolValue =
                    quote(
                        IERC20(extPool.enterToken()),
                        IERC20(denominateTo),
                        extPool.getTokenStaked()
                    );
                if (poolValue >= amount) {
                    return (extAddress, PoolType.EXT);
                }
            }
        }

        require(pool != address(0), "No pool for requested amount");
    }

    /**
     * @dev Main method to burn S/F tokens and get back the requested amount from denominated token [DAI] to user
     * NB: flashloan attacks shold be discouraged
     * NB: considering to split it into 2 separate transactions, to disregard the flashloan use. 
    
     */
    function burn(address toToken, uint256 amount)
        external
        discountCHI
        onlyEOA
        nonReentrant
        returns (uint256 toBurn)
    {
        if (toToken == address(0)) {
            toToken = address(WETH_ADDRESS);
        }

        IERC20 _toToken = IERC20(toToken);
        ISFToken _SFToken = ISFToken(SFToken);
        // get latest token value, we don't want to burn more than expected if the value drops down
        _rebaseOnChain();

        // limit by existing balance - be can burn only that value and no more than that
        uint256 senderBalance = _SFToken.balanceOf(msg.sender);
        if (senderBalance < amount) {
            amount = senderBalance;
        }
        require(amount > 0, "Not enough burn balance");
        toBurn = amount;
        _SFToken.burn(msg.sender, toBurn);

        /// convert to denominateTo
        amount = fromSFDecimals(amount);
        uint256 feeTaken = getFee(amount);
        emit LogFeeTaken(feeTaken);
        amount -= feeTaken;

        //Find the suitable pool to extract value
        (address pool, PoolType poolType) = pickPoolToExtract(amount);

        uint256 returnAmount;

        if (poolType == PoolType.EXT) {
            //External pool flow
            IExternalPool extPool = IExternalPool(pool);
            address poolToken = extPool.enterToken();

            // get quote from sf token to pool token
            // how much pool token [DAI?] is needed to make this amount of [denominateTo] (also DAI now)
            // poolToken might be == denominateTo, in that case the price skew (FL attack) seem to be eliminated
            uint256 poolTokenWithdraw =
                reverseQuote(IERC20(poolToken), IERC20(denominateTo), amount);

            require(poolTokenWithdraw > 0, "Reverse Quote is 0");

            //pull out pool tokens
            extPool.exitPosition(poolTokenWithdraw);
            //get them out from the pool here
            uint256 returnPoolTokenAmount =
                extPool.transferTokenTo(
                    poolToken,
                    address(this),
                    poolTokenWithdraw
                );

            if (votedChi > 0) {
                // topup our contract with CHi to save on gas
                returnPoolTokenAmount = returnPoolTokenAmount.sub(
                    topUpChi(IERC20(poolToken), returnPoolTokenAmount)
                );
            }

            returnAmount = swap(
                IERC20(poolToken),
                _toToken,
                returnPoolTokenAmount,
                true
            );
        } else {
            // Uni pool workflow
            // Might be prone to Flashloan Attacks - the whole logic needs to be reviewed and maybe improved

            (IERC20 token0, IERC20 token1, uint256 bal0, uint256 bal1) =
                burnUniLq(amount, pool);

            returnAmount = swap(token0, _toToken, bal0, true);
            returnAmount += swap(token1, _toToken, bal1, true);

            if (votedChi > 0) {
                // topup with CHi
                returnAmount = returnAmount.sub(
                    topUpChi(_toToken, returnAmount)
                );
            }
        }

        //Here we transfer the value back to a user
        //TODO: consider splitting it to a separate transaction, not available to perform in the same block
        //might mitigate FL attack risk
        if (toToken == address(WETH_ADDRESS)) {
            IWETH(address(WETH_ADDRESS)).withdraw(returnAmount);
            msg.sender.transfer(returnAmount);
        } else {
            _toToken.universalTransfer(msg.sender, returnAmount);
        }

        emit LogBurnGiven(returnAmount);
    }

    /**
     * @dev Burn Uni LP token to get the necessary amount of tokens as requested
     */
    function burnUniLq(uint256 amount, address pool)
        internal
        returns (
            IERC20 token0,
            IERC20 token1,
            uint256 bal0,
            uint256 bal1
        )
    {
        IUniswapV2Exchange pair = IUniswapV2Exchange(pool);
        (, uint256 I1, address tok0, address tok1) =
            getUniSplit(amount, pair, IERC20(denominateTo), true);

        (, uint256 reserve1, ) = pair.getReserves();

        uint256 lq = pair.totalSupply().mul(I1).div(reserve1); // might be min of either of those token0/token1

        pair.transfer(pool, lq);
        pair.burn(address(this));

        token0 = IERC20(tok0);
        token1 = IERC20(tok1);

        bal0 = token0.balanceOf(address(this));
        bal1 = token1.balanceOf(address(this));
    }

    /**
     * @dev math to calculate the fee
     */
    function getFee(uint256 amount) internal view returns (uint256 feeTaken) {
        feeTaken = amount.mul(votedFee).div(10000);
    }

    /**
     * @dev Internal function to rebase main S/F token with given value
     * @param value - Total supply of S/F
     */
    function _rebase(uint256 value) internal {
        ISFToken SF = ISFToken(SFToken);
        SF.rebase(value);
    }

    /**
     * @dev Internal function to rebase main S/F token with the value
     * as confirmed by on-chain quotes from XChanger(XTrinity) contract
     * Consumes more gas, therefore it will be used only when minting/burning
     */
    function _rebaseOnChain() internal {
        uint256 amount = toSFDecimals(getTotalValue() + 1);
        _rebase(amount);
    }

    /**
     * @dev ValueManager can run onchain rebase any time as required
     */
    function rebase() public discountCHI onlyValueManager {
        _rebaseOnChain();
    }

    /**
     * @dev ValueManager can run an arbitrary rebase too - to save on gas as this TX is much cheaper
     * This is really a workaround that should be disregarded by the community
     */
    function rebase(uint256 value) external onlyValueManager {
        _rebase(value);
    }

    /**
     * @dev math function to convert decimals from dS/F decimals (6) to enomination token [DAI] (18)
     */

    function fromSFDecimals(uint256 value) internal view returns (uint256) {
        return value.mul(10**uint256(denominateDecimals - sfDecimals));
    }

    /**
     * @dev math function to convert decimals from denomination token [DAI] (18) to S/F decimals (6)
     */
    function toSFDecimals(uint256 value) internal view returns (uint256) {
        return value.div(10**uint256(denominateDecimals - sfDecimals));
    }

    /**
     * @dev method for Value Manager to claim vaue from external (CompMiner) pool by collecting COMP, converting to [DAI]
     * and then adding back to the same pool ()
     */
    function harvest() external onlyValueManager {
        for (uint256 j = 0; j < extLen; j++) {
            address extAddress = externalPools[j];
            if (extAddress != address(0)) {
                harvestAt(extAddress);
                harvestAddValueAt(extAddress);
            }
        }
    }

    /**
     * @dev method for Value Manager to claim vaue from selected external (CompMiner) pool by collecting COMP,
     * converting to [DAI]
     */
    function harvestAt(address pool) public onlyValueManager {
        IExternalPool externalPool = IExternalPool(pool);
        externalPool.claimValue();

        IERC20 poolToken = IERC20(externalPool.enterToken());
        uint256 poolTokenBalance = poolToken.balanceOf(pool);
        require(poolTokenBalance > 0, "Nothing to harvest");
        externalPool.transferTokenTo(
            address(poolToken),
            address(this),
            poolTokenBalance
        );
        //TODO: performance fee
        if (votedPerformanceFee > 0) {
            uint256 performanceFee =
                poolTokenBalance.mul(votedPerformanceFee).div(10000);
            poolTokenBalance -= performanceFee;

            poolToken.universalTransfer(ValueManager, performanceFee);
        }
        if (votedChi > 0) {
            topUpChi(poolToken, poolTokenBalance);
        }

        poolToken.universalTransfer(pool, poolToken.balanceOf(address(this)));
    }

    /**
     * @dev method for Value Manager to add harvested value back to the pool for compounding
     */
    function harvestAddValueAt(address pool) public onlyValueManager {
        IExternalPool externalPool = IExternalPool(pool);
        externalPool.addPosition();
    }

    /**
     * @dev math to calculate the %% of the uni pool owned by the holder
     */
    function getHolderPc(IUniswapV2Exchange uniPool)
        internal
        view
        returns (uint256 holderPc)
    {
        try uniPool.totalSupply() returns (uint256 uniTotalSupply) {
            holderPc = (uniPool.balanceOf(address(this)).mul(fpNumbers)).div(
                uniTotalSupply
            );
        } catch {}
    }

    /**
     * @dev method to return the amount of tokens in the uni LP pool owned by the holder
     */
    function getUniReserve(IUniswapV2Exchange uniPool)
        public
        view
        returns (uint256 myreserve0, uint256 myreserve1)
    {
        uint256 holderPc = getHolderPc(uniPool);

        try uniPool.getReserves() returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32
        ) {
            myreserve0 = (uint256(reserve0).mul(holderPc)).div(fpNumbers);
            myreserve1 = (uint256(reserve1).mul(holderPc)).div(fpNumbers);
        } catch {}
    }

    /**
     * @dev method to return the external pool total value
     */
    function getExternalValue() public view returns (uint256 totalReserve) {
        for (uint256 j = 0; j < extLen; j++) {
            address extAddress = externalPools[j];
            if (extAddress != address(0)) {
                IExternalPool externalPool = IExternalPool(extAddress);

                address poolToken = externalPool.enterToken();
                // changing quotes to this contract instead
                uint256 addValue =
                    quote(
                        IERC20(poolToken),
                        IERC20(denominateTo),
                        externalPool.getPoolValue(poolToken)
                    );
                totalReserve = totalReserve.add(addValue);
            }
        }
    }

    /**
     * @dev method to return the denominated [DAI] uni pool value owned by the user
     */
    function getDenominatedValue(IUniswapV2Exchange uniPool)
        public
        view
        returns (uint256 myreserve0, uint256 myreserve1)
    {
        (myreserve0, myreserve1) = getUniReserve(uniPool);

        address token0 = uniPool.token0();
        address token1 = uniPool.token1();

        if (token0 != denominateTo) {
            //get amount and convert to denominate addr;
            if (token0 != SFToken && myreserve0 > 0) {
                (myreserve0) = quote(
                    IERC20(uniPool.token0()),
                    IERC20(denominateTo),
                    myreserve0
                );
            } else {
                myreserve0 = 0;
            }
        }

        if (uniPool.token1() != denominateTo) {
            //get amount and convert to denominate addr;
            if (token1 != SFToken && myreserve1 > 0) {
                (myreserve1) = quote(
                    IERC20(uniPool.token1()),
                    IERC20(denominateTo),
                    myreserve1
                );
            } else {
                myreserve1 = 0;
            }
        }
    }

    /**
     * @dev method to return total value of the fund from all the external and internal (uni) pools
     * plus the own balance if there is one
     */
    function getTotalValue() public view returns (uint256 totalReserve) {
        for (uint256 i = 0; i < uniLen; i++) {
            address uniAddress = uniPools[i];

            if (uniAddress != address(0)) {
                IUniswapV2Exchange uniPool = IUniswapV2Exchange(uniAddress);
                (uint256 myreserve0, uint256 myreserve1) =
                    getDenominatedValue(uniPool);

                totalReserve += myreserve0;
                totalReserve += myreserve1;
            }
        }

        totalReserve += getExternalValue();
        totalReserve += IERC20(denominateTo).balanceOf(address(this));
    }

    /**
     * @dev add new Uni pool - only by Voter
     */
    function addUni(address pool) public onlyVoter {
        uniPools[uniLen] = pool;
        uniLen++;
    }

    /**
     * @dev remove a Uni pool - only by Voter
     */
    function delUni(uint256 i) external onlyVoter {
        uniPools[i] = address(0);
    }

    /**
     * @dev add new External pool - only by Voter
     */
    function addExt(address pool) public onlyVoter {
        externalPools[extLen] = pool;
        extLen++;
    }

    /**
     * @dev remove External pool - only by Voter
     */
    function delExt(uint256 i) external onlyVoter {
        externalPools[i] = address(0);
    }

    /**
     * @dev to fix the length on the Uni pool array
     * might be not needed but good for testing/fixing storage state
     */
    function setUniLen(uint256 i) external onlyVoter {
        uniLen = i;
    }

    /**
     * @dev to fix the length on the Ext pool array
     * might be not needed but good for testing/fixing storage state
     */
    function setExtLen(uint256 i) external onlyVoter {
        extLen = i;
    }
}