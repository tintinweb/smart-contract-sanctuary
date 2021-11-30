// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./libraries/Uniswap.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IUniswapZapper.sol";

contract UniswapZapper is IUniswapZapper {
    event ZapToVault(
        address indexed from,
        address indexed vault,
        uint256 value
    );

    using SafeERC20 for IERC20;

    struct ZapInfo {
        IUniswapV2Pair lpToken;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
    }

    IUniswapV2Router02 public immutable router;

    constructor(IUniswapV2Router02 _router) {
        router = _router;
    }

    receive() external payable {}

    function zapToVaultETH(
        IVault _vault,
        uint256 _strategyId,
        uint256 _amountLP,
        uint256 _amount0,
        uint256 _amount1
    )
        external
        payable
        returns (
            uint256 shares,
            uint112 reserve0,
            uint112 reserve1,
            uint256 lpTotalSupply,
            uint256 pricePerShare
        )
    {
        (, address underlying, ) = _vault.getStrategy(_strategyId);
        IUniswapV2Pair pair = IUniswapV2Pair(underlying);
        shares = _zapToVault(
            _vault,
            _strategyId,
            _amountLP,
            _amount0,
            _amount1,
            router.WETH()
        );
        (reserve0, reserve1, ) = pair.getReserves();
        lpTotalSupply = pair.totalSupply();
        pricePerShare = _vault.pricePerShare(_strategyId);
    }

    function zapToVault(
        IVault _vault,
        uint256 _strategyId,
        uint256 _amountLP,
        uint256 _amount0,
        uint256 _amount1
    )
        external
        returns (
            uint256 shares,
            uint112 reserve0,
            uint112 reserve1,
            uint256 lpTotalSupply,
            uint256 pricePerShare
        )
    {
        (, address underlying, ) = _vault.getStrategy(_strategyId);
        IUniswapV2Pair pair = IUniswapV2Pair(underlying);
        shares = _zapToVault(
            _vault,
            _strategyId,
            _amountLP,
            _amount0,
            _amount1,
            address(0)
        );
        (reserve0, reserve1, ) = pair.getReserves();
        lpTotalSupply = pair.totalSupply();
        pricePerShare = _vault.pricePerShare(_strategyId);
    }

    function zapFromVault(
        IVault _vault,
        uint256 _strategyId,
        address _to,
        uint16 _lpTokenWeight,
        uint16 _token0Weight,
        uint16 _token1Weight,
        address _weth
    )
        external
        returns (
            uint256 amountLP,
            uint256 amountToken0,
            uint256 amountToken1
        )
    {
        require(
            _lpTokenWeight + _token0Weight + _token1Weight == 1000,
            "Weights should add up to 1000"
        );
        (, address underlying, ) = _vault.getStrategy(_strategyId);
        IUniswapV2Pair pair = IUniswapV2Pair(underlying);
        uint256 lpBalance = pair.balanceOf(address(this));
        if (_lpTokenWeight > 0) {
            amountLP = (_lpTokenWeight * lpBalance) / 1000;
            pair.transfer(_to, amountLP);
        }
        lpBalance = pair.balanceOf(address(this));
        if (lpBalance > 0) {
            pair.approve(address(router), lpBalance);
            router.removeLiquidity(
                pair.token0(),
                pair.token1(),
                lpBalance,
                1,
                1,
                address(this),
                block.timestamp
            );
            if (_token0Weight == _token1Weight) {
                // Dont do anything
            } else if (_token0Weight == 0) {
                _convertAllToken(pair, pair.token1());
            } else if (_token1Weight == 0) {
                _convertAllToken(pair, pair.token0());
            } else {
                _convertToRatio(pair, _token0Weight, _token1Weight);
            }
            amountToken0 = IERC20(pair.token0()).balanceOf(address(this));
            if (amountToken0 > 0) {
                if (pair.token0() == _weth) {
                    IWETH(_weth).withdraw(amountToken0);
                    (bool success, ) = payable(_to).call{value: amountToken0}(
                        new bytes(0)
                    );
                    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
                } else {
                    IERC20(pair.token0()).safeTransfer(_to, amountToken0);
                }
            }
            amountToken1 = IERC20(pair.token1()).balanceOf(address(this));
            if (amountToken1 > 0) {
                if (pair.token1() == _weth) {
                    IWETH(_weth).withdraw(amountToken1);
                    (bool success, ) = payable(_to).call{value: amountToken1}(
                        new bytes(0)
                    );
                    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
                } else {
                    IERC20(pair.token1()).safeTransfer(_to, amountToken1);
                }
            }
        }
    }

    function _convertToRatio(
        IUniswapV2Pair _pair,
        uint16 _token0Weight,
        uint16 _token1Weight
    ) internal {
        uint32 ratio = (uint32(_token0Weight) * 1000) / uint32(_token1Weight);
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        IERC20 tokenIn = IERC20(_pair.token0());
        IERC20 tokenOut = IERC20(_pair.token1());
        if (_token0Weight < _token1Weight) {
            ratio = (uint32(_token1Weight) * 1000) / uint32(_token0Weight);
            (reserve1, reserve0, ) = _pair.getReserves();
            tokenIn = IERC20(_pair.token1());
            tokenOut = IERC20(_pair.token0());
        }
        uint256 give = Uniswap.divideLP(
            ratio,
            tokenIn.balanceOf(address(this)),
            reserve0,
            reserve1
        );
        address[] memory route = new address[](2);
        route[0] = address(tokenOut);
        route[1] = address(tokenIn);
        tokenOut.approve(address(router), tokenOut.balanceOf(address(this)));
        router.swapExactTokensForTokens(
            give,
            1,
            route,
            address(this),
            block.timestamp
        );
    }

    function _convertAllToken(IUniswapV2Pair _pair, address _want) internal {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        address[] memory route = new address[](2);
        route[1] = _want;
        if (_want == token0) {
            route[0] = token1;
        } else {
            route[0] = token0;
        }
        IERC20 tokenIn = IERC20(route[0]);
        tokenIn.approve(address(router), tokenIn.balanceOf(address(this)));
        router.swapExactTokensForTokens(
            tokenIn.balanceOf(address(this)),
            1,
            route,
            address(this),
            block.timestamp
        );
    }

    function _zapInLPToken(
        IUniswapV2Pair _lpToken,
        uint256 _amount0,
        uint256 _amount1,
        address _weth
    ) internal returns (uint256 liquidity) {
        // use structure to avoid stack too deep
        ZapInfo memory zapInfo;
        zapInfo.lpToken = _lpToken;
        zapInfo.token0 = zapInfo.lpToken.token0();
        zapInfo.token1 = zapInfo.lpToken.token1();
        (zapInfo.reserve0, zapInfo.reserve1, ) = zapInfo.lpToken.getReserves();
        // when amount1 of token1 has more value then amount0 of token0 we switch stuff around
        bool switched = false;
        if (_amount1 * zapInfo.reserve0 > _amount0 * zapInfo.reserve1) {
            (
                switched,
                _amount0,
                _amount1,
                zapInfo.token0,
                zapInfo.token1,
                zapInfo.reserve0,
                zapInfo.reserve1
            ) = (
                true,
                _amount1,
                _amount0,
                zapInfo.token1,
                zapInfo.token0,
                zapInfo.reserve1,
                zapInfo.reserve0
            );
        }
        uint256 swapIn = Uniswap.getSwapAmount(
            _amount0,
            _amount1,
            zapInfo.reserve0,
            zapInfo.reserve1
        );
        uint256 swapOut;
        if (swapIn > 0) {
            // swap so we get equal value for token0 and token1
            uint256 swapWithFee = swapIn * 997;
            swapOut =
                (swapWithFee * zapInfo.reserve1) /
                (zapInfo.reserve0 * 1000 + (swapWithFee));
            if (_weth == zapInfo.token0) {
                // transfer token directly as its already paid
                IERC20(zapInfo.token0).safeTransfer(
                    address(zapInfo.lpToken),
                    swapIn
                );
            } else {
                // transfer token from user
                IERC20(zapInfo.token0).safeTransferFrom(
                    msg.sender,
                    address(zapInfo.lpToken),
                    swapIn
                );
            }
            // do the actual swap
            if (!switched) {
                zapInfo.lpToken.swap(0, swapOut, address(this), new bytes(0));
            } else {
                zapInfo.lpToken.swap(swapOut, 0, address(this), new bytes(0));
            }
            _amount0 = _amount0 - swapIn;
            IERC20(zapInfo.token1).safeTransfer(
                address(zapInfo.lpToken),
                swapOut
            );
        }
        // refresh reserves after swap
        (zapInfo.reserve0, zapInfo.reserve1, ) = zapInfo.lpToken.getReserves();
        if (switched) {
            (zapInfo.reserve0, zapInfo.reserve1) = (
                zapInfo.reserve1,
                zapInfo.reserve0
            );
        }
        // quote for token0 wrt to token1 already transferred and remaining
        uint256 quote0 = ((_amount1 + swapOut) * zapInfo.reserve0) /
            zapInfo.reserve1;
        if (quote0 <= _amount0) {
            // update amount to be transferred to actual quote
            _amount0 = quote0;
        } else {
            // need a quote for token1 as we cannot afford token0 quote
            _amount1 =
                (_amount0 * zapInfo.reserve1) /
                zapInfo.reserve0 -
                swapOut;
        }
        if (_amount0 > 0) {
            if (_weth == zapInfo.token0) {
                IERC20(zapInfo.token0).safeTransfer(
                    address(zapInfo.lpToken),
                    _amount0
                );
            } else {
                IERC20(zapInfo.token0).safeTransferFrom(
                    msg.sender,
                    address(zapInfo.lpToken),
                    _amount0
                );
            }
        }
        if (_amount1 > 0) {
            if (_weth == zapInfo.token1) {
                IERC20(zapInfo.token1).safeTransfer(
                    address(zapInfo.lpToken),
                    _amount1
                );
            } else {
                IERC20(zapInfo.token1).safeTransferFrom(
                    msg.sender,
                    address(zapInfo.lpToken),
                    _amount1
                );
            }
        }
        liquidity = zapInfo.lpToken.mint(address(this));
    }

    function _zapToVault(
        IVault _vault,
        uint256 _strategyId,
        uint256 _amountLP,
        uint256 _amount0,
        uint256 _amount1,
        address _weth
    ) internal returns (uint256 shares) {
        (, address token, ) = _vault.getStrategy(_strategyId);
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        uint256 lpBalance = pair.balanceOf(address(this));
        if (msg.value > 0) {
            IWETH(_weth).deposit{value: msg.value}();
        }
        if (_amountLP > 0) {
            pair.transferFrom(msg.sender, address(this), _amountLP);
        }
        if (_amount0 > 0 || _amount1 > 0) {
            _zapInLPToken(pair, _amount0, _amount1, _weth);
        }
        uint256 amount = pair.balanceOf(address(this)) - lpBalance;
        pair.transfer(address(_vault), amount);
        shares = _vault.deposit(_strategyId, msg.sender);
        uint256 token0Balance = IERC20(pair.token0()).balanceOf(address(this));
        uint256 token1Balance = IERC20(pair.token1()).balanceOf(address(this));
        if (token0Balance > 0) {
            IERC20(pair.token0()).safeTransfer(msg.sender, token0Balance);
        }
        if (token1Balance > 0) {
            IERC20(pair.token1()).safeTransfer(msg.sender, token1Balance);
        }
        emit ZapToVault(msg.sender, address(_vault), amount);
    }
}

pragma solidity ^0.8.0;

interface IStrategy {
    function balanceOf(address _stakeToken) external view returns (uint256);

    function stake(address _stakeToken) external;

    function beforeDeposit(address _underlying) external;

    function beforeWithdrawal(address _underlying) external;

    function withdraw(
        address _stakeToken,
        address _to,
        uint256 _amount
    ) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IVault.sol";

interface IUniswapZapper {
    function zapToVault(
        IVault vault,
        uint256 _strategyId,
        uint256 _amountLP,
        uint256 _amount0,
        uint256 _amount1
    )
        external
        returns (
            uint256 shares,
            uint112 reserve0,
            uint112 reserve1,
            uint256 lpTotalSupply,
            uint256 pricePerShare
        );

    function zapToVaultETH(
        IVault vault,
        uint256 _strategyId,
        uint256 _amountLP,
        uint256 _amount0,
        uint256 _amount1
    )
        external
        payable
        returns (
            uint256 shares,
            uint112 reserve0,
            uint112 reserve1,
            uint256 lpTotalSupply,
            uint256 pricePerShare
        );

    function zapFromVault(
        IVault _vault,
        uint256 _strategyId,
        address _to,
        uint16 _lpTokenWeight,
        uint16 _token0Weight,
        uint16 _token1Weight,
        address _weth
    )
        external
        returns (
            uint256 amountLP,
            uint256 amountToken0,
            uint256 amountToken1
        );
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IStrategy.sol";

interface IVault {
    event Deposit(
        address indexed from,
        uint256 indexed strategyId,
        uint256 value
    );
    event Withdrawal(
        address indexed to,
        uint256 indexed strategyId,
        uint256 value
    );

    function pricePerShare(uint256 _strategyId) external view returns (uint256);

    function getStrategy(uint256 _strategyId)
        external
        view
        returns (
            string memory,
            address,
            IStrategy
        );

    function deposit(uint256 _strategy, address to) external returns (uint256);
}

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity ^0.8.0;

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
    }
}

pragma solidity ^0.8.0;

import "./Math.sol";

library Uniswap {
    function getSwapAmount(
        uint256 _in0,
        uint256 _in1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal pure returns (uint256 swapAmount) {
        // Determine how much of token0 should be swapped for token1
        swapAmount = 0;
        uint256 part0 = (_in0 * _reserve1 * 3988000) +
            (_in1 * _reserve0 * 9) +
            (_reserve0 * _reserve1 * 3988009);
        uint256 part1 = Math.sqrt((_reserve0 * part0) / (_in1 + _reserve1));
        uint256 part2 = _reserve0 * 1997;
        if (part1 <= part2) {
            swapAmount = 0;
        } else {
            swapAmount = (part1 - part2) / 1994;
        }
        assert(swapAmount < _in0);
    }

    function divideLP(
        uint32 ratio,
        uint256 want,
        uint112 reserve0,
        uint112 reserve1
    ) internal pure returns (uint256 swapOut) {
        // Wolfram solve R*S - (R-x)(S+F*y/D) = 0, (X+x)/((X*S/R-y)*(R-x)/(S+F*y/D)) - Q = 0, S  > 0, R > 0, X > 0, x > 0 for y
        uint256 R = reserve0;
        uint256 S = reserve1;
        uint256 F = 997;
        uint256 D = 1000;
        uint256 Q = ratio;
        uint256 X = want;
        swapOut = Math.sqrt(D * S**2);
        swapOut =
            swapOut *
            Math.sqrt(
                D *
                    F**2 *
                    R**2 +
                    2 *
                    D *
                    F *
                    Q *
                    R**2 +
                    4 *
                    D *
                    F *
                    Q *
                    R *
                    X +
                    D *
                    Q**2 *
                    R**2 +
                    4 *
                    F**2 *
                    Q *
                    R *
                    X +
                    4 *
                    F**2 *
                    Q *
                    X**2
            );
        swapOut = swapOut - (Q * R * S * D + D * F * R * S + 2 * D * F * S * X);
        swapOut = swapOut / (2 * F**2 * (R + X));
    }
}