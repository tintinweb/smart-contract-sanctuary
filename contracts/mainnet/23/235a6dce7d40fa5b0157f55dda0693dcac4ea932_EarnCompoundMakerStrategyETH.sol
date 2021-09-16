/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.6.0 https://hardhat.org

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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File contracts/interfaces/bloq/ISwapManager.sol



pragma solidity 0.8.3;

/* solhint-disable func-name-mixedcase */

interface ISwapManager {
    event OracleCreated(address indexed _sender, address indexed _newOracle, uint256 _period);

    function N_DEX() external view returns (uint256);

    function ROUTERS(uint256 i) external view returns (IUniswapV2Router02);

    function bestOutputFixedInput(
        address _from,
        address _to,
        uint256 _amountIn
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountOut,
            uint256 rIdx
        );

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function bestInputFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountIn,
            uint256 rIdx
        );

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function safeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function safeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function comparePathsFixedInput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function comparePathsFixedOutput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function ours(address a) external view returns (bool);

    function oracleCount() external view returns (uint256);

    function oracleAt(uint256 idx) external view returns (address);

    function getOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external view returns (address);

    function createOrUpdateOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external returns (address oracleAddr);

    function consultForFree(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAt);

    /// get the data we want and pay the gas to update
    function consult(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    )
        external
        returns (
            uint256 amountOut,
            uint256 lastUpdatedAt,
            bool updated
        );

    function updateOracles() external returns (uint256 updated, uint256 expected);

    function updateOracles(address[] memory _oracleAddrs) external returns (uint256 updated, uint256 expected);
}


// File contracts/interfaces/bloq/IAddressList.sol



pragma solidity 0.8.3;

interface IAddressList {
    function add(address a) external returns (bool);

    function remove(address a) external returns (bool);

    function get(address a) external view returns (uint256);

    function contains(address a) external view returns (bool);

    function length() external view returns (uint256);

    function grantRole(bytes32 role, address account) external;
}


// File contracts/interfaces/bloq/IAddressListFactory.sol



pragma solidity 0.8.3;

interface IAddressListFactory {
    function ours(address a) external view returns (bool);

    function listCount() external view returns (uint256);

    function listAt(uint256 idx) external view returns (address);

    function createList() external returns (address listaddr);
}


// File contracts/interfaces/vesper/IStrategy.sol



pragma solidity 0.8.3;

interface IStrategy {
    function rebalance() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function isReservedToken(address _token) external view returns (bool);

    function migrate(address _newStrategy) external;

    function token() external view returns (address);

    function totalValue() external view returns (uint256);

    function totalValueCurrent() external returns (uint256);

    function pool() external view returns (address);
}


// File contracts/interfaces/vesper/IVesperPool.sol



pragma solidity 0.8.3;


interface IVesperPool is IERC20 {
    function deposit() external payable;

    function deposit(uint256 _share) external;

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool);

    function excessDebt(address _strategy) external view returns (uint256);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function poolRewards() external returns (address);

    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external;

    function reportLoss(uint256 _loss) external;

    function resetApproval() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function withdrawETH(uint256 _amount) external;

    function whitelistedWithdraw(uint256 _amount) external;

    function governor() external view returns (address);

    function keepers() external view returns (IAddressList);

    function maintainers() external view returns (IAddressList);

    function feeCollector() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function strategy(address _strategy)
        external
        view
        returns (
            bool _active,
            uint256 _interestFee,
            uint256 _debtRate,
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio
        );

    function stopEverything() external view returns (bool);

    function token() external view returns (IERC20);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);
}


// File contracts/strategies/Strategy.sol



pragma solidity 0.8.3;







abstract contract Strategy is IStrategy, Context {
    using SafeERC20 for IERC20;

    IERC20 public immutable collateralToken;
    address public receiptToken;
    address public immutable override pool;
    IAddressList public keepers;
    address public override feeCollector;
    ISwapManager public swapManager;

    uint256 public oraclePeriod = 3600; // 1h
    uint256 public oracleRouterIdx = 0; // Uniswap V2
    uint256 public swapSlippage = 10000; // 100% Don't use oracles by default

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;

    event UpdatedFeeCollector(address indexed previousFeeCollector, address indexed newFeeCollector);
    event UpdatedSwapManager(address indexed previousSwapManager, address indexed newSwapManager);
    event UpdatedSwapSlippage(uint256 oldSwapSlippage, uint256 newSwapSlippage);
    event UpdatedOracleConfig(uint256 oldPeriod, uint256 newPeriod, uint256 oldRouterIdx, uint256 newRouterIdx);

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) {
        require(_pool != address(0), "pool-address-is-zero");
        require(_swapManager != address(0), "sm-address-is-zero");
        swapManager = ISwapManager(_swapManager);
        pool = _pool;
        collateralToken = IVesperPool(_pool).token();
        receiptToken = _receiptToken;
    }

    modifier onlyGovernor {
        require(_msgSender() == IVesperPool(pool).governor(), "caller-is-not-the-governor");
        _;
    }

    modifier onlyKeeper() {
        require(keepers.contains(_msgSender()), "caller-is-not-a-keeper");
        _;
    }

    modifier onlyPool() {
        require(_msgSender() == pool, "caller-is-not-vesper-pool");
        _;
    }

    /**
     * @notice Add given address in keepers list.
     * @param _keeperAddress keeper address to add.
     */
    function addKeeper(address _keeperAddress) external onlyGovernor {
        require(keepers.add(_keeperAddress), "add-keeper-failed");
    }

    /**
     * @notice Create keeper list
     * NOTE: Any function with onlyKeeper modifier will not work until this function is called.
     * NOTE: Due to gas constraint this function cannot be called in constructor.
     * @param _addressListFactory To support same code in eth side chain, user _addressListFactory as param
     * ethereum- 0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3
     * polygon-0xD10D5696A350D65A9AA15FE8B258caB4ab1bF291
     */
    function init(address _addressListFactory) external onlyGovernor {
        require(address(keepers) == address(0), "keeper-list-already-created");
        // Prepare keeper list
        IAddressListFactory _factory = IAddressListFactory(_addressListFactory);
        keepers = IAddressList(_factory.createList());
        require(keepers.add(_msgSender()), "add-keeper-failed");
    }

    /**
     * @notice Migrate all asset and vault ownership,if any, to new strategy
     * @dev _beforeMigration hook can be implemented in child strategy to do extra steps.
     * @param _newStrategy Address of new strategy
     */
    function migrate(address _newStrategy) external virtual override onlyPool {
        require(_newStrategy != address(0), "new-strategy-address-is-zero");
        require(IStrategy(_newStrategy).pool() == pool, "not-valid-new-strategy");
        _beforeMigration(_newStrategy);
        IERC20(receiptToken).safeTransfer(_newStrategy, IERC20(receiptToken).balanceOf(address(this)));
        collateralToken.safeTransfer(_newStrategy, collateralToken.balanceOf(address(this)));
    }

    /**
     * @notice Remove given address from keepers list.
     * @param _keeperAddress keeper address to remove.
     */
    function removeKeeper(address _keeperAddress) external onlyGovernor {
        require(keepers.remove(_keeperAddress), "remove-keeper-failed");
    }

    /**
     * @notice Update fee collector
     * @param _feeCollector fee collector address
     */
    function updateFeeCollector(address _feeCollector) external onlyGovernor {
        require(_feeCollector != address(0), "fee-collector-address-is-zero");
        require(_feeCollector != feeCollector, "fee-collector-is-same");
        emit UpdatedFeeCollector(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /**
     * @notice Update swap manager address
     * @param _swapManager swap manager address
     */
    function updateSwapManager(address _swapManager) external onlyGovernor {
        require(_swapManager != address(0), "sm-address-is-zero");
        require(_swapManager != address(swapManager), "sm-is-same");
        emit UpdatedSwapManager(address(swapManager), _swapManager);
        swapManager = ISwapManager(_swapManager);
    }

    function updateSwapSlippage(uint256 _newSwapSlippage) external onlyGovernor {
        require(_newSwapSlippage <= 10000, "invalid-slippage-value");
        emit UpdatedSwapSlippage(swapSlippage, _newSwapSlippage);
        swapSlippage = _newSwapSlippage;
    }

    function updateOracleConfig(uint256 _newPeriod, uint256 _newRouterIdx) external onlyGovernor {
        require(_newRouterIdx < swapManager.N_DEX(), "invalid-router-index");
        if (_newPeriod == 0) _newPeriod = oraclePeriod;
        require(_newPeriod > 59, "invalid-oracle-period");
        emit UpdatedOracleConfig(oraclePeriod, _newPeriod, oracleRouterIdx, _newRouterIdx);
        oraclePeriod = _newPeriod;
        oracleRouterIdx = _newRouterIdx;
    }

    /// @dev Approve all required tokens
    function approveToken() external onlyKeeper {
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    function setupOracles() external onlyKeeper {
        _setupOracles();
    }

    /**
     * @dev Withdraw collateral token from lending pool.
     * @param _amount Amount of collateral token
     */
    function withdraw(uint256 _amount) external override onlyPool {
        _withdraw(_amount);
    }

    /**
     * @dev Rebalance profit, loss and investment of this strategy
     */
    function rebalance() external virtual override onlyKeeper {
        (uint256 _profit, uint256 _loss, uint256 _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _reinvest();
    }

    /**
     * @dev sweep given token to feeCollector of strategy
     * @param _fromToken token address to sweep
     */
    function sweepERC20(address _fromToken) external override onlyKeeper {
        require(feeCollector != address(0), "fee-collector-not-set");
        require(_fromToken != address(collateralToken), "not-allowed-to-sweep-collateral");
        require(!isReservedToken(_fromToken), "not-allowed-to-sweep");
        if (_fromToken == ETH) {
            Address.sendValue(payable(feeCollector), address(this).balance);
        } else {
            uint256 _amount = IERC20(_fromToken).balanceOf(address(this));
            IERC20(_fromToken).safeTransfer(feeCollector, _amount);
        }
    }

    /// @notice Returns address of token correspond to collateral token
    function token() external view override returns (address) {
        return receiptToken;
    }

    /// @dev Convert from 18 decimals to token defined decimals. Default no conversion.
    function convertFrom18(uint256 amount) public pure virtual returns (uint256) {
        return amount;
    }

    /**
     * @notice Calculate total value of asset under management
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _value);

    /**
     * @notice Calculate total value of asset under management (in real-time)
     * @dev Report total value in collateral token
     */
    function totalValueCurrent() external virtual override returns (uint256) {
        return totalValue();
    }

    /// @notice Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool);

    /**
     * @notice some strategy may want to prepare before doing migration. 
        Example In Maker old strategy want to give vault ownership to new strategy
     * @param _newStrategy .
     */
    function _beforeMigration(address _newStrategy) internal virtual;

    /**
     *  @notice Generate report for current profit and loss. Also liquidate asset to payback
     * excess debt, if any.
     * @return _profit Calculate any realized profit and convert it to collateral, if not already.
     * @return _loss Calculate any loss that strategy has made on investment. Convert into collateral token.
     * @return _payback If strategy has any excess debt, we have to liquidate asset to payback excess debt.
     */
    function _generateReport()
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        _profit = _realizeProfit(_totalDebt);
        _loss = _realizeLoss(_totalDebt);
        _payback = _liquidate(_excessDebt);
    }

    function _calcAmtOutAfterSlippage(uint256 _amount, uint256 _slippage) internal pure returns (uint256) {
        return (_amount * (10000 - _slippage)) / (10000);
    }

    function _simpleOraclePath(address _from, address _to) internal pure returns (address[] memory path) {
        if (_from == WETH || _to == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }
    }

    function _consultOracle(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        // from, to, amountIn, period, router
        (uint256 rate, uint256 lastUpdate, ) = swapManager.consult(_from, _to, _amt, oraclePeriod, oracleRouterIdx);
        // We're looking at a TWAP ORACLE with a 1 hr Period that has been updated within the last hour
        if ((lastUpdate > (block.timestamp - oraclePeriod)) && (rate != 0)) return (rate, true);
        return (0, false);
    }

    function _getOracleRate(address[] memory path, uint256 _amountIn) internal returns (uint256 amountOut) {
        require(path.length > 1, "invalid-oracle-path");
        amountOut = _amountIn;
        bool isValid;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (amountOut, isValid) = _consultOracle(path[i], path[i + 1], amountOut);
            require(isValid, "invalid-oracle-rate");
        }
    }

    /**
     * @notice Safe swap via Uniswap / Sushiswap (better rate of the two)
     * @dev There are many scenarios when token swap via Uniswap can fail, so this
     * method will wrap Uniswap call in a 'try catch' to make it fail safe.
     * however, this method will throw minAmountOut is not met
     * @param _from address of from token
     * @param _to address of to token
     * @param _amountIn Amount to be swapped
     * @param _minAmountOut minimum amount out
     */
    function _safeSwap(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) internal {
        (address[] memory path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(_from, _to, _amountIn);
        if (_minAmountOut == 0) _minAmountOut = 1;
        if (amountOut != 0) {
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                _amountIn,
                _minAmountOut,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    // These methods can be implemented by the inheriting strategy.
    /* solhint-disable no-empty-blocks */
    function _claimRewardsAndConvertTo(address _toToken) internal virtual {}

    /**
     * @notice Set up any oracles that are needed for this strategy.
     */
    function _setupOracles() internal virtual {}

    /* solhint-enable */

    // These methods must be implemented by the inheriting strategy
    function _withdraw(uint256 _amount) internal virtual;

    function _approveToken(uint256 _amount) internal virtual;

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @return _payback amount in collateral token. Usually it is equal to excess debt.
     */
    function _liquidate(uint256 _excessDebt) internal virtual returns (uint256 _payback);

    /**
     * @notice Calculate earning and withdraw/convert it into collateral token.
     * @param _totalDebt Total collateral debt of this strategy
     * @return _profit Profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal virtual returns (uint256 _profit);

    /**
     * @notice Calculate loss
     * @param _totalDebt Total collateral debt of this strategy
     * @return _loss Realized loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal virtual returns (uint256 _loss);

    /**
     * @notice Reinvest collateral.
     * @dev Once we file report back in pool, we might have some collateral in hand
     * which we want to reinvest aka deposit in lender/provider.
     */
    function _reinvest() internal virtual;
}


// File contracts/interfaces/vesper/ICollateralManager.sol



pragma solidity 0.8.3;

interface ICollateralManager {
    function addGemJoin(address[] calldata _gemJoins) external;

    function borrow(uint256 _amount) external;

    function createVault(bytes32 _collateralType) external returns (uint256 _vaultNum);

    function depositCollateral(uint256 _amount) external;

    function payback(uint256 _amount) external;

    function transferVaultOwnership(address _newOwner) external;

    function withdrawCollateral(uint256 _amount) external;

    function getVaultBalance(address _vaultOwner) external view returns (uint256 collateralLocked);

    function getVaultDebt(address _vaultOwner) external view returns (uint256 daiDebt);

    function getVaultInfo(address _vaultOwner)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function mcdManager() external view returns (address);

    function vaultNum(address _vaultOwner) external view returns (uint256 _vaultNum);

    function whatWouldWithdrawDo(address _vaultOwner, uint256 _amount)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );
}


// File contracts/strategies/maker/MakerStrategy.sol



pragma solidity 0.8.3;


/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in other lending pool to earn interest.
abstract contract MakerStrategy is Strategy {
    using SafeERC20 for IERC20;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ICollateralManager public immutable cm;
    bytes32 public immutable collateralType;
    uint256 public highWater;
    uint256 public lowWater;
    uint256 private constant WAT = 10**16;

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType
    ) Strategy(_pool, _swapManager, _receiptToken) {
        require(_cm != address(0), "cm-address-is-zero");
        collateralType = _collateralType;
        cm = ICollateralManager(_cm);
    }

    /// @notice Create new Maker vault
    function createVault() external onlyGovernor {
        cm.createVault(collateralType);
    }

    /**
     * @dev If pool is underwater this function will resolve underwater condition.
     * If Debt in Maker is greater than Dai balance in lender then pool is underwater.
     * Lowering DAI debt in Maker will resolve underwater condition.
     * Resolve: Calculate required collateral token to lower DAI debt. Withdraw required
     * collateral token from Maker and convert those to DAI via Uniswap.
     * Finally payback debt in Maker using DAI.
     * @dev Also report loss in pool.
     */
    function resurface() external onlyKeeper {
        _resurface();
    }

    /**
     * @notice Update balancing factors aka high water and low water values.
     * Water mark values represent Collateral Ratio in Maker. For example 300 as high water
     * means 300% collateral ratio.
     * @param _highWater Value for high water mark.
     * @param _lowWater Value for low water mark.
     */
    function updateBalancingFactor(uint256 _highWater, uint256 _lowWater) external onlyGovernor {
        require(_lowWater != 0, "lowWater-is-zero");
        require(_highWater > _lowWater, "highWater-less-than-lowWater");
        highWater = _highWater * WAT;
        lowWater = _lowWater * WAT;
    }

    /**
     * @notice Report total value of this strategy
     * @dev Make sure to return value in collateral token and in order to do that
     * we are using Uniswap to get collateral amount for earned DAI.
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        uint256 _daiBalance = _getDaiBalance();
        uint256 _debt = cm.getVaultDebt(address(this));
        if (_daiBalance > _debt) {
            uint256 _daiEarned = _daiBalance - _debt;
            (, _totalValue) = swapManager.bestPathFixedInput(DAI, address(collateralToken), _daiEarned, 0);
        }
        _totalValue += convertFrom18(cm.getVaultBalance(address(this)));
    }

    function vaultNum() external view returns (uint256) {
        return cm.vaultNum(address(this));
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == receiptToken;
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than earning of pool.
     * @notice Earning - Sum of DAI balance and DAI from accrued reward, if any, in lending pool.
     */
    function isUnderwater() public view virtual returns (bool) {
        return cm.getVaultDebt(address(this)) > _getDaiBalance();
    }

    /**
     * @notice Before migration hook. It will be called during migration
     * @dev Transfer Maker vault ownership to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        cm.transferVaultOwnership(_newStrategy);
    }

    function _approveToken(uint256 _amount) internal virtual override {
        IERC20(DAI).safeApprove(address(cm), _amount);
        collateralToken.safeApprove(address(cm), _amount);
        collateralToken.safeApprove(pool, _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            collateralToken.safeApprove(address(swapManager.ROUTERS(i)), _amount);
            IERC20(DAI).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    function _moveDaiToMaker(uint256 _amount) internal {
        if (_amount != 0) {
            _withdrawDaiFromLender(_amount);
            cm.payback(_amount);
        }
    }

    function _moveDaiFromMaker(uint256 _amount) internal virtual {
        cm.borrow(_amount);
        _amount = IERC20(DAI).balanceOf(address(this));
        _depositDaiToLender(_amount);
    }

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @return payback amount in collateral token. Usually it is equal to excess debt.
     */
    function _liquidate(uint256 _excessDebt) internal virtual override returns (uint256) {
        _withdrawHere(_excessDebt);
        return _excessDebt;
    }

    /**
     * @notice Calculate earning and convert it to collateral token
     * @dev Also claim rewards if available.
     *      Withdraw excess DAI from lender.
     *      Swap net earned DAI to collateral token
     * @return profit in collateral token
     */
    function _realizeProfit(
        uint256 /*_totalDebt*/
    ) internal virtual override returns (uint256) {
        _claimRewardsAndConvertTo(DAI);
        _rebalanceDaiInLender();
        uint256 _daiBalance = IERC20(DAI).balanceOf(address(this));
        if (_daiBalance != 0) {
            _safeSwap(DAI, address(collateralToken), _daiBalance, 1);
        }
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate collateral loss from resurface, if any
     * @dev Difference of total debt of strategy in pool and collateral locked
     *      in Maker vault is the loss.
     * @return loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal virtual override returns (uint256) {
        uint256 _collateralLocked = convertFrom18(cm.getVaultBalance(address(this)));
        return _totalDebt > _collateralLocked ? _totalDebt - _collateralLocked : 0;
    }

    /**
     * @notice Deposit collateral in Maker and rebalance collateral and debt in Maker.
     * @dev Based on defined risk parameter either borrow more DAI from Maker or
     * payback some DAI in Maker. It will try to mitigate risk of liquidation.
     */
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            cm.depositCollateral(_collateralBalance);
        }

        (
            uint256 _collateralLocked,
            uint256 _currentDebt,
            uint256 _collateralUsdRate,
            uint256 _collateralRatio,
            uint256 _minimumAllowedDebt
        ) = cm.getVaultInfo(address(this));
        uint256 _maxDebt = (_collateralLocked * _collateralUsdRate) / highWater;
        if (_maxDebt < _minimumAllowedDebt) {
            // Dusting Scenario:: Based on collateral locked, if our max debt is less
            // than Maker defined minimum debt then payback whole debt and wind up.
            _moveDaiToMaker(_currentDebt);
        } else {
            if (_collateralRatio > highWater) {
                require(!isUnderwater(), "pool-is-underwater");
                // Safe to borrow more DAI
                _moveDaiFromMaker(_maxDebt - _currentDebt);
            } else if (_collateralRatio < lowWater) {
                // Being below low water brings risk of liquidation in Maker.
                // Withdraw DAI from Lender and deposit in Maker
                _moveDaiToMaker(_currentDebt - _maxDebt);
            }
        }
    }

    function _resurface() internal virtual {
        require(isUnderwater(), "pool-is-above-water");
        uint256 _daiNeeded = cm.getVaultDebt(address(this)) - _getDaiBalance();
        (address[] memory _path, uint256 _collateralNeeded, uint256 rIdx) =
            swapManager.bestInputFixedOutput(address(collateralToken), DAI, _daiNeeded);
        if (_collateralNeeded != 0) {
            cm.withdrawCollateral(_collateralNeeded);
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                _collateralNeeded,
                1,
                _path,
                address(this),
                block.timestamp
            );
            cm.payback(IERC20(DAI).balanceOf(address(this)));
            IVesperPool(pool).reportLoss(_collateralNeeded);
        }
    }

    function _withdraw(uint256 _amount) internal override {
        _withdrawHere(_amount);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    // TODO do we need a safe withdraw
    function _withdrawHere(uint256 _amount) internal {
        (
            uint256 collateralLocked,
            uint256 debt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        ) = cm.whatWouldWithdrawDo(address(this), _amount);
        if (debt != 0 && collateralRatio < lowWater) {
            // If this withdraw results in Low Water scenario.
            uint256 maxDebt = (collateralLocked * collateralUsdRate) / highWater;
            if (maxDebt < minimumDebt) {
                // This is Dusting scenario
                _moveDaiToMaker(debt);
            } else if (maxDebt < debt) {
                _moveDaiToMaker(debt - maxDebt);
            }
        }
        cm.withdrawCollateral(_amount);
    }

    function _depositDaiToLender(uint256 _amount) internal virtual;

    function _rebalanceDaiInLender() internal virtual;

    function _withdrawDaiFromLender(uint256 _amount) internal virtual;

    function _getDaiBalance() internal view virtual returns (uint256);
}


// File contracts/interfaces/vesper/IPoolRewards.sol



pragma solidity 0.8.3;

interface IPoolRewards {
    /// Emitted after reward added
    event RewardAdded(address indexed rewardToken, uint256 reward, uint256 rewardDuration);
    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);
    /// Emitted after adding new rewards token into rewardTokens array
    event RewardTokenAdded(address indexed rewardToken, address[] existingRewardTokens);

    function claimReward(address) external;

    function notifyRewardAmount(
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _rewardDuration
    ) external;

    function notifyRewardAmount(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts,
        uint256[] memory _rewardDurations
    ) external;

    function updateReward(address) external;

    function claimable(address _account)
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts);

    function lastTimeRewardApplicable(address _rewardToken) external view returns (uint256);

    function rewardForDuration()
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardForDuration);

    function rewardPerToken()
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardPerTokenRate);
}


// File contracts/strategies/Earn.sol



pragma solidity 0.8.3;





abstract contract Earn is Strategy {
    using SafeERC20 for IERC20;

    address public immutable dripToken;

    uint256 public dripPeriod = 48 hours;
    uint256 public totalEarned; // accounting total stable coin earned. This amount is not reported to pool.

    event DripPeriodUpdated(uint256 oldDripPeriod, uint256 newDripPeriod);

    constructor(address _dripToken) {
        require(_dripToken != address(0), "dripToken-zero");
        dripToken = _dripToken;
    }

    /**
     * @notice Update update period of distribution of earning done in one rebalance
     * @dev _dripPeriod in seconds
     */
    function updateDripPeriod(uint256 _dripPeriod) external onlyGovernor {
        require(_dripPeriod != 0, "dripPeriod-zero");
        require(_dripPeriod != dripPeriod, "same-dripPeriod");
        emit DripPeriodUpdated(dripPeriod, _dripPeriod);
        dripPeriod = _dripPeriod;
    }

    /// @notice Converts excess collateral earned to drip token
    function _convertCollateralToDrip() internal {
        uint256 _collateralAmount = collateralToken.balanceOf(address(this));
        _convertCollateralToDrip(_collateralAmount);
    }

    function _convertCollateralToDrip(uint256 _collateralAmount) internal {
        if (_collateralAmount != 0) {
            uint256 minAmtOut =
                (swapSlippage != 10000)
                    ? _calcAmtOutAfterSlippage(
                        _getOracleRate(_simpleOraclePath(address(collateralToken), dripToken), _collateralAmount),
                        swapSlippage
                    )
                    : 1;
            _safeSwap(address(collateralToken), dripToken, _collateralAmount, minAmtOut);
        }
    }

    /**
     * @notice Send this earning to drip contract.
     */
    function _forwardEarning() internal {
        (, uint256 _interestFee, , , , , , ) = IVesperPool(pool).strategy(address(this));
        address _dripContract = IVesperPool(pool).poolRewards();
        uint256 _earned = IERC20(dripToken).balanceOf(address(this));
        if (_earned != 0) {
            totalEarned += _earned;
            uint256 _fee = (_earned * _interestFee) / 10000;
            if (_fee != 0) {
                IERC20(dripToken).safeTransfer(feeCollector, _fee);
                _earned = _earned - _fee;
            }
            IERC20(dripToken).safeTransfer(_dripContract, _earned);
            IPoolRewards(_dripContract).notifyRewardAmount(dripToken, _earned, dripPeriod);
        }
    }
}


// File contracts/interfaces/compound/ICompound.sol



pragma solidity 0.8.3;

interface CToken {
    function accrueInterest() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrow(uint256 borrowAmount) external returns (uint256);

    function mint() external payable; // For ETH

    function mint(uint256 mintAmount) external returns (uint256); // For ERC20

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable; // For ETH

    function repayBorrow(uint256 repayAmount) external returns (uint256); // For ERC20

    function transfer(address user, uint256 amount) external returns (bool);

    function getCash() external view returns (uint256);

    function transferFrom(
        address owner,
        address user,
        uint256 amount
    ) external returns (bool);

    function underlying() external view returns (address);
}

interface Comptroller {
    function claimComp(address holder, address[] memory) external;

    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function compAccrued(address holder) external view returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function markets(address market)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isCompted
        );
}


// File contracts/strategies/maker/CompoundMakerStrategy.sol



pragma solidity 0.8.3;


/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Compound to earn interest.
abstract contract CompoundMakerStrategy is MakerStrategy {
    using SafeERC20 for IERC20;

    address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    CToken internal immutable cToken;
    Comptroller internal constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType
    ) MakerStrategy(_pool, _cm, _swapManager, _receiptToken, _collateralType) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
    }

    /**
     * @notice Report total value of this strategy
     * @dev Make sure to return value in collateral token.
     * @dev Total value = DAI earned + COMP earned + Collateral locked in Maker
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        _totalValue = _calculateTotalValue(COMPTROLLER.compAccrued(address(this)));
    }

    function totalValueCurrent() public virtual override returns (uint256 _totalValue) {
        _claimComp();
        _totalValue = _calculateTotalValue(IERC20(COMP).balanceOf(address(this)));
    }

    function _calculateTotalValue(uint256 _compAccrued) internal view returns (uint256 _totalValue) {
        uint256 _daiBalance = _getDaiBalance();
        uint256 _debt = cm.getVaultDebt(address(this));
        if (_daiBalance > _debt) {
            uint256 _daiEarned = _daiBalance - _debt;
            (, _totalValue) = swapManager.bestPathFixedInput(DAI, address(collateralToken), _daiEarned, 0);
        }

        if (_compAccrued != 0) {
            (, uint256 _compAsCollateral) =
                swapManager.bestPathFixedInput(COMP, address(collateralToken), _compAccrued, 0);
            _totalValue += _compAsCollateral;
        }
        _totalValue += convertFrom18(cm.getVaultBalance(address(this)));
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return _token == receiptToken || _token == COMP;
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than earning of pool.
     * @notice Earning - Sum of DAI balance and DAI from accrued reward, if any, in lending pool.
     * @dev There can be a scenario when someone calls claimComp() periodically which will
     * leave compAccrued = 0 and pool might be underwater. Call rebalance() to liquidate COMP.
     */
    function isUnderwater() public view override returns (bool) {
        uint256 _compAccrued = COMPTROLLER.compAccrued(address(this));
        uint256 _daiEarned;
        if (_compAccrued != 0) {
            (, _daiEarned) = swapManager.bestPathFixedInput(COMP, DAI, _compAccrued, 0);
        }
        return cm.getVaultDebt(address(this)) > (_getDaiBalance() + _daiEarned);
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(address(receiptToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(COMP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /// @notice Claim rewardToken from lender and convert it into DAI
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        _claimComp();
        uint256 _compAmount = IERC20(COMP).balanceOf(address(this));
        if (_compAmount > 0) {
            _safeSwap(COMP, _toToken, _compAmount, 1);
        }
    }

    function _claimComp() internal {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        COMPTROLLER.claimComp(address(this), _markets);
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        if (_amount != 0) {
            require(cToken.mint(_amount) == 0, "deposit-in-compound-failed");
        }
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return (cToken.balanceOf(address(this)) * cToken.exchangeRateStored()) / 1e18;
    }

    /**
     * @dev Rebalance DAI in lender. If lender has more DAI than DAI debt in Maker
     * then withdraw excess DAI from lender. If lender is short on DAI, underwater,
     * then deposit DAI to lender.
     * @dev There may be a scenario where we do not have enough DAI to deposit to
     * lender, in that case pool will be underwater even after rebalanceDai.
     */
    function _rebalanceDaiInLender() internal override {
        uint256 _daiDebtInMaker = cm.getVaultDebt(address(this));
        uint256 _daiInLender = _getDaiBalance();
        if (_daiInLender > _daiDebtInMaker) {
            _withdrawDaiFromLender(_daiInLender - _daiDebtInMaker);
        } else if (_daiInLender < _daiDebtInMaker) {
            // We have more DAI debt in Maker than DAI in lender
            uint256 _daiNeeded = _daiDebtInMaker - _daiInLender;
            uint256 _daiBalanceHere = IERC20(DAI).balanceOf(address(this));
            if (_daiBalanceHere > _daiNeeded) {
                _depositDaiToLender(_daiNeeded);
            } else {
                _depositDaiToLender(_daiBalanceHere);
            }
        }
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
    }
}


// File contracts/interfaces/aave/IAave.sol



pragma solidity 0.8.3;

interface AaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getAddress(bytes32 id) external view returns (address);
}

interface AToken is IERC20 {
    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController() external view returns (address);
}

interface AaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface AaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface AaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

//solhint-disable func-name-mixedcase
interface StakedAave is IERC20 {
    function claimRewards(address to, uint256 amount) external;

    function cooldown() external;

    function stake(address onBehalfOf, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker) external view returns (uint256);

    function stakersCooldowns(address staker) external view returns (uint256);

    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);
}


// File contracts/strategies/aave/AaveCore.sol



pragma solidity 0.8.3;

/// @title This contract provide core operations for Aave
abstract contract AaveCore {
    //solhint-disable-next-line const-name-snakecase
    StakedAave public constant stkAAVE = StakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    AaveLendingPoolAddressesProvider public aaveAddressesProvider =
        AaveLendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    AaveLendingPool public immutable aaveLendingPool;
    AaveProtocolDataProvider public immutable aaveProtocolDataProvider;
    AaveIncentivesController public immutable aaveIncentivesController;

    AToken internal immutable aToken;
    bytes32 private constant AAVE_PROVIDER_ID = 0x0100000000000000000000000000000000000000000000000000000000000000;

    constructor(address _receiptToken) {
        require(_receiptToken != address(0), "aToken-address-is-zero");
        aToken = AToken(_receiptToken);
        // If there is no AAVE incentive then below call will fail
        try AToken(_receiptToken).getIncentivesController() {
            aaveIncentivesController = AaveIncentivesController(AToken(_receiptToken).getIncentivesController());
        } catch {} //solhint-disable no-empty-blocks

        aaveLendingPool = AaveLendingPool(aaveAddressesProvider.getLendingPool());
        aaveProtocolDataProvider = AaveProtocolDataProvider(aaveAddressesProvider.getAddress(AAVE_PROVIDER_ID));
    }

    ///////////////////////// External access functions /////////////////////////

    /**
     * @notice Initiate cooldown to unstake aave.
     * @dev We only want to call this function when cooldown is expired and
     * that's the reason we have 'if' condition.
     * @dev Child contract should expose this function as external and onlyKeeper
     */
    function _startCooldown() internal returns (bool) {
        if (canStartCooldown()) {
            stkAAVE.cooldown();
            return true;
        }
        return false;
    }

    /**
     * @notice Unstake Aave from stakedAave contract
     * @dev We want to unstake as soon as favorable condition exit
     * @dev No guarding condition thus this call can fail, if we can't unstake.
     * @dev Child contract should expose this function as external and onlyKeeper
     */
    function _unstakeAave() internal {
        stkAAVE.redeem(address(this), type(uint256).max);
    }

    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns true if Aave can be unstaked
    function canUnstake() external view returns (bool) {
        (, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        return _canUnstake(_cooldownEnd, _unstakeEnd);
    }

    /// @notice Returns true if we should start cooldown
    function canStartCooldown() public view returns (bool) {
        (uint256 _cooldownStart, , uint256 _unstakeEnd) = cooldownData();
        return _canStartCooldown(_cooldownStart, _unstakeEnd);
    }

    /// @notice Return cooldown related timestamps
    function cooldownData()
        public
        view
        returns (
            uint256 _cooldownStart,
            uint256 _cooldownEnd,
            uint256 _unstakeEnd
        )
    {
        _cooldownStart = stkAAVE.stakersCooldowns(address(this));
        _cooldownEnd = _cooldownStart + stkAAVE.COOLDOWN_SECONDS();
        _unstakeEnd = _cooldownEnd + stkAAVE.UNSTAKE_WINDOW();
    }

    /**
     * @notice Claim Aave. Also unstake all Aave if favorable condition exits or start cooldown.
     * @dev If we unstake all Aave, we can't start cooldown because it requires StakedAave balance.
     * @dev DO NOT convert 'if else' to 2 'if's as we are reading cooldown state once to save gas.
     * @dev Not all collateral token has aave incentive
     */
    function _claimAave() internal returns (uint256) {
        if (address(aaveIncentivesController) == address(0)) {
            return 0;
        }
        (uint256 _cooldownStart, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        if (_cooldownStart == 0 || block.timestamp > _unstakeEnd) {
            // claim stkAave when its first rebalance or unstake period passed.
            address[] memory _assets = new address[](1);
            _assets[0] = address(aToken);
            aaveIncentivesController.claimRewards(_assets, type(uint256).max, address(this));
        }
        // Fetch and check again for next action.
        (_cooldownStart, _cooldownEnd, _unstakeEnd) = cooldownData();
        if (_canUnstake(_cooldownEnd, _unstakeEnd)) {
            stkAAVE.redeem(address(this), type(uint256).max);
        } else if (_canStartCooldown(_cooldownStart, _unstakeEnd)) {
            stkAAVE.cooldown();
        }

        stkAAVE.claimRewards(address(this), type(uint256).max);
        return IERC20(AAVE).balanceOf(address(this));
    }

    /// @notice Deposit asset into Aave
    function _deposit(address _asset, uint256 _amount) internal {
        if (_amount != 0) {
            aaveLendingPool.deposit(_asset, _amount, address(this), 0);
        }
    }

    /**
     * @notice Safe withdraw will make sure to check asking amount against available amount.
     * @dev Check we have enough aToken and liquidity to support this withdraw
     * @param _asset Address of asset to withdraw
     * @param _to Address that will receive collateral token.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _safeWithdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 _aTokenBalance = aToken.balanceOf(address(this));
        // If Vesper becomes large liquidity provider in Aave(This happened in past in vUSDC 1.0)
        // In this case we might have more aToken compare to available liquidity in Aave and any
        // withdraw asking more than available liquidity will fail. To do safe withdraw, check
        // _amount against available liquidity.
        (uint256 _availableLiquidity, , , , , , , , , ) = aaveProtocolDataProvider.getReserveData(_asset);
        // Get minimum of _amount, _aTokenBalance and _availableLiquidity
        return _withdraw(_asset, _to, _min(_amount, _min(_aTokenBalance, _availableLiquidity)));
    }

    /**
     * @notice Withdraw given amount of collateral from Aave to given address
     * @param _asset Address of asset to withdraw
     * @param _to Address that will receive collateral token.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _withdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount != 0) {
            require(aaveLendingPool.withdraw(_asset, _amount, _to) == _amount, "withdrawn-amount-is-not-correct");
        }
        return _amount;
    }

    /**
     * @dev Return true, only if we have StakedAave balance and either cooldown expired or cooldown is zero
     * @dev If we are in cooldown period we cannot unstake Aave. But our cooldown is still valid so we do
     * not want to reset/start cooldown.
     */
    function _canStartCooldown(uint256 _cooldownStart, uint256 _unstakeEnd) internal view returns (bool) {
        return stkAAVE.balanceOf(address(this)) != 0 && (_cooldownStart == 0 || block.timestamp > _unstakeEnd);
    }

    /// @dev Return true, if cooldown is over and we are in unstake window.
    function _canUnstake(uint256 _cooldownEnd, uint256 _unstakeEnd) internal view returns (bool) {
        return block.timestamp > _cooldownEnd && block.timestamp <= _unstakeEnd;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function _isReservedToken(address _token) internal view returns (bool) {
        return _token == address(aToken) || _token == AAVE || _token == address(stkAAVE);
    }

    /**
     * @notice Return total AAVE incentive allocated to this address
     * @dev Aave and StakedAave are 1:1
     * @dev Not all collateral token has aave incentive
     */
    function _totalAave() internal view returns (uint256) {
        if (address(aaveIncentivesController) == address(0)) {
            return 0;
        }
        address[] memory _assets = new address[](1);
        _assets[0] = address(aToken);
        // TotalAave = Get current StakedAave rewards from controller +
        //             StakedAave balance here +
        //             Aave rewards by staking Aave in StakedAave contract
        return
            aaveIncentivesController.getRewardsBalance(_assets, address(this)) +
            stkAAVE.balanceOf(address(this)) +
            stkAAVE.getTotalRewardsBalance(address(this));
    }

    /// @notice Returns minimum of 2 given numbers
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


// File contracts/strategies/maker/EarnCompoundMakerStrategy.sol


pragma solidity 0.8.3;





/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Aave to earn interest.
abstract contract EarnCompoundMakerStrategy is CompoundMakerStrategy, Earn {
    //solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType,
        address _dripToken
    ) CompoundMakerStrategy(_pool, _cm, _swapManager, _receiptToken, _collateralType) Earn(_dripToken) {}

    function totalValueCurrent() public override(Strategy, CompoundMakerStrategy) returns (uint256 _totalValue) {
        _claimComp();
        _totalValue = _calculateTotalValue(IERC20(COMP).balanceOf(address(this)));
    }

    function _claimRewardsAndConvertTo(address _toToken) internal override(Strategy, CompoundMakerStrategy) {
        CompoundMakerStrategy._claimRewardsAndConvertTo(_toToken);
    }

    /**
     * @notice Calculate earning and convert it to collateral token
     * @dev Also claim rewards if available.
     *      Withdraw excess DAI from lender.
     *      Swap net earned DAI to collateral token
     * @return profit in collateral token
     */
    function _realizeProfit(
        uint256 /*_totalDebt*/
    ) internal virtual override(Strategy, MakerStrategy) returns (uint256) {
        _claimRewardsAndConvertTo(dripToken);
        _rebalanceDaiInLender();
        _forwardEarning();
        return collateralToken.balanceOf(address(this));
    }
}


// File contracts/strategies/maker/EarnCompoundMakerStrategyETH.sol



pragma solidity 0.8.3;

//solhint-disable no-empty-blocks
contract EarnCompoundMakerStrategyETH is EarnCompoundMakerStrategy {
    string public constant NAME = "Earn-Aave-Maker-Strategy-ETH";
    string public constant VERSION = "3.0.0";

    // cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
    constructor(
        address _pool,
        address _cm,
        address _swapManager
    ) EarnCompoundMakerStrategy(_pool, _cm, _swapManager, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, "ETH-C", DAI) {}
}