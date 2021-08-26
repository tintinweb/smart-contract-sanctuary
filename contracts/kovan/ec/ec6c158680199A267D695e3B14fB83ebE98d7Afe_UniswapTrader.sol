// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUniswapFactory.sol";
import "../interfaces/IUniswapPositionManager.sol";
import "../interfaces/IUniswapSwapRouter.sol";
import "../interfaces/IUniswapTrader.sol";
import "../interfaces/IUniswapPool.sol";
import "../libraries/FullMath.sol";

/// @notice Integrates 0x Nodes to Uniswap v3
/// @notice tokenA/tokenB naming implies tokens are unsorted
/// @notice token0/token1 naming implies tokens are sorted
contract UniswapTrader is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IUniswapTrader
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    struct Pool {
        uint24 feeNumerator;
        uint24 slippageNumerator;
    }

    struct TokenPair {
        address token0;
        address token1;
    }

    uint24 private constant FEE_DENOMINATOR = 1_000_000;
    uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
    address private factoryAddress;
    address private swapRouterAddress;

    mapping(address => mapping(address => Pool[])) private pools;
    TokenPair[] private tokenPairs;

    event UniswapPoolAdded(address indexed token0, address indexed token1, uint24 fee, uint24 slippageNumerator);
    event UniswapPoolSlippageNumeratorUpdated(address indexed token0, address indexed token1, uint256 poolIndex, uint24 slippageNumerator);
    event UniswapPairPrimaryPoolUpdated(address indexed token0, address indexed token1, uint256 primaryPoolIndex);

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ Module Map address
    /// @param factoryAddress_ The address of the Uniswap factory contract
    /// @param swapRouterAddress_ The address of the Uniswap swap router contract
    function initialize(address[] memory controllers_, address moduleMap_, address factoryAddress_, address swapRouterAddress_) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        __ModuleMapConsumer_init(moduleMap_);
        factoryAddress = factoryAddress_;
        swapRouterAddress = swapRouterAddress_;
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param feeNumerator The Uniswap pool fee numerator
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    /// positions is enabled for this pool
    function addPool(address tokenA, address tokenB, uint24 feeNumerator, uint24 slippageNumerator) external override onlyManager {
        require(IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap)).getIsTokenAdded(tokenA), 
            "UniswapTrader::addPool: TokenA has not been added in the Integration Map");
        require(IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap)).getIsTokenAdded(tokenB), 
            "UniswapTrader::addPool: TokenB has not been added in the Integration Map");
        require(slippageNumerator <= SLIPPAGE_DENOMINATOR, 
            "UniswapTrader::addPool: Slippage numerator cannot be greater than slippapge denominator");
        require(IUniswapFactory(factoryAddress).getPool(tokenA, tokenB, feeNumerator) != address(0), 
            "UniswapTrader::addPool: Pool does not exist");

        (address token0, address token1) = getTokensSorted(tokenA, tokenB);     

        bool poolAdded;
        for(uint256 poolIndex; poolIndex < pools[token0][token1].length; poolIndex++) {
            if(pools[token0][token1][poolIndex].feeNumerator == feeNumerator) {
                poolAdded = true;
            }
        }

        require(!poolAdded, "UniswapTrader::addPool: Pool has already been added");

        Pool memory newPool;
        newPool.feeNumerator = feeNumerator;
        newPool.slippageNumerator = slippageNumerator;
        pools[token0][token1].push(newPool);

        bool tokenPairAdded;
        for(uint256 pairIndex; pairIndex < tokenPairs.length; pairIndex++) {
            if(tokenPairs[pairIndex].token0 == token0 && tokenPairs[pairIndex].token1 == token1) {
                tokenPairAdded = true;
            }
        }

        if(!tokenPairAdded) {
            TokenPair memory newTokenPair;
            newTokenPair.token0 = token0;
            newTokenPair.token1 = token1;
            tokenPairs.push(newTokenPair);

            if(IERC20MetadataUpgradeable(token0).allowance(address(this), moduleMap.getModuleAddress(Modules.YieldManager)) == 0) {
                IERC20MetadataUpgradeable(token0).safeApprove(moduleMap.getModuleAddress(Modules.YieldManager), type(uint256).max);
            }

            if(IERC20MetadataUpgradeable(token1).allowance(address(this), moduleMap.getModuleAddress(Modules.YieldManager)) == 0) {
                IERC20MetadataUpgradeable(token1).safeApprove(moduleMap.getModuleAddress(Modules.YieldManager), type(uint256).max);
            }

            if(IERC20MetadataUpgradeable(token0).allowance(address(this), swapRouterAddress) == 0) {
                IERC20MetadataUpgradeable(token0).safeApprove(swapRouterAddress, type(uint256).max);
            }

            if(IERC20MetadataUpgradeable(token1).allowance(address(this), swapRouterAddress) == 0) {
                IERC20MetadataUpgradeable(token1).safeApprove(swapRouterAddress, type(uint256).max);
            }
        }

        emit UniswapPoolAdded(token0, token1, feeNumerator, slippageNumerator);
    }

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(
        address tokenA, 
        address tokenB, 
        uint256 poolIndex, 
        uint24 slippageNumerator
    ) external override onlyManager {
        require(slippageNumerator <= SLIPPAGE_DENOMINATOR, 
            "UniswapTrader:updatePoolSlippageNumerator: Slippage numerator must not be greater than slippage denominator");
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        require(pools[token0][token1][poolIndex].slippageNumerator != slippageNumerator, 
            "UniswapTrader:updatePoolSlippageNumerator: Slippage numerator must be updated to a new number");
        require(pools[token0][token1].length > poolIndex, 
            "UniswapTrader:updatePoolSlippageNumerator: Pool does not exist");

        pools[token0][token1][poolIndex].slippageNumerator = slippageNumerator;

        emit UniswapPoolSlippageNumeratorUpdated(token0, token1, poolIndex, slippageNumerator);
    }
    
    /// @notice Updates which Uniswap pool to use as the default pool 
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(
        address tokenA, 
        address tokenB, 
        uint256 primaryPoolIndex
    ) external override onlyManager {
        require(primaryPoolIndex != 0, "UniswapTrader::updatePairPrimaryPool: Specified index is already the primary pool");
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        require(primaryPoolIndex < pools[token0][token1].length, "UniswapTrader::updatePairPrimaryPool: Specified pool index does not exist");

        uint24 newPrimaryPoolFeeNumerator = pools[token0][token1][primaryPoolIndex].feeNumerator;
        uint24 newPrimaryPoolSlippageNumerator = pools[token0][token1][primaryPoolIndex].slippageNumerator;

        pools[token0][token1][primaryPoolIndex].feeNumerator = pools[token0][token1][0].feeNumerator;
        pools[token0][token1][primaryPoolIndex].slippageNumerator = pools[token0][token1][0].slippageNumerator;

        pools[token0][token1][0].feeNumerator = newPrimaryPoolFeeNumerator;
        pools[token0][token1][0].slippageNumerator = newPrimaryPoolSlippageNumerator;

        emit UniswapPairPrimaryPoolUpdated(token0, token1, primaryPoolIndex);
    }    

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountIn The exact amount of the input to swap
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) external override onlyController returns (bool tradeSuccess) {
        (address token0, address token1) = getTokensSorted(tokenIn, tokenOut);

        require(pools[token0][token1].length > 0, "UniswapTrader::swapExactInput: Pool has not been added");
        IERC20MetadataUpgradeable tokenInErc20 = IERC20MetadataUpgradeable(tokenIn);
        require(tokenInErc20.balanceOf(address(this)) >= amountIn, "UniswapTrader::swapExactInput: Balance is less than trade amount");

        uint256 amountOutMinimum = getAmountOutMinimum(tokenIn, tokenOut, amountIn);

        IUniswapSwapRouter.ExactInputSingleParams memory exactInputSingleParams;
        exactInputSingleParams.tokenIn = tokenIn;
        exactInputSingleParams.tokenOut = tokenOut;
        exactInputSingleParams.fee = pools[token0][token1][0].feeNumerator;
        exactInputSingleParams.recipient = recipient;
        exactInputSingleParams.deadline = block.timestamp;
        exactInputSingleParams.amountIn = amountIn;
        exactInputSingleParams.amountOutMinimum = amountOutMinimum;
        exactInputSingleParams.sqrtPriceLimitX96 = 0;

        try IUniswapSwapRouter(swapRouterAddress).exactInputSingle(exactInputSingleParams) {
            tradeSuccess = true;
        } catch {
            tradeSuccess = false;
            tokenInErc20.safeTransfer(recipient, tokenInErc20.balanceOf(address(this)));
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountOut The exact amount of the output token to receive
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut
    ) external override onlyController returns (bool tradeSuccess) {
        (address token0, address token1) = getTokensSorted(tokenIn, tokenOut);
        require(pools[token0][token1][0].feeNumerator > 0, "UniswapTrader::swapExactOutput: Pool has not been added");
        uint256 amountInMaximum = getAmountInMaximum(tokenIn, tokenOut, amountOut);
        IERC20MetadataUpgradeable tokenInErc20 = IERC20MetadataUpgradeable(tokenIn);
        require(tokenInErc20.balanceOf(address(this)) >= amountInMaximum, "UniswapTrader::swapExactOutput: Balance is less than trade amount");
        
        IUniswapSwapRouter.ExactOutputSingleParams memory exactOutputSingleParams;
        exactOutputSingleParams.tokenIn = tokenIn;
        exactOutputSingleParams.tokenOut = tokenOut;
        exactOutputSingleParams.fee = pools[token0][token1][0].feeNumerator;
        exactOutputSingleParams.recipient = recipient;
        exactOutputSingleParams.deadline = block.timestamp;
        exactOutputSingleParams.amountOut = amountOut;
        exactOutputSingleParams.amountInMaximum = amountInMaximum;
        exactOutputSingleParams.sqrtPriceLimitX96 = 0;

        try IUniswapSwapRouter(swapRouterAddress).exactOutputSingle(exactOutputSingleParams) {
            tradeSuccess = true;
        } catch {
            tradeSuccess = false;
        }
        tokenInErc20.safeTransfer(recipient, tokenInErc20.balanceOf(address(this)));
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @return pool The pool address
    function getPoolAddress(address tokenA, address tokenB) public view returns (address pool) {
        uint24 feeNumerator = getPoolFeeNumerator(tokenA, tokenB, 0);
        pool = IUniswapFactory(factoryAddress).getPool(tokenA, tokenB, feeNumerator);
    }

    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    function getSqrtPriceX96(address tokenA, address tokenB) public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapPool(getPoolAddress(tokenA, tokenB)).slot0();
        return uint256(sqrtPriceX96);
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
    function getAmountOutMinimum(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 amountOutMinimum) {
        uint256 estimatedAmountOut = getEstimatedTokenOut(tokenIn, tokenOut, amountIn);
        uint24 poolSlippageNumerator = getPoolSlippageNumerator(tokenIn, tokenOut, 0);
        amountOutMinimum = estimatedAmountOut * (SLIPPAGE_DENOMINATOR - poolSlippageNumerator) / SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of token being swapped for
    /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
    function getAmountInMaximum(address tokenIn, address tokenOut, uint256 amountOut) public view override returns (uint256 amountInMaximum) {
        uint256 estimatedAmountIn = getEstimatedTokenIn(tokenIn, tokenOut, amountOut);
        uint24 poolSlippageNumerator = getPoolSlippageNumerator(tokenIn, tokenOut, 0);
        amountInMaximum = estimatedAmountIn * (SLIPPAGE_DENOMINATOR + poolSlippageNumerator) / SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(address tokenIn, address tokenOut, uint256 amountIn) public view override returns (uint256 amountOut) {
        uint24 feeNumerator = getPoolFeeNumerator(tokenIn, tokenOut, 0);
        uint256 sqrtPriceX96 = getSqrtPriceX96(tokenIn, tokenOut);

        // FullMath is used to allow intermediate calculation values of up to 2^512
        if(tokenIn < tokenOut) {
            amountOut = FullMath.mulDiv(FullMath.mulDiv(amountIn, sqrtPriceX96, 2**96), sqrtPriceX96, 2**96) 
                * (FEE_DENOMINATOR - feeNumerator) / FEE_DENOMINATOR;
        } else {
            amountOut = FullMath.mulDiv(FullMath.mulDiv(amountIn, 2**96, sqrtPriceX96), 2**96, sqrtPriceX96)
                * (FEE_DENOMINATOR - feeNumerator) / FEE_DENOMINATOR;
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of the output token to swap for
    /// @return amountIn The estimated amount of tokenIn to spend
    function getEstimatedTokenIn(address tokenIn, address tokenOut, uint256 amountOut) public view returns (uint256 amountIn) {
        uint24 feeNumerator = getPoolFeeNumerator(tokenIn, tokenOut, 0);
        uint256 sqrtPriceX96 = getSqrtPriceX96(tokenIn, tokenOut);

        // FullMath is used to allow intermediate calculation values of up to 2^512
        if(tokenIn < tokenOut) {
            amountIn = FullMath.mulDiv(FullMath.mulDiv(amountOut, 2**96, sqrtPriceX96), 2**96, sqrtPriceX96)
                * (FEE_DENOMINATOR - feeNumerator) / FEE_DENOMINATOR;
        } else {
            amountIn = FullMath.mulDiv(FullMath.mulDiv(amountOut, sqrtPriceX96, 2**96), sqrtPriceX96, 2**96)
                * (FEE_DENOMINATOR - feeNumerator) / FEE_DENOMINATOR;
        } 
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(address tokenA, address tokenB, uint256 poolId) public view override returns (uint24 feeNumerator) {
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        require(poolId < pools[token0][token1].length, "UniswapTrader::getPoolFeeNumerator: Pool ID does not exist");
        feeNumerator = pools[token0][token1][poolId].feeNumerator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return slippageNumerator The numerator that gets divided by the slippage denominator
    function getPoolSlippageNumerator(address tokenA, address tokenB, uint256 poolId) public view returns (uint24 slippageNumerator) {
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        return pools[token0][token1][poolId].slippageNumerator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB) public pure override returns (address token0, address token1) {
        if(tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param amountA The amount of tokenA
    /// @param amountB The amount of tokenB
    /// @return token0 The address of sorted token0
    /// @return token1 The address of sorted token1
    /// @return amount0 The amount of sorted token0
    /// @return amount1 The amount of sorted token1
    function getTokensAndAmountsSorted(
            address tokenA, 
            address tokenB, 
            uint256 amountA, 
            uint256 amountB
        ) public pure returns (
            address token0, 
            address token1, 
            uint256 amount0, 
            uint256 amount1) {
        if(tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
            amount0 = amountA;
            amount1 = amountB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
            amount0 = amountB;
            amount1 = amountA;
        }
    }

    /// @return The denominator used to calculate the pool fee percentage
    function getFeeDenominator() external pure returns (uint24) {
        return FEE_DENOMINATOR;
    }

    /// @return The denominator used to calculate the allowable slippage percentage
    function getSlippageDenominator() external pure returns (uint24) {
        return SLIPPAGE_DENOMINATOR;
    }

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view override returns (uint256) {
        return tokenPairs.length;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB) external view override returns (uint256) {
        (address token0, address token1) = getTokensSorted(tokenA, tokenB);
        return pools[token0][token1].length;
    }

    /// @param tokenPairIndex The index of the token pair
    /// @return The address of token0
    /// @return The address of token1
    function getTokenPair(uint256 tokenPairIndex) external view returns (address, address) {
        require(tokenPairIndex < tokenPairs.length, "UniswapTrader::getTokenPair: Token pair does not exist");
        return(tokenPairs[tokenPairIndex].token0, tokenPairs[tokenPairIndex].token1);
    }

    /// @param token0 The address of token0 of the pool
    /// @param token1 The address of token1 of the pool
    /// @param poolIndex The index of the pool
    /// @return The pool fee numerator
    /// @return The pool slippage numerator
    function getPool(address token0, address token1, uint256 poolIndex) external view returns (uint24, uint24) {
        require(poolIndex < pools[token0][token1].length, "UniswapTrader:getPool: Pool does not exist");
        return(pools[token0][token1][poolIndex].feeNumerator, pools[token0][token1][poolIndex].slippageNumerator);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IKernel.sol";

abstract contract Controlled is 
    Initializable,
    ModuleMapConsumer
{
    address[] public controllers;

    function __Controlled_init(address[] memory controllers_, address moduleMap_) public initializer {
        controllers = controllers_;
        __ModuleMapConsumer_init(moduleMap_);
    }

    function addController(address controller) external onlyOwner {
        bool controllerAdded;
        for(uint256 i; i < controllers.length; i++) {
            if(controller == controllers[i]) {
                controllerAdded = true;
            }
        }
        require(!controllerAdded, "Controlled::addController: Address is already a controller");
        controllers.push(controller);
    }

    modifier onlyOwner() {
        require(IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isOwner(msg.sender), "Controlled::onlyOwner: Caller is not owner");
        _;
    }

    modifier onlyManager() {
        require(IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isManager(msg.sender), "Controlled::onlyManager: Caller is not manager");
        _;
    }

    modifier onlyController() {
        bool senderIsController;
        for(uint256 i; i < controllers.length; i++) {
            if(msg.sender == controllers[i]) {
                senderIsController = true;
                break;
            }
        }
        require(senderIsController, "Controlled::onlyController: Caller is not controller");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModuleMap.sol";

abstract contract ModuleMapConsumer is Initializable {
    IModuleMap public moduleMap;

    function __ModuleMapConsumer_init(address moduleMap_) internal initializer {
        moduleMap = IModuleMap(moduleMap_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IIntegrationMap {
    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    /// @param weightsByTokenId The weights of each token for the added integration
    function addIntegration(address contractAddress, string memory name, uint256[] memory weightsByTokenId) external;

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    /// @param weightsByIntegrationId The weights of each integration for the added token
    function addToken(
        address tokenAddress, 
        bool acceptingDeposits, 
        bool acceptingWithdrawals, 
        uint256 biosRewardWeight, 
        uint256 reserveRatioNumerator, 
        uint256[] memory weightsByIntegrationId
    ) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenDeposits(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenDeposits(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenWithdrawals(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenWithdrawals(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @param rewardWeight The updated token BIOS reward weight
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight) external;

    /// @param integrationAddress The address of the integration contract
    /// @param tokenAddress the address of the token ERC20 contract
    /// @param updatedWeight The updated token integration weight
    function updateTokenIntegrationWeight(address integrationAddress, address tokenAddress, uint256 updatedWeight) external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(address tokenAddress, uint256 reserveRatioNumerator) external;

    /// @param integrationId The ID of the integration
    /// @return The address of the integration contract
    function getIntegrationAddress(uint256 integrationId) external view returns (address);

    /// @param integrationAddress The address of the integration contract
    /// @return The name of the of the protocol being integrated to
    function getIntegrationName(address integrationAddress) external view returns (string memory);

    /// @return The address of the WETH token
    function getWethTokenAddress() external view returns (address);

    /// @return The address of the BIOS token
    function getBiosTokenAddress() external view returns (address);

    /// @param tokenId The ID of the token
    /// @return The address of the token ERC20 contract
    function getTokenAddress(uint256 tokenId) external view returns (address);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The index of the token in the tokens array
    function getTokenId(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The token BIOS reward weight
    function getTokenBiosRewardWeight(address tokenAddress) external view returns (uint256);

    /// @return rewardWeightSum reward weight of depositable tokens
    function getBiosRewardWeightSum() external view returns (uint256 rewardWeightSum);

    /// @param integrationAddress The address of the integration contract
    /// @param tokenAddress the address of the token ERC20 contract
    /// @return The weight of the specified integration & token combination
    function getTokenIntegrationWeight(address integrationAddress, address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenWeightSum The sum of the specified token weights
    function getTokenIntegrationWeightSum(address tokenAddress) external view returns (uint256 tokenWeightSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether depositing this token is currently enabled
    function getTokenAcceptingDeposits(address tokenAddress) external view returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether withdrawing this token is currently enabled
    function getTokenAcceptingWithdrawals(address tokenAddress) external view returns (bool);

    // @param tokenAddress The address of the token ERC20 contract
    // @return bool indicating whether the token has been added
    function getIsTokenAdded(address tokenAddress) external view returns (bool);

    // @param integrationAddress The address of the integration contract
    // @return bool indicating whether the integration has been added
    function getIsIntegrationAdded(address tokenAddress) external view returns (bool);

    /// @notice get the length of supported tokens
    /// @return The quantity of tokens added
    function getTokenAddressesLength() external view returns (uint256);

    /// @notice get the length of supported integrations
    /// @return The quantity of integrations added
    function getIntegrationAddressesLength() external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The value that gets divided by the reserve ratio denominator
    function getTokenReserveRatioNumerator(address tokenAddress) external view returns (uint256);

    /// @return The token reserve ratio denominator
    function getReserveRatioDenominator() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapFactory {
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapSwapRouter {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapTrader {    
    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param fee The Uniswap pool fee
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    function addPool(address tokenA, address tokenB, uint24 fee, uint24 slippageNumerator) external;

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(address tokenA, address tokenB, uint256 poolIndex, uint24 slippageNumerator) external;

    /// @notice Changes which Uniswap pool to use as the default pool 
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(address tokenA, address tokenB, uint256 primaryPoolIndex) external;
 
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountIn The exact amount of the input to swap
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountOut The exact amount of the output token to receive
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of token being swapped for
    /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
    function getAmountInMaximum(address tokenIn, address tokenOut, uint256 amountOut) external view returns (uint256 amountInMaximum);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB) external pure returns (address token0, address token1);

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB) external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(address tokenA, address tokenB, uint256 poolId) external view returns (uint24 feeNumerator);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapPool {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

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
        uint256 twos = denominator & (~denominator + 1);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKernel {
    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) external view returns (bool);

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Modules {
    Kernel, // 0
    UserPositions, // 1
    YieldManager, // 2
    IntegrationMap, // 3
    BiosRewards, // 4
    EtherRewards, // 5
    SushiSwapTrader, // 6
    UniswapTrader // 7
}

interface IModuleMap {
    function getModuleAddress(Modules key) external view returns (address);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}