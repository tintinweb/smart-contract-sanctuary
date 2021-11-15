// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IArchRouterImmutableState.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract ArchRouterImmutableState is IArchRouterImmutableState {
    /// @inheritdoc IArchRouterImmutableState
    address public immutable override uniV3Factory;
    /// @inheritdoc IArchRouterImmutableState
    address public immutable override WETH;

    constructor(address _uniV3Factory, address _WETH) {
        uniV3Factory = _uniV3Factory;
        WETH = _WETH;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt ([email protected]).
*/

import './interfaces/IERC20Extended.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV3Pool.sol';
import './interfaces/IUniV3Router.sol';
import './interfaces/IWETH.sol';
import './lib/RouteLib.sol';
import './lib/TransferHelper.sol';
import './lib/SafeCast.sol';
import './lib/Path.sol';
import './lib/CallbackValidation.sol';
import './ArchRouterImmutableState.sol';
import './PaymentsWithFee.sol';
import './Multicall.sol';
import './SelfPermit.sol';

/**
 * @title ArcherSwapRouter
 * @dev Allows Uniswap V2/V3 Router-compliant trades to be paid via tips instead of gas
 */
contract ArcherSwapRouter is
    IUniV3Router,
    ArchRouterImmutableState,
    PaymentsWithFee,
    Multicall,
    SelfPermit
{
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Trade details
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address payable to;
        uint256 deadline;
    }

    /// @notice Uniswap V3 Swap Callback 
    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /**
     * @notice Construct new ArcherSwap Router
     * @param _uniV3Factory Uni V3 Factory address
     * @param _WETH WETH address
     */
    constructor(address _uniV3Factory, address _WETH) ArchRouterImmutableState(_uniV3Factory, _WETH) {}

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapExactTokensForETHAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(trade.path[trade.path.length - 1] == WETH, 'ArchRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), trade.amountIn
        );
        _exactInputSwap(factory, trade.path, address(this));
        uint256 amountOut = IWETH(WETH).balanceOf(address(this));
        require(amountOut >= trade.amountOut, 'ArchRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);

        tip(tipAmount);
        TransferHelper.safeTransferETH(trade.to, amountOut - tipAmount);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapTokensForExactETHAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(trade.path[trade.path.length - 1] == WETH, 'ArchRouter: INVALID_PATH');
        uint[] memory amounts = RouteLib.getAmountsIn(factory, trade.amountOut, trade.path);
        require(amounts[0] <= trade.amountIn, 'ArchRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), amounts[0]
        );
        _exactOutputSwap(factory, amounts, trade.path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        tip(tipAmount);
        TransferHelper.safeTransferETH(trade.to, trade.amountOut - tipAmount);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapExactETHForTokensAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        tip(tipAmount);
        require(trade.path[0] == WETH, 'ArchRouter: INVALID_PATH');
        uint256 inputAmount = msg.value - tipAmount;
        IWETH(WETH).deposit{value: inputAmount}();
        assert(IWETH(WETH).transfer(RouteLib.pairFor(factory, trade.path[0], trade.path[1]), inputAmount));
        uint256 balanceBefore = IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to);
        _exactInputSwap(factory, trade.path, trade.to);
        require(
            IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to) - balanceBefore >= trade.amountOut,
            'ArchRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice Swap ETH for tokens and pay amount of ETH input as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapETHForExactTokensAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        tip(tipAmount);
        require(trade.path[0] == WETH, 'ArchRouter: INVALID_PATH');
        uint[] memory amounts = RouteLib.getAmountsIn(factory, trade.amountOut, trade.path);
        uint256 inputAmount = msg.value - tipAmount;
        require(amounts[0] <= inputAmount, 'ArchRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(RouteLib.pairFor(factory, trade.path[0], trade.path[1]), amounts[0]));
        _exactOutputSwap(factory, amounts, trade.path, trade.to);

        if (inputAmount > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, inputAmount - amounts[0]);
        }
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapExactTokensForTokensAndTipAmount(
        address factory,
        Trade calldata trade
    ) external payable {
        tip(msg.value);
        _swapExactTokensForTokens(factory, trade);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapExactTokensForTokensAndTipPct(
        address factory,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint32 tipPct
    ) external payable {
        _swapExactTokensForTokens(factory, trade);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        TransferHelper.safeTransfer(pathToEth[0], trade.to, contractTokenBalance - tipAmount);
        _tipWithTokens(factory, pathToEth);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapTokensForExactTokensAndTipAmount(
        address factory,
        Trade calldata trade
    ) external payable {
        tip(msg.value);
        _swapTokensForExactTokens(factory, trade);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapTokensForExactTokensAndTipPct(
        address factory,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint32 tipPct
    ) external payable {
        _swapTokensForExactTokens(factory, trade);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        TransferHelper.safeTransfer(pathToEth[0], trade.to, contractTokenBalance - tipAmount);
        _tipWithTokens(factory, pathToEth);
    }

    /** 
     * @notice Returns the pool for the given token pair and fee. The pool contract may or may not exist.
     * @param tokenA First token
     * @param tokenB Second token
     * @param fee Pool fee
     * @return Uniswap V3 Pool 
     */ 
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(RouteLib.computeAddress(uniV3Factory, RouteLib.getPoolKey(tokenA, tokenB, fee)));
    }

    /**
     * @notice Uniswap V3 Callback function that validates and pays for trade
     * @dev Called by Uni V3 pool contract
     * @param amount0Delta Delta for token 0
     * @param amount1Delta Delta for token 1
     * @param _data Swap callback data
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(uniV3Factory, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        } else {
            // either initiate the next swap or pay
            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                _exactOutputInternal(amountToPay, msg.sender, 0, data);
            } else {
                amountInCached = amountToPay;
                tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
                pay(tokenIn, data.payer, msg.sender, amountToPay);
            }
        }
    }

    /// @inheritdoc IUniV3Router
    function exactInputSingle(ExactInputSingleParams calldata params)
        public
        payable
        override
        returns (uint256 amountOut)
    {
        amountOut = _exactInputInternal(
            params.amountIn,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut), payer: msg.sender})
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /**
     * @notice Performs a single exact input Uni V3 swap and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactInputSingleAndTipAmount(ExactInputSingleParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = exactInputSingle(params);
        tip(tipAmount);
    }

    /// @inheritdoc IUniV3Router
    function exactInput(ExactInputParams memory params)
        public
        payable
        override
        returns (uint256 amountOut)
    {
        address payer = msg.sender; // msg.sender pays for the first hop

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = _exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this); // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /**
     * @notice Performs multiple exact input Uni V3 swaps and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactInputAndTipAmount(ExactInputParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = exactInput(params);
        tip(tipAmount);
    }

    /// @inheritdoc IUniV3Router
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        public
        payable
        override
        returns (uint256 amountIn)
    {
        // avoid an SLOAD by using the swap return data
        amountIn = _exactOutputInternal(
            params.amountOut,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({path: abi.encodePacked(params.tokenOut, params.fee, params.tokenIn), payer: msg.sender})
        );

        require(amountIn <= params.amountInMaximum, 'Too much requested');
        // has to be reset even though we don't use it in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /**
     * @notice Performs an exact output Uni V3 swap and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactOutputSingleAndTipAmount(ExactOutputSingleParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = exactOutputSingle(params);
        tip(tipAmount);
    }

    /// @inheritdoc IUniV3Router
    function exactOutput(ExactOutputParams calldata params)
        public
        payable
        override
        returns (uint256 amountIn)
    {
        // it's okay that the payer is fixed to msg.sender here, as they're only paying for the "final" exact output
        // swap, which happens first, and subsequent swaps are paid for within nested callback frames
        _exactOutputInternal(
            params.amountOut,
            params.recipient,
            0,
            SwapCallbackData({path: params.path, payer: msg.sender})
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /**
     * @notice Performs multiple exact output Uni V3 swaps and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactOutputAndTipAmount(ExactOutputParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = exactOutput(params);
        tip(tipAmount);
    }

    /**
     * @notice Performs a single exact input Uni V3 swap
     * @param amountIn Amount of input token
     * @param recipient Recipient of swap result
     * @param sqrtPriceLimitX96 Price limit
     * @param data Swap callback data
     */
    function _exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        if (recipient == address(0)) recipient = address(this);

        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /**
     * @notice Performs a single exact output Uni V3 swap
     * @param amountOut Amount of output token
     * @param recipient Recipient of swap result
     * @param sqrtPriceLimitX96 Price limit
     * @param data Swap callback data
     */
    function _exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountIn) {
        // allow swapping to the router address with address 0
        if (recipient == address(0)) recipient = address(this);

        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                -amountOut.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function _swapExactTokensForTokens(
        address factory,
        Trade calldata trade
    ) internal {
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), trade.amountIn
        );
        uint balanceBefore = IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to);
        _exactInputSwap(factory, trade.path, trade.to);
        require(
            IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to) - balanceBefore >= trade.amountOut,
            'ArchRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function _swapTokensForExactTokens(
        address factory,
        Trade calldata trade
    ) internal {
        uint[] memory amounts = RouteLib.getAmountsIn(factory, trade.amountOut, trade.path);
        require(amounts[0] <= trade.amountIn, 'ArchRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), amounts[0]
        );
        _exactOutputSwap(factory, amounts, trade.path, trade.to);
    }

    /**
     * @notice Internal implementation of exact input Uni V2/Sushi swap
     * @param factory Uniswap V2-compliant Factory contract
     * @param path Trade path
     * @param _to Trade recipient
     */
    function _exactInputSwap(
        address factory, 
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = RouteLib.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(RouteLib.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            {
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20Extended(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = RouteLib.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? RouteLib.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @notice Internal implementation of exact output Uni V2/Sushi swap
     * @param factory Uniswap V2-compliant Factory contract
     * @param amounts Output amounts
     * @param path Trade path
     * @param _to Trade recipient
     */
    function _exactOutputSwap(
        address factory, 
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = RouteLib.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? RouteLib.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(RouteLib.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @notice Convert a token balance into ETH and then tip
     * @param factory Factory address
     * @param path Path for swap
     */
    function _tipWithTokens(
        address factory,
        address[] memory path
    ) internal {
        _exactInputSwap(factory, path, address(this));
        uint256 amountOut = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountOut);

        tip(address(this).balance);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IERC20Extended.sol';
import './interfaces/IPayments.sol';
import './interfaces/IWETH.sol';
import './lib/TransferHelper.sol';
import './ArchRouterImmutableState.sol';

abstract contract Payments is IPayments, ArchRouterImmutableState {
    receive() external payable {
        require(msg.sender == WETH, 'Not WETH');
    }

    /// @inheritdoc IPayments
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWETH = withdrawWETH(amountMinimum);
        TransferHelper.safeTransferETH(recipient, balanceWETH);
    }

    /// @inheritdoc IPayments
    function unwrapWETHAndTip(uint256 tipAmount, uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWETH = withdrawWETH(amountMinimum);
        tip(tipAmount);
        if(balanceWETH > tipAmount) {
            TransferHelper.safeTransferETH(recipient, balanceWETH - tipAmount);
        }
    }

    /// @inheritdoc IPayments
    function tip(uint256 tipAmount) public payable override {
        TransferHelper.safeTransferETH(block.coinbase, tipAmount);
    }

    /// @inheritdoc IPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable override {
        uint256 balanceToken = IERC20Extended(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPayments
    function refundETH() external payable override {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @param amountMinimum Min amount of WETH to withdraw
    function withdrawWETH(uint256 amountMinimum) public returns(uint256 balanceWETH){
        balanceWETH = IWETH(WETH).balanceOf(address(this));
        require(balanceWETH >= amountMinimum && balanceWETH > 0, 'Insufficient WETH');
        IWETH(WETH).withdraw(balanceWETH);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH
            IWETH(WETH).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IERC20Extended.sol';
import './interfaces/IPaymentsWithFee.sol';
import './interfaces/IWETH.sol';
import './lib/TransferHelper.sol';
import './Payments.sol';

abstract contract PaymentsWithFee is Payments, IPaymentsWithFee {
    /// @inheritdoc IPaymentsWithFee
    function unwrapWETHWithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
        require(balanceWETH >= amountMinimum, 'Insufficient WETH');

        if (balanceWETH > 0) {
            IWETH(WETH).withdraw(balanceWETH);
            uint256 feeAmount = (balanceWETH * feeBips) / 10_000;
            if (feeAmount > 0) TransferHelper.safeTransferETH(feeRecipient, feeAmount);
            TransferHelper.safeTransferETH(recipient, balanceWETH - feeAmount);
        }
    }

    /// @inheritdoc IPaymentsWithFee
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceToken = IERC20Extended(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            uint256 feeAmount = (balanceToken * feeBips) / 10_000;
            if (feeAmount > 0) TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
            TransferHelper.safeTransfer(token, recipient, balanceToken - feeAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IERC20Extended.sol';
import './interfaces/ISelfPermit.sol';
import './interfaces/IERC20PermitAllowed.sol';

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20Extended(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (IERC20Extended(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (IERC20Extended(token).allowance(msg.sender, address(this)) < type(uint256).max)
            selfPermitAllowed(token, nonce, expiry, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IArchRouterImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function uniV3Factory() external view returns (address);

    /// @return Returns the address of WETH
    function WETH() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20Extended {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function version() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function receiveWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address) external view returns (uint);
    function getDomainSeparator() external view returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERSION_HASH() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function TRANSFER_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    function RECEIVE_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPayments {
    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH from users.
    /// @param amountMinimum The minimum amount of WETH to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Tips miners using the WETH balance in the contract and then transfers the remainder to recipient
    /// @dev The recipientMinimum parameter prevents malicious contracts from stealing the ETH from users
    /// @param tipAmount Tip amount
    /// @param amountMinimum The minimum amount of WETH to withdraw
    /// @param recipient The destination address of the ETH left after tipping
    function unwrapWETHAndTip(
        uint256 tipAmount, 
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Tips miners using the ETH balance in the contract + msg.value
    /// @param tipAmount Tip amount
    function tip(
        uint256 tipAmount
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './IPayments.sol';

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPaymentsWithFee is IPayments {
    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH from users.
    function unwrapWETHWithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniV3Router is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool
{
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../interfaces/IUniswapV3Pool.sol';
import './RouteLib.sol';

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(factory, RouteLib.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, RouteLib.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(RouteLib.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IUniswapV2Pair.sol';

library RouteLib {
  address internal constant _SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
  bytes32 internal constant _SUSHI_ROUTER_INIT_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
  bytes32 internal constant _UNI_V2_ROUTER_INIT_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
  bytes32 internal constant _UNI_V3_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  /// @notice The identifying key of the pool
  struct PoolKey {
      address token0;
      address token1;
      uint24 fee;
  }

  /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
  /// @param tokenA The first token of a pool, unsorted
  /// @param tokenB The second token of a pool, unsorted
  /// @param fee The fee level of the pool
  /// @return Poolkey The pool details with ordered token0 and token1 assignments
  function getPoolKey(
      address tokenA,
      address tokenB,
      uint24 fee
  ) internal pure returns (PoolKey memory) {
      if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
      return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'RouteLib: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'RouteLib: ZERO_ADDRESS');
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    bytes32 initHash = factory == _SUSHI_FACTORY ? _SUSHI_ROUTER_INIT_HASH : _UNI_V2_ROUTER_INIT_HASH;
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              initHash // init code hash
            )
          )
        )
      )
    );
  }

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param factory The Uniswap V3 factory contract address
  /// @param key The PoolKey
  /// @return pool The contract address of the V3 pool
  function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
      require(key.token0 < key.token1);
      pool = address(
          uint160(
              uint256(
                  keccak256(
                      abi.encodePacked(
                          hex'ff',
                          factory,
                          keccak256(abi.encode(key.token0, key.token1, key.fee)),
                          _UNI_V3_INIT_CODE_HASH
                      )
                  )
              )
          )
      );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'RouteLib: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'RouteLib: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * (reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'RouteLib: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'RouteLib: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn * 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
    require(amountOut > 0, 'RouteLib: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'RouteLib: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn * amountOut * 1000;
    uint denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'RouteLib: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'RouteLib: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
  }
}

