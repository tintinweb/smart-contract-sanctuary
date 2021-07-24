pragma solidity >=0.7.6;
pragma abicoder v2;

import './interfaces/ISwapFeeReward.sol';
import './interfaces/IPolyDexFactory.sol';
import './interfaces/IPolyDexFormula.sol';
import './interfaces/IPolyDexPair.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPolyDexRouterV2.sol';
import './libraries/SafeMath.sol';
import './interfaces/IWETH.sol';

contract PolyDexRouterV2 is IPolyDexRouterV2 {
    using SafeMath for uint;
    address public governance;
    address public immutable override factory;
    address public immutable override formula;
    address public override swapFeeReward;
    address public immutable override WETH;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'Router: EXPIRED');
        _;
    }
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        formula = IPolyDexFactory(_factory).formula();
        WETH = _WETH;
        governance = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "PolyDexRouterV2: !governance");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance override {
        require(_governance != address(0), "PolyDexRouterV2: invalid governance");
        governance = _governance;
    }

    function setSwapFeeReward(address _swapFeeReward) public onlyGovernance {
        swapFeeReward = _swapFeeReward;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB) = IPolyDexFormula(formula).getReserves(pair, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = IPolyDexFormula(formula).quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = IPolyDexFormula(formula).quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _addLiquidityToken(
        address pair,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        (amountA, amountB) = _addLiquidity(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    }
    function createPair( address tokenA, address tokenB,uint amountA,uint amountB, address to) public virtual override returns (uint liquidity) {
        address pair = IPolyDexFactory(factory).createPair(tokenA, tokenB);
        _addLiquidityToken(pair, tokenA, tokenB, amountA, amountB, 0, 0);
        liquidity = IPolyDexPair(pair).mint(to);
    }
    function addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA,  amountB) = _addLiquidityToken(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        liquidity = IPolyDexPair(pair).mint(to);
    }

    function _addLiquidityETH(
        address pair,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to
    ) internal returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            pair,
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        transferETHTo(amountETH, pair);
        liquidity = IPolyDexPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }
    function createPairETH( address token, uint amountToken, address to) public virtual override payable returns (uint liquidity) {
        address pair = IPolyDexFactory(factory).createPair(token, WETH);
        (,,liquidity) = _addLiquidityETH(pair, token, amountToken, 0, 0, to);
    }
    function addLiquidityETH(
        address pair,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH, liquidity) = _addLiquidityETH(pair, token, amountTokenDesired, amountTokenMin, amountETHMin, to);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(address tokenIn, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        address input = tokenIn;
        for (uint i = 0; i < path.length; i++) {
            IPolyDexPair pairV2 = IPolyDexPair(path[i]);
            address token0 = pairV2.token0();
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out, address output) = input == token0 ? (uint(0), amountOut, pairV2.token1()) : (amountOut, uint(0), token0);
            if (swapFeeReward != address(0)) {
                ISwapFeeReward(swapFeeReward).swap(msg.sender, address(pairV2), input, output, amountOut);
            }
            address to = i < path.length - 1 ? path[i + 1] : _to;
            pairV2.swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
            emit Exchange(address(pairV2), amountOut, output);
            input = output;
        }
    }

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = _validateAmountOut(tokenIn, tokenOut, amountIn, amountOutMin, path);

        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, path[0], amounts[0]
        );
        _swap(tokenIn, amounts, path, to);
    }

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = _validateAmountIn(tokenIn, tokenOut, amountOut, amountInMax, path);

        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, path[0], amounts[0]
        );
        _swap(tokenIn, amounts, path, to);
    }

    function swapExactETHForTokens(address tokenOut, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        amounts = _validateAmountOut(WETH, tokenOut, msg.value, amountOutMin, path);

        transferETHTo(amounts[0], path[0]);
        _swap(WETH, amounts, path, to);
    }
    function swapTokensForExactETH(address tokenIn, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        amounts = _validateAmountIn(tokenIn, WETH, amountOut, amountInMax, path);

        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, path[0], amounts[0]
        );
        _swap(tokenIn, amounts, path, address(this));
        transferAll(ETH_ADDRESS, to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(address tokenIn, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        amounts = _validateAmountOut(tokenIn, WETH, amountIn, amountOutMin, path);

        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, path[0], amounts[0]
        );
        _swap(tokenIn, amounts, path, address(this));
        transferAll(ETH_ADDRESS, to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(address tokenOut, uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        amounts = _validateAmountIn(WETH, tokenOut, amountOut, msg.value, path);

        transferETHTo(amounts[0], path[0]);
        _swap(WETH, amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address tokenIn, address[] memory path, address _to) internal virtual {
        address input = tokenIn;
        for (uint i; i < path.length; i++) {
            IPolyDexPair pair = IPolyDexPair(path[i]);

            uint amountInput;
            uint amountOutput;
            address currentOutput;
            {
                (address output, uint reserveInput, uint reserveOutput, uint32 tokenWeightInput, uint32 tokenWeightOutput, uint32 swapFee) = IPolyDexFormula(formula).getFactoryReserveAndWeights(factory, address(pair), input);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = IPolyDexFormula(formula).getAmountOut(amountInput, reserveInput, reserveOutput, tokenWeightInput, tokenWeightOutput, swapFee);
                currentOutput = output;
                if (swapFeeReward != address(0)) {
                    ISwapFeeReward(swapFeeReward).swap(msg.sender, address(pair), input, output, amountOutput);
                }
            }
            (uint amount0Out, uint amount1Out) = input == pair.token0() ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 1 ? path[i + 1] : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
            emit Exchange(address(pair), amountOutput, currentOutput);
            input = currentOutput;
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, path[0], amountIn
        );
        uint balanceBefore = IERC20(tokenOut).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(tokenIn, path, to);
        require(
            IERC20(tokenOut).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
//            require(path[0] == WETH, 'Router: INVALID_PATH');
        uint amountIn = msg.value;
        transferETHTo(amountIn, path[0]);
        uint balanceBefore = IERC20(tokenOut).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(WETH, path, to);
        require(
            IERC20(tokenOut).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, path[0], amountIn
        );
        _swapSupportingFeeOnTransferTokens(tokenIn, path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');
        transferAll(ETH_ADDRESS, to, amountOut);
    }
    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint deadline
    ) public payable override virtual ensure(deadline) returns (uint totalAmountOut) {
        transferFromAll(tokenIn, totalAmountIn);
        uint balanceBefore;
        if (!isETH(tokenOut)) {
            balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);
        }

        for (uint i = 0; i < swapSequences.length; i++) {
            uint tokenAmountOut;
            for (uint k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                if (k > 0) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }
                tokenAmountOut = _swapSingleSupportFeeOnTransferTokens(swap.tokenIn, swap.tokenOut, swap.pool, swap.swapAmount, swap.limitReturnAmount);
            }

            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        transferAll(tokenOut, msg.sender, totalAmountOut);
        transferAll(tokenIn, msg.sender, getBalance(tokenIn));

        if (isETH(tokenOut)) {
            require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");
        } else {
            require(IERC20(tokenOut).balanceOf(msg.sender).sub(balanceBefore) >= minTotalAmountOut, '<minTotalAmountOut');
        }
    }

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint maxTotalAmountIn,
        uint deadline
    ) public payable override virtual ensure(deadline) returns (uint totalAmountIn) {
        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint i = 0; i < swapSequences.length; i++) {
            uint tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                tokenAmountInFirstSwap = _swapSingleMixOut(swap.tokenIn, swap.tokenOut, swap.pool, swap.swapAmount, swap.limitReturnAmount, swap.maxPrice);

            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint intermediateTokenAmount;
                // This would be token B as described above
                Swap memory secondSwap = swapSequences[i][1];
                {
                    address[] memory paths = new address[](1);
                    paths[0] = secondSwap.pool;
                    uint[] memory amounts = IPolyDexFormula(formula).getFactoryAmountsIn(factory, secondSwap.tokenIn, secondSwap.tokenOut, secondSwap.swapAmount, paths);
                    intermediateTokenAmount = amounts[0];
                    require(intermediateTokenAmount <= secondSwap.limitReturnAmount, 'Router: EXCESSIVE_INPUT_AMOUNT');
                }

                //// Buy intermediateTokenAmount of token B with A in the first pool
                Swap memory firstSwap = swapSequences[i][0];
                tokenAmountInFirstSwap = _swapSingleMixOut(firstSwap.tokenIn, firstSwap.tokenOut, firstSwap.pool, intermediateTokenAmount, firstSwap.limitReturnAmount, firstSwap.maxPrice);

                //// Buy the final amount of token C desired
                _swapSingle(secondSwap.tokenIn, secondSwap.pool, intermediateTokenAmount, secondSwap.swapAmount);
            }

            totalAmountIn = tokenAmountInFirstSwap.add(totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(tokenOut, msg.sender, getBalance(tokenOut));
        transferAll(tokenIn, msg.sender, getBalance(tokenIn));
    }

    function transferFromAll(address token, uint amount) internal returns (bool) {
        if (isETH(token)) {
            IWETH(WETH).deposit{value : msg.value}();
        } else {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        }
        return true;
    }

    function getBalance(address token) internal view returns (uint) {
        if (isETH(token)) {
            return IWETH(WETH).balanceOf(address(this));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function _swapSingleMixOut(address tokenIn, address tokenOut, address pool, uint swapAmount, uint limitReturnAmount, uint maxPrice) internal returns (uint tokenAmountIn) {
        address[] memory paths = new address[](1);
        paths[0] = pool;
        uint[] memory amounts = IPolyDexFormula(formula).getFactoryAmountsIn(factory, tokenIn, tokenOut, swapAmount, paths);
        tokenAmountIn = amounts[0];
        require(tokenAmountIn <= limitReturnAmount, 'Router: EXCESSIVE_INPUT_AMOUNT');
        _swapSingle(tokenIn, pool, tokenAmountIn, amounts[1]);
    }

    function _swapSingle(address tokenIn, address pair, uint targetSwapAmount, uint targetOutAmount) internal {
        TransferHelper.safeTransfer(tokenIn, pair, targetSwapAmount);
        IPolyDexPair pairV2 = IPolyDexPair(pair);
        address token0 = pairV2.token0();

        (uint amount0Out, uint amount1Out, address output) = tokenIn == token0 ? (uint(0), targetOutAmount, pairV2.token1()) : (targetOutAmount, uint(0), token0);
        pairV2.swap(amount0Out, amount1Out, address(this), new bytes(0));

        emit Exchange(pair, targetOutAmount, output);
    }

    function _swapSingleSupportFeeOnTransferTokens(address tokenIn, address tokenOut, address pool, uint swapAmount, uint limitReturnAmount) internal returns(uint tokenAmountOut) {
        TransferHelper.safeTransfer(tokenIn, pool, swapAmount);

        uint amountOutput;
        {
            (, uint reserveInput, uint reserveOutput, uint32 tokenWeightInput, uint32 tokenWeightOutput, uint32 swapFee) = IPolyDexFormula(formula).getFactoryReserveAndWeights(factory, pool, tokenIn);
            uint amountInput = IERC20(tokenIn).balanceOf(pool).sub(reserveInput);
            amountOutput = IPolyDexFormula(formula).getAmountOut(amountInput, reserveInput, reserveOutput, tokenWeightInput, tokenWeightOutput, swapFee);
        }
        uint balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        (uint amount0Out, uint amount1Out) = tokenIn == IPolyDexPair(pool).token0() ? (uint(0), amountOutput) : (amountOutput, uint(0));
        IPolyDexPair(pool).swap(amount0Out, amount1Out, address(this), new bytes(0));
        emit Exchange(pool, amountOutput, tokenOut);

        tokenAmountOut = IERC20(tokenOut).balanceOf(address(this)).sub(balanceBefore);
        require(tokenAmountOut >= limitReturnAmount,'Router: INSUFFICIENT_OUTPUT_AMOUNT');
    }

    function _validateAmountOut(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        amounts = IPolyDexFormula(formula).getFactoryAmountsOut(factory, tokenIn, tokenOut, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');
    }

    function _validateAmountIn(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        uint amountInMax,
        address[] calldata path
    ) internal view returns (uint[] memory amounts) {
        amounts = IPolyDexFormula(formula).getFactoryAmountsIn(factory, tokenIn, tokenOut, amountOut, path);
        require(amounts[0] <= amountInMax, 'Router: EXCESSIVE_INPUT_AMOUNT');
    }

    function transferETHTo(uint amount, address to) internal {
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(to, amount));
    }

    function transferAll(address token, address to, uint amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
        return true;
    }

    function isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }
// **** REMOVE LIQUIDITY ****
    function _removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal  returns (uint amountA, uint amountB) {
        require(IPolyDexFactory(factory).isPair(pair), "Router: Invalid pair");
        IPolyDexPair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint amount0, uint amount1) = IPolyDexPair(pair).burn(to);
        (address token0,) = IPolyDexFormula(formula).sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        (amountA, amountB) = _removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function removeLiquidityETH(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = _removeLiquidity(
            pair,
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this)
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        transferAll(ETH_ADDRESS, to, amountETH);
    }

    function removeLiquidityWithPermit(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        {
            uint value = approveMax ? uint(- 1) : liquidity;
            IPolyDexPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        }
        (amountA, amountB) = _removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function removeLiquidityETHWithPermit(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        uint value = approveMax ? uint(- 1) : liquidity;
        IPolyDexPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(pair, token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            pair,
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        transferAll(ETH_ADDRESS, to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        uint value = approveMax ? uint(- 1) : liquidity;
        IPolyDexPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            pair, token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }
}

pragma solidity >=0.5.16;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.16;

interface IPolyDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 swapFee, uint);
    function feeTo() external view returns (address);
    function formula() external view returns (address);
    function protocolFee() external view returns (uint);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function isPair(address) external view returns (bool);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getWeightsAndSwapFee(address pair) external view returns (uint32 tokenWeight0, uint32 tokenWeight1, uint32 swapFee);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.5.16;

/*
    Bancor Formula interface
*/
interface IPolyDexFormula {

    function getReserveAndWeights(address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getFactoryReserveAndWeights(address factory, address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getAmountIn(
        uint amountOut,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountIn);

    function getPairAmountIn(address pair, address tokenIn, uint amountOut) external view returns (uint amountIn);

    function getAmountOut(
        uint amountIn,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountOut);

    function getPairAmountOut(address pair, address tokenIn, uint amountIn) external view returns (uint amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function ensureConstantValue(uint reserve0, uint reserve1, uint balance0Adjusted, uint balance1Adjusted, uint32 tokenWeight0) external view returns (bool);
    function getReserves(address pair, address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);
    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function mintLiquidityFee(
        uint totalLiquidity,
        uint112 reserve0,
        uint112  reserve1,
        uint112  collectedFee0,
        uint112 collectedFee1) external view returns (uint amount);
}

pragma solidity >=0.5.16;
interface IPolyDexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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


    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
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
    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);
    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);
    function getSwapFee() external view returns (uint32);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint32) external;
}

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IPolyDexRouterV2 {
    event Exchange(
        address pair,
        uint amountOut,
        address output
    );
    event ChangeGovernance(address indexed governance);
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint swapAmount; // tokenInAmount / tokenOutAmount
        uint limitReturnAmount; // minAmountOut / maxAmountIn
        uint maxPrice;
    }
    function factory() external view returns (address);
    function formula() external view returns (address);
    function swapFeeReward() external view returns (address);

    function WETH() external view returns (address);

    function setGovernance(address) external;

    function addLiquidity(
        address pair,
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
        address pair,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);


    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(address tokenOut, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(address tokenIn, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(address tokenIn, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(address tokenOut, uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;


    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint deadline
    )
    external payable returns (uint totalAmountOut);
    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint maxTotalAmountIn,
        uint deadline
    ) external payable returns (uint totalAmountIn);

    function createPair( address tokenA, address tokenB,uint amountA,uint amountB, address to) external returns (uint liquidity);
    function createPairETH( address token, uint amountToken, address to) external payable returns (uint liquidity);

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address pair,
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
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);


    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
}

pragma solidity >=0.5.16;
interface ISwapFeeReward {
    function swap(address account, address pair, address input, address output, uint256 amount) external returns (bool);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity >=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, 'ds-math-division-by-zero');
        c = a / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.16;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper { 
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}