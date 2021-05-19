//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwap.sol";
import "../interfaces/IXToken.sol";
import "../interfaces/IXTokenWrapper.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IBRegistry.sol";
import "../interfaces/IProtocolFee.sol";
import "../interfaces/IUTokenPriceFeed.sol";

/**
 * @title BPoolProxy
 * @author Protofire
 * @dev Forwarding proxy that allows users to batch execute swaps and join/exit pools.
 * User should interact with pools through this contracts as it is the one that charge
 * the protocol swap fee, and wrap/unwrap pool tokens into/from xPoolToken.
 *
 * This code is based on Balancer ExchangeProxy contract
 * https://docs.balancer.finance/smart-contracts/exchange-proxy
 * (https://etherscan.io/address/0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21#code)
 */
contract BPoolProxy is Ownable, ISwap, ERC1155Holder {
    using SafeMath for uint256;

    struct Pool {
        address pool;
        uint256 tokenBalanceIn;
        uint256 tokenWeightIn;
        uint256 tokenBalanceOut;
        uint256 tokenWeightOut;
        uint256 swapFee;
        uint256 effectiveLiquidity;
    }

    uint256 private constant BONE = 10**18;

    /// @dev Address of BRegistry
    IBRegistry public registry;
    /// @dev Address of ProtocolFee module
    IProtocolFee public protocolFee;
    /// @dev Address of XTokenWrapper
    IXTokenWrapper public xTokenWrapper;
    /// @dev Address of Utitlity Token Price Feed - Used as feature flag for discounted fee
    IUTokenPriceFeed public utilityTokenFeed;
    /// @dev Address who receives fees
    address public feeReceiver;
    /// @dev Address Utitlity Token - Used as feature flag for discounted fee
    address public utilityToken;

     /**
     * @dev Emitted when `joinPool` function is executed.
     */
    event JoinPool(address liquidityProvider, address bpool, uint256 shares);

    /**
     * @dev Emitted when `exitPool` function is executed.
     */
    event ExitPool(address iquidityProvider, address bpool, uint256 shares);

    /**
     * @dev Emitted when `registry` address is set.
     */
    event RegistrySet(address registry);

    /**
     * @dev Emitted when `protocolFee` address is set.
     */
    event ProtocolFeeSet(address protocolFee);

    /**
     * @dev Emitted when `feeReceiver` address is set.
     */
    event FeeReceiverSet(address feeReceiver);

    /**
     * @dev Emitted when `xTokenWrapper` address is set.
     */
    event XTokenWrapperSet(address xTokenWrapper);

    /**
     * @dev Emitted when `utilityToken` address is set.
     */
    event UtilityTokenSet(address utilityToken);

    /**
     * @dev Emitted when `utilityTokenFeed` address is set.
     */
    event UtilityTokenFeedSet(address utilityTokenFeed);

    /**
     * @dev Sets the values for {registry}, {protocolFee}, {feeReceiver},
     * {xTokenWrapper}, {utilityToken} and {utilityTokenFeed}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(
        address _registry,
        address _protocolFee,
        address _feeReceiver,
        address _xTokenWrapper,
        address _utilityToken,
        address _utilityTokenFeed
    ) {
        _setRegistry(_registry);
        _setProtocolFee(_protocolFee);
        _setFeeReceiver(_feeReceiver);
        _setXTokenWrapper(_xTokenWrapper);
        _setUtilityToken(_utilityToken);
        _setUtilityTokenFeed(_utilityTokenFeed);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function setRegistry(address _registry) external onlyOwner {
        _setRegistry(_registry);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_protocolFee` should not be the zero address.
     *
     * @param _protocolFee The address of the protocolFee.
     */
    function setProtocolFee(address _protocolFee) external onlyOwner {
        _setProtocolFee(_protocolFee);
    }

    /**
     * @dev Sets `_feeReceiver` as the new feeReceiver.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_feeReceiver` should not be the zero address.
     *
     * @param _feeReceiver The address of the feeReceiver.
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        _setFeeReceiver(_feeReceiver);
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function setXTokenWrapper(address _xTokenWrapper) external onlyOwner {
        _setXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_utilityToken` as the new utilityToken.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     * @param _utilityToken The address of the utilityToken.
     */
    function setUtilityToken(address _utilityToken) external onlyOwner {
        _setUtilityToken(_utilityToken);
    }

    /**
     * @dev Sets `_utilityTokenFeed` as the new utilityTokenFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     * @param _utilityTokenFeed The address of the utilityTokenFeed.
     */
    function setUtilityTokenFeed(address _utilityTokenFeed) external onlyOwner {
        _setUtilityTokenFeed(_utilityTokenFeed);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function _setRegistry(address _registry) internal {
        require(_registry != address(0), "registry is the zero address");
        emit RegistrySet(_registry);
        registry = IBRegistry(_registry);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - `_protocolFee` should not be the zero address.
     *
     * @param _protocolFee The address of the protocolFee.
     */
    function _setProtocolFee(address _protocolFee) internal {
        require(_protocolFee != address(0), "protocolFee is the zero address");
        emit ProtocolFeeSet(_protocolFee);
        protocolFee = IProtocolFee(_protocolFee);
    }

    /**
     * @dev Sets `_feeReceiver` as the new feeReceiver.
     *
     * Requirements:
     *
     * - `_feeReceiver` should not be the zero address.
     *
     * @param _feeReceiver The address of the feeReceiver.
     */
    function _setFeeReceiver(address _feeReceiver) internal {
        require(_feeReceiver != address(0), "feeReceiver is the zero address");
        emit FeeReceiverSet(_feeReceiver);
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function _setXTokenWrapper(address _xTokenWrapper) internal {
        require(_xTokenWrapper != address(0), "xTokenWrapper is the zero address");
        emit XTokenWrapperSet(_xTokenWrapper);
        xTokenWrapper = IXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_utilityToken` as the new utilityToken.
     *
     * @param _utilityToken The address of the utilityToken.
     */
    function _setUtilityToken(address _utilityToken) internal {
        emit UtilityTokenSet(_utilityToken);
        utilityToken = _utilityToken;
    }

    /**
     * @dev Sets `_utilityTokenFeed` as the new utilityTokenFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     * @param _utilityTokenFeed The address of the utilityTokenFeed.
     */
    function _setUtilityTokenFeed(address _utilityTokenFeed) internal {
        emit UtilityTokenFeedSet(_utilityTokenFeed);
        utilityTokenFeed = IUTokenPriceFeed(_utilityTokenFeed);
    }

    /**
     * @dev Execute single-hop swaps for swapExactIn trade type. Used for swaps
     * returned from viewSplit function and legacy off-chain SOR.
     *
     * @param swaps Array of single-hop swaps.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param totalAmountIn Total amount of tokenIn.
     * @param minTotalAmountOut Minumum amount of tokenOut.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function batchSwapExactIn(
        Swap[] memory swaps,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        bool useUtilityToken
    ) public returns (uint256 totalAmountOut) {
        transferFrom(tokenIn, totalAmountIn);

        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IXToken swapTokenIn = IXToken(swap.tokenIn);
            IBPool pool = IBPool(swap.pool);

            if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                swapTokenIn.approve(swap.pool, 0);
            }
            swapTokenIn.approve(swap.pool, swap.swapAmount);

            (uint256 tokenAmountOut, ) =
                pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferFeeFrom(tokenIn, protocolFee.batchFee(swaps, totalAmountIn), useUtilityToken);

        transfer(tokenOut, totalAmountOut);
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Execute single-hop swaps for swapExactOut trade type. Used for swaps
     * returned from viewSplit function and legacy off-chain SOR.
     *
     * @param swaps Array of single-hop swaps.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param maxTotalAmountIn Maximum total amount of tokenIn.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function batchSwapExactOut(
        Swap[] memory swaps,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 maxTotalAmountIn,
        bool useUtilityToken
    ) public returns (uint256 totalAmountIn) {
        transferFrom(tokenIn, maxTotalAmountIn);

        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IXToken swapTokenIn = IXToken(swap.tokenIn);
            IBPool pool = IBPool(swap.pool);

            if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                swapTokenIn.approve(swap.pool, 0);
            }
            swapTokenIn.approve(swap.pool, swap.limitReturnAmount);

            (uint256 tokenAmountIn, ) =
                pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            totalAmountIn = tokenAmountIn.add(totalAmountIn);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferFeeFrom(tokenIn, protocolFee.batchFee(swaps, totalAmountIn), useUtilityToken);

        transfer(tokenOut, getBalance(tokenOut));
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Execute multi-hop swaps returned from off-chain SOR for swapExactIn trade type.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param totalAmountIn Total amount of tokenIn.
     * @param minTotalAmountOut Minumum amount of tokenOut.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        bool useUtilityToken
    ) external returns (uint256 totalAmountOut) {
        transferFrom(tokenIn, totalAmountIn);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountOut;
            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                IXToken swapTokenIn = IXToken(swap.tokenIn);
                if (k == 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }

                IBPool pool = IBPool(swap.pool);
                if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                    swapTokenIn.approve(swap.pool, 0);
                }
                swapTokenIn.approve(swap.pool, swap.swapAmount);
                (tokenAmountOut, ) = pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            }
            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferFeeFrom(tokenIn, protocolFee.multihopBatch(swapSequences, totalAmountIn), useUtilityToken);

        transfer(tokenOut, totalAmountOut);
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Execute multi-hop swaps returned from off-chain SOR for swapExactOut trade type.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param maxTotalAmountIn Maximum total amount of tokenIn.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 maxTotalAmountIn,
        bool useUtilityToken
    ) external returns (uint256 totalAmountIn) {
        transferFrom(tokenIn, maxTotalAmountIn);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                IXToken swapTokenIn = IXToken(swap.tokenIn);

                IBPool pool = IBPool(swap.pool);
                if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                    swapTokenIn.approve(swap.pool, 0);
                }
                swapTokenIn.approve(swap.pool, swap.limitReturnAmount);

                (tokenAmountInFirstSwap, ) = pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint256 intermediateTokenAmount; // This would be token B as described above
                Swap memory secondSwap = swapSequences[i][1];
                IBPool poolSecondSwap = IBPool(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.getSwapFee()
                );

                //// Buy intermediateTokenAmount of token B with A in the first pool
                Swap memory firstSwap = swapSequences[i][0];
                IXToken firstswapTokenIn = IXToken(firstSwap.tokenIn);
                IBPool poolFirstSwap = IBPool(firstSwap.pool);
                if (firstswapTokenIn.allowance(address(this), firstSwap.pool) < uint256(-1)) {
                    firstswapTokenIn.approve(firstSwap.pool, uint256(-1));
                }

                (tokenAmountInFirstSwap, ) = poolFirstSwap.swapExactAmountOut(
                    firstSwap.tokenIn,
                    firstSwap.limitReturnAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount, // This is the amount of token B we need
                    firstSwap.maxPrice
                );

                //// Buy the final amount of token C desired
                IXToken secondswapTokenIn = IXToken(secondSwap.tokenIn);
                if (secondswapTokenIn.allowance(address(this), secondSwap.pool) < uint256(-1)) {
                    secondswapTokenIn.approve(secondSwap.pool, uint256(-1));
                }

                poolSecondSwap.swapExactAmountOut(
                    secondSwap.tokenIn,
                    secondSwap.limitReturnAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn = tokenAmountInFirstSwap.add(totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferFeeFrom(tokenIn, protocolFee.multihopBatch(swapSequences, totalAmountIn), useUtilityToken);

        transfer(tokenOut, getBalance(tokenOut));
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Used for swaps returned from viewSplit function.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param totalAmountIn Total amount of tokenIn.
     * @param minTotalAmountOut Minumum amount of tokenOut.
     * @param nPools Maximum mumber of pools.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function smartSwapExactIn(
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 nPools,
        bool useUtilityToken
    ) external returns (uint256 totalAmountOut) {
        Swap[] memory swaps;
        uint256 totalOutput;
        (swaps, totalOutput) = viewSplitExactIn(address(tokenIn), address(tokenOut), totalAmountIn, nPools);

        require(totalOutput >= minTotalAmountOut, "ERR_LIMIT_OUT");

        totalAmountOut = batchSwapExactIn(swaps, tokenIn, tokenOut, totalAmountIn, minTotalAmountOut, useUtilityToken);
    }

    /**
     * @dev Used for swaps returned from viewSplit function.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param maxTotalAmountIn Maximum total amount of tokenIn.
     * @param nPools Maximum mumber of pools.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function smartSwapExactOut(
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountOut,
        uint256 maxTotalAmountIn,
        uint256 nPools,
        bool useUtilityToken
    ) external returns (uint256 totalAmountIn) {
        Swap[] memory swaps;
        uint256 totalInput;
        (swaps, totalInput) = viewSplitExactOut(address(tokenIn), address(tokenOut), totalAmountOut, nPools);

        require(totalInput <= maxTotalAmountIn, "ERR_LIMIT_IN");

        totalAmountIn = batchSwapExactOut(swaps, tokenIn, tokenOut, maxTotalAmountIn, useUtilityToken);
    }

    /**
     * @dev Join the `pool`, getting `poolAmountOut` pool tokens. This will pull some of each of the currently
     * trading tokens in the pool, meaning you must have called approve for each token for this pool. These
     * values are limited by the array of `maxAmountsIn` in the order of the pool tokens.
     *
     * @param pool Pool address.
     * @param poolAmountOut Exact pool amount out.
     * @param maxAmountsIn Maximum amounts in.
     */
    function joinPool(
        address pool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = IBPool(pool).getCurrentTokens();

        // pull xTokens
        for (uint256 i = 0; i < tokens.length; i++) {
            transferFrom(IXToken(tokens[i]), maxAmountsIn[i]);
            IXToken(tokens[i]).approve(pool, maxAmountsIn[i]);
        }

        IBPool(pool).joinPool(poolAmountOut, maxAmountsIn);

        // push remaining xTokens
        for (uint256 i = 0; i < tokens.length; i++) {
            transfer(IXToken(tokens[i]), getBalance(IXToken(tokens[i])));
        }

        // Wrap balancer liquidity tokens into its representing xToken
        IBPool(pool).approve(address(xTokenWrapper), poolAmountOut);
        require(xTokenWrapper.wrap(pool, poolAmountOut), "ERR_WRAP_POOL");

        transfer(IXToken(xTokenWrapper.tokenToXToken(pool)), poolAmountOut);

        emit JoinPool(msg.sender, pool,  poolAmountOut);
    }

    /**
     * @dev Exit the pool, paying poolAmountIn pool tokens and getting some of each of the currently trading
     * tokens in return. These values are limited by the array of minAmountsOut in the order of the pool tokens.
     *
     * @param pool Pool address.
     * @param poolAmountIn Exact pool amount int.
     * @param minAmountsOut Minumum amounts out.
     */
    function exitPool(
        address pool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    ) external {
        address wrappedLPT = xTokenWrapper.tokenToXToken(pool);

        // pull wrapped liquitity tokens
        transferFrom(IXToken(wrappedLPT), poolAmountIn);

        // unwrap wrapped liquitity tokens
        require(xTokenWrapper.unwrap(wrappedLPT, poolAmountIn), "ERR_UNWRAP_POOL");

        // LPT do not need to be approved when exit
        IBPool(pool).exitPool(poolAmountIn, minAmountsOut);

        // push xTokens
        address[] memory tokens = IBPool(pool).getCurrentTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            transfer(IXToken(tokens[i]), getBalance(IXToken(tokens[i])));
        }

        emit ExitPool(msg.sender, pool, poolAmountIn); 
    }

    /**
     * @dev Pay `tokenAmountIn` of token `tokenIn` to join the pool, getting `poolAmountOut` of the pool shares.
     *
     * @param pool Pool address.
     * @param tokenIn Input token.
     * @param tokenAmountIn Exact amount of tokenIn to pay.
     * @param minPoolAmountOut Minumum amount of pool shares to get.
     */
    function joinswapExternAmountIn(
        address pool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut) {
        // pull xToken
        transferFrom(IXToken(tokenIn), tokenAmountIn);
        IXToken(tokenIn).approve(pool, tokenAmountIn);

        poolAmountOut = IBPool(pool).joinswapExternAmountIn(tokenIn, tokenAmountIn, minPoolAmountOut);

        // Wrap balancer liquidity tokens into its representing xToken
        IBPool(pool).approve(address(xTokenWrapper), poolAmountOut);
        require(xTokenWrapper.wrap(pool, poolAmountOut), "ERR_WRAP_POOL");

        transfer(IXToken(xTokenWrapper.tokenToXToken(pool)), poolAmountOut);

        emit JoinPool(msg.sender, pool,  poolAmountOut);
    }

    /**
     * @dev Specify `poolAmountOut` pool shares that you want to get, and a token `tokenIn` to pay with.
     * This costs `tokenAmountIn` tokens (these went into the pool).
     *
     * @param pool Pool address.
     * @param tokenIn Input token.
     * @param poolAmountOut Exact amount of pool shares to get.
     * @param maxAmountIn Minumum amount of tokenIn to pay.
     */
    function joinswapPoolAmountOut(
        address pool,
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn) {
        // pull xToken
        transferFrom(IXToken(tokenIn), maxAmountIn);
        IXToken(tokenIn).approve(pool, maxAmountIn);

        tokenAmountIn = IBPool(pool).joinswapPoolAmountOut(tokenIn, poolAmountOut, maxAmountIn);

        // push remaining xTokens
        transfer(IXToken(tokenIn), getBalance(IXToken(tokenIn)));

        // Wrap balancer liquidity tokens into its representing xToken
        IBPool(pool).approve(address(xTokenWrapper), poolAmountOut);
        require(xTokenWrapper.wrap(pool, poolAmountOut), "ERR_WRAP_POOL");

        transfer(IXToken(xTokenWrapper.tokenToXToken(pool)), poolAmountOut);

        emit JoinPool(msg.sender, pool,  poolAmountOut);
    }

    /**
     * @dev Pay `poolAmountIn` pool shares into the pool, getting `tokenAmountOut` of the given
     * token `tokenOut` out of the pool.
     *
     * @param pool Pool address.
     * @param tokenOut Input token.
     * @param poolAmountIn Exact amount of pool shares to pay.
     * @param minAmountOut Minumum amount of tokenIn to get.
     */
    function exitswapPoolAmountIn(
        address pool,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut) {
        address wrappedLPT = xTokenWrapper.tokenToXToken(pool);

        // pull wrapped liquitity tokens
        transferFrom(IXToken(wrappedLPT), poolAmountIn);

        // unwrap wrapped liquitity tokens
        require(xTokenWrapper.unwrap(wrappedLPT, poolAmountIn), "ERR_UNWRAP_POOL");

        // LPT do not need to be approved when exit
        tokenAmountOut = IBPool(pool).exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);

        // push xToken
        transfer(IXToken(tokenOut), tokenAmountOut);

        emit ExitPool(msg.sender, pool, poolAmountIn);
    }

    /**
     * @dev Specify tokenAmountOut of token tokenOut that you want to get out of the pool.
     * This costs poolAmountIn pool shares (these went into the pool).
     *
     * @param pool Pool address.
     * @param tokenOut Input token.
     * @param tokenAmountOut Exact amount of of tokenIn to get.
     * @param maxPoolAmountIn Maximum amount of pool shares to pay.
     */
    function exitswapExternAmountOut(
        address pool,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn) {
        address wrappedLPT = xTokenWrapper.tokenToXToken(pool);

        // pull wrapped liquitity tokens
        transferFrom(IXToken(wrappedLPT), maxPoolAmountIn);

        // unwrap wrapped liquitity tokens
        require(xTokenWrapper.unwrap(wrappedLPT, maxPoolAmountIn), "ERR_UNWRAP_POOL");

        // LPT do not need to be approved when exit
        poolAmountIn = IBPool(pool).exitswapExternAmountOut(tokenOut, tokenAmountOut, maxPoolAmountIn);

        // push xToken
        transfer(IXToken(tokenOut), tokenAmountOut);

        uint256 remainingLPT = maxPoolAmountIn.sub(poolAmountIn);
        if (remainingLPT > 0) {
            // Wrap remaining balancer liquidity tokens into its representing xToken
            IBPool(pool).approve(address(xTokenWrapper), remainingLPT);
            require(xTokenWrapper.wrap(pool, remainingLPT), "ERR_WRAP_POOL");

            transfer(IXToken(wrappedLPT), remainingLPT);
        }

        emit ExitPool(msg.sender, pool, poolAmountIn);
    }

    /**
     * @dev View function that calculates most optimal swaps (exactIn swap type) across a max of nPools.
     * Returns an array of `Swaps` and the total amount out for swap.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param swapAmount Amount of tokenIn.
     * @param nPools Maximum mumber of pools.
     */
    function viewSplitExactIn(
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        uint256 nPools
    ) public view returns (Swap[] memory swaps, uint256 totalOutput) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(tokenIn, tokenOut, nPools);

        Pool[] memory pools = new Pool[](poolAddresses.length);
        uint256 sumEffectiveLiquidity;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            pools[i] = getPoolData(tokenIn, tokenOut, poolAddresses[i]);
            sumEffectiveLiquidity = sumEffectiveLiquidity.add(pools[i].effectiveLiquidity);
        }

        uint256[] memory bestInputAmounts = new uint256[](pools.length);
        uint256 totalInputAmount;
        for (uint256 i = 0; i < pools.length; i++) {
            bestInputAmounts[i] = swapAmount.mul(pools[i].effectiveLiquidity).div(sumEffectiveLiquidity);
            totalInputAmount = totalInputAmount.add(bestInputAmounts[i]);
        }

        if (totalInputAmount < swapAmount) {
            bestInputAmounts[0] = bestInputAmounts[0].add(swapAmount.sub(totalInputAmount));
        } else {
            bestInputAmounts[0] = bestInputAmounts[0].sub(totalInputAmount.sub(swapAmount));
        }

        swaps = new Swap[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            swaps[i] = Swap({
                pool: pools[i].pool,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                swapAmount: bestInputAmounts[i],
                limitReturnAmount: 0,
                maxPrice: uint256(-1)
            });
        }

        totalOutput = calcTotalOutExactIn(bestInputAmounts, pools);

        return (swaps, totalOutput);
    }

    /**
     * @dev View function that calculates most optimal swaps (exactOut swap type) across a max of nPools.
     * Returns an array of Swaps and the total amount in for swap.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param swapAmount Amount of tokenIn.
     * @param nPools Maximum mumber of pools.
     */
    function viewSplitExactOut(
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        uint256 nPools
    ) public view returns (Swap[] memory swaps, uint256 totalInput) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(tokenIn, tokenOut, nPools);

        Pool[] memory pools = new Pool[](poolAddresses.length);
        uint256 sumEffectiveLiquidity;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            pools[i] = getPoolData(tokenIn, tokenOut, poolAddresses[i]);
            sumEffectiveLiquidity = sumEffectiveLiquidity.add(pools[i].effectiveLiquidity);
        }

        uint256[] memory bestInputAmounts = new uint256[](pools.length);
        uint256 totalInputAmount;
        for (uint256 i = 0; i < pools.length; i++) {
            bestInputAmounts[i] = swapAmount.mul(pools[i].effectiveLiquidity).div(sumEffectiveLiquidity);
            totalInputAmount = totalInputAmount.add(bestInputAmounts[i]);
        }

        if (totalInputAmount < swapAmount) {
            bestInputAmounts[0] = bestInputAmounts[0].add(swapAmount.sub(totalInputAmount));
        } else {
            bestInputAmounts[0] = bestInputAmounts[0].sub(totalInputAmount.sub(swapAmount));
        }

        swaps = new Swap[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            swaps[i] = Swap({
                pool: pools[i].pool,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                swapAmount: bestInputAmounts[i],
                limitReturnAmount: uint256(-1),
                maxPrice: uint256(-1)
            });
        }

        totalInput = calcTotalOutExactOut(bestInputAmounts, pools);

        return (swaps, totalInput);
    }

    function getPoolData(
        address tokenIn,
        address tokenOut,
        address poolAddress
    ) internal view returns (Pool memory) {
        IBPool pool = IBPool(poolAddress);
        uint256 tokenBalanceIn = pool.getBalance(tokenIn);
        uint256 tokenBalanceOut = pool.getBalance(tokenOut);
        uint256 tokenWeightIn = pool.getDenormalizedWeight(tokenIn);
        uint256 tokenWeightOut = pool.getDenormalizedWeight(tokenOut);
        uint256 swapFee = pool.getSwapFee();

        uint256 effectiveLiquidity = calcEffectiveLiquidity(tokenWeightIn, tokenBalanceOut, tokenWeightOut);
        Pool memory returnPool =
            Pool({
                pool: poolAddress,
                tokenBalanceIn: tokenBalanceIn,
                tokenWeightIn: tokenWeightIn,
                tokenBalanceOut: tokenBalanceOut,
                tokenWeightOut: tokenWeightOut,
                swapFee: swapFee,
                effectiveLiquidity: effectiveLiquidity
            });

        return returnPool;
    }

    function calcEffectiveLiquidity(
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut
    ) internal pure returns (uint256 effectiveLiquidity) {
        // Bo * wi/(wi+wo)
        effectiveLiquidity = tokenWeightIn.mul(BONE).div(tokenWeightOut.add(tokenWeightIn)).mul(tokenBalanceOut).div(
            BONE
        );

        return effectiveLiquidity;
    }

    function calcTotalOutExactIn(uint256[] memory bestInputAmounts, Pool[] memory bestPools)
        internal
        pure
        returns (uint256 totalOutput)
    {
        totalOutput = 0;
        for (uint256 i = 0; i < bestInputAmounts.length; i++) {
            uint256 output =
                IBPool(bestPools[i].pool).calcOutGivenIn(
                    bestPools[i].tokenBalanceIn,
                    bestPools[i].tokenWeightIn,
                    bestPools[i].tokenBalanceOut,
                    bestPools[i].tokenWeightOut,
                    bestInputAmounts[i],
                    bestPools[i].swapFee
                );

            totalOutput = totalOutput.add(output);
        }
        return totalOutput;
    }

    function calcTotalOutExactOut(uint256[] memory bestInputAmounts, Pool[] memory bestPools)
        internal
        pure
        returns (uint256 totalOutput)
    {
        totalOutput = 0;
        for (uint256 i = 0; i < bestInputAmounts.length; i++) {
            uint256 output =
                IBPool(bestPools[i].pool).calcInGivenOut(
                    bestPools[i].tokenBalanceIn,
                    bestPools[i].tokenWeightIn,
                    bestPools[i].tokenBalanceOut,
                    bestPools[i].tokenWeightOut,
                    bestInputAmounts[i],
                    bestPools[i].swapFee
                );

            totalOutput = totalOutput.add(output);
        }
        return totalOutput;
    }

    /**
     * @dev Trtansfers `token` from the sender to this conteract.
     *
     */
    function transferFrom(IXToken token, uint256 amount) internal {
        require(token.transferFrom(msg.sender, address(this), amount), "ERR_TRANSFER_FAILED");
    }

    /**
     * @dev Trtansfers protocol swap fee from the sender to this `feeReceiver`.
     *
     */
    function transferFeeFrom(
        IXToken token,
        uint256 amount,
        bool useUtitlityToken
    ) internal {
        if (useUtitlityToken && utilityToken != address(0) && address(utilityTokenFeed) != address(0)) {
            uint256 discountedFee = utilityTokenFeed.calculateAmount(address(token), amount.div(2));

            if (discountedFee > 0) {
                require(
                    IERC20(utilityToken).transferFrom(msg.sender, feeReceiver, discountedFee),
                    "ERR_FEE_UTILITY_TRANSFER_FAILED"
                );
            } else {
                require(token.transferFrom(msg.sender, feeReceiver, amount), "ERR_FEE_TRANSFER_FAILED");
            }
        } else {
            require(token.transferFrom(msg.sender, feeReceiver, amount), "ERR_FEE_TRANSFER_FAILED");
        }
    }

    function getBalance(IXToken token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(IXToken token, uint256 amount) internal {
        require(token.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface ISwap {
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IXToken
 * @author Protofire
 * @dev XToken Interface.
 *
 */
interface IXToken is IERC20 {
    /**
     * @dev Triggers stopped state.
     *
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     */
    function unpause() external;

    /**
     * @dev Sets authorization.
     *
     */
    function setAuthorization(address authorization_) external;

    /**
     * @dev Sets operationsRegistry.
     *
     */
    function setOperationsRegistry(address operationsRegistry_) external;

    /**
     * @dev Sets kya.
     *
     */
    function setKya(string memory kya_) external;

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     */
    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title IXTokenWrapper
 * @author Protofire
 * @dev XTokenWrapper Interface.
 *
 */
interface IXTokenWrapper is IERC1155Receiver {
    /**
     * @dev Token to xToken registry.
     */
    function tokenToXToken(address _token) external view returns (address);

    /**
     * @dev xToken to Token registry.
     */
    function xTokenToToken(address _xToken) external view returns (address);

    /**
     * @dev Wraps `_token` into its associated xToken.
     *
     */
    function wrap(address _token, uint256 _amount) external payable returns (bool);

    /**
     * @dev Unwraps `_xToken`.
     *
     */
    function unwrap(address _xToken, uint256 _amount) external returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool {
    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBRegistry
 * @author Protofire
 * @dev Balancer BRegistry contract interface.
 *
 */

interface IBRegistry {
    function getBestPoolsWithLimit(
        address,
        address,
        uint256
    ) external view returns (address[] memory);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../balancer/ISwap.sol";

/**
 * @title IProtocolFee
 * @author Protofire
 * @dev ProtocolFee interface.
 *
 */
interface IProtocolFee is ISwap {
    function batchFee(Swap[] memory swaps, uint256 amountIn) external view returns (uint256);

    function multihopBatch(Swap[][] memory swapSequences, uint256 amountIn) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IUtilTokenPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any UtilityToken price feed logic contract used in the protocol.
 *
 */
interface IUTokenPriceFeed {
    /**
     * @dev Gets the price a `_asset` in UtilityToken.
     *
     * @param _asset address of asset to get the price.
     */
    function getPrice(address _asset) external returns (uint256);

    /**
     * @dev Gets how many UtilityToken represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the amount.
     * @param _amount amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "libraries": {}
}