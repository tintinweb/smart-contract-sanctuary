/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: AGPL V3.0

pragma solidity 0.8.4;
pragma abicoder v2;



// Part: ILmClaimer

interface ILmClaimer {
    function claimEpoch(
        uint256 epoch,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external;
}

// Part: IMCLP

interface IMCLP {
    enum PerpetualState {
        INVALID,
        INITIALIZING,
        NORMAL,
        EMERGENCY,
        CLEARED
    }

    function deposit(
        uint256 perpetualIndex,
        address trader,
        int256 amount
    ) external;

    function withdraw(
        uint256 perpetualIndex,
        address trader,
        int256 amount
    ) external;

    function trade(
        uint256 perpetualIndex,
        address trader,
        int256 amount,
        int256 limitPrice,
        uint256 deadline,
        address referrer,
        uint32 flags
    ) external returns (int256 tradeAmount);

    function settle(uint256 perpetualIndex, address trader) external;

    /**
     * @notice Get the account info of the trader. Need to update the funding state and the oracle price
     *         of each perpetual before and update the funding rate of each perpetual after
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @param trader The address of the trader
     * @return cash The cash(collateral) of the account
     * @return position The position of the account
     * @return availableMargin The available margin of the account
     * @return margin The margin of the account
     * @return settleableMargin The settleable margin of the account
     * @return isInitialMarginSafe True if the account is initial margin safe
     * @return isMaintenanceMarginSafe True if the account is maintenance margin safe
     * @return isMarginSafe True if the total value of margin account is beyond 0
     * @return targetLeverage   The target leverage for openning position.
     */
    function getMarginAccount(uint256 perpetualIndex, address trader)
        external
        view
        returns (
            int256 cash,
            int256 position,
            int256 availableMargin,
            int256 margin,
            int256 settleableMargin,
            bool isInitialMarginSafe,
            bool isMaintenanceMarginSafe,
            bool isMarginSafe, // bankrupt
            int256 targetLeverage
        );

    function setTargetLeverage(
        uint256,
        address,
        int256
    ) external;

    /**
     * @notice  Query the price, fees and cost when trade agaist amm.
     *          The trading price is determined by the AMM based on the index price of the perpetual.
     *          This method should returns the same result as a 'read-only' trade.
     *          WARN: the result of this function is base on current storage of liquidityPool, not the latest.
     *          To get the latest status, call `syncState` first.
     *
     *          Flags is a 32 bit uint value which indicates: (from highest bit)
     *            - close only      only close position during trading;
     *            - market order    do not check limit price during trading;
     *            - stop loss       only available in brokerTrade mode;
     *            - take profit     only available in brokerTrade mode;
     *          For stop loss and take profit, see `validateTriggerPrice` in OrderModule.sol for details.
     *
     * @param   perpetualIndex  The index of the perpetual in liquidity pool.
     * @param   trader          The address of trader.
     * @param   amount          The amount of position to trader, positive for buying and negative for selling. The amount always use decimals 18.
     * @param   referrer        The address of referrer who will get rebate from the deal.
     * @param   flags           The flags of the trade.
     * @return  tradePrice      The average fill price.
     * @return  totalFee        The total fee collected from the trader after the trade.
     * @return  cost            Deposit or withdraw to let effective leverage == targetLeverage if flags contain USE_TARGET_LEVERAGE. > 0 if deposit, < 0 if withdraw.
     */
    function queryTrade(
        uint256 perpetualIndex,
        address trader,
        int256 amount,
        address referrer,
        uint32 flags
    )
        external
        returns (
            int256 tradePrice,
            int256 totalFee,
            int256 cost
        );

    /**
     * @notice Get the info of the perpetual. Need to update the funding state and the oracle price
     *         of each perpetual before and update the funding rate of each perpetual after
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @return state The state of the perpetual
     * @return oracle The oracle's address of the perpetual
     * @return nums The related numbers of the perpetual
     */
    function getPerpetualInfo(uint256 perpetualIndex)
        external
        view
        returns (
            PerpetualState state,
            address oracle,
            // [0] totalCollateral
            // [1] markPrice, (return settlementPrice if it is in EMERGENCY state)
            // [2] indexPrice,
            // [3] fundingRate,
            // [4] unitAccumulativeFunding,
            // [5] initialMarginRate,
            // [6] maintenanceMarginRate,
            // [7] operatorFeeRate,
            // [8] lpFeeRate,
            // [9] referralRebateRate,
            // [10] liquidationPenaltyRate,
            // [11] keeperGasReward,
            // [12] insuranceFundRate,
            // [13-15] halfSpread value, min, max,
            // [16-18] openSlippageFactor value, min, max,
            // [19-21] closeSlippageFactor value, min, max,
            // [22-24] fundingRateLimit value, min, max,
            // [25-27] ammMaxLeverage value, min, max,
            // [28-30] maxClosePriceDiscount value, min, max,
            // [31] openInterest,
            // [32] maxOpenInterestRate,
            // [33-35] fundingRateFactor value, min, max,
            // [36-38] defaultTargetLeverage value, min, max,
            int256[39] memory nums
        );

    /**
     * @notice  If you want to get the real-time data, call this function first
     */
    function forceToSyncState() external;

    function getLiquidityPoolInfo()
        external
        view
        returns (
            bool isRunning,
            bool isFastCreationEnabled,
            // [0] creator,
            // [1] operator,
            // [2] transferringOperator,
            // [3] governor,
            // [4] shareToken,
            // [5] collateralToken,
            // [6] vault,
            address[7] memory addresses,
            // [0] vaultFeeRate,
            // [1] poolCash,
            // [2] insuranceFundCap,
            // [3] insuranceFund,
            // [4] donatedInsuranceFund,
            int256[5] memory intNums,
            // [0] collateralDecimals,
            // [1] perpetualCount,
            // [2] fundingTime,
            // [3] operatorExpiration,
            // [4] liquidityCap,
            // [5] shareTransferDelay,
            uint256[6] memory uintNums
        );
}

// Part: IOracle

interface IOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external returns (bool);

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external returns (bool);

    /**
     * @dev Get collateral symbol.
     */
    function collateral() external view returns (string memory);

    /**
     * @dev Get underlying asset symbol.
     */
    function underlyingAsset() external view returns (string memory);

    /**
     * @dev Mark price.
     */
    function priceTWAPLong()
        external
        returns (int256 newPrice, uint256 newTimestamp);

    /**
     * @dev Index price.
     */
    function priceTWAPShort()
        external
        returns (int256 newPrice, uint256 newTimestamp);
}

// Part: IRouterV2

interface IRouterV2 {
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

// Part: OpenZeppelin/[email protected]/Initializable

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: Uniswap/[email protected]/IUniswapV3PoolActions

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// Part: Uniswap/[email protected]/IUniswapV3PoolDerivedState

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// Part: Uniswap/[email protected]/IUniswapV3PoolEvents

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// Part: Uniswap/[email protected]/IUniswapV3PoolImmutables

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// Part: Uniswap/[email protected]/IUniswapV3PoolOwnerActions

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// Part: Uniswap/[email protected]/IUniswapV3PoolState

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// Part: Uniswap/[email protected]/IUniswapV3SwapCallback

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// Part: IBasisVault

interface IBasisVault {
    function deposit(uint256, address) external returns (uint256);

    function update(uint256, bool) external returns (uint256);

    function want() external returns (IERC20);
}

// Part: OpenZeppelin/[email protected]/ContextUpgradeable

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// Part: OpenZeppelin/[email protected]/ReentrancyGuardUpgradeable

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: Uniswap/[email protected]/IUniswapV3Pool

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// Part: Uniswap/[email protected]/ISwapRouter

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// Part: OpenZeppelin/[email protected]/OwnableUpgradeable

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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

// Part: OpenZeppelin/[email protected]/PausableUpgradeable

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
    uint256[49] private __gap;
}

// File: BasisStrategy.sol

/**
 * @title  BasisStrategy
 * @author akropolis.io
 * @notice A strategy used to perform basis trading using funds from a BasisVault
 */
contract BasisStrategy is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    // struct to store the position state of the strategy
    struct Positions {
        int256 perpContracts;
        int256 margin;
        int256 unitAccumulativeFunding;
    }

    // MCDEX Liquidity and Perpetual Pool interface address
    IMCLP public mcLiquidityPool;
    // Uniswap v3 pair pool interface address
    address public pool;
    // Uniswap v3 router interface address
    address public router;
    // Basis Vault interface address
    IBasisVault public vault;
    // MCDEX oracle
    IOracle public oracle;
    // MCDEX trade reward claimer
    ILmClaimer public lmClaimer;

    // address of the want (short collateral) of the strategy
    address public want;
    // address of the long asset of the strategy
    address public long;
    // address of the mcb token
    address public mcb;
    // address of the referrer for MCDEX
    address public referrer;
    // address of governance
    address public governance;
    // address weth
    address public weth;
    // Positions of the strategy
    Positions public positions;
    // perpetual index in MCDEX
    uint256 public perpetualIndex;
    // margin buffer of the strategy, between 0 and 10_000
    uint256 public buffer;
    // max bips
    uint256 public constant MAX_BPS = 1_000_000;
    // decimal shift for USDC
    int256 public DECIMAL_SHIFT;
    // dust for margin positions
    int256 public dust = 1000;
    // slippage Tolerance for the perpetual trade
    int256 public slippageTolerance;
    // unwind state tracker
    bool public isUnwind;
    // trade mode of the perp
    uint32 public tradeMode = 0x40000000;
    // bool determine layer version
    bool isV2;
    // modifier to check that the caller is governance
    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    // modifier to check that the caller is governance or owner
    modifier onlyAuthorised() {
        require(
            msg.sender == governance || msg.sender == owner(),
            "!authorised"
        );
        _;
    }

    // modifier to check that the caller is the vault
    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }

    /**
     * @param _long            address of the long asset of the strategy
     * @param _pool            Uniswap v3 pair pool address
     * @param _vault           Basis Vault address
     * @param _oracle          MCDEX oracle address
     * @param _router          Uniswap v3 router address
     * @param _governance      Governance address
     * @param _mcLiquidityPool MCDEX Liquidity and Perpetual Pool address
     * @param _perpetualIndex  index of the perpetual market
     */
    function initialize(
        address _long,
        address _pool,
        address _vault,
        address _oracle,
        address _router,
        address _weth,
        address _governance,
        address _mcLiquidityPool,
        uint256 _perpetualIndex,
        bool _isV2
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        require(_long != address(0), "!_long");
        require(_pool != address(0), "!_pool");
        require(_vault != address(0), "!_vault");
        require(_oracle != address(0), "!_oracle");
        require(_router != address(0), "!_router");
        require(_governance != address(0), "!_governance");
        require(_mcLiquidityPool != address(0), "!_mcLiquidityPool");
        require(_weth != address(0), "!_weth");
        long = _long;
        pool = _pool;
        vault = IBasisVault(_vault);
        oracle = IOracle(_oracle);
        router = _router;
        weth = _weth;
        governance = _governance;
        mcLiquidityPool = IMCLP(_mcLiquidityPool);
        perpetualIndex = _perpetualIndex;
        isV2 = _isV2;
        want = address(vault.want());
        mcLiquidityPool.setTargetLeverage(perpetualIndex, address(this), 1e18);
        (, , , , uint256[6] memory stores) = mcLiquidityPool
            .getLiquidityPoolInfo();
        DECIMAL_SHIFT = int256(1e18 / 10**(stores[0]));
    }

    /**********
     * EVENTS *
     **********/

    event DepositToMarginAccount(uint256 amount, uint256 perpetualIndex);
    event WithdrawStrategy(uint256 amountWithdrawn, uint256 loss);
    event Harvest(int256 perpContracts, uint256 longPosition, int256 margin);
    event StrategyUnwind(uint256 positionSize);
    event EmergencyExit(address indexed recipient, uint256 positionSize);
    event PerpPositionOpened(
        int256 perpPositions,
        uint256 perpetualIndex,
        uint256 collateral
    );
    event PerpPositionClosed(
        int256 perpPositions,
        uint256 perpetualIndex,
        uint256 collateral
    );
    event AllPerpPositionsClosed(int256 perpPositions, uint256 perpetualIndex);
    event Snapshot(
        int256 cash,
        int256 position,
        int256 availableMargin,
        int256 margin,
        int256 settleableMargin,
        bool isInitialMarginSafe,
        bool isMaintenanceMarginSafe,
        bool isMarginSafe // bankrupt
    );
    event BufferAdjusted(
        int256 oldMargin,
        int256 newMargin,
        int256 oldPerpContracts,
        int256 newPerpContracts,
        uint256 oldLong,
        uint256 newLong
    );
    event Remargined(int256 unwindAmount);

    /***********
     * SETTERS *
     ***********/

    /**
     * @notice  setter for the mcdex liquidity pool
     * @param   _mcLiquidityPool MCDEX Liquidity and Perpetual Pool address
     * @dev     only callable by owner
     */
    function setLiquidityPool(address _mcLiquidityPool) external onlyOwner {
        mcLiquidityPool = IMCLP(_mcLiquidityPool);
    }

    /**
     * @notice  setter for the uniswap pair pool
     * @param   _pool Uniswap v3 pair pool address
     * @dev     only callable by owner
     */
    function setUniswapPool(address _pool) external onlyOwner {
        pool = _pool;
    }

    /**
     * @notice  setter for the basis vault
     * @param   _vault Basis Vault address
     * @dev     only callable by owner
     */
    function setBasisVault(address _vault) external onlyOwner {
        vault = IBasisVault(_vault);
    }

    /**
     * @notice  setter for buffer
     * @param   _buffer Basis strategy margin buffer
     * @dev     only callable by owner
     */
    function setBuffer(uint256 _buffer) public onlyOwner {
        require(_buffer < 1_000_000, "!_buffer");
        buffer = _buffer;
    }

    /**
     * @notice  setter for perpetualIndex value
     * @param   _perpetualIndex MCDEX perpetual index
     * @dev     only callable by owner
     */
    function setPerpetualIndex(uint256 _perpetualIndex) external onlyOwner {
        perpetualIndex = _perpetualIndex;
    }

    /**
     * @notice  setter for referrer for MCDEX rebates
     * @param   _referrer address of the MCDEX referral recipient
     * @dev     only callable by owner
     */
    function setReferrer(address _referrer) external onlyOwner {
        referrer = _referrer;
    }

    /**
     * @notice  setter for perpetual trade slippage tolerance
     * @param   _slippageTolerance amount of slippage tolerance to accept on perp trade
     * @dev     only callable by owner
     */
    function setSlippageTolerance(int256 _slippageTolerance)
        external
        onlyOwner
    {
        slippageTolerance = _slippageTolerance;
    }

    /**
     * @notice  setter for dust for closing margin positions
     * @param   _dust amount of dust in wei that is acceptable
     * @dev     only callable by owner
     */
    function setDust(int256 _dust) external onlyOwner {
        dust = _dust;
    }

    /**
     * @notice  setter for the tradeMode of the perp
     * @param   _tradeMode uint32 for the perp trade mode
     * @dev     only callable by owner
     */
    function setTradeMode(uint32 _tradeMode) external onlyOwner {
        tradeMode = _tradeMode;
    }

    /**
     * @notice  setter for the governance address
     * @param   _governance address of governance
     * @dev     only callable by governance
     */
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    /**

     * @notice set router version for network
     * @param _isV2 bool to set the version of rooter
     * @dev only callable by owner
     */
    function setVersion(bool _isV2) external onlyOwner {
        isV2 = _isV2;
    }

    /**
     * @notice  setter for liquidity mining claim contract
     * @param   _lmClaimer the claim contract
     * @param   _mcb the mcb token address
     * @dev     only callable by owner
     */
    function setLmClaimerAndMcb(address _lmClaimer, address _mcb)
        external
        onlyOwner
    {
        lmClaimer = ILmClaimer(_lmClaimer);
        mcb = _mcb;
    }

    /**
     * @notice  setter for weth depending on the network
     * @param   _weth for weth
     * @dev     only callable by owner
     */
    function setWeth(address _weth) external onlyOwner {
        require(_weth != address(0), "!_weth");
        weth = _weth;
    }

    /**
     * @notice  setter for long asset
     * @param   _long for long
     * @dev     only callable by owner
     */
    function setLong(address _long) external onlyOwner {
        require(_long != address(0), "!_long");
        long = _long;
    }

    /**********************
     * EXTERNAL FUNCTIONS *
     **********************/

    /**
     * @notice  harvest the strategy. This involves accruing profits from the strategy and depositing
     *          user funds to the strategy. The funds are split into their constituents and then distributed
     *          to their appropriate location.
     *          For the shortPosition a perpetual position is opened, for the long position funds are swapped
     *          to the long asset. For the buffer position the funds are deposited to the margin account idle.
     * @dev     only callable by the owner
     */
    function harvest() public onlyOwner {
        uint256 shortPosition;
        uint256 longPosition;
        uint256 bufferPosition;
        isUnwind = false;

        mcLiquidityPool.forceToSyncState();
        // determine the profit since the last harvest and remove profits from the margin
        // account to be redistributed
        uint256 amount;
        bool loss;
        if (positions.unitAccumulativeFunding != 0) {
            (amount, loss) = _determineFee();
        }
        // update the vault with profits/losses accrued and receive deposits
        uint256 newFunds = vault.update(amount, loss);
        // combine the funds and check that they are larger than 0
        uint256 toActivate = IERC20(want).balanceOf(address(this));

        if (toActivate > 0) {
            // determine the split of the funds and trade for the spot position of long
            (shortPosition, longPosition, bufferPosition) = _calculateSplit(
                toActivate
            );
            // deposit the bufferPosition to the margin account
            _depositToMarginAccount(bufferPosition);
            // open a short perpetual position and store the number of perp contracts
            positions.perpContracts += _openPerpPosition(shortPosition, true);
        }
        // record incremented positions
        positions.margin = getMargin();
        positions.unitAccumulativeFunding = getUnitAccumulativeFunding();
        emit Harvest(
            positions.perpContracts,
            IERC20(long).balanceOf(address(this)),
            positions.margin
        );
    }

    /**
     * @notice  unwind the position in adverse funding rate scenarios, settle short position
     *          and pull funds from the margin account. Then converts the long position back
     *          to want.
     * @dev     only callable by the owner
     */
    function unwind() public onlyAuthorised {
        require(!isUnwind, "unwound");
        isUnwind = true;
        mcLiquidityPool.forceToSyncState();
        // swap long asset back to want
        _swap(IERC20(long).balanceOf(address(this)), long, want);
        // check if the perpetual is in settlement, if it is then settle it
        // otherwise unwind the fund as normal.
        if (!_settle()) {
            // close the short position
            _closeAllPerpPositions();
            // withdraw all cash in the margin account
            mcLiquidityPool.withdraw(
                perpetualIndex,
                address(this),
                getMargin()
            );
        }
        // reset positions
        positions.perpContracts = 0;
        positions.margin = getMargin();
        positions.unitAccumulativeFunding = getUnitAccumulativeFunding();
        emit StrategyUnwind(IERC20(want).balanceOf(address(this)));
    }

    /**
     * @notice  emergency exit the entire strategy in extreme circumstances
     *          unwind the strategy and send the funds to governance
     * @dev     only callable by governance
     */
    function emergencyExit() external onlyGovernance {
        // unwind strategy unless it is already unwound
        if (!isUnwind) {
            unwind();
        }
        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        // send funds to governance
        IERC20(want).safeTransfer(governance, wantBalance);
        emit EmergencyExit(governance, wantBalance);
    }

    /**
     * @notice  remargin the strategy such that margin call risk is reduced
     * @dev     only callable by owner
     */
    function remargin() external onlyOwner {
        // harvest the funds so the positions are up to date
        harvest();
        // ratio of the short in the short and buffer
        int256 K = (((int256(MAX_BPS) - int256(buffer)) / 2) * 1e18) /
            (((int256(MAX_BPS) - int256(buffer)) / 2) + int256(buffer));
        // get the price of ETH
        (int256 price, ) = oracle.priceTWAPLong();
        // calculate amount to unwind
        int256 unwindAmount = (((price * -getMarginPositions()) -
            K *
            getMargin()) * 1e18) / ((1e18 + K) * price);
        require(unwindAmount != 0, "no changes to margin necessary");
        // check if leverage is to be reduced or increased then act accordingly
        if (unwindAmount > 0) {
            // swap unwindAmount long to want
            uint256 wantAmount = _swap(uint256(unwindAmount), long, want);
            // close unwindAmount short to margin account
            mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                unwindAmount,
                price + slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
            // deposit long swapped collateral to margin account
            _depositToMarginAccount(wantAmount);
        } else if (unwindAmount < 0) {
            // the buffer is too high so reduce it to the correct size
            // open a perpetual short position using the unwindAmount
            mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                unwindAmount,
                price - slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
            // withdraw funds from the margin account
            int256 withdrawAmount = (price * -unwindAmount) / 1e18;
            mcLiquidityPool.withdraw(
                perpetualIndex,
                address(this),
                withdrawAmount
            );
            // open a long position with the withdrawn funds
            _swap(uint256(withdrawAmount / DECIMAL_SHIFT), want, long);
        }
        positions.margin = getMargin();
        positions.unitAccumulativeFunding = getUnitAccumulativeFunding();
        positions.perpContracts = getMarginPositions();
        emit Remargined(unwindAmount);
    }

    /**
     * @notice  withdraw funds from the strategy
     * @param   _amount the amount to be withdrawn
     * @return  loss loss recorded
     * @return  withdrawn amount withdrawn
     * @dev     only callable by the vault
     */
    function withdraw(uint256 _amount)
        external
        onlyVault
        returns (uint256 loss, uint256 withdrawn)
    {
        require(_amount > 0, "withdraw: _amount is 0");

        if (!isUnwind) {
            mcLiquidityPool.forceToSyncState();
            // remove the buffer from the amount
            uint256 bufferPosition = (_amount * buffer) / MAX_BPS;
            // decrement the amount by buffer position
            uint256 _remAmount = _amount - bufferPosition;
            // determine the longPosition in want
            uint256 longPositionWant = _remAmount / 2;
            // determine the short position
            uint256 shortPosition = _remAmount - longPositionWant;
            // close the short position
            int256 positionsClosed = _closePerpPosition(shortPosition);
            // determine the long position
            uint256 longPosition = uint256(positionsClosed);
            if (longPosition < IERC20(long).balanceOf(address(this))) {
                // if for whatever reason there are funds left in long when there shouldnt be then liquidate them
                if (getMarginPositions() == 0) {
                    longPosition = IERC20(long).balanceOf(address(this));
                }
                // convert the long to want
                longPositionWant = _swap(longPosition, long, want);
            } else {
                // convert the long to want
                longPositionWant = _swap(
                    IERC20(long).balanceOf(address(this)),
                    long,
                    want
                );
            }
            if (
                getMargin() >
                int256(bufferPosition + shortPosition) * DECIMAL_SHIFT &&
                getMarginPositions() < 0
            ) {
                // withdraw the short and buffer from the margin account
                mcLiquidityPool.withdraw(
                    perpetualIndex,
                    address(this),
                    int256(bufferPosition + shortPosition) * DECIMAL_SHIFT
                );
            } else {
                if (getMarginPositions() < 0) {
                    _closeAllPerpPositions();
                }
                mcLiquidityPool.withdraw(
                    perpetualIndex,
                    address(this),
                    getMargin()
                );
            }

            withdrawn = longPositionWant + shortPosition + bufferPosition;
        } else {
            withdrawn = _amount;
        }

        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        // transfer the funds back to the vault, if at this point needed isnt covered then
        // record a loss
        if (_amount > wantBalance) {
            IERC20(want).safeTransfer(address(vault), wantBalance);
            loss = _amount - wantBalance;
            withdrawn = wantBalance;
        } else {
            IERC20(want).safeTransfer(address(vault), withdrawn);
            loss = 0;
        }

        positions.perpContracts = getMarginPositions();
        positions.margin = getMargin();
        emit WithdrawStrategy(withdrawn, loss);
    }

    /**
     * @notice  emit a snapshot of the margin account
     */
    function snapshot() public {
        mcLiquidityPool.forceToSyncState();
        (
            int256 cash,
            int256 position,
            int256 availableMargin,
            int256 margin,
            int256 settleableMargin,
            bool isInitialMarginSafe,
            bool isMaintenanceMarginSafe,
            bool isMarginSafe,

        ) = mcLiquidityPool.getMarginAccount(perpetualIndex, address(this));
        emit Snapshot(
            cash,
            position,
            availableMargin,
            margin,
            settleableMargin,
            isInitialMarginSafe,
            isMaintenanceMarginSafe,
            isMarginSafe
        );
    }

    /**
     * @notice  gather any liquidity mining rewards of mcb and transfer them to governance
     *          further distribution
     * @param   epoch the epoch to claim rewards for
     * @param   amount the amount to redeem
     * @param   merkleProof the proof to use on the claim
     * @dev     only callable by governance
     */
    function gatherLMrewards(
        uint256 epoch,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external onlyGovernance {
        lmClaimer.claimEpoch(epoch, amount, merkleProof);
        IERC20(mcb).safeTransfer(
            governance,
            IERC20(mcb).balanceOf(address(this))
        );
    }

    /**********************
     * INTERNAL FUNCTIONS *
     **********************/

    /**
     * @notice  open the perpetual short position on MCDEX
     * @param   _amount the collateral used to purchase the perpetual short position
     * @return  tradeAmount the amount of perpetual contracts opened
     */
    function _openPerpPosition(uint256 _amount, bool deposit)
        internal
        returns (int256 tradeAmount)
    {
        if (deposit) {
            // deposit funds to the margin account to enable trading
            _depositToMarginAccount(_amount);
        }

        // get the long asset mark price from the MCDEX oracle
        (int256 price, ) = oracle.priceTWAPLong();
        // calculate the number of contracts (*1e12 because USDC is 6 decimals)
        int256 contracts = ((int256(_amount) * DECIMAL_SHIFT) * 1e18) / price;
        int256 longBalInt = -int256(IERC20(long).balanceOf(address(this)));
        // check that the long and short positions will be equal after the deposit
        if (-contracts + getMarginPositions() >= longBalInt) {
            // open short position
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                -contracts,
                price - slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        } else {
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                -(getMarginPositions() - longBalInt),
                price - slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        }

        emit PerpPositionOpened(tradeAmount, perpetualIndex, _amount);
    }

    /**
     * @notice  close the perpetual short position on MCDEX
     * @param   _amount the collateral to be returned from the short position
     * @return  tradeAmount the amount of perpetual contracts closed
     */
    function _closePerpPosition(uint256 _amount)
        internal
        returns (int256 tradeAmount)
    {
        // get the long asset mark price from the MCDEX oracle
        (int256 price, ) = oracle.priceTWAPLong();
        // calculate the number of contracts (*1e12 because USDC is 6 decimals)
        int256 contracts = ((int256(_amount) * DECIMAL_SHIFT) * 1e18) / price;
        if (contracts + getMarginPositions() < -dust) {
            // close short position
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                contracts,
                price + slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        } else {
            // close all remaining short positions
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                -getMarginPositions(),
                price + slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        }

        emit PerpPositionClosed(tradeAmount, perpetualIndex, _amount);
    }

    /**
     * @notice  close all perpetual short positions on MCDEX
     * @return  tradeAmount the amount of perpetual contracts closed
     */
    function _closeAllPerpPositions() internal returns (int256 tradeAmount) {
        // get the long asset mark price from the MCDEX oracle
        (int256 price, ) = oracle.priceTWAPLong();
        // close short position
        tradeAmount = mcLiquidityPool.trade(
            perpetualIndex,
            address(this),
            -getMarginPositions(),
            price + slippageTolerance,
            block.timestamp,
            referrer,
            tradeMode
        );
        emit AllPerpPositionsClosed(tradeAmount, perpetualIndex);
    }

    /**
     * @notice  deposit to the margin account without opening a perpetual position
     * @param   _amount the amount to deposit into the margin account
     */
    function _depositToMarginAccount(uint256 _amount) internal {
        IERC20(want).approve(address(mcLiquidityPool), _amount);
        mcLiquidityPool.deposit(
            perpetualIndex,
            address(this),
            int256(_amount) * DECIMAL_SHIFT
        );
        emit DepositToMarginAccount(_amount, perpetualIndex);
    }

    /**
     * @notice  determine the funding premiums that have been collected since the last epoch
     * @return  fee  the funding rate premium collected since the last epoch
     * @return  loss whether the funding rate was a loss or not
     */
    function _determineFee() internal returns (uint256 fee, bool loss) {
        int256 feeInt;

        // get the cash held in the margin cash, funding rates are saved as cash in the margin account
        int256 newAccFunding = getUnitAccumulativeFunding();
        int256 prevAccFunding = positions.unitAccumulativeFunding;
        int256 livePositions = getMarginPositions();
        if (prevAccFunding >= newAccFunding) {
            // if the margin cash held has gone down then record a loss
            loss = true;
            feeInt = ((prevAccFunding - newAccFunding) * -livePositions) / 1e18;
            fee = uint256(feeInt / DECIMAL_SHIFT);
        } else {
            // if the margin cash held has gone up then record a profit and withdraw the excess for redistribution
            feeInt = ((newAccFunding - prevAccFunding) * -livePositions) / 1e18;
            uint256 balanceBefore = IERC20(want).balanceOf(address(this));
            if (feeInt > 0) {
                mcLiquidityPool.withdraw(perpetualIndex, address(this), feeInt);
            }
            fee = IERC20(want).balanceOf(address(this)) - balanceBefore;
        }
    }

    /**
     * @notice  split an amount of assets into three:
     *          the short position which represents the short perpetual position
     *          the long position which represents the long spot position
     *          the buffer position which represents the funds to be left idle in the margin account
     * @param   _amount the amount to be split in want
     * @return  shortPosition  the size of the short perpetual position in want
     * @return  longPosition   the size of the long spot position in long
     * @return  bufferPosition the size of the buffer position in want
     */
    function _calculateSplit(uint256 _amount)
        internal
        returns (
            uint256 shortPosition,
            uint256 longPosition,
            uint256 bufferPosition
        )
    {
        require(_amount > 0, "_calculateSplit: _amount is 0");
        // remove the buffer from the amount
        bufferPosition = (_amount * buffer) / MAX_BPS;
        // decrement the amount by buffer position
        _amount -= bufferPosition;
        // determine the longPosition in want then convert it to long
        uint256 longPositionWant = _amount / 2;
        longPosition = _swap(longPositionWant, want, long);
        // determine the short position
        shortPosition = _amount - longPositionWant;
    }

    /**
     * @notice  swap function using uniswapv3 to facilitate the swap, specifying the amount in
     * @param   _amount    the amount to be swapped in want
     * @param   _tokenIn   the asset sent in
     * @param   _tokenOut  the asset taken out
     * @return  amountOut the amount of tokenOut exchanged for tokenIn
     */
    function _swap(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    ) internal returns (uint256 amountOut) {
        // set up swap params
        if (!isV2) {
            uint256 deadline = block.timestamp;
            address tokenIn = _tokenIn;
            address tokenOut = _tokenOut;
            uint24 fee = IUniswapV3Pool(pool).fee();
            address recipient = address(this);
            uint256 amountIn = _amount;
            uint256 amountOutMinimum = 0;
            uint160 sqrtPriceLimitX96 = 0;
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams(
                    tokenIn,
                    tokenOut,
                    fee,
                    recipient,
                    deadline,
                    amountIn,
                    amountOutMinimum,
                    sqrtPriceLimitX96
                );
            // approve the router to spend the tokens
            IERC20(_tokenIn).safeApprove(router, _amount);
            // swap optimistically via the uniswap v3 router
            amountOut = ISwapRouter(router).exactInputSingle(params);
        } else {
            //get balance of tokenOut
            uint256 amountTokenOut = IERC20(_tokenOut).balanceOf(address(this));
            // set the swap params
            uint256 deadline = block.timestamp;
            address[] memory path;
            if (_tokenIn == weth || _tokenOut == weth) {
                path = new address[](2);
                path[0] = _tokenIn;
                path[1] = _tokenOut;
            } else {
                path = new address[](3);
                path[0] = _tokenIn;
                path[1] = weth;
                path[2] = _tokenOut;
            }
            // approve the router to spend the token
            IERC20(_tokenIn).safeApprove(router, _amount);
            IRouterV2(router).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                deadline
            );

            amountOut =
                IERC20(_tokenOut).balanceOf(address(this)) -
                amountTokenOut;
        }
    }

    /**
     * @notice  swap function using uniswapv3 to facilitate the swap, specifying the amount in
     * @param   _amount    the amount to be swapped into want
     * @param   _tokenIn   the asset sent in
     * @param   _tokenOut  the asset taken out
     * @return  out the amount of tokenOut exchanged for tokenIn
     */
    function _swapTokenOut(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    ) internal returns (uint256 out) {
        if (!isV2) {
            // set up swap params
            uint256 deadline = block.timestamp;
            address tokenIn = _tokenIn;
            address tokenOut = _tokenOut;
            uint24 fee = IUniswapV3Pool(pool).fee();
            address recipient = address(this);
            uint256 amountOut = _amount;
            uint256 amountInMaximum = IERC20(_tokenIn).balanceOf(address(this));
            uint160 sqrtPriceLimitX96 = 0;
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams(
                    tokenIn,
                    tokenOut,
                    fee,
                    recipient,
                    deadline,
                    amountOut,
                    amountInMaximum,
                    sqrtPriceLimitX96
                );
            // approve the router to spend the tokens
            IERC20(_tokenIn).approve(
                router,
                IERC20(_tokenIn).balanceOf(address(this))
            );
            // swap optimistically via the uniswap v3 router
            out = ISwapRouter(router).exactOutputSingle(params);
        } else {
            //get balance of tokenOut
            uint256 amountTokenOut = IERC20(_tokenOut).balanceOf(address(this));
            // set the swap params
            uint256 deadline = block.timestamp;
            address[] memory path;
            if (_tokenIn == weth || _tokenOut == weth) {
                path = new address[](2);
                path[0] = _tokenIn;
                path[1] = _tokenOut;
            } else {
                path = new address[](3);
                path[0] = _tokenIn;
                path[1] = weth;
                path[2] = _tokenOut;
            }
            // approve the router to spend the token
            IERC20(_tokenIn).safeApprove(router, _amount);
            IRouterV2(router).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                deadline
            );

            out = IERC20(_tokenOut).balanceOf(address(this)) - amountTokenOut;
        }
    }

    /**
     * @notice  settle function for dealing with the perpetual if it has settled
     * @return  isSettled whether the perp needed to be settled or not.
     */
    function _settle() internal returns (bool isSettled) {
        (IMCLP.PerpetualState perpetualState, , ) = mcLiquidityPool
            .getPerpetualInfo(perpetualIndex);
        if (perpetualState == IMCLP.PerpetualState.CLEARED) {
            mcLiquidityPool.settle(perpetualIndex, address(this));
            isSettled = true;
        }
    }

    /***********
     * GETTERS *
     ***********/

    /**
     * @notice  getter for the MCDEX margin account cash balance of the strategy
     * @return  cash of the margin account
     */
    function getMarginCash() public view returns (int256 cash) {
        (cash, , , , , , , , ) = mcLiquidityPool.getMarginAccount(
            perpetualIndex,
            address(this)
        );
    }

    /**
     * @notice  getter for the MCDEX margin positions of the strategy
     * @return  position of the margin account
     */
    function getMarginPositions() public view returns (int256 position) {
        (, position, , , , , , , ) = mcLiquidityPool.getMarginAccount(
            perpetualIndex,
            address(this)
        );
    }

    /**
     * @notice  getter for the MCDEX margin  of the strategy
     * @return  margin of the margin account
     */
    function getMargin() public view returns (int256 margin) {
        (, , , margin, , , , , ) = mcLiquidityPool.getMarginAccount(
            perpetualIndex,
            address(this)
        );
    }

    /**
     * @notice Get the account info of the trader. Need to update the funding state and the oracle price
     *         of each perpetual before and update the funding rate of each perpetual after
     * @return cash the cash held in the margin account
     * @return position The position of the account
     * @return availableMargin The available margin of the account
     * @return margin The margin of the account
     * @return settleableMargin The settleable margin of the account
     * @return isInitialMarginSafe True if the account is initial margin safe
     * @return isMaintenanceMarginSafe True if the account is maintenance margin safe
     * @return isMarginSafe True if the total value of margin account is beyond 0
     */
    function getMarginAccount()
        public
        view
        returns (
            int256 cash,
            int256 position,
            int256 availableMargin,
            int256 margin,
            int256 settleableMargin,
            bool isInitialMarginSafe,
            bool isMaintenanceMarginSafe,
            bool isMarginSafe // bankrupt
        )
    {
        (
            cash,
            position,
            availableMargin,
            margin,
            settleableMargin,
            isInitialMarginSafe,
            isMaintenanceMarginSafe,
            isMarginSafe,

        ) = mcLiquidityPool.getMarginAccount(perpetualIndex, address(this));
    }

    /**
     * @notice Get the funding rate
     * @return the funding rate of the perpetual
     */
    function getFundingRate() public view returns (int256) {
        (, , int256[39] memory nums) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        return nums[3];
    }

    /**
     * @notice Get the unit accumulative funding
     * @return get the unit accumulative funding of the perpetual
     */
    function getUnitAccumulativeFunding() public view returns (int256) {
        (, , int256[39] memory nums) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        return nums[4];
    }
}