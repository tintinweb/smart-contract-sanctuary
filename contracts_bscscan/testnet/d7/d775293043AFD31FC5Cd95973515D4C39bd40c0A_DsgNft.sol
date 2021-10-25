// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '../libraries/SwapLibrary.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/ISwapRouter02.sol';
import '../interfaces/ISwapFactory.sol';
import '../interfaces/IWOKT.sol';
import "../libraries/TransferHelper.sol";
import "../interfaces/ISwapAdapter.sol";

interface ITradingPool {
    function swap(
        address account,
        address input,
        address output,
        uint256 amount
    ) external returns (bool);
}

contract SwapRouter is ISwapRouter02, Ownable {
    using SafeMath for uint256;

    struct PoolInfo {
        uint256 direction;
        uint256 poolEdition;
        uint256 weight;
        address pool;
        address adapter;
        bytes moreInfo;
    }

    event ExSwap(
        address fromToken,
        address toToken,
        address sender,
        uint256 fromAmount,
        uint256 returnAmount
    );

    address public immutable override factory;
    address public immutable override WOKT;
    address public override tradingPool;
    mapping (address => bool) public isWhiteListed;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'SwapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WOKT) public {
        factory = _factory;
        WOKT = _WOKT;
    }

    receive() external payable {
        assert(msg.sender == WOKT); // only accept OKT via fallback from the WOKT contract
    }

    function addWhiteList (address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = true;
    }

    function removeWhiteList (address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = false;
    }

    function setTradingPool(address _tradingPool) public onlyOwner {
        tradingPool = _tradingPool;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (ISwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = SwapLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SwapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = SwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SwapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function pairFor(address tokenA, address tokenB) public view returns(address) {
        return SwapLibrary.pairFor(factory, tokenA, tokenB);
    }

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
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SwapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISwapPair(pair).mint(to);
    }

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
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WOKT,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SwapLibrary.pairFor(factory, token, WOKT);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWOKT(WOKT).deposit{value: amountETH}();
        assert(IWOKT(WOKT).transfer(pair, amountETH));
        liquidity = ISwapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = SwapLibrary.pairFor(factory, tokenA, tokenB);
        ISwapPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = ISwapPair(pair).burn(to);
        (address token0, ) = SwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SwapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SwapRouter: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WOKT,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWOKT(WOKT).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

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
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = SwapLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

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
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = SwapLibrary.pairFor(factory, token, WOKT);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(token, WOKT, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWOKT(WOKT).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

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
    ) external virtual override returns (uint256 amountETH) {
        address pair = SwapLibrary.pairFor(factory, token, WOKT);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = SwapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            if (tradingPool != address(0)) {
                ITradingPool(tradingPool).swap(msg.sender, input, output, amountOut);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? SwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ISwapPair(SwapLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = SwapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = SwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SwapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WOKT, 'SwapRouter: INVALID_PATH');
        amounts = SwapLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWOKT(WOKT).deposit{value: amounts[0]}();
        assert(IWOKT(WOKT).transfer(SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WOKT, 'SwapRouter: INVALID_PATH');
        amounts = SwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SwapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWOKT(WOKT).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WOKT, 'SwapRouter: INVALID_PATH');
        amounts = SwapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWOKT(WOKT).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WOKT, 'SwapRouter: INVALID_PATH');
        amounts = SwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'SwapRouter: EXCESSIVE_INPUT_AMOUNT');
        IWOKT(WOKT).deposit{value: amounts[0]}();
        assert(IWOKT(WOKT).transfer(SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = SwapLibrary.sortTokens(input, output);
            ISwapPair pair = ISwapPair(SwapLibrary.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = SwapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            if (tradingPool != address(0)) {
                ITradingPool(tradingPool).swap(msg.sender, input, output, amountOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? SwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(path[0], msg.sender, SwapLibrary.pairFor(factory, path[0], path[1]), amountIn);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WOKT, 'SwapRouter: INVALID_PATH');
        uint256 amountIn = msg.value;
        IWOKT(WOKT).deposit{value: amountIn}();
        assert(IWOKT(WOKT).transfer(SwapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WOKT, 'SwapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(path[0], msg.sender, SwapLibrary.pairFor(factory, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(WOKT).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWOKT(WOKT).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    /**** mix swap  ****/

    function externalSwap(
        address fromToken,
        address toToken,
        address approveTarget,
        address swapTarget,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        bytes memory callDataConcat,
        uint256 deadLine
    )
    external
    override
    payable
    ensure(deadLine)
    returns (uint256 returnAmount)
    {
        require(minReturnAmount > 0, "SwapRouter: RETURN_AMOUNT_ZERO");

        uint256 toTokenOriginBalance = TransferHelper.universalBalanceOf(toToken, msg.sender);
        if (!TransferHelper.isETH(fromToken)) {
            TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromTokenAmount);

            TransferHelper.universalApproveMax(fromToken, approveTarget, fromTokenAmount);
        }

        require(isWhiteListed[swapTarget], "SwapRouter: Not Whitelist Contract");
        (bool success, ) = swapTarget.call{value: TransferHelper.isETH(fromToken) ? msg.value : 0}(callDataConcat);

        require(success, "SwapRouter: External Swap execution Failed");

        TransferHelper.universalTransfer(
            toToken, msg.sender, TransferHelper.universalBalanceOf(toToken, address(this))
        );

        returnAmount = TransferHelper.universalBalanceOf(toToken, msg.sender).sub(toTokenOriginBalance);
        require(returnAmount >= minReturnAmount, "SwapRouter: Return amount is not enough");

        emit ExSwap(fromToken, toToken, msg.sender, fromTokenAmount, returnAmount);
    }

    function mixSwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory mixAdapters,
        address[] memory mixPairs,
        address[] memory assetTo,
        uint256 directions,
        uint256 deadLine
    ) external override payable ensure(deadLine) returns (uint256 returnAmount) {
        require(mixPairs.length > 0, "SwapRouter: PAIRS_EMPTY");
        require(mixPairs.length == mixAdapters.length, "SwapRouter: PAIR_ADAPTER_NOT_MATCH");
        require(mixPairs.length == assetTo.length - 1, "SwapRouter: PAIR_ASSETTO_NOT_MATCH");
        require(minReturnAmount > 0, "SwapRouter: RETURN_AMOUNT_ZERO");

        address _fromToken = fromToken;
        address _toToken = toToken;
        uint256 _fromTokenAmount = fromTokenAmount;

        uint256 toTokenOriginBalance = TransferHelper.universalBalanceOf(_toToken, msg.sender);

        _deposit(msg.sender, assetTo[0], _fromToken, _fromTokenAmount, TransferHelper.isETH(_fromToken));

        for (uint256 i = 0; i < mixPairs.length; i++) {
            if (directions & 1 == 0) {
                ISwapAdapter(mixAdapters[i]).sellBase(assetTo[i + 1], mixPairs[i], "");
            } else {
                ISwapAdapter(mixAdapters[i]).sellQuote(assetTo[i + 1], mixPairs[i], "");
            }
            directions = directions >> 1;
        }

        if(TransferHelper.isETH(_toToken)) {
            returnAmount = IWOKT(WOKT).balanceOf(address(this));
            IWOKT(WOKT).withdraw(returnAmount);
            msg.sender.transfer(returnAmount);
        } else {
            returnAmount = TransferHelper.tokenBalanceOf(_toToken, msg.sender).sub(toTokenOriginBalance);
        }

        require(returnAmount >= minReturnAmount, "SwapRouter: Return amount is not enough");

        emit ExSwap(fromToken, toToken, msg.sender, _fromTokenAmount, returnAmount);
    }

    function polySwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint[] memory weights,
        address[] memory adapters,
        address[] memory pools,
        uint256 directions,
        uint256 deadLine
    ) external payable override ensure(deadLine) returns (uint256 returnAmount) {
        require(pools.length == adapters.length, 'SwapRouter: POOL_ADAPTER_NOT_MATCH');
        require(minReturnAmount > 0, "SwapRouter: RETURN_AMOUNT_ZERO");

        uint256 _fromTokenAmount = fromTokenAmount;
        uint256 toTokenOriginBalance = TransferHelper.universalBalanceOf(toToken, msg.sender);
        address _fromToken = fromToken;

        _deposit(msg.sender, address(this), _fromToken, _fromTokenAmount, TransferHelper.isETH(_fromToken));

        address midTo = msg.sender;
        if (TransferHelper.isETH(_fromToken)) {
            midTo = address(this);
        }

        address _toToken = toToken;
        address[] memory _adapters = adapters;
        uint[] memory _weights = weights;
        address[] memory _pools = pools;
        for(uint256 i = 0; i < _adapters.length; i++) {
            uint256 curAmount = _fromTokenAmount.mul(uint256(_weights[i])).div(100);
            IERC20(_fromToken).transfer(_pools[i], curAmount);

            if (directions & 1 == 0) {
                ISwapAdapter(_adapters[i]).sellBase(midTo, _pools[i], "");
            } else {
                ISwapAdapter(_adapters[i]).sellQuote(midTo, _pools[i], "");
            }
            directions = directions >> 1;
        }

        if(TransferHelper.isETH(_toToken)) {
            returnAmount = IWOKT(WOKT).balanceOf(address(this));
            IWOKT(WOKT).withdraw(returnAmount);
            msg.sender.transfer(returnAmount);
        }else {
            returnAmount = TransferHelper.tokenBalanceOf(_toToken, msg.sender).sub(toTokenOriginBalance);
        }

        require(returnAmount >= minReturnAmount, "SwapRouter: Return amount is not enough");

        emit ExSwap(_fromToken, _toToken, msg.sender, _fromTokenAmount, returnAmount);
    }

    function _deposit(
        address from,
        address to,
        address token,
        uint256 amount,
        bool isETH
    ) internal {
        if (isETH) {
            if (amount > 0) {
                IWOKT(WOKT).deposit{value: amount}();
                if (to != address(this)) TransferHelper.safeTransfer(WOKT, to, amount);
            }
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return SwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return SwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return SwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return SwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return SwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ISwapPair.sol";

library SwapLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SwapLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"772d76e02b5a3aeeef00b07a18a744c893227f52ecb6e3d431da85a229ed6a1d" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ISwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "SwapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SwapLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "SwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "SwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "SwapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "SwapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function universalTransfer(
        address token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                safeTransfer(token, to, amount);
            }
        }
    }

    function universalApproveMax(
        address token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                safeApprove(token, to, 0);
            }
            safeApprove(token, to, uint256(-1));
        }
    }

    function universalBalanceOf(address token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return IERC20(token).balanceOf(who);
        }
    }

    function tokenBalanceOf(address token, address who) internal view returns (uint256) {
        return IERC20(token).balanceOf(who);
    }

    function isETH(address token) internal pure returns (bool) {
        return token == ETH_ADDRESS;
    }

    function getETH() internal pure returns (address) {
        return ETH_ADDRESS;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import './ISwapRouter01.sol';

interface ISwapRouter02 is ISwapRouter01 {
    function tradingPool() external pure returns (address);

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

    function externalSwap(
        address fromToken,
        address toToken,
        address approveTarget,
        address swapTarget,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        bytes memory callDataConcat,
        uint256 deadLine
    )
    external
    payable
    returns (uint256 returnAmount);

    function mixSwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory mixAdapters,
        address[] memory mixPairs,
        address[] memory assetTo,
        uint256 directions,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function polySwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint[] memory weights,
        address[] memory adapters,
        address[] memory pools,
        uint256 directions,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ISwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function feeToRate() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setFeeToRate(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWOKT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ISwapAdapter {

    function sellBase(address to, address pool, bytes memory data) external;

    function sellQuote(address to, address pool, bytes memory data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.5.0;

interface ISwapPair {
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
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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

    function price(address token, uint256 baseDecimal) external view returns (uint256);

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface ISwapRouter01 {
    function factory() external pure returns (address);

    function WOKT() external pure returns (address);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../interfaces/IDsgNft.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IWOKT.sol";
import "../libraries/TransferHelper.sol";

contract NftEarnErc20Pool is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 share; // How many powers the user has provided.
        uint256 rewardDebt; // Reward debt.
        EnumerableSet.UintSet nfts;
        uint slots; //Number of enabled card slots
        mapping(uint => uint256[]) slotNfts; //slotIndex:tokenIds
        uint256 accRewardAmount;
    }

    struct SlotView {
        uint index;
        uint256[] tokenIds;
    }

    struct PoolView {
        address dsgToken;
        uint8 dsgDecimals;
        address rewardToken;
        uint8 rewardDecimals;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 totalAmount;
        address nft;
        string nftSymbol;
    }

    uint constant MAX_LEVEL = 6;

    IERC20 public dsgToken;
    IERC20 public rewardToken;
    address vdsgTreasury;
    address public immutable WOKT;
    uint256 public rewardTokenPerBlock;

    IDsgNft public dsgNft; // Address of NFT token contract.

    uint256 public constant BONUS_MULTIPLIER = 1;

    mapping(address => UserInfo) private userInfo;
    EnumerableSet.AddressSet private _callers;

    uint256 public startBlock;
    uint256 public endBlock;

    uint256 lastRewardBlock; //Last block number that TOKENs distribution occurs.
    uint256 accRewardTokenPerShare; // Accumulated TOKENs per share, times 1e12. See below.
    uint256 accShare;
    uint256 public allocRewardAmount; //Total number of rewards to be claimed
    uint256 public accRewardAmount; //Total number of rewards


    uint256 public slotAdditionRate = 40000; //400%
    uint256 public enableSlotFee = 10000e18; //10000dsg

    event Stake(address indexed user, uint256 tokenId);
    event StakeWithSlot(address indexed user, uint slot, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256 tokenId);
    event EmergencyWithdraw(address indexed user, uint256 tokenId);
    event WithdrawSlot(address indexed user, uint slot);
    event EmergencyWithdrawSlot(address indexed user, uint slot);

    constructor(
        address _wokt,
        address _dsgToken,
        address _rewardToken,
        address _nftAddress,
        address _vdsgTreasury,
        uint256 _startBlock
    ) public {
        WOKT = _wokt;
        dsgToken = IERC20(_dsgToken);
        dsgNft = IDsgNft(_nftAddress);
        rewardToken = IERC20(_rewardToken);
        vdsgTreasury = _vdsgTreasury;
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
    public
    pure
    returns (uint256)
    {
        return _to.sub(_from);
    }

    function setEnableSlotFee(uint256 fee) public onlyOwner {
        enableSlotFee = fee;
    }

    function recharge(uint256 amount, uint256 rewardsBlocks) public onlyCaller {
        updatePool();

        uint256 oldBal = rewardToken.balanceOf(address(this));
        if(allocRewardAmount > oldBal) {
            allocRewardAmount = oldBal;
        }
        uint256 remainingBal = oldBal.sub(allocRewardAmount);
        if(remainingBal > 0 && rewardTokenPerBlock > 0) {
            uint256 remainingBlocks = remainingBal.div(rewardTokenPerBlock);
            rewardsBlocks = rewardsBlocks.add(remainingBlocks);
        }

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        rewardTokenPerBlock = rewardToken.balanceOf(address(this)).sub(allocRewardAmount).div(rewardsBlocks);
        if(block.number >= startBlock) {
            endBlock = block.number.add(rewardsBlocks);
        } else {
            endBlock = startBlock.add(rewardsBlocks);
        }
    }

    // View function to see pending STARs on frontend.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = accRewardTokenPerShare;
        uint256 blk = block.number;
        if(blk > endBlock) {
            blk = endBlock;
        }
        if (blk > lastRewardBlock && accShare != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, blk);
            uint256 tokenReward = multiplier.mul(rewardTokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(accShare)
            );
        }
        return user.share.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    function getPoolInfo() public view
    returns (
        uint256 accShare_,
        uint256 accRewardTokenPerShare_,
        uint256 rewardTokenPerBlock_
    )
    {
        accShare_ = accShare;
        accRewardTokenPerShare_ = accRewardTokenPerShare;
        rewardTokenPerBlock_ = rewardTokenPerBlock;
    }

    function getPoolView() public view returns(PoolView memory) {
        return PoolView({
            dsgToken: address(dsgToken),
            dsgDecimals: IERC20Metadata(address(dsgToken)).decimals(),
            rewardToken: address(rewardToken),
            rewardDecimals: IERC20Metadata(address(rewardToken)).decimals(),
            lastRewardBlock: lastRewardBlock,
            rewardsPerBlock: rewardTokenPerBlock,
            accRewardPerShare: accRewardTokenPerShare,
            allocRewardAmount: allocRewardAmount,
            accRewardAmount: accRewardAmount,
            totalAmount: dsgNft.balanceOf(address(this)),
            nft: address(dsgNft),
            nftSymbol: IERC721Metadata(address(dsgNft)).symbol()
        });
    }

    function updatePool() public {
        if(block.number < startBlock) {
            return;
        }

        uint256 blk = block.number;
        if(blk > endBlock) {
            blk = endBlock;
        }

        if (blk <= lastRewardBlock) {
            return;
        }

        if (accShare == 0) {
            lastRewardBlock = blk;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, blk);
        uint256 rewardTokenReward = multiplier.mul(rewardTokenPerBlock);
        accRewardTokenPerShare = accRewardTokenPerShare.add(
            rewardTokenReward.mul(1e12).div(accShare)
        );
        allocRewardAmount = allocRewardAmount.add(rewardTokenReward);
        accRewardAmount = accRewardAmount.add(rewardTokenReward);

        lastRewardBlock = blk;
    }

    function getUserInfo(address _user) public view
    returns (
        uint256 share,
        uint256 numNfts,
        uint slotNum,
        uint256 rewardDebt
    )
    {
        UserInfo storage user = userInfo[_user];
        share = user.share;
        numNfts = user.nfts.length();
        slotNum = user.slots;
        rewardDebt = user.rewardDebt;
    }

    function getFullUserInfo(address _user) public view
    returns (
        uint256 share,
        uint256[] memory nfts,
        uint slotNum,
        SlotView[] memory slots,
        uint256 accRewardAmount_,
        uint256 rewardDebt
    )
    {
        UserInfo storage user = userInfo[_user];
        share = user.share;
        nfts = getNfts(_user);
        slotNum = user.slots;
        slots = getSlotNfts(_user);
        rewardDebt = user.rewardDebt;
        accRewardAmount_ = user.accRewardAmount;
    }

    function getNfts(address _user) public view returns(uint256[] memory ids) {
        UserInfo storage user = userInfo[_user];
        uint256 len = user.nfts.length();

        uint256[] memory ret = new uint256[](len);
        for(uint256 i = 0; i < len; i++) {
            ret[i] = user.nfts.at(i);
        }
        return ret;
    }

    function getSlotNftsWithIndex(address _user, uint256 index) public view returns(uint256[] memory) {
        return userInfo[_user].slotNfts[index];
    }

    function getSlotNfts(address _user) public view returns(SlotView[] memory slots) {
        UserInfo memory user = userInfo[_user];
        if(user.slots == 0) {
            return slots;
        }
        slots = new SlotView[](user.slots);
        for(uint i = 0; i < slots.length; i++) {
            slots[i] = SlotView(i, getSlotNftsWithIndex(_user, i));
        }
    }

    function enableSlot() public {
        UserInfo storage user = userInfo[msg.sender];

        uint256 oldBal = dsgToken.balanceOf(address(this));
        dsgToken.safeTransferFrom(msg.sender, address(this), enableSlotFee);
        uint256 amount = dsgToken.balanceOf(address(this)).sub(oldBal);
        dsgToken.transfer(vdsgTreasury, amount);

        user.slots += 1;
    }

    function harvest() public {
        updatePool();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending =
        user.share.mul(accRewardTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeTokenTransfer(msg.sender, pending);

        allocRewardAmount = pending < allocRewardAmount? allocRewardAmount.sub(pending) : 0;
        user.accRewardAmount = user.accRewardAmount.add(pending);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
    }

    function withdraw(uint256 _tokenId) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.nfts.contains(_tokenId),
            "withdraw: not token onwer"
        );

        user.nfts.remove(_tokenId);

        harvest();

        uint256 power = getNftPower(_tokenId);
        accShare = accShare.sub(power);
        user.share = user.share.sub(power);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
        dsgNft.transferFrom(address(this), address(msg.sender), _tokenId);
        emit Withdraw(msg.sender, _tokenId);
    }

    function withdrawAll() public {
        uint256[] memory ids = getNfts(msg.sender);
        for(uint i = 0; i < ids.length; i++) {
            withdraw(ids[i]);
        }
    }

    function emergencyWithdraw(uint256 _tokenId) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.nfts.contains(_tokenId),
            "withdraw: not token onwer"
        );

        user.nfts.remove(_tokenId);

        dsgNft.transferFrom(address(this), address(msg.sender), _tokenId);
        emit EmergencyWithdraw(msg.sender, _tokenId);

        if(user.share <= accShare) {
            accShare = accShare.sub(user.share);
        } else {
            accShare = 0;
        }
        user.share = 0;
        user.rewardDebt = 0;
    }

    function withdrawSlot(uint slot) public {
        UserInfo storage user = userInfo[msg.sender];
        require(slot < user.slots, "slot not enabled");

        uint256[] memory tokenIds = user.slotNfts[slot];
        delete user.slotNfts[slot];

        harvest();

        uint256 totalPower;
        for(uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            LibPart.NftInfo memory info = dsgNft.getNft(tokenId);
            totalPower = totalPower.add(info.power);
            dsgNft.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        totalPower = totalPower.add(totalPower.mul(slotAdditionRate).div(10000));

        accShare = accShare.sub(totalPower);
        user.share = user.share.sub(totalPower);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
        emit WithdrawSlot(msg.sender, slot);
    }

    function emergencyWithdrawSlot(uint slot) public {
        UserInfo storage user = userInfo[msg.sender];
        require(slot < user.slots, "slot not enabled");

        uint256[] memory tokenIds = user.slotNfts[slot];
        delete user.slotNfts[slot];

        uint256 totalPower;
        for(uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            LibPart.NftInfo memory info = dsgNft.getNft(tokenId);
            totalPower = totalPower.add(info.power);
            dsgNft.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        totalPower = totalPower.add(totalPower.mul(slotAdditionRate).div(10000));

        if(user.share <= accShare) {
            accShare = accShare.sub(user.share);
        } else {
            accShare = 0;
        }
        user.share = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdrawSlot(msg.sender, slot);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            if (tokenBal > 0) {
                _amount = tokenBal;
            }
        }
        if(_amount>0) {
            if (address(rewardToken) == WOKT) {
                IWOKT(WOKT).withdraw(_amount);
                TransferHelper.safeTransferETH(_to, _amount);
            } else {
                rewardToken.transfer(_to, _amount);
            }
        }
    }

    function getNftPower(uint256 nftId) public view returns (uint256) {
        uint256 power = dsgNft.getPower(nftId);
        return power;
    }

    function stake(uint256 tokenId) public {
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        user.nfts.add(tokenId);

        dsgNft.safeTransferFrom(
            address(msg.sender),
            address(this),
            tokenId
        );

        if (user.share > 0) {
            harvest();
        }

        uint256 power = getNftPower(tokenId);
        user.share = user.share.add(power);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
        accShare = accShare.add(power);
        emit Stake(msg.sender, tokenId);
    }

    function batchStake(uint256[] memory tokenIds) public {
        for(uint i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i]);
        }
    }

    function slotStake(uint slot, uint256[] memory tokenIds) public {
        require(tokenIds.length == MAX_LEVEL, "token count not match");

        UserInfo storage user = userInfo[msg.sender];
        require(slot < user.slots, "slot not enabled");
        require(user.slotNfts[slot].length == 0, "slot already used");

        updatePool();

        uint256 totalPower;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            LibPart.NftInfo memory info = dsgNft.getNft(tokenId);
            require(info.level == i+1, "nft level not match");

            totalPower = totalPower.add(info.power);
            dsgNft.safeTransferFrom(msg.sender, address(this), tokenId);
        }
        user.slotNfts[slot] = tokenIds;

        if (user.share > 0) {
            harvest();
        }
        totalPower = totalPower.add(totalPower.mul(slotAdditionRate).div(10000));
        user.share = user.share.add(totalPower);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
        accShare = accShare.add(totalPower);
        emit StakeWithSlot(msg.sender, slot, tokenIds);
    }

    function slotReplace(uint slot, uint256[] memory newTokenIds) public {
        withdrawSlot(slot);
        slotStake(slot, newTokenIds);
    }

    function onERC721Received(
        address operator,
        address, //from
        uint256, //tokenId
        bytes calldata //data
    ) public override nonReentrant returns (bytes4) {
        require(
            operator == address(this),
            "received Nft from unauthenticated contract"
        );

        return
        bytes4(
            keccak256("onERC721Received(address,address,uint256,bytes)")
        );
    }

    function addCaller(address _newCaller) public onlyOwner returns (bool) {
        require(_newCaller != address(0), "NftEarnErc20Pool: address is zero");
        return EnumerableSet.add(_callers, _newCaller);
    }

    function delCaller(address _delCaller) public onlyOwner returns (bool) {
        require(_delCaller != address(0), "NftEarnErc20Pool: address is zero");
        return EnumerableSet.remove(_callers, _delCaller);
    }

    function getCallerLength() public view returns (uint256) {
        return EnumerableSet.length(_callers);
    }

    function isCaller(address _caller) public view returns (bool) {
        return EnumerableSet.contains(_callers, _caller);
    }

    function getCaller(uint256 _index) public view returns (address) {
        require(_index <= getCallerLength() - 1, "NftEarnErc20Pool: index out of bounds");
        return EnumerableSet.at(_callers, _index);
    }

    modifier onlyCaller() {
        require(isCaller(msg.sender), "NftEarnErc20Pool: not the caller");
        _;
    }

    receive() external payable {
        assert(msg.sender == WOKT); // only accept OKT via fallback from the WOKT contract
    }
}

// SPDX-License-Identifier: MIT

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/LibPart.sol";

interface IDsgNft is IERC721 {

    function mint(
        address to, string memory nftName, uint quality, uint256 power, string memory res, address author
    ) external returns(uint256 tokenId);

    function burn(uint256 tokenId) external;

    function getFeeToken() external view returns (address);

    function getNft(uint256 id) external view returns (LibPart.NftInfo memory);

    function getRoyalties(uint256 tokenId) external view returns (LibPart.Part[] memory);

    function sumRoyalties(uint256 tokenId) external view returns(uint256);

    function upgradeNft(uint256 nftId, uint256 materialNftId) external;

    function getPower(uint256 tokenId) external view returns (uint256);

    function getLevel(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20Metadata {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256('Part(address account,uint96 value)');

    struct Part {
        address payable account;
        uint96 value;
    }

    struct NftInfo {
        uint256 level;
        uint256 power;
        string name;
        string res;
        address author;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/LibPart.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IWOKT.sol";
import "../governance/InitializableOwner.sol";

interface Royalties {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRoyalties(uint256 id) external view returns (LibPart.Part[] memory);
}

contract NFTMarket is Context, IERC721Receiver, ReentrancyGuard, InitializableOwner {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct SalesObject {
        uint256 id;
        uint256 tokenId;
        uint256 startTime;
        uint256 durationTime;
        uint256 maxPrice;
        uint256 minPrice;
        uint256 finalPrice;
        uint8 status;
        address payable seller;
        address payable buyer;
        IERC721 nft;
    }

    event eveSales(
        uint256 indexed id, 
        uint256 indexed tokenId,
        address buyer, 
        address currency,
        uint256 finalPrice, 
        uint256 tipsFee,
        uint256 royaltiesAmount,
        uint256 timestamp
    );

    event eveNewSales(
        uint256 indexed id,
        uint256 indexed tokenId, 
        address seller, 
        address nft,
        address buyer, 
        address currency,
        uint256 startTime,
        uint256 durationTime,
        uint256 maxPrice, 
        uint256 minPrice,
        uint256 finalPrice
    );
    event eveCancelSales(
        uint256 indexed id,
        uint256 tokenId
    );
    event eveNFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);
    event eveSupportCurrency(
        address currency, 
        bool support
    );

    uint256 public _salesAmount = 0;

    SalesObject[] _salesObjects;

    uint256 public _minDurationTime = 5 minutes;
    
    address public WETH;

    mapping(address => bool) public _seller;
    mapping(address => bool) public _verifySeller;
    mapping(address => bool) public _supportNft;
    bool public _isStartUserSales;

    uint256 public _tipsFeeRate = 20;
    uint256 public _baseRate = 1000;
    address payable _tipsFeeWallet;
    mapping(address => bool) private _disabledRoyalties;

    mapping(uint256 => address) public _saleOnCurrency;
    mapping(address => bool) public _supportCurrency;
    
    constructor() public {

    }

    function initialize(address payable tipsFeeWallet, address weth) public {
        super._initialize();

        _tipsFeeRate = 50;
        _baseRate = 1000;
        _minDurationTime = 5 minutes;
        _tipsFeeWallet = tipsFeeWallet;
        WETH = weth;

        addSupportCurrency(TransferHelper.getETH());
    }

    /**
     * check address
     */
    modifier validAddress( address addr ) {
        require(addr != address(0));
        _;
    }

    modifier checkindex(uint index) {
        require(index < _salesObjects.length, "overflow");
        _;
    }

    modifier checkTime(uint index) {
        require(index < _salesObjects.length, "overflow");
        SalesObject storage obj = _salesObjects[index];
        require(obj.startTime <= block.timestamp, "!open");
        _;
    }

    modifier mustNotSellingOut(uint index) {
        require(index < _salesObjects.length, "overflow");
        SalesObject storage obj = _salesObjects[index];
        require(obj.buyer == address(0) && obj.status == 0, "sry, selling out");
        _;
    }

    modifier onlySalesOwner(uint index) {
        require(index < _salesObjects.length, "overflow");
        SalesObject storage obj = _salesObjects[index];
        require(obj.seller == msg.sender || msg.sender == owner(), "author & owner");
        _;
    }

    function seize(IERC20 asset) external returns (uint256 balance) {
        balance = asset.balanceOf(address(this));
        asset.safeTransfer(owner(), balance);
    }

    function updateDisabledRoyalties(address nft, bool val) public onlyOwner {
        _disabledRoyalties[nft] = val;
    }

    function addSupportNft(address nft) public onlyOwner validAddress(nft) {
        _supportNft[nft] = true;
    }

    function removeSupportNft(address nft) public onlyOwner validAddress(nft) {
        _supportNft[nft] = false;
    }

    function addSeller(address seller) public onlyOwner validAddress(seller) {
        _seller[seller] = true;
    }

    function removeSeller(address seller) public onlyOwner validAddress(seller) {
        _seller[seller] = false;
    }
    
    function addSupportCurrency(address erc20) public onlyOwner {
        require(_supportCurrency[erc20] == false, "the currency have support");
        _supportCurrency[erc20] = true;
        emit eveSupportCurrency(erc20, true);
    }

    function removeSupportCurrency(address erc20) public onlyOwner {
        require(_supportCurrency[erc20], "the currency can not remove");
        _supportCurrency[erc20] = false;
        emit eveSupportCurrency(erc20, false);
    }

    function addVerifySeller(address seller) public onlyOwner validAddress(seller) {
        _verifySeller[seller] = true;
    }

    function removeVerifySeller(address seller) public onlyOwner validAddress(seller) {
        _verifySeller[seller] = false;
    }

    function setIsStartUserSales(bool isStartUserSales) public onlyOwner {
        _isStartUserSales = isStartUserSales;
    }

    function setMinDurationTime(uint256 durationTime) public onlyOwner {
        _minDurationTime = durationTime;
    }

    function setTipsFeeWallet(address payable wallet) public onlyOwner {
        _tipsFeeWallet = wallet;
    }

    function getTipsFeeWallet() public view returns(address) {
        return address(_tipsFeeWallet);
    }

    function getSalesEndTime(uint index) 
        external
        view
        checkindex(index)
        returns (uint256) 
    {
        SalesObject storage obj = _salesObjects[index];
        return obj.startTime.add(obj.durationTime);
    }

    function getSales(uint index) external view checkindex(index) returns(SalesObject memory) {
        return _salesObjects[index];
    }
    
    function getSalesCurrency(uint index) public view returns(address) {
        return _saleOnCurrency[index];
    }

    function getSalesPrice(uint index)
        external
        view
        checkindex(index)
        returns (uint256)
    {
        SalesObject storage obj = _salesObjects[index];
        if(obj.buyer != address(0) || obj.status == 1) {
            return obj.finalPrice;
        } else {
            if(obj.startTime.add(obj.durationTime) < block.timestamp) {
                return obj.minPrice;
            } else if (obj.startTime >= block.timestamp) {
                return obj.maxPrice;
            } else {
                uint256 per = obj.maxPrice.sub(obj.minPrice).div(obj.durationTime);
                return obj.maxPrice.sub(block.timestamp.sub(obj.startTime).mul(per));
            }
        }
    }

    function setBaseRate(uint256 rate) external onlyOwner {
        _baseRate = rate;
    }

    function setTipsFeeRate(uint256 rate) external onlyOwner {
        _tipsFeeRate = rate;
    }

    function isVerifySeller(uint index) public view checkindex(index) returns(bool) {
        SalesObject storage obj = _salesObjects[index];
        return _verifySeller[obj.seller];
    }

    function cancelSales(uint index) external checkindex(index) onlySalesOwner(index) mustNotSellingOut(index) nonReentrant {
        SalesObject storage obj = _salesObjects[index];
        obj.status = 2;
        obj.nft.safeTransferFrom(address(this), obj.seller, obj.tokenId);

        emit eveCancelSales(index, obj.tokenId);
    }

    function startSales(uint256 tokenId,
                        uint256 maxPrice, 
                        uint256 minPrice,
                        uint256 startTime, 
                        uint256 durationTime,
                        address nft,
                        address currency)
        external 
        nonReentrant
        validAddress(nft)
        returns(uint)
    {
        require(tokenId != 0, "invalid token");
        require(startTime.add(durationTime) > block.timestamp, "invalid start time");
        require(durationTime >= _minDurationTime, "invalid duration");
        require(maxPrice >= minPrice, "invalid price");
        require(_isStartUserSales || _seller[msg.sender] == true || _supportNft[nft] == true, "cannot sales");
        require(_supportCurrency[currency] == true, "not support currency");

        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

        _salesAmount++;
        SalesObject memory obj;

        obj.id = _salesAmount;
        obj.tokenId = tokenId;
        obj.seller = payable(msg.sender);
        obj.nft = IERC721(nft);
        obj.startTime = startTime;
        obj.durationTime = durationTime;
        obj.maxPrice = maxPrice;
        obj.minPrice = minPrice;
        
        _saleOnCurrency[obj.id] = currency;
        
        if (_salesObjects.length == 0) {
            SalesObject memory zeroObj;
            zeroObj.status = 2;
            _salesObjects.push(zeroObj);    
        }

        _salesObjects.push(obj);
        
        uint256 tmpMaxPrice = maxPrice;
        uint256 tmpMinPrice = minPrice;
        emit eveNewSales(obj.id, tokenId, msg.sender, nft, address(0x0), currency, startTime, durationTime, tmpMaxPrice, tmpMinPrice, 0);
        return _salesAmount;
    }

    function buy(uint index)
        public
        nonReentrant
        mustNotSellingOut(index)
        checkTime(index)
        payable 
    {
        SalesObject storage obj = _salesObjects[index];
        require(obj.status == 0, "bad status");
        
        uint256 price = this.getSalesPrice(index);
        obj.status = 1;

        uint256 tipsFee = price.mul(_tipsFeeRate).div(_baseRate);
        uint256 purchase = price.sub(tipsFee);

        address currencyAddr = _saleOnCurrency[obj.id];
        if (currencyAddr == address(0)) {
            currencyAddr = TransferHelper.getETH();
        }

        uint256 royaltiesAmount;
        if(obj.nft.supportsInterface(bytes4(keccak256('getRoyalties(uint256)')))
            && _disabledRoyalties[address(obj.nft)] == false) {

            LibPart.Part[] memory fees = Royalties(address(obj.nft)).getRoyalties(obj.tokenId);
            for(uint i = 0; i < fees.length; i++) {
                uint256 feeValue = price.mul(fees[i].value).div(10000);
                if (purchase > feeValue) {
                    purchase = purchase.sub(feeValue);
                } else {
                    feeValue = purchase;
                    purchase = 0;
                }
                if (feeValue != 0) {
                    royaltiesAmount = royaltiesAmount.add(feeValue);
                    if(TransferHelper.isETH(currencyAddr)) {
                        TransferHelper.safeTransferETH(fees[i].account, feeValue);
                    } else {
                        IERC20(currencyAddr).safeTransferFrom(msg.sender, fees[i].account, feeValue);
                    }
                }
            }
        }

        if (TransferHelper.isETH(currencyAddr)) {
            require (msg.value >= this.getSalesPrice(index), "your price is too low");
            uint256 returnBack = msg.value.sub(price);
            if(returnBack > 0) {
                payable(msg.sender).transfer(returnBack);
            }
            if(tipsFee > 0) {
                IWOKT(WETH).deposit{value: tipsFee}();
                IWOKT(WETH).transfer(_tipsFeeWallet, tipsFee);
            }
            obj.seller.transfer(purchase);
        } else {
            IERC20(currencyAddr).safeTransferFrom(msg.sender, _tipsFeeWallet, tipsFee);
            IERC20(currencyAddr).safeTransferFrom(msg.sender, obj.seller, purchase);
        }

        obj.nft.safeTransferFrom(address(this), msg.sender, obj.tokenId);
        
        obj.buyer = payable(msg.sender);
        obj.finalPrice = price;

        // fire event
        emit eveSales(index, obj.tokenId, msg.sender, currencyAddr, price, tipsFee, royaltiesAmount, block.timestamp);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }

        //success
        emit eveNFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // fallback() external payable {
    //     revert();
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/proxy/Initializable.sol";

contract InitializableOwner is Initializable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    function _initialize() initializer internal {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../governance/InitializableOwner.sol";
import "../interfaces/IDsgNft.sol";
import "../interfaces/IFragmentToken.sol";
import "../libraries/Random.sol";


contract MysteryBox is ERC721, InitializableOwner {

    struct BoxFactory {
        uint256 id;
        string name;
        IDsgNft nft;
        uint256 limit; //0 unlimit
        uint256 minted;
        address currency;
        uint256 price;
        string resPrefix; // default res prefix
        address author;
        uint256 createdTime;
    }

    struct BoxView {
        uint256 id;
        uint256 factoryId;
        string name;
        address nft;
        uint256 limit; //0 unlimit
        uint256 minted;
        address author;
    }

    struct ResInfo {
        string name;
        string prefix; //If the resNumBegin = resNumEnd, resName will be resPrefix
        uint numBegin;
        uint numEnd;
    }

    event NewBoxFactory(
        uint256 indexed id,
        string name,
        address nft,
        uint256 limit,
        address author,
        address currency,
        uint256 price,
        uint256 createdTime
    );

    event OpenBox(uint256 indexed id, address indexed nft, uint256 boxId, uint256 tokenId);
    event Minted(uint256 indexed id, uint256 indexed factoryId, address to);

    uint256 private _boxFactoriesId = 0;
    uint256 private _boxId = 1e3;

    string private _baseURIVar;

    mapping(uint256 => uint256) private _boxes; // boxId: BoxFactoryId
    mapping(uint256 => BoxFactory) private _boxFactories; // factoryId: BoxFactory
    mapping(uint256 => mapping(uint256 => ResInfo)) private _res; // factoryId: {level: ResInfo}

    uint256[] private _levelBasePower = [1000, 2500, 6500, 14500, 35000, 90000];

    string private _name;
    string private _symbol;

    constructor() public ERC721("", "") {
    }

    function initialize(string memory uri) public {
        super._initialize();

        _levelBasePower = [1000, 2500, 6500, 14500, 35000, 90000];
        _boxId = 1e3;

        _baseURIVar = uri;

        _name = "DsgMysteryBox";
        _symbol = "DsgBox";
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseURIVar = uri;
    }

    function baseURI() public view override returns (string memory) {
        return _baseURIVar;
    }

    function addBoxFactory(
        string memory name_,
        IDsgNft nft,
        uint256 limit,
        address author,
        address currency,
        uint256 price,
        string memory resPrefix
    ) public onlyOwner returns (uint256) {
        _boxFactoriesId++;

        BoxFactory memory box;
        box.id = _boxFactoriesId;
        box.name = name_;
        box.nft = nft;
        box.limit = limit;
        box.author = author;
        box.currency = currency;
        box.price = price;
        box.resPrefix  = resPrefix;
        box.createdTime = block.timestamp;

        _boxFactories[_boxFactoriesId] = box;

        emit NewBoxFactory(
            _boxFactoriesId,
            name_,
            address(nft),
            limit,
            author,
            currency,
            price,
            block.timestamp
        );
        return _boxFactoriesId;
    }

    function setRes(
        uint256 factoryId, 
        uint256 level, 
        string memory nftName, 
        string memory prefix, 
        uint numBegin, 
        uint numEnd
    ) public onlyOwner {
        ResInfo storage res = _res[factoryId][level];
        res.name = nftName;
        res.prefix = prefix;
        res.numBegin = numBegin;
        res.numEnd = numEnd;
    }

    function getRes(uint256 factoryId, uint256 level) public view returns (ResInfo memory) {
        return _res[factoryId][level];
    }

    function mint(address to, uint256 factoryId, uint256 amount) public onlyOwner {
        BoxFactory storage box = _boxFactories[factoryId];
        require(address(box.nft) != address(0), "box not found");
        
        if(box.limit > 0) {
            require(box.limit.sub(box.minted) >= amount, "Over the limit");
        }
        box.minted = box.minted.add(amount);

        for(uint i = 0; i < amount; i++) {
            _boxId++;
            _mint(to, _boxId);
            _boxes[_boxId] = factoryId;
            emit Minted(_boxId, factoryId, to);
        }
    }

    function buy(uint256 factoryId, uint256 amount) public {
        BoxFactory storage box = _boxFactories[factoryId];
        require(address(box.nft) != address(0), "box not found");

        if(box.limit > 0) {
            require(box.limit.sub(box.minted) >= amount, "Over the limit");
        }
        box.minted = box.minted.add(amount);

        uint256 price = box.price.mul(amount);
        require(IFragmentToken(box.currency).transferFrom(msg.sender, address(this), price), "transfer error");
        IFragmentToken(box.currency).burn(price);

        for(uint i = 0; i < amount; i++) {
            _boxId++;
            _mint(msg.sender, _boxId);
            _boxes[_boxId] = factoryId;
            emit Minted(_boxId, factoryId, msg.sender);
        }
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "caller is not the box owner");

        delete _boxes[tokenId];
        _burn(tokenId);
    }

    function getFactory(uint256 factoryId) public view
    returns (BoxFactory memory)
    {
        return _boxFactories[factoryId];
    }

    function getBox(uint256 boxId)
    public
    view
    returns (BoxView memory)
    {
        uint256 factoryId = _boxes[boxId];
        BoxFactory memory factory = _boxFactories[factoryId];

        return BoxView({
            id: boxId,
            factoryId: factoryId,
            name: factory.name,
            nft: address(factory.nft),
            limit: factory.limit,
            minted: factory.minted,
            author: factory.author
        });
    }

    // 81.92 12.23 3.5 1.5 0.6 0.25
    function getLevel(uint256 seed) internal pure returns(uint256) {
        uint256 val = seed / 8897 % 10000;
        if(val <= 8192) {
            return 1;
        } else if (val < 9415) {
            return 2;
        } else if (val < 9765) {
            return 3;
        } else if (val < 9915) {
            return 4;
        } else if (val < 9975) {
            return 5;
        }
        return 6;
    }

    function randomPower(uint256 level, uint256 seed ) internal view returns(uint256) {
        if (level == 1) {
            return _levelBasePower[0] + seed % 200;
        } else if (level == 2) {
            return _levelBasePower[1] + seed % 500;
        } else if (level == 3) {
            return _levelBasePower[2] + seed % 500;
        } else if (level == 4) {
            return _levelBasePower[3] + seed % 500;
        } else if (level == 5) {
            return _levelBasePower[4] + seed % 5000;
        }

        return _levelBasePower[5] + seed % 10000;
    }

    function randomRes(uint256 seed, uint256 level, BoxFactory memory factory) 
    internal view returns(string memory resName, string memory nftName) {
        string memory prefix = factory.resPrefix;
        uint numBegin = 1;
        uint numEnd = 1;

        {
            ResInfo storage res = _res[factory.id][level];
            if (bytes(res.prefix).length > 0) {
                prefix = res.prefix;
                numBegin = res.numBegin;
                numEnd = res.numEnd;
                nftName = res.name;
            }
        }

        uint256 num = uint256(numEnd.sub(numBegin));
        
        num = (seed / 3211 % (num+1)).add(uint256(numBegin));
        resName = string(abi.encodePacked(prefix, num.toString()));
    }

    function openBox(uint256 boxId) public {
        require(isContract(msg.sender) == false && tx.origin == msg.sender, "Prohibit contract calls");

        uint256 factoryId = _boxes[boxId];
        BoxFactory memory factory = _boxFactories[factoryId];
        burn(boxId);

        uint256 seed = Random.computerSeed();

        uint256 level = getLevel(seed);
        uint256 power = randomPower(level, seed);
        
        (string memory resName, string memory nftName) = randomRes(seed, level, factory);

        uint256 tokenId = factory.nft.mint(_msgSender(), nftName, level, power, resName, factory.author);

        emit OpenBox(boxId, address(factory.nft), boxId, tokenId);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFragmentToken is IERC20 {
    function decimals() external view returns (uint8);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";


library Random {
    using SafeMath for uint256;

    function computerSeed() internal view returns (uint256) {
        uint256 seed =
        uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp)
                    .add(block.difficulty)
                    .add(
                        (
                        uint256(
                            keccak256(abi.encodePacked(block.coinbase))
                        )
                        ) / (block.timestamp)
                    )
                    .add(block.gaslimit)
                    .add(
                        (uint256(keccak256(abi.encodePacked(msg.sender)))) /
                        (block.timestamp)
                    )
                    .add(block.number)
                )
            )
        );
        return seed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../governance/InitializableOwner.sol";
import "../interfaces/IDsgNft.sol";
import "../libraries/LibPart.sol";
import "../libraries/Random.sol";


contract DsgNft is IDsgNft, ERC721, InitializableOwner, ReentrancyGuard, Pausable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;
    using Strings for uint256;
    
    event Minted(
        uint256 indexed id,
        address to,
        uint256 level,
        uint256 power,
        string name,
        string res,
        address author,
        uint256 timestamp
    );

    event Upgraded(
        uint256 indexed nft1Id,
        uint256 nft2Id,
        uint256 newNftId,
        uint256 newLevel,
        uint256 timestamp
    );

    event RoyaltiesUpdated(uint256 indexed nftId, uint256 oldRoyalties, uint256 newRoyalties);

    mapping(uint256=>LibPart.NftInfo) private _nfts;

    /*
     *     bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *     bytes4(keccak256('sumRoyalties(uint256)')) == 0x09b94e2a
     *
     *     => 0xbb3bafd6 ^ 0x09b94e2a == 0xb282e1fc
     */
    bytes4 private constant _INTERFACE_ID_GET_ROYALTIES = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xb282e1fc;

    uint256 private _tokenId ;

    uint256 public  maxLevel;

    string private _baseURIVar;

    IERC20 private _token;
    address public _feeWallet;

    uint256[] private _levelBasePower;
    uint256[] private _levelUpFee ;

    mapping(uint256 => LibPart.Part[])  private _royalties; //tokenId : LibPart.Part[]

    string private _name;
    string private _symbol;
    bool public canUpgrade;

    constructor() public ERC721("", "")
    {
        super._initialize();
    }
    
    function initialize(
        string memory name_,
        string memory symbol_,
        address feeToken,
        address feeWallet_,
        bool _canUpgrade,
        string memory baseURI_
    ) public onlyOwner{
        _tokenId = 1000;
        _levelBasePower = [1000, 2500, 6500, 14500, 35000, 90000];
        _levelUpFee = [0, 500e18, 1200e18, 2400e18, 4800e18, 9600e18];
        maxLevel = 6;


        _registerInterface(_INTERFACE_ID_GET_ROYALTIES);
        _registerInterface(_INTERFACE_ID_ROYALTIES);

        _name = name_;
        _symbol = symbol_;
        _token = IERC20(feeToken);
        _feeWallet = feeWallet_;
        _baseURIVar = baseURI_;
        canUpgrade = _canUpgrade;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseURIVar = uri;
    }

    function baseURI() public view override returns (string memory) {
        return _baseURIVar;
    }

    function setFeeWallet(address feeWallet_) public onlyOwner {
        _feeWallet = feeWallet_;
    }

    function setFeeToken(address token) public onlyOwner {
        _token = IERC20(token);
    }

    function getFeeToken() public view override returns (address) {
        return address(_token);
    }

    function setCanUpgrade(bool newVal) public onlyOwner {
        canUpgrade = newVal;
    }

    function getNft(uint256 id) public view override returns (LibPart.NftInfo memory) {
        return _nfts[id];
    }

    function setDefaultRoyalty(address payable account, uint96 value) public onlyOwner {
        uint256 old = sumRoyalties(0);

        if(_royalties[0].length > 0) {
            _royalties[0][0] = LibPart.Part(account, value);
        } else {
            _royalties[0].push(LibPart.Part(account, value));
        }
        
        emit RoyaltiesUpdated(0, old, sumRoyalties(0));
    }

    function getDefultRoyalty() public view returns(LibPart.Part memory part) {
        if(_royalties[0].length > 0) {
            part = _royalties[0][0];
        }
    }

    function getRoyalties(uint256 tokenId) public view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory ret = _royalties[tokenId];
        if (ret.length == 0) {
            return _royalties[0];
        }
        return ret;
    }

    function sumRoyalties(uint256 tokenId) public view override returns(uint256) {
        uint256 val;
        LibPart.Part[] memory parts = getRoyalties(tokenId);
        for(uint i = 0; i < parts.length; i++) {
            val += parts[i].value;
        }
        return val;
    }

    function updateRoyalties(uint256 tokenId, LibPart.Part[] memory parts) public {
        require(_nfts[tokenId].author == msg.sender, "not the author");

        uint256 old = sumRoyalties(tokenId);

        LibPart.Part[] storage np;
        for (uint i = 0; i < parts.length; i++) {
            np.push(parts[i]);
        }
        _royalties[tokenId] = np;

        emit RoyaltiesUpdated(tokenId, old, sumRoyalties(tokenId));
    }

    function updateRoyalty(uint256 tokenId, uint index, LibPart.Part memory newPart) public {
        require(_nfts[tokenId].author == msg.sender, "not the author");
        require(index < _royalties[tokenId].length, "bad index");

        uint256 old = sumRoyalties(tokenId);

        _royalties[tokenId][index] = newPart;

        emit RoyaltiesUpdated(tokenId, old, sumRoyalties(tokenId));
    }

    function addRoyalty(uint256 tokenId, LibPart.Part memory newPart) public {
        require(_nfts[tokenId].author == msg.sender, "not the author");

        uint256 old = sumRoyalties(tokenId);

        _royalties[tokenId].push(newPart);

        emit RoyaltiesUpdated(tokenId, old, sumRoyalties(tokenId));
    }

    function _doMint(
        address to, string memory nftName, uint256 level, uint256 power, string memory res, address author
    ) internal returns(uint256) {
        _tokenId++;
        if(bytes(nftName).length == 0) {
            nftName = name();
        }

        _mint(to, _tokenId);

        LibPart.NftInfo memory nft;
        nft.name = nftName;
        nft.level = level;
        nft.power = power;
        nft.res = res;
        nft.author = author;

        _nfts[_tokenId] = nft;

        emit Minted(_tokenId, to, level, power, nftName, res, author, block.timestamp);
        return _tokenId;
    }

    function mint(
        address to, string memory nftName, uint level, uint256 power, string memory res, address author
    ) public override onlyMinter nonReentrant returns(uint256 tokenId){
        tokenId = _doMint(to, nftName, level, power, res, author);
    }

    function burn(uint256 tokenId) public override {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "caller is not the token owner");

        _burn(tokenId);
    }

    function randomPower(uint256 level, uint256 seed ) internal view returns(uint256) {
        if (level == 1) {
            return _levelBasePower[0] + seed % 200;
        } else if (level == 2) {
            return _levelBasePower[1] + seed % 500;
        } else if (level == 3) {
            return _levelBasePower[2] + seed % 500;
        } else if (level == 4) {
            return _levelBasePower[3] + seed % 500;
        } else if (level == 5) {
            return _levelBasePower[4] + seed % 5000;
        }

        return _levelBasePower[5] + seed % 10000;
    }

    function getUpgradeFee(uint256 newLevel) public view returns (uint256) {
        return _levelUpFee[newLevel-1];
    }

    function upgradeNft(uint256 nftId, uint256 materialNftId) public override nonReentrant whenNotPaused
    {
        require(canUpgrade, "CANT UPGRADE");
        LibPart.NftInfo memory nft = getNft(nftId);
        LibPart.NftInfo memory materialNft = getNft(materialNftId);

        require(nft.level == materialNft.level, "The level must be the same");
        require(nft.level < maxLevel, "Has reached the max level");

        burn(nftId);
        burn(materialNftId);

        uint256 newLevel = nft.level + 1;
        uint256 fee = getUpgradeFee(newLevel);
        if (fee > 0) {
            _token.safeTransferFrom(_msgSender(), _feeWallet, fee);
        }

        uint256 seed = Random.computerSeed()/23;

        uint256 newId = _doMint(_msgSender(), nft.name, newLevel, randomPower(newLevel, seed), nft.res, nft.author);

        emit Upgraded(nftId, materialNftId, newId, newLevel, block.timestamp);
    }

    function getPower(uint256 tokenId) public view override returns (uint256) {
        return _nfts[tokenId].power;
    }

    function getLevel(uint256 tokenId) public view override returns (uint256) {
        return _nfts[tokenId].level;
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "Token: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "Token: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "Token: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../token/DSGToken.sol";
import "../interfaces/ISwapPair.sol";
import "../interfaces/IDsgNft.sol";
import "../interfaces/IERC20Metadata.sol";

contract LiquidityPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _pairs;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardPending; //Rewards that have been settled and pending
        uint256 accRewardAmount; // How many rewards the user has got.
        uint256 additionalNftId; //Nft used to increase revenue
        uint256 additionalRate; //nft additional rate of reward, base 10000
        uint256 additionalAmount; //nft additional amount of share
    }

    struct UserView {
        uint256 stakedAmount;
        uint256 unclaimedRewards;
        uint256 lpBalance;
        uint256 accRewardAmount;
        uint256 additionalNftId; //Nft used to increase revenue
        uint256 additionalRate; //nft additional rate of reward
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        address additionalNft; //Nft for users to increase share rate
        uint256 allocPoint; // How many allocation points assigned to this pool. reward tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that reward tokens distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward tokens per share, times 1e12.
        uint256 totalAmount; // Total amount of current pool deposit.
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 accDonateAmount;
    }

    struct PoolView {
        uint256 pid;
        address lpToken;
        address additionalNft;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 totalAmount;
        address token0;
        string symbol0;
        string name0;
        uint8 decimals0;
        address token1;
        string symbol1;
        string name1;
        uint8 decimals1;
    }

    // The reward token!
    DSGToken public rewardToken;
    // reward tokens created per block.
    uint256 public rewardTokenPerBlock;

    address public feeWallet;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // pid corresponding address
    mapping(address => uint256) public LpOfPid;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when token mining starts.
    uint256 public startBlock;
    uint256 public halvingPeriod = 3952800; // half year

    uint256[] public additionalRate = [0, 300, 400, 500, 600, 800, 1000]; //The share ratio that can be increased by each level of nft
    uint256 public nftSlotFee = 10e18; //Additional nft requires a card slot, enable the card slot requires fee

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Donate(address indexed user, uint256 pid, uint256 donateAmount, uint256 realAmount);
    event AdditionalNft(address indexed user, uint256 pid, uint256 nftId);

    constructor(
        DSGToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        address _feeWallet
    ) public {
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        feeWallet = _feeWallet;
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock)).div(halvingPeriod);
        }
        return 0;
    }

    function getRewardTokenPerBlock(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return rewardTokenPerBlock.div(2**_phase);
    }

    function getRewardTokenBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 lastRewardPhase = phase(_lastRewardBlock);
        uint256 currentPhase = phase(block.number);
        while (lastRewardPhase < currentPhase) {
            lastRewardPhase++;
            uint256 height = lastRewardPhase.mul(halvingPeriod).add(startBlock);
            blockReward = blockReward.add((height.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(height)));
            _lastRewardBlock = height;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(block.number)));
        return blockReward;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _additionalNft,
        bool _withUpdate
    ) public onlyOwner {
        require(_lpToken != address(0), "LiquidityPool: _lpToken is the zero address");
        require(ISwapPair(_lpToken).token0() != address(0), "not lp");

        require(!EnumerableSet.contains(_pairs, _lpToken), "LiquidityPool: _lpToken is already added to the pool");
        // return EnumerableSet.add(_pairs, _lpToken);
        EnumerableSet.add(_pairs, _lpToken);

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                additionalNft: _additionalNft,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                accDonateAmount: 0,
                totalAmount: 0,
                allocRewardAmount: 0,
                accRewardAmount: 0
            })
        );
        LpOfPid[_lpToken] = getPoolLength() - 1;
    }

    function setAdditionalNft(uint256 _pid, address _additionalNft) public onlyOwner {
        require(poolInfo[_pid].additionalNft == address(0), "already set");

        poolInfo[_pid].additionalNft = _additionalNft;
    }

    function getAdditionalRates() public view returns(uint256[] memory) {
        return additionalRate;
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);

        if (blockReward <= 0) {
            return;
        }

        uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);

        pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(pool.totalAmount));
        pool.allocRewardAmount = pool.allocRewardAmount.add(tokenReward);
        pool.accRewardAmount = pool.accRewardAmount.add(tokenReward);
        pool.lastRewardBlock = block.number;
    }

    function donate(uint256 donateAmount) public {
        uint256 oldBal = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), donateAmount);
        uint256 realAmount = IERC20(rewardToken).balanceOf(address(this)) - oldBal;

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);

            PoolInfo storage pool = poolInfo[pid];
            if(pool.allocPoint == 0) {
                continue;
            }
            require(pool.totalAmount > 0, "no lp staked");

            uint256 tokenReward = realAmount.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(pool.totalAmount));
            pool.allocRewardAmount = pool.allocRewardAmount.add(tokenReward);
            pool.accDonateAmount = pool.accDonateAmount.add(tokenReward);
        }

        emit Donate(msg.sender, 100000, donateAmount, realAmount);
    }

    function donateToPool(uint256 pid, uint256 donateAmount) public {
        updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        require(pool.allocPoint > 0, "pool closed");

        require(pool.totalAmount > 0, "no lp staked");

        uint256 oldBal = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), donateAmount);
        uint256 realAmount = IERC20(rewardToken).balanceOf(address(this)) - oldBal;

        pool.accRewardPerShare = pool.accRewardPerShare.add(realAmount.mul(1e12).div(pool.totalAmount));
        pool.allocRewardAmount = pool.allocRewardAmount.add(realAmount);
        pool.accDonateAmount = pool.accDonateAmount.add(realAmount);

        emit Donate(msg.sender, pid, donateAmount, realAmount);
    }

    function additionalNft(uint256 _pid, uint256 nftId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.additionalNftId == 0, "nft already set");
        updatePool(_pid);

        uint256 level = IDsgNft(pool.additionalNft).getLevel(nftId);
        require(level > 0, "no level");

        if(nftSlotFee > 0) {
            IERC20(rewardToken).safeTransferFrom(msg.sender, feeWallet, nftSlotFee);
        }

        IDsgNft(pool.additionalNft).safeTransferFrom(msg.sender, address(this), nftId);
        IDsgNft(pool.additionalNft).burn(nftId);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardPending = user.rewardPending.add(pending);
        }

        user.additionalNftId = nftId;
        user.additionalRate = additionalRate[level];
        
        user.additionalAmount = user.amount.mul(user.additionalRate).div(10000);
        pool.totalAmount = pool.totalAmount.add(user.additionalAmount);

        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
        emit AdditionalNft(msg.sender, _pid, nftId);
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        user.rewardPending = user.rewardPending.add(pending);

        if (_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
            if(user.additionalRate > 0) {
                uint256 _add = _amount.mul(user.additionalRate).div(10000);
                user.additionalAmount = user.additionalAmount.add(_add);
                pool.totalAmount = pool.totalAmount.add(_add);
            }
        }

        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function harvest(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        uint256 pendingAmount = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        pendingAmount = pendingAmount.add(user.rewardPending);
        user.rewardPending = 0;
        if (pendingAmount > 0) {
            safeRewardTokenTransfer(msg.sender, pendingAmount);
            user.accRewardAmount = user.accRewardAmount.add(pendingAmount);
            pool.allocRewardAmount = pool.allocRewardAmount.sub(pendingAmount);
        }

        // pool.totalAmount = pool.totalAmount.sub(user.additionalAmount);
        // user.additionalAmount = 0;
        // user.additionalRate = 0;
        // user.additionalNftId = 0;
        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
    }

    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid <= poolInfo.length - 1, "LiquidityPool: Can not find this pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        uint256 pending = 0;
        uint256 amount = user.amount.add(user.additionalAmount);
        if (amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);
                uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(tokenReward.mul(1e12).div(pool.totalAmount));
                pending = amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            } else if (block.number == pool.lastRewardBlock) {
                pending = amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        pending = pending.add(user.rewardPending);
        return pending;
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "LiquidityPool: withdraw not good");
        updatePool(_pid);

        harvest(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            IERC20(pool.lpToken).safeTransfer(msg.sender, _amount);
            
            pool.totalAmount = pool.totalAmount.sub(user.additionalAmount);
            user.additionalAmount = 0;
            user.additionalRate = 0;
            user.additionalNftId = 0;
        }
        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function harvestAll() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            harvest(i);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IERC20(pool.lpToken).safeTransfer(msg.sender, amount);
        pool.totalAmount = pool.totalAmount.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            IERC20(address(rewardToken)).safeTransfer(_to, rewardTokenBalance);
        } else {
            IERC20(address(rewardToken)).safeTransfer(_to, _amount);
        }
    }

    // Set the number of reward token produced by each block
    function setRewardTokenPerBlock(uint256 _newPerBlock) public onlyOwner {
        massUpdatePools();
        rewardTokenPerBlock = _newPerBlock;
    }

    function setHalvingPeriod(uint256 _block) public onlyOwner {
        halvingPeriod = _block;
    }

    function getPairsLength() public view returns (uint256) {
        return EnumerableSet.length(_pairs);
    }

    function getPairs(uint256 _index) public view returns (address) {
        require(_index <= getPairsLength() - 1, "LiquidityPool: index out of bounds");
        return EnumerableSet.at(_pairs, _index);
    }

    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getPoolView(uint256 pid) public view returns (PoolView memory) {
        require(pid < poolInfo.length, "LiquidityPool: pid out of range");
        PoolInfo memory pool = poolInfo[pid];
        address lpToken = pool.lpToken;
        IERC20 token0 = IERC20(ISwapPair(lpToken).token0());
        IERC20 token1 = IERC20(ISwapPair(lpToken).token1());
        string memory symbol0 = IERC20Metadata(address(token0)).symbol();
        string memory name0 = IERC20Metadata(address(token0)).name();
        uint8 decimals0 = IERC20Metadata(address(token0)).decimals();
        string memory symbol1 = IERC20Metadata(address(token1)).symbol();
        string memory name1 = IERC20Metadata(address(token1)).name();
        uint8 decimals1 = IERC20Metadata(address(token1)).decimals();
        uint256 rewardsPerBlock = pool.allocPoint.mul(rewardTokenPerBlock).div(totalAllocPoint);
        return
            PoolView({
                pid: pid,
                lpToken: lpToken,
                additionalNft: pool.additionalNft,
                allocPoint: pool.allocPoint,
                lastRewardBlock: pool.lastRewardBlock,
                accRewardPerShare: pool.accRewardPerShare,
                rewardsPerBlock: rewardsPerBlock,
                allocRewardAmount: pool.allocRewardAmount,
                accRewardAmount: pool.accRewardAmount,
                totalAmount: pool.totalAmount,
                token0: address(token0),
                symbol0: symbol0,
                name0: name0,
                decimals0: decimals0,
                token1: address(token1),
                symbol1: symbol1,
                name1: name1,
                decimals1: decimals1
            });
    }

    function getPoolViewByAddress(address lpToken) public view returns (PoolView memory) {
        uint256 pid = LpOfPid[lpToken];
        return getPoolView(pid);
    }

    function getAllPoolViews() external view returns (PoolView[] memory) {
        PoolView[] memory views = new PoolView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            views[i] = getPoolView(i);
        }
        return views;
    }

    function getUserView(address lpToken, address account) public view returns (UserView memory) {
        uint256 pid = LpOfPid[lpToken];
        UserInfo memory user = userInfo[pid][account];
        uint256 unclaimedRewards = pendingRewards(pid, account);
        uint256 lpBalance = ERC20(lpToken).balanceOf(account);
        return
            UserView({
                stakedAmount: user.amount,
                unclaimedRewards: unclaimedRewards,
                lpBalance: lpBalance,
                accRewardAmount: user.accRewardAmount,
                additionalNftId: user.additionalNftId,
                additionalRate: user.additionalRate
            });
    }

    function getUserViews(address account) external view returns (UserView[] memory) {
        address lpToken;
        UserView[] memory views = new UserView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            lpToken = address(poolInfo[i].lpToken);
            views[i] = getUserView(lpToken, account);
        }
        return views;
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./DelegateERC20.sol";

contract DSGToken is DelegateERC20, Ownable {

    event AddWhiteList(address user);
    event RemoveWhiteList(address user);

    uint256 public teamRate = 990;
    address public teamWallet;
    address public feeWallet;

    uint256 public vTokenFeeRate = 2;
    uint256 public burnRate = 3;

    mapping(address => bool) _whiteList;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    constructor(address _teamWallet) public ERC20("Dinosaur Eggs Token", "DSG") {
        teamWallet = _teamWallet;
        _mint(msg.sender, 20e18); //for init pool
    }

    function setTeamRate(uint256 rate) public onlyOwner {
        require(rate < 10000, "bad rate");
        teamRate = rate;
    }

    function setTeamWallet(address team) public onlyOwner {
        teamWallet = team;
    }

    function setFeeWallet(address _feeWallet) public onlyOwner {
        feeWallet = _feeWallet;
    }

    function setVTokenFeeRate(uint256 rate) public onlyOwner {
        require(rate < 100, "bad num");

        vTokenFeeRate = rate;
    }

    function setBurnRate(uint256 rate) public onlyOwner {
        require(rate < 100, "bad num");

        burnRate = rate;
    }

    function addWhiteList(address user) public onlyOwner {
        _whiteList[user] = true;

        emit AddWhiteList(user);
    }

    function removeWhiteList(address user) public onlyOwner {
        delete _whiteList[user];

        emit RemoveWhiteList(user);
    }

    function isWhiteList(address user) public view returns(bool) {
        return _whiteList[user];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 _amount = amount;
        if(_whiteList[sender] == false && _whiteList[recipient] == false && recipient != address(0)) {
            if(vTokenFeeRate > 0) {
                uint256 fee = _amount.mul(vTokenFeeRate).div(10000);
                amount = amount.sub(fee);
                super._transfer(sender, feeWallet, fee);
            }

            if(burnRate > 0) {
                uint256 burn = _amount.mul(burnRate).div(10000);
                amount = amount.sub(burn);
                _burn(sender, burn);
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        uint256 teamAmount;
        if (teamWallet != address(0) && teamRate > 0) {
            teamAmount = _amount.mul(teamRate).div(10000);
        }

        _mint(_to, _amount);

        if (teamAmount > 0) {
            _mint(teamWallet, teamAmount);
        }
        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "Token: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "Token: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "Token: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

abstract contract DelegateERC20 is ERC20 {
    // A record of each accounts delegate
    mapping(address => address) internal _delegates;
    uint256 public totalBurned;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegate_,uint256 nonce,uint256 expiry)");

    // A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    // support delegates mint
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);

        // add delegates to the minter
        _moveDelegates(address(0), _delegates[account], amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _moveDelegates(_delegates[account], address(0), amount);
        totalBurned += amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        super._transfer(sender, recipient, amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegate_`
     * @param delegate_ The address to delegate votes to
     */
    function delegate(address delegate_) external {
        return _delegate(msg.sender, delegate_);
    }

    /**
     * @notice Delegates votes from signatory to `delegate_`
     * @param delegate_ The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegate_,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator =
        keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegate_, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DSGToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DSGToken::delegateBySig: invalid nonce");
        require(now <= expiry, "DSGToken::delegateBySig: signature expired");
        return _delegate(signatory, delegate_);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "DSGToken::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegate_) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying balances (not scaled);
        _delegates[delegator] = delegate_;

        _moveDelegates(currentDelegate, delegate_, delegatorBalance);

        emit DelegateChanged(delegator, currentDelegate, delegate_);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegate_,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "DSGToken::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegate_][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegate_][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegate_][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegate_] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegate_, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return chainId;
    }

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./SinglePool.sol";
import "../interfaces/IERC20Metadata.sol";

contract SinglePoolFactory is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private pools;

    struct PoolView {
        address pool;
        address depositToken;
        address rewardsToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 totalAmount;
        uint256 startBlock;
        uint256 bonusEndBlock;
        string depositSymbol;
        string depositName;
        uint8 depositDecimals;
        string rewardsSymbol;
        string rewardsName;
        uint8 rewardsDecimals;
    }

    struct UserView {
        uint256 stakedAmount;
        uint256 unclaimedRewards;
        uint256 tokenBalance;
    }

    event NewPool(
        address pool, 
        address depositToken, 
        address rewardToken, 
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 bonusEndBlock
    );

    constructor() public {

    }

    function createPool(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock) public onlyOwner {
        
        SinglePool pool = new SinglePool(_depositToken, _rewardToken, _rewardPerBlock, _startBlock, _bonusEndBlock);
        pools.add(address(pool));

        emit NewPool(address(pool), address(_depositToken), address(_rewardToken), _rewardPerBlock, _startBlock, _bonusEndBlock);
    }

    function addPool(address pool) public onlyOwner {
        pools.add(pool);
    }

    function removePool(address pool) public onlyOwner {
        address owner = SinglePool(pool).owner();
        if(owner == address(this)) {
            SinglePool(pool).transferOwnership(msg.sender);
        }
        pools.remove(pool);
    }

    function getAllPoolViews() public view returns(PoolView[] memory){
        uint len = pools.length();
        PoolView[] memory views = new PoolView[](len);
        for (uint256 i = 0; i < len; i++) {
            views[i] = getPoolView(i);
        }
        return views;
    }

    function getPoolView(uint idx) public view returns(PoolView memory) {
        address pool = pools.at(idx);
        (IERC20 depositToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accRewardsPerShare) = SinglePool(pool).poolInfo(0);
        IERC20 rewardToken = SinglePool(pool).rewardToken();

        string memory depositSymbol = IERC20Metadata(address(depositToken)).symbol();
        string memory depositName = IERC20Metadata(address(depositToken)).name();
        uint8 depositDecimals = IERC20Metadata(address(depositToken)).decimals();

        string memory rewardSymbol = IERC20Metadata(address(rewardToken)).symbol();
        string memory rewardName = IERC20Metadata(address(rewardToken)).name();
        uint8 rewardDecimals = IERC20Metadata(address(rewardToken)).decimals();

        return
            PoolView({
                pool: pool,
                depositToken: address(depositToken),
                rewardsToken: address(rewardToken),
                allocPoint: allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: accRewardsPerShare,
                rewardsPerBlock: SinglePool(pool).rewardPerBlock(),
                totalAmount: SinglePool(pool).totalDeposit(),
                startBlock: SinglePool(pool).startBlock(),
                bonusEndBlock: SinglePool(pool).bonusEndBlock(),
                depositSymbol: depositSymbol,
                depositName: depositName,
                depositDecimals: depositDecimals,
                rewardsSymbol: rewardSymbol,
                rewardsName: rewardName,
                rewardsDecimals: rewardDecimals
            });
    }

    function getUserView(address pool, address account) public view returns (UserView memory) {
        (uint256 amount, ) = SinglePool(pool).userInfo(account);
        uint256 unclaimedRewards = SinglePool(pool).pendingReward(account);
        uint256 lpBalance = IERC20(SinglePool(pool).depositToken()).balanceOf(account);

        return
            UserView({
                stakedAmount: amount,
                unclaimedRewards: unclaimedRewards,
                tokenBalance: lpBalance
            });
    }

    function getUserViews(address account) external view returns (UserView[] memory) {
        address pool;
        uint len = pools.length();

        UserView[] memory views = new UserView[](len);
        for (uint256 i = 0; i < len; i++) {
            pool = pools.at(i);
            views[i] = getUserView(pool, account);
        }
        return views;
    }

    function stopReward(address pool) public onlyOwner {
        SinglePool(pool).stopReward();
    }

    function updateMultiplier(address pool, uint256 multiplierNumber) public onlyOwner {
        SinglePool(pool).updateMultiplier(multiplierNumber);
    }

    function emergencyRewardWithdraw(address pool, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(SinglePool(pool).rewardToken());
        uint256 oldAmount = token.balanceOf(address(this));
        SinglePool(pool).emergencyRewardWithdraw(_amount);
        uint256 amount = token.balanceOf(address(this)) - oldAmount;

        require(token.transfer(msg.sender, amount));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract SinglePool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Tokens distribution occurs.
        uint256 accRewardsPerShare; // Accumulated RewardTokens per share, times 1e18. See below.
    }

    IERC20 public depositToken;
    IERC20 public rewardToken;

    // uint256 public maxStaking;

    // tokens created per block.
    uint256 public rewardPerBlock;

    // Bonus muliplier for early makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total amount pledged by users
    uint256 public totalDeposit;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when mining starts.
    uint256 public startBlock;
    // The block number when mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        depositToken = _depositToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _depositToken,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accRewardsPerShare: 0
        }));

        totalAllocPoint = 1000;
        // maxStaking = 50000000000000000000;

    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER);
        }
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = totalDeposit;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardsPerShare = accRewardsPerShare.add(tokenReward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accRewardsPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalDeposit;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewardsPerShare = pool.accRewardsPerShare.add(tokenReward.mul(1e18).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Stake tokens to Pool
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        // require (_amount.add(user.amount) <= maxStaking, 'exceed max stake');

        updatePool(0);
        
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 bal = rewardToken.balanceOf(address(this));
                if(bal >= pending) {
                    rewardToken.safeTransfer(address(msg.sender), pending);
                } else {
                    rewardToken.safeTransfer(address(msg.sender), bal);
                }
            }
        }
        if(_amount > 0) {
            uint256 oldBal = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(oldBal);

            user.amount = user.amount.add(_amount);
            totalDeposit = totalDeposit.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
            uint256 bal = rewardToken.balanceOf(address(this));
            if(bal >= pending) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            } else {
                rewardToken.safeTransfer(address(msg.sender), bal);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalDeposit = totalDeposit.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e18);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        if(totalDeposit >= user.amount) {
            totalDeposit = totalDeposit.sub(user.amount);
        } else {
            totalDeposit = 0;
        }
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount <= rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/DecimalMath.sol";
import "../interfaces/IDsgToken.sol";

contract vDSGToken is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Storage(ERC20) ============

    string public name = "vDSG Membership Token";
    string public symbol = "vDSG";
    uint8 public decimals = 18;

    uint256 public _MIN_PENALTY_RATIO_ = 15 * 10**16; // 15%
    uint256 public _MAX_PENALTY_RATIO_ = 80 * 10**16; // 80%
    uint256 public _MIN_MINT_RATIO_ = 10 * 10**16; //10%
    uint256 public _MAX_MINT_RATIO_ = 80 * 10**16; //80%

    mapping(address => mapping(address => uint256)) internal _allowed;

    // ============ Storage ============

    address public _dsgToken;
    address public _dsgTeam;
    address public _dsgReserve;

    bool public _canTransfer;

    // staking reward parameters
    uint256 public _dsgPerBlock;
    uint256 public constant _superiorRatio = 10**17; // 0.1
    uint256 public constant _dsgRatio = 100; // 100
    uint256 public _dsgFeeBurnRatio = 30 * 10**16; //30%
    uint256 public _dsgFeeReserveRatio = 20 * 10**16; //20%

    // accounting
    uint112 public alpha = 10**18; // 1
    uint112 public _totalBlockDistribution;
    uint32 public _lastRewardBlock;

    uint256 public _totalBlockReward;
    uint256 public _totalStakingPower;
    mapping(address => UserInfo) public userInfo;
    
    uint256 public _superiorMinDSG = 1000e18; //The superior must obtain the min DSG that should be pledged for invitation rewards

    struct UserInfo {
        uint128 stakingPower;
        uint128 superiorSP;
        address superior;
        uint256 credit;
        uint256 creditDebt;
    }

    // ============ Events ============

    event MintVDSG(address user, address superior, uint256 mintDSG);
    event RedeemVDSG(address user, uint256 receiveDSG, uint256 burnDSG, uint256 feeDSG, uint256 reserveDSG);
    event DonateDSG(address user, uint256 donateDSG);
    event SetCanTransfer(bool allowed);

    event PreDeposit(uint256 dsgAmount);
    event ChangePerReward(uint256 dsgPerBlock);
    event UpdateDSGFeeBurnRatio(uint256 dsgFeeBurnRatio);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ============ Modifiers ============

    modifier canTransfer() {
        require(_canTransfer, "vDSGToken: not allowed transfer");
        _;
    }

    modifier balanceEnough(address account, uint256 amount) {
        require(availableBalanceOf(account) >= amount, "vDSGToken: available amount not enough");
        _;
    }

    // ============ Constructor ============

    constructor(
        address dsgToken,
        address dsgTeam,
        address dsgReserve
    ) public {
        _dsgToken = dsgToken;
        _dsgTeam = dsgTeam;
        _dsgReserve = dsgReserve;

        changePerReward(15*10**18);
    }

    // ============ Ownable Functions ============`

    function setCanTransfer(bool allowed) public onlyOwner {
        _canTransfer = allowed;
        emit SetCanTransfer(allowed);
    }

    function changePerReward(uint256 dsgPerBlock) public onlyOwner {
        _updateAlpha();
        _dsgPerBlock = dsgPerBlock;
        emit ChangePerReward(dsgPerBlock);
    }

    function updateDSGFeeBurnRatio(uint256 dsgFeeBurnRatio) public onlyOwner {
        _dsgFeeBurnRatio = dsgFeeBurnRatio;
        emit UpdateDSGFeeBurnRatio(_dsgFeeBurnRatio);
    }

    function updateDSGFeeReserveRatio(uint256 dsgFeeReserve) public onlyOwner {
        _dsgFeeReserveRatio = dsgFeeReserve;
    }

    function updateTeamAddress(address team) public onlyOwner {
        _dsgTeam = team;
    }

    function updateReserveAddress(address newAddress) public onlyOwner {
        _dsgReserve = newAddress;
    }
    
    function setSuperiorMinDSG(uint256 val) public onlyOwner {
        _superiorMinDSG = val;
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 dsgBalance = IERC20(_dsgToken).balanceOf(address(this));
        IERC20(_dsgToken).safeTransfer(owner(), dsgBalance);
    }

    // ============ Mint & Redeem & Donate ============

    function mint(uint256 dsgAmount, address superiorAddress) public {
        require(
            superiorAddress != address(0) && superiorAddress != msg.sender,
            "vDSGToken: Superior INVALID"
        );
        require(dsgAmount >= 1e18, "vDSGToken: must mint greater than 1");
        

        UserInfo storage user = userInfo[msg.sender];

        if (user.superior == address(0)) {
            require(
                superiorAddress == _dsgTeam || userInfo[superiorAddress].superior != address(0),
                "vDSGToken: INVALID_SUPERIOR_ADDRESS"
            );
            user.superior = superiorAddress;
        }
        
        if(_superiorMinDSG > 0) {
            uint256 curDSG = dsgBalanceOf(user.superior);
            if(curDSG < _superiorMinDSG) {
                user.superior = _dsgTeam;
            }
        }

        _updateAlpha();

        IERC20(_dsgToken).safeTransferFrom(msg.sender, address(this), dsgAmount);

        uint256 newStakingPower = DecimalMath.divFloor(dsgAmount, alpha);

        _mint(user, newStakingPower);

        emit MintVDSG(msg.sender, superiorAddress, dsgAmount);
    }

    function redeem(uint256 vDsgAmount, bool all) public balanceEnough(msg.sender, vDsgAmount) {
        _updateAlpha();
        UserInfo storage user = userInfo[msg.sender];

        uint256 dsgAmount;
        uint256 stakingPower;

        if (all) {
            stakingPower = uint256(user.stakingPower).sub(DecimalMath.divFloor(user.credit, alpha));
            dsgAmount = DecimalMath.mulFloor(stakingPower, alpha);
        } else {
            dsgAmount = vDsgAmount.mul(_dsgRatio);
            stakingPower = DecimalMath.divFloor(dsgAmount, alpha);
        }

        _redeem(user, stakingPower);

        (uint256 dsgReceive, uint256 burnDsgAmount, uint256 withdrawFeeAmount, uint256 reserveAmount) = getWithdrawResult(dsgAmount);

        IERC20(_dsgToken).safeTransfer(msg.sender, dsgReceive);

        if (burnDsgAmount > 0) {
            IDsgToken(_dsgToken).burn(burnDsgAmount);
        }
        if (reserveAmount > 0) {
            IERC20(_dsgToken).safeTransfer(_dsgReserve, reserveAmount);
        }

        if (withdrawFeeAmount > 0) {
            alpha = uint112(
                uint256(alpha).add(
                    DecimalMath.divFloor(withdrawFeeAmount, _totalStakingPower)
                )
            );
        }

        emit RedeemVDSG(msg.sender, dsgReceive, burnDsgAmount, withdrawFeeAmount, reserveAmount);
    }

    function donate(uint256 dsgAmount) public {

        IERC20(_dsgToken).safeTransferFrom(msg.sender, address(this), dsgAmount);

        alpha = uint112(
            uint256(alpha).add(DecimalMath.divFloor(dsgAmount, _totalStakingPower))
        );
        emit DonateDSG(msg.sender, dsgAmount);
    }

    // function preDepositedBlockReward(uint256 dsgAmount) public {

    //     IERC20(_dsgToken).safeTransferFrom(msg.sender, address(this), dsgAmount);

    //     _totalBlockReward = _totalBlockReward.add(dsgAmount);
    //     emit PreDeposit(dsgAmount);
    // }

    // ============ ERC20 Functions ============

    function totalSupply() public view returns (uint256 vDsgSupply) {
        uint256 totalDsg = IERC20(_dsgToken).balanceOf(address(this));
        (,uint256 curDistribution) = getLatestAlpha();
        
        uint256 actualDsg = totalDsg.add(curDistribution);
        vDsgSupply = actualDsg / _dsgRatio;
    }

    function balanceOf(address account) public view returns (uint256 vDsgAmount) {
        vDsgAmount = dsgBalanceOf(account) / _dsgRatio;
    }

    function transfer(address to, uint256 vDsgAmount) public returns (bool) {
        _updateAlpha();
        _transfer(msg.sender, to, vDsgAmount);
        return true;
    }

    function approve(address spender, uint256 vDsgAmount) canTransfer public returns (bool) {
        _allowed[msg.sender][spender] = vDsgAmount;
        emit Approval(msg.sender, spender, vDsgAmount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 vDsgAmount
    ) public returns (bool) {
        require(vDsgAmount <= _allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");
        _updateAlpha();
        _transfer(from, to, vDsgAmount);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(vDsgAmount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    // ============ Helper Functions ============

    function getLatestAlpha() public view returns (uint256 newAlpha, uint256 curDistribution) {
        if (_lastRewardBlock == 0) {
            curDistribution = 0;
        } else {
            curDistribution = _dsgPerBlock * (block.number - _lastRewardBlock);
        }
        if (_totalStakingPower > 0) {
            newAlpha = uint256(alpha).add(DecimalMath.divFloor(curDistribution, _totalStakingPower));
        } else {
            newAlpha = alpha;
        }
    }

    function availableBalanceOf(address account) public view returns (uint256 vDsgAmount) {
        vDsgAmount = balanceOf(account);
    }

    function dsgBalanceOf(address account) public view returns (uint256 dsgAmount) {
        UserInfo memory user = userInfo[account];
        (uint256 newAlpha,) = getLatestAlpha();
        uint256 nominalDsg =  DecimalMath.mulFloor(uint256(user.stakingPower), newAlpha);
        if(nominalDsg > user.credit) {
            dsgAmount = nominalDsg - user.credit;
        } else {
            dsgAmount = 0;
        }
    }

    function getWithdrawResult(uint256 dsgAmount)
    public
    view
    returns (
        uint256 dsgReceive,
        uint256 burnDsgAmount,
        uint256 withdrawFeeDsgAmount,
        uint256 reserveDsgAmount
    )
    {
        uint256 feeRatio = getDsgWithdrawFeeRatio();

        withdrawFeeDsgAmount = DecimalMath.mulFloor(dsgAmount, feeRatio);
        dsgReceive = dsgAmount.sub(withdrawFeeDsgAmount);

        burnDsgAmount = DecimalMath.mulFloor(withdrawFeeDsgAmount, _dsgFeeBurnRatio);
        reserveDsgAmount = DecimalMath.mulFloor(withdrawFeeDsgAmount, _dsgFeeReserveRatio);

        withdrawFeeDsgAmount = withdrawFeeDsgAmount.sub(burnDsgAmount);
        withdrawFeeDsgAmount = withdrawFeeDsgAmount.sub(reserveDsgAmount);
    }

    function getDsgWithdrawFeeRatio() public view returns (uint256 feeRatio) {
        uint256 dsgCirculationAmount = getCirculationSupply();

        uint256 x =
        DecimalMath.divCeil(
            totalSupply() * 100,
            dsgCirculationAmount
        );

        feeRatio = getRatioValue(x);
    }

    function setRatioValue(uint256 min, uint256 max) public onlyOwner {
        require(max > min, "bad num");

        _MIN_PENALTY_RATIO_ = min;
        _MAX_PENALTY_RATIO_ = max;
    }

    function setMintLimitRatio(uint256 min, uint256 max) public onlyOwner {
        require(max < 10**18, "bad max");
        require( (max - min)/10**16 > 0, "bad max - min");

        _MIN_MINT_RATIO_ = min;
        _MAX_MINT_RATIO_ = max;
    }

    function getRatioValue(uint256 input) public view returns (uint256) {

        // y = 15% (x < 0.1)
        // y = 5% (x > 0.5)
        // y = 0.175 - 0.25 * x

        if (input <= _MIN_MINT_RATIO_) {
            return _MAX_PENALTY_RATIO_;
        } else if (input >= _MAX_MINT_RATIO_) {
            return _MIN_PENALTY_RATIO_;
        } else {
            uint256 step = (_MAX_PENALTY_RATIO_ - _MIN_PENALTY_RATIO_) * 10 / ((_MAX_MINT_RATIO_ - _MIN_MINT_RATIO_) / 1e16);
            return _MAX_PENALTY_RATIO_ + step - DecimalMath.mulFloor(input, step*10);
        }
    }

    function getSuperior(address account) public view returns (address superior) {
        return userInfo[account].superior;
    }

    // ============ Internal Functions ============

    function _updateAlpha() internal {
        (uint256 newAlpha, uint256 curDistribution) = getLatestAlpha();
        uint256 newTotalDistribution = curDistribution.add(_totalBlockDistribution);
        require(newAlpha <= uint112(-1) && newTotalDistribution <= uint112(-1), "OVERFLOW");
        alpha = uint112(newAlpha);
        _totalBlockDistribution = uint112(newTotalDistribution);
        _lastRewardBlock = uint32(block.number);
        
        if( curDistribution > 0) {
            IDsgToken(_dsgToken).mint(address(this), curDistribution);
        
            _totalBlockReward = _totalBlockReward.add(curDistribution);
            emit PreDeposit(curDistribution);
        }
        
    }

    function _mint(UserInfo storage to, uint256 stakingPower) internal {
        require(stakingPower <= uint128(-1), "OVERFLOW");
        UserInfo storage superior = userInfo[to.superior];
        uint256 superiorIncreSP = DecimalMath.mulFloor(stakingPower, _superiorRatio);
        uint256 superiorIncreCredit = DecimalMath.mulFloor(superiorIncreSP, alpha);

        to.stakingPower = uint128(uint256(to.stakingPower).add(stakingPower));
        to.superiorSP = uint128(uint256(to.superiorSP).add(superiorIncreSP));

        superior.stakingPower = uint128(uint256(superior.stakingPower).add(superiorIncreSP));
        superior.credit = uint128(uint256(superior.credit).add(superiorIncreCredit));

        _totalStakingPower = _totalStakingPower.add(stakingPower).add(superiorIncreSP);
    }

    function _redeem(UserInfo storage from, uint256 stakingPower) internal {
        from.stakingPower = uint128(uint256(from.stakingPower).sub(stakingPower));

        uint256 userCreditSP = DecimalMath.divFloor(from.credit, alpha);
        if(from.stakingPower > userCreditSP) {
            from.stakingPower = uint128(uint256(from.stakingPower).sub(userCreditSP));
        } else {
            userCreditSP = from.stakingPower;
            from.stakingPower = 0;
        }
        from.creditDebt = from.creditDebt.add(from.credit);
        from.credit = 0;

        // superior decrease sp = min(stakingPower*0.1, from.superiorSP)
        uint256 superiorDecreSP = DecimalMath.mulFloor(stakingPower, _superiorRatio);
        superiorDecreSP = from.superiorSP <= superiorDecreSP ? from.superiorSP : superiorDecreSP;
        from.superiorSP = uint128(uint256(from.superiorSP).sub(superiorDecreSP));
        uint256 superiorDecreCredit = DecimalMath.mulFloor(superiorDecreSP, alpha);

        UserInfo storage superior = userInfo[from.superior];
        if(superiorDecreCredit > superior.creditDebt) {
            uint256 dec = DecimalMath.divFloor(superior.creditDebt, alpha);
            superiorDecreSP = dec >= superiorDecreSP ? 0 : superiorDecreSP.sub(dec);
            superiorDecreCredit = superiorDecreCredit.sub(superior.creditDebt);
            superior.creditDebt = 0;
        } else {
            superior.creditDebt = superior.creditDebt.sub(superiorDecreCredit);
            superiorDecreCredit = 0;
            superiorDecreSP = 0;
        }
        uint256 creditSP = DecimalMath.divFloor(superior.credit, alpha);

        if (superiorDecreSP >= creditSP) {
            superior.credit = 0;
            superior.stakingPower = uint128(uint256(superior.stakingPower).sub(creditSP));
        } else {
            superior.credit = uint128(
                uint256(superior.credit).sub(superiorDecreCredit)
            );
            superior.stakingPower = uint128(uint256(superior.stakingPower).sub(superiorDecreSP));
        }

        _totalStakingPower = _totalStakingPower.sub(stakingPower).sub(superiorDecreSP).sub(userCreditSP);
    }

    function _transfer(
        address from,
        address to,
        uint256 vDsgAmount
    ) internal canTransfer balanceEnough(from, vDsgAmount) {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(from != to, "transfer from same with to");

        uint256 stakingPower = DecimalMath.divFloor(vDsgAmount * _dsgRatio, alpha);

        UserInfo storage fromUser = userInfo[from];
        UserInfo storage toUser = userInfo[to];

        _redeem(fromUser, stakingPower);
        _mint(toUser, stakingPower);

        emit Transfer(from, to, vDsgAmount);
    }

     function getCirculationSupply() public view returns (uint256 supply) {
        supply = IERC20(_dsgToken).totalSupply();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MySafeMath {
    using SafeMath for uint256;

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a.div(b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}

library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return MySafeMath.divCeil(target.mul(d), 10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return MySafeMath.divCeil(target.mul(10**18), d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return MySafeMath.divCeil(uint256(10**36), target);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDsgToken is IERC20 {
    function decimals() external view returns (uint8);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IDsgToken.sol";
import "../libraries/SwapLibrary.sol";
import "../interfaces/ISwapRouter02.sol";

interface IvDsg {
    function donate(uint256 dsgAmount) external;
}

contract vDsgTreasury is Ownable {
    using SafeERC20 for IERC20;

    event Swap(address token0, address token1, uint256 amountIn, uint256 amountOut);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _callers;

    address public factory;
    address public vdsg;
    address public dsg;

    constructor(address _factory, address _dsg, address _vdsg) public {
        factory = _factory;
        dsg = _dsg;
        vdsg = _vdsg;
    }

    function sendToVDSG() external onlyCaller {
        uint256 _amount = IDsgToken(dsg).balanceOf(address(this));

        require(_amount > 0, "vDsgTreasury: amount exceeds balance");

        IDsgToken(dsg).approve(vdsg, _amount);
        IvDsg(vdsg).donate(_amount);
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) internal returns (uint256 amountOut) {
        address pair = SwapLibrary.pairFor(factory, _tokenIn, _tokenOut);
        (uint256 reserve0, uint256 reserve1, ) = ISwapPair(pair).getReserves();

        (uint256 reserveInput, uint256 reserveOutput) =
            _tokenIn == ISwapPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        amountOut = SwapLibrary.getAmountOut(_amountIn, reserveInput, reserveOutput);
        IERC20(_tokenIn).safeTransfer(pair, _amountIn);

        _tokenIn == ISwapPair(pair).token0()
            ? ISwapPair(pair).swap(0, amountOut, _to, new bytes(0))
            : ISwapPair(pair).swap(amountOut, 0, _to, new bytes(0));

        emit Swap(_tokenIn, _tokenOut, _amountIn, amountOut);
    }

    function anySwap(address _tokenIn, address _tokenOut, uint256 _amountIn) external onlyCaller {
        _swap(_tokenIn, _tokenOut, _amountIn, address(this));
    }

    function anySwapAll(address _tokenIn, address _tokenOut) public onlyCaller {
        uint256 _amountIn = IERC20(_tokenIn).balanceOf(address(this));
        if(_amountIn == 0) {
            return;
        }
        _swap(_tokenIn, _tokenOut, _amountIn, address(this));
    }

    function batchAnySwapAll(address[] memory _tokenIns, address[] memory _tokenOuts) public onlyCaller {
        require(_tokenIns.length == _tokenOuts.length, "lengths not match");
        for (uint i = 0; i < _tokenIns.length; i++) {
            anySwapAll(_tokenIns[i], _tokenOuts[i]);
        }
    }

    function emergencyWithdraw(address _token) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) > 0, "vDsgTreasury: insufficient contract balance");
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function addCaller(address _newCaller) public onlyOwner returns (bool) {
        require(_newCaller != address(0), "vDsgTreasury: address is zero");
        return EnumerableSet.add(_callers, _newCaller);
    }

    function delCaller(address _delCaller) public onlyOwner returns (bool) {
        require(_delCaller != address(0), "vDsgTreasury: address is zero");
        return EnumerableSet.remove(_callers, _delCaller);
    }

    function getCallerLength() public view returns (uint256) {
        return EnumerableSet.length(_callers);
    }

    function isCaller(address _caller) public view returns (bool) {
        return EnumerableSet.contains(_callers, _caller);
    }

    function getCaller(uint256 _index) public view returns (address) {
        require(_index <= getCallerLength() - 1, "vDsgTreasury: index out of bounds");
        return EnumerableSet.at(_callers, _index);
    }

    modifier onlyCaller() {
        require(isCaller(msg.sender), "vDsgTreasury: not the caller");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/SwapLibrary.sol";
import "../interfaces/ISwapRouter02.sol";
import "../interfaces/IDsgToken.sol";
import "../governance/InitializableOwner.sol";
import "../interfaces/IWOKT.sol";

interface INftEarnErc20Pool {
    function recharge(uint256 amount, uint256 rewardsBlocks) external;
}

interface ILiquidityPool {
    function donate(uint256 donateAmount) external;
    function donateToPool(uint256 pid, uint256 donateAmount) external;
}

contract Treasury is InitializableOwner {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _callers;
    EnumerableSet.AddressSet private _stableCoins; // all stable coins must has a pair with USDT

    address public factory;
    address public router;
    address public USDT;
    address public VAI;
    address public WETH;
    address public DSG;
    address public team;
    address public nftBonus;
    address public lpBonus;
    address public vDsgTreasury;
    address public emergencyAddress;

    uint256 constant BASE_RATIO = 1000;

    uint256 public constant lpBonusRatio = 333;
    uint256 public constant nftBonusRatio = 133;
    uint256 public constant dsgLpBonusRatio = 84;
    uint256 public constant vDsgBonusRatio = 84;
    uint256 public constant teamRatio = 200;

    uint256 public totalFee;

    uint256 public lpBonusAmount;
    uint256 public nftBonusAmount;
    uint256 public dsgLpBonusAmount;
    uint256 public vDsgBonusAmount;
    uint256 public totalDistributedFee;
    uint256 public totalBurnedDSG;
    uint256 public totalRepurchasedUSDT;

    struct PairInfo {
        uint256 count; // how many times the liquidity burned
        uint256 burnedLiquidity;
        address token0;
        address token1;
        uint256 amountOfToken0;
        uint256 amountOfToken1;
    }

    mapping(address => PairInfo) public pairs;

    event Burn(address pair, uint256 liquidity, uint256 amountA, uint256 amountB);
    event Swap(address token0, address token1, uint256 amountIn, uint256 amountOut);
    event Distribute(
        uint256 totalAmount,
        uint256 repurchasedAmount,
        uint256 teamAmount,
        uint256 nftBonusAmount,
        uint256 burnedAmount
    );
    event Repurchase(uint256 amountIn, uint256 burnedAmount);
    event NFTPoolTransfer(address nftBonus, uint256 amount);
    event RemoveAndSwapTo(address token0, address token1, address toToken, uint256 token0Amount, uint256 token1Amount);

    constructor() public {

    }

    function initialize (
        address _factory,
        address _router,
        address _usdt,
        address _vai,
        address _weth,
        address _dsg,
        address _vdsgTreasury,
        address _lpPool,
        address _nftPool,
        address _teamAddress
    ) public {
        super._initialize();

        factory = _factory;
        router = _router;
        USDT = _usdt;
        VAI = _vai;
        WETH = _weth;
        DSG = _dsg;
        vDsgTreasury = _vdsgTreasury;
        lpBonus = _lpPool;
        nftBonus = _nftPool;
        team = _teamAddress;
    }

    function setEmergencyAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Treasury: address is zero");
        emergencyAddress = _newAddress;
    }

    function setTeamAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Treasury: address is zero");
        team = _newAddress;
    }

    function setNftBonusAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Treasury: address is zero");
        nftBonus = _newAddress;
    }

    function setLpBonusAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Treasury: address is zero");
        lpBonus = _newAddress;
    }

    function setVDsgTreasuryAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Treasury: address is zero");
        vDsgTreasury = _newAddress;
    }

    function _removeLiquidity(address _token0, address _token1) internal returns (uint256 amount0, uint256 amount1) {
        address pair = SwapLibrary.pairFor(factory, _token0, _token1);
        uint256 liquidity = IERC20(pair).balanceOf(address(this));
        if(liquidity == 0) {
            return (0, 0);
        }

        (uint112 _reserve0, uint112 _reserve1, ) = ISwapPair(pair).getReserves();
        uint256 totalSupply = ISwapPair(pair).totalSupply();
        amount0 = liquidity.mul(_reserve0) / totalSupply;
        amount1 = liquidity.mul(_reserve1) / totalSupply;
        if (amount0 == 0 || amount1 == 0) {
            return (0, 0);
        }

        ISwapPair(pair).transfer(pair, liquidity);
        (amount0, amount1) = ISwapPair(pair).burn(address(this));

        pairs[pair].count += 1;
        pairs[pair].burnedLiquidity = pairs[pair].burnedLiquidity.add(liquidity);
        if (pairs[pair].token0 == address(0)) {
            pairs[pair].token0 = ISwapPair(pair).token0();
            pairs[pair].token1 = ISwapPair(pair).token1();
        }
        pairs[pair].amountOfToken0 = pairs[pair].amountOfToken0.add(amount0);
        pairs[pair].amountOfToken1 = pairs[pair].amountOfToken1.add(amount1);

        emit Burn(pair, liquidity, amount0, amount1);
    }

    // swap any token to stable token
    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) internal returns (uint256 amountOut) {
        address pair = SwapLibrary.pairFor(factory, _tokenIn, _tokenOut);
        (uint256 reserve0, uint256 reserve1, ) = ISwapPair(pair).getReserves();

        (uint256 reserveInput, uint256 reserveOutput) =
            _tokenIn == ISwapPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        amountOut = SwapLibrary.getAmountOut(_amountIn, reserveInput, reserveOutput);
        IERC20(_tokenIn).safeTransfer(pair, _amountIn);

        _tokenIn == ISwapPair(pair).token0()
            ? ISwapPair(pair).swap(0, amountOut, _to, new bytes(0))
            : ISwapPair(pair).swap(amountOut, 0, _to, new bytes(0));

        emit Swap(_tokenIn, _tokenOut, _amountIn, amountOut);
    }

    function anySwap(address _tokenIn, address _tokenOut, uint256 _amountIn) external onlyCaller {
        _swap(_tokenIn, _tokenOut, _amountIn, address(this));
    }

    function anySwapAll(address _tokenIn, address _tokenOut) public onlyCaller {
        uint256 _amountIn = IERC20(_tokenIn).balanceOf(address(this));
        if(_amountIn == 0) {
            return;
        }
        _swap(_tokenIn, _tokenOut, _amountIn, address(this));
    }

    function batchAnySwapAll(address[] memory _tokenIns, address[] memory _tokenOuts) public onlyCaller {
        require(_tokenIns.length == _tokenOuts.length, "lengths not match");
        for (uint i = 0; i < _tokenIns.length; i++) {
            anySwapAll(_tokenIns[i], _tokenOuts[i]);
        }
    }

    function removeAndSwapTo(address _token0, address _token1, address _toToken) public onlyCaller {
        (address token0, address token1) = SwapLibrary.sortTokens(_token0, _token1);
        (uint256 amount0, uint256 amount1) = _removeLiquidity(token0, token1);

        if (amount0 > 0 && token0 != _toToken) {
            _swap(token0, _toToken, amount0, address(this));
        }
        if (amount1 > 0 && token1 != _toToken) {
            _swap(token1, _toToken, amount1, address(this));
        }

        emit RemoveAndSwapTo(token0, token1, _toToken, amount0, amount1);
    }

    function batchRemoveAndSwapTo(address[] memory _token0s, address[] memory _token1s, address[] memory _toTokens) public onlyCaller {
        require(_token0s.length == _token1s.length, "lengths not match");
        require(_token1s.length == _toTokens.length, "lengths not match");
        
        for (uint i = 0; i < _token0s.length; i++) {
            removeAndSwapTo(_token0s[i], _token1s[i], _toTokens[i]);
        }
    }

    function swap(address _token0, address _token1) public onlyCaller {
        require(isStableCoin(_token0) || isStableCoin(_token1), "Treasury: must has a stable coin");

        (address token0, address token1) = SwapLibrary.sortTokens(_token0, _token1);
        (uint256 amount0, uint256 amount1) = _removeLiquidity(token0, token1);

        uint256 amountOut;
        if (isStableCoin(token0)) {
            amountOut = _swap(token1, token0, amount1, address(this));
            if (token0 != USDT) {
                amountOut = _swap(token0, USDT, amountOut.add(amount0), address(this));
            }
        } else {
            amountOut = _swap(token0, token1, amount0, address(this));
            if (token1 != USDT) {
                amountOut = _swap(token1, USDT, amountOut.add(amount1), address(this));
            }
        }

        totalFee = totalFee.add(amountOut);
    }

    function getRemaining() public view onlyCaller returns(uint256 remaining) {
        uint256 pending = lpBonusAmount.add(nftBonusAmount).add(dsgLpBonusAmount).add(vDsgBonusAmount);
        uint256 bal = IERC20(USDT).balanceOf(address(this));
        if (bal <= pending) {
            return 0;
        }
        remaining = bal.sub(pending);
    }

    function distribute(uint256 _amount) public onlyCaller {
        uint256 remaining = getRemaining();
        if (_amount == 0) {
            _amount = remaining;
        }
        require(_amount <= remaining, "Treasury: amount exceeds remaining of contract");

        uint256 curAmount = _amount;

        uint256 _lpBonusAmount =_amount.mul(lpBonusRatio).div(BASE_RATIO);
        curAmount = curAmount.sub(_lpBonusAmount);

        uint256 _nftBonusAmount = _amount.mul(nftBonusRatio).div(BASE_RATIO);
        curAmount = curAmount.sub(_nftBonusAmount);

        uint256 _dsgLpBonusAmount = _amount.mul(dsgLpBonusRatio).div(BASE_RATIO);
        curAmount = curAmount.sub(_dsgLpBonusAmount);

        uint256 _vDsgBonusAmount = _amount.mul(vDsgBonusRatio).div(BASE_RATIO);
        curAmount = curAmount.sub(_vDsgBonusAmount);

        uint256 _teamAmount = _amount.mul(teamRatio).div(BASE_RATIO);
        curAmount = curAmount.sub(_teamAmount);

        uint256 _repurchasedAmount = curAmount;
        uint256 _burnedAmount = repurchase(_repurchasedAmount);

        IERC20(USDT).safeTransfer(team, _teamAmount);

        lpBonusAmount = lpBonusAmount.add(_lpBonusAmount);
        nftBonusAmount = nftBonusAmount.add(_nftBonusAmount);
        dsgLpBonusAmount = dsgLpBonusAmount.add(_dsgLpBonusAmount);
        vDsgBonusAmount = vDsgBonusAmount.add(_vDsgBonusAmount);
        totalDistributedFee = totalDistributedFee.add(_amount);

        emit Distribute(_amount, _repurchasedAmount, _teamAmount, _nftBonusAmount, _burnedAmount);
    }

    function sendToLpPool(uint256 _amountUSD) public onlyCaller {
        require(_amountUSD <= lpBonusAmount, "Treasury: amount exceeds lp bonus amount");
        lpBonusAmount = lpBonusAmount.sub(_amountUSD);

        uint256 _amount = swapUSDToDSG(_amountUSD);
        IERC20(DSG).approve(lpBonus, _amount);
        ILiquidityPool(lpBonus).donate(_amount);
    }

    function sendToDSGLpPool(uint256 _amountUSD, uint256 pid) public onlyCaller {
        require(_amountUSD <= dsgLpBonusAmount, "Treasury: amount exceeds dsg lp bonus amount");
        dsgLpBonusAmount = dsgLpBonusAmount.sub(_amountUSD);

        uint256 _amount = swapUSDToDSG(_amountUSD);
        IERC20(DSG).approve(lpBonus, _amount);
        ILiquidityPool(lpBonus).donateToPool(pid, _amount);
    }

    function sendToNftPool(uint256 _amountUSD, uint256 _rewardsBlocks) public onlyCaller {
        require(_amountUSD <= nftBonusAmount, "Treasury: amount exceeds nft bonus amount");
        nftBonusAmount = nftBonusAmount.sub(_amountUSD);

        uint256 _amount = swapUSDToWETH(_amountUSD);

        IWOKT(WETH).approve(nftBonus, _amount);
        INftEarnErc20Pool(nftBonus).recharge(_amount, _rewardsBlocks);
        emit NFTPoolTransfer(nftBonus, _amount);
    }

    function sendToVDSG(uint256 _amountUSD) public onlyCaller {
        require(_amountUSD <= vDsgBonusAmount, "Treasury: amount exceeds vDsg bonus amount");
        vDsgBonusAmount = vDsgBonusAmount.sub(_amountUSD);

        uint256 _amount = swapUSDToDSG(_amountUSD);
        IERC20(DSG).transfer(vDsgTreasury, _amount);
    }

    function repurchase(uint256 _amountIn) internal returns (uint256 amountOut) {
        require(IERC20(USDT).balanceOf(address(this)) >= _amountIn, "Treasury: amount is less than USDT balance");

        amountOut = swapUSDToDSG(_amountIn);
        IDsgToken(DSG).burn(amountOut);

        totalRepurchasedUSDT = totalRepurchasedUSDT.add(_amountIn);
        totalBurnedDSG = totalBurnedDSG.add(amountOut);
    }

    function sendAll(uint256 _nftRewardsBlocks, uint256[] memory pids) external onlyCaller {
        if(lpBonusAmount>0) {
            sendToLpPool(lpBonusAmount);
        }
        
        if(vDsgBonusAmount > 0) {
            sendToVDSG(vDsgBonusAmount);
        }
        
        if (_nftRewardsBlocks > 0) {
            sendToNftPool(nftBonusAmount, _nftRewardsBlocks);
        }

        if(pids.length > 0 && dsgLpBonusAmount > 0) {
            uint256 amount = dsgLpBonusAmount.div(pids.length);
            for (uint i = 0; i < pids.length; i++) {
                sendToDSGLpPool(amount, pids[i]);
            }
        }
    }

    function emergencyWithdraw(address _token) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) > 0, "Treasury: insufficient contract balance");
        IERC20(_token).transfer(emergencyAddress, IERC20(_token).balanceOf(address(this)));
    }

    function swapUSDToDSG(uint256 _amountUSD) internal returns(uint256 amountOut) {
        uint256 balOld = IERC20(DSG).balanceOf(address(this));
        
        _swap(USDT, VAI, _amountUSD, address(this));
        uint256 amountVAI = IERC20(VAI).balanceOf(address(this));
        _swap(VAI, DSG, amountVAI, address(this));

        amountOut = IERC20(DSG).balanceOf(address(this)).sub(balOld);
    }

    function swapUSDToWETH(uint256 _amountUSD) internal returns(uint256 amountOut) {
        uint256 balOld = IERC20(WETH).balanceOf(address(this));
        _swap(USDT, WETH, _amountUSD, address(this));
        amountOut = IERC20(WETH).balanceOf(address(this)).sub(balOld);
    }

    function addCaller(address _newCaller) public onlyOwner returns (bool) {
        require(_newCaller != address(0), "Treasury: address is zero");
        return EnumerableSet.add(_callers, _newCaller);
    }

    function delCaller(address _delCaller) public onlyOwner returns (bool) {
        require(_delCaller != address(0), "Treasury: address is zero");
        return EnumerableSet.remove(_callers, _delCaller);
    }

    function getCallerLength() public view returns (uint256) {
        return EnumerableSet.length(_callers);
    }

    function isCaller(address _caller) public view returns (bool) {
        return EnumerableSet.contains(_callers, _caller);
    }

    function getCaller(uint256 _index) public view returns (address) {
        require(_index <= getCallerLength() - 1, "Treasury: index out of bounds");
        return EnumerableSet.at(_callers, _index);
    }

    function addStableCoin(address _token) public onlyOwner returns (bool) {
        require(_token != address(0), "Treasury: address is zero");
        return EnumerableSet.add(_stableCoins, _token);
    }

    function delStableCoin(address _token) public onlyOwner returns (bool) {
        require(_token != address(0), "Treasury: address is zero");
        return EnumerableSet.remove(_stableCoins, _token);
    }

    function getStableCoinLength() public view returns (uint256) {
        return EnumerableSet.length(_stableCoins);
    }

    function isStableCoin(address _token) public view returns (bool) {
        return EnumerableSet.contains(_stableCoins, _token);
    }

    function getStableCoin(uint256 _index) public view returns (address) {
        require(_index <= getStableCoinLength() - 1, "Treasury: index out of bounds");
        return EnumerableSet.at(_stableCoins, _index);
    }

    modifier onlyCaller() {
        require(isCaller(msg.sender), "Treasury: not the caller");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '../libraries/FixedPoint.sol';
import '../libraries/SwapOracleLibrary.sol';
import '../libraries/SwapLibrary.sol';
import '../interfaces/ISwapFactory.sol';
import '../interfaces/ISwapPair.sol';

interface IERC20p {
    function decimals() external view returns (uint8);
}

contract Oracle is Ownable {
    using FixedPoint for *;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _routerTokens; // all router token must has pair with anchor token

    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    struct BlockInfo {
        uint256 height;
        uint256 timestamp;
    }

    address public immutable factory;
    address public immutable anchorToken;
    uint256 public constant CYCLE = 30 minutes;
    BlockInfo public blockInfo;

    // mapping from pair address to a list of price observations of that pair
    mapping(address => Observation) public pairObservations;

    constructor(address _factory, address _anchorToken) public {
        factory = _factory;
        anchorToken = _anchorToken;
    }

    function update(address tokenA, address tokenB) external returns (bool) {
        address pair = SwapLibrary.pairFor(factory, tokenA, tokenB);
        if (pair == address(0)) return false;

        Observation storage observation = pairObservations[pair];
        uint256 timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed < CYCLE) return false;

        (uint256 price0Cumulative, uint256 price1Cumulative, ) = SwapOracleLibrary.currentCumulativePrices(pair);
        observation.timestamp = block.timestamp;
        observation.price0Cumulative = price0Cumulative;
        observation.price1Cumulative = price1Cumulative;
        return true;
    }

    function updateBlockInfo() external returns (bool) {
        if ((block.number - blockInfo.height) < 1000) return false;

        blockInfo.height = block.number;
        blockInfo.timestamp = 1000 * block.timestamp;
        return true;
    }

    function computeAmountOut(
        uint256 priceCumulativeStart,
        uint256 priceCumulativeEnd,
        uint256 timeElapsed,
        uint256 amountIn
    ) private pure returns (uint256 amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage =
            FixedPoint.uq112x112(uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed));
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    function consult(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) private view returns (uint256 amountOut) {
        address pair = SwapLibrary.pairFor(factory, tokenIn, tokenOut);
        if (pair == address(0)) return 0;

        Observation memory observation = pairObservations[pair];
        uint256 timeElapsed = block.timestamp - observation.timestamp;
        (uint256 price0Cumulative, uint256 price1Cumulative, ) = SwapOracleLibrary.currentCumulativePrices(pair);
        (address token0, ) = SwapLibrary.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }

    // used for trading pool to calculate quantity
    function getQuantity(address token, uint256 amount) public view returns (uint256 quantity) {
        uint256 decimal = IERC20p(token).decimals();
        if (token == anchorToken) {
            quantity = amount;
        } else {
            quantity = getAveragePrice(token).mul(amount).div(10**decimal);
        }
    }

    function getAveragePrice(address token) public view returns (uint256 price) {
        uint256 decimal = IERC20p(token).decimals();
        uint256 amount = 10**decimal;
        if (token == anchorToken) {
            price = amount;
        } else if (ISwapFactory(factory).getPair(token, anchorToken) != address(0)) {
            price = consult(token, amount, anchorToken);
        } else {
            uint256 length = getRouterTokenLength();
            for (uint256 index = 0; index < length; index++) {
                address intermediate = getRouterToken(index);
                if (
                    SwapLibrary.pairFor(factory, token, intermediate) != address(0) &&
                    SwapLibrary.pairFor(factory, intermediate, anchorToken) != address(0)
                ) {
                    uint256 interPrice = consult(token, amount, intermediate);
                    price = consult(intermediate, interPrice, anchorToken);
                    break;
                }
            }
        }
    }

    function getCurrentPrice(address token) public view returns (uint256 price) {
        uint256 anchorTokenDecimal = IERC20p(anchorToken).decimals();
        uint256 tokenDecimal = IERC20p(token).decimals();

        if (token == anchorToken) {
            price = 10**anchorTokenDecimal;
        } else if (SwapLibrary.pairFor(factory, token, anchorToken) != address(0)) {
            (uint256 reserve0, uint256 reserve1) = SwapLibrary.getReserves(factory, token, anchorToken);
            price = (10**tokenDecimal).mul(reserve1).div(reserve0);
        } else {
            uint256 length = getRouterTokenLength();
            for (uint256 index = 0; index < length; index++) {
                address intermediate = getRouterToken(index);
                if (
                    SwapLibrary.pairFor(factory, token, intermediate) != address(0) &&
                    SwapLibrary.pairFor(factory, intermediate, anchorToken) != address(0)
                ) {
                    (uint256 reserve0, uint256 reserve1) = SwapLibrary.getReserves(factory, token, intermediate);
                    uint256 amountOut = 10**tokenDecimal.mul(reserve1).div(reserve0);
                    (uint256 reserve2, uint256 reserve3) = SwapLibrary.getReserves(factory, intermediate, anchorToken);
                    price = amountOut.mul(reserve3).div(reserve2);
                    break;
                }
            }
        }
    }

    function getLpTokenValue(address _lpToken, uint256 _amount) public view returns (uint256 value) {
        uint256 totalSupply = IERC20(_lpToken).totalSupply();
        address token0 = ISwapPair(_lpToken).token0();
        address token1 = ISwapPair(_lpToken).token1();
        uint256 token0Decimal = IERC20p(token0).decimals();
        uint256 token1Decimal = IERC20p(token1).decimals();
        (uint256 reserve0, uint256 reserve1) = SwapLibrary.getReserves(factory, token0, token1);

        uint256 token0Value = (getAveragePrice(token0)).mul(reserve0).div(10**token0Decimal);
        uint256 token1Value = (getAveragePrice(token1)).mul(reserve1).div(10**token1Decimal);
        value = (token0Value.add(token1Value)).mul(_amount).div(totalSupply);
    }

    function getAverageBlockTime() public view returns (uint256) {
        return (1000 * block.timestamp - blockInfo.timestamp).div(block.number - blockInfo.height);
    }

    function addRouterToken(address _token) public onlyOwner returns (bool) {
        require(_token != address(0), 'Oracle: address is zero');
        return EnumerableSet.add(_routerTokens, _token);
    }

    function addRouterTokens(address[] memory tokens) public onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            addRouterToken(tokens[i]);
        }
    }

    function delRouterToken(address _token) public onlyOwner returns (bool) {
        require(_token != address(0), 'Oracle: address is zero');
        return EnumerableSet.remove(_routerTokens, _token);
    }

    function getRouterTokenLength() public view returns (uint256) {
        return EnumerableSet.length(_routerTokens);
    }

    function isRouterToken(address _token) public view returns (bool) {
        return EnumerableSet.contains(_routerTokens, _token);
    }

    function getRouterToken(uint256 _index) public view returns (address) {
        require(_index <= getRouterTokenLength() - 1, 'Oracle: index out of bounds');
        return EnumerableSet.at(_routerTokens, _index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), 'FixedPoint: MULTIPLICATION_OVERFLOW');
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import './FixedPoint.sol';
import '../interfaces/ISwapPair.sol';

library SwapOracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = ISwapPair(pair).price0CumulativeLast();
        price1Cumulative = ISwapPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = ISwapPair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISwapPair.sol";



contract Erc20EarnNftPool is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct Pool {
        address tokenAddress;
        bool isLpToken;
        uint256 stakeAmount;
        uint256 stakeTime;
        address nftAddress;
        uint256[] nftTokenIds;
        uint256 nftLeft;
    }
    Pool[] public pool;

    // pool id => user address => stake info list (start staking time)
    mapping (uint256 => mapping (address => uint256[])) public user;

    mapping (address => mapping (uint256 => bool)) public nftInContract;

    struct StakeView {
        uint pid;
        uint256 amount;
        uint256 beginTime;
        uint256 endTime;
        bool isCompleted;
    }

    struct PoolView {
        address tokenAddress;
        bool isLpToken;
        uint256 stakeAmount;
        uint256 stakeTime;
        address nftAddress;
        uint256[] nftTokenIds;
        uint256 nftLeft;
        address token0;
        string symbol0;
        string name0;
        uint8 decimals0;
        address token1;
        string symbol1;
        string name1;
        uint8 decimals1;
    }

    event AddPoolEvent(address indexed tokenAddress, uint256 indexed stakeAmount, uint256 stakeTime, address indexed nftAddress);
    event AddNftToPoolEvent(uint256 indexed pid, uint256[] tokenIds);
    event StakeEvent(uint256 indexed pid, address indexed user, uint256 beginTime);
    event ForceWithdrawEvent(uint256 indexed pid, address indexed user, uint256 indexed beginTime);
    event HarvestEvent(uint256 indexed pid, address indexed user, uint256 indexed tokenId);

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < pool.length, "pool does not exist");
        _;
    }

    constructor() public {

    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function addPool(address _tokenAddress, uint256 _stakeAmount, uint256 _stakeTime, address _nftAddress, bool isLp) external onlyOwner {
        require(_tokenAddress.isContract(), "stake token address should be smart contract address");
        require(_nftAddress.isContract(), "NFT address should be smart contract address");

        uint256[] memory tokenIds;

        if(isLp) {
            require(ISwapPair(_tokenAddress).token0() != address(0), "not lp");
        }

        pool.push(Pool({
            tokenAddress: _tokenAddress,
            isLpToken: isLp,
            stakeAmount: _stakeAmount,
            stakeTime: _stakeTime,
            nftAddress: _nftAddress,
            nftTokenIds: tokenIds,
            nftLeft: 0
        }));

        emit AddPoolEvent(_tokenAddress, _stakeAmount, _stakeTime, _nftAddress);
    }

    function addNftToPool(uint256 _pid, uint256[] memory _tokenIds) external onlyOwner validatePoolByPid(_pid) {
        IERC721 nft = IERC721(pool[_pid].nftAddress);
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(nft.ownerOf(tokenId) == address(this), "NFT is not owned by Stake contract");
            require(!nftInContract[pool[_pid].nftAddress][tokenId], "NFT already in Stake contract list");
            pool[_pid].nftTokenIds.push(tokenId);
            pool[_pid].nftLeft++;
            nftInContract[pool[_pid].nftAddress][tokenId] = true;
        }

        emit AddNftToPoolEvent(_pid, _tokenIds);
    }

    function getPool(uint256 _pid) external view validatePoolByPid(_pid) returns(Pool memory) {
        return pool[_pid];
    }

    function getAllPools() external view  returns(Pool[] memory) {
        return pool;
    }

    function getPoolView(uint256 _pid) public view validatePoolByPid(_pid) returns(PoolView memory poolView) {
        Pool memory p = pool[_pid];

        poolView = PoolView({
            tokenAddress: p.tokenAddress,
            isLpToken: p.isLpToken,
            stakeAmount: p.stakeAmount,
            stakeTime: p.stakeTime,
            nftAddress: p.nftAddress,
            nftTokenIds: p.nftTokenIds,
            nftLeft: p.nftLeft,
            token0: address(0),
            symbol0: "",
            name0: "",
            decimals0: 0,
            token1: address(0),
            symbol1: "",
            name1: "",
            decimals1: 0
        });

        if(p.isLpToken) {
            address lpToken = p.tokenAddress;
            ERC20 token0 = ERC20(ISwapPair(lpToken).token0());
            ERC20 token1 = ERC20(ISwapPair(lpToken).token1());
            poolView.token0 = address(token0);
            poolView.symbol0 = token0.symbol();
            poolView.name0 = token0.name();
            poolView.decimals0 = token0.decimals();
            poolView.token1 = address(token1);
            poolView.symbol1 = token1.symbol();
            poolView.name1 = token1.name();
            poolView.decimals1 = token1.decimals();
        } else {
            ERC20 token = ERC20(p.tokenAddress);
            poolView.token0 = p.tokenAddress;
            poolView.symbol0 = token.symbol();
            poolView.name0 = token.name();
            poolView.decimals0 = token.decimals();
        }
    }

    function getAllPoolViews() external view  returns(PoolView[] memory) {
        PoolView[] memory views = new PoolView[](pool.length);
        for (uint256 i = 0; i < pool.length; i++) {
            views[i] = getPoolView(i);
        }
        return views;
    }

    function stake(uint256 _pid) external validatePoolByPid(_pid) {
        require(pool[_pid].nftLeft > 0, "no NFT to earn");

        IERC20 token = IERC20(pool[_pid].tokenAddress);
        require(token.balanceOf(msg.sender) >= pool[_pid].stakeAmount, "out of balance");
        require(token.allowance(msg.sender, address(this)) >= pool[_pid].stakeAmount, "not enough permission to stake token");

        pool[_pid].nftLeft--;
        user[_pid][msg.sender].push(block.timestamp);

        uint256 oldBal = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), pool[_pid].stakeAmount), "transfer from staking token's owner error");
        uint256 realAmount = token.balanceOf(address(this)).sub(oldBal);
        require(realAmount >= pool[_pid].stakeAmount, "transfer amount not match");

        emit StakeEvent(_pid, msg.sender, block.timestamp);
    }

    function forceWithdraw(uint256 _pid, uint256 _sid) external validatePoolByPid(_pid) {
        require(_sid < user[_pid][msg.sender].length, "staking is not existed");
        uint256 beginTime = user[_pid][msg.sender][_sid];
        require(block.timestamp < beginTime + pool[_pid].stakeTime, "staking is ended");

        IERC20 token = IERC20(pool[_pid].tokenAddress);
        require(token.balanceOf(address(this)) >= pool[_pid].stakeAmount, "out of contract balance");
        removeFromUserList(_pid, _sid);
        pool[_pid].nftLeft++;

        token.safeTransfer(msg.sender, pool[_pid].stakeAmount);

        emit ForceWithdrawEvent(_pid, msg.sender, beginTime);
    }

    function harvest(uint256 _pid, uint256 _sid) external validatePoolByPid(_pid) {
        require(_sid < user[_pid][msg.sender].length, "staking is not existed");
        require(block.timestamp >= user[_pid][msg.sender][_sid] + pool[_pid].stakeTime, "staking is not due");
        require(pool[_pid].nftTokenIds.length > 0, "no nft left");

        IERC721 nft = IERC721(pool[_pid].nftAddress);
        uint256 tokenIdIdx = genRandomTokenId(_pid);
        uint256 tokenId = pool[_pid].nftTokenIds[tokenIdIdx];
        require(nft.ownerOf(tokenId) == address(this), "stake contract not own NFT");
        removeFromTokenIdList(_pid, tokenIdIdx);

        IERC20 token = IERC20(pool[_pid].tokenAddress);
        require(token.balanceOf(address(this)) >= pool[_pid].stakeAmount, "out of contract balance");
        removeFromUserList(_pid, _sid);

        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        token.safeTransfer(msg.sender, pool[_pid].stakeAmount);

        emit HarvestEvent(_pid, msg.sender, tokenId);
    }

    /*
    function withdrawTokenByOwner(uint256 _pid, uint256 _sid, address _to) external onlyOwner validatePoolByPid(_pid) {
        require(_sid < user[_pid][_to].length, "staking is not existed");

        IERC20 token = IERC20(pool[_pid].tokenAddress);
        uint256 amount = pool[_pid].stakeAmount <= token.balanceOf(address(this)) ? pool[_pid].stakeAmount : token.balanceOf(address(this));
        removeFromUserList(_pid, _sid);
        pool[_pid].nftLeft++;

        token.safeTransfer(_to, amount);
    }

    
    function withdrawNftByOwner(uint256 _pid, uint256 _tokenId, address _to) external onlyOwner validatePoolByPid(_pid) {
        require(pool[_pid].nftLeft > 0, "no available NFT to withdraw");
        uint idx = 0;
        bool found = false;
        IERC721 nft = IERC721(pool[_pid].nftAddress);
        while (idx < pool[_pid].nftTokenIds.length) {
            if (pool[_pid].nftTokenIds[idx] == _tokenId) {
                removeFromTokenIdList(_pid, idx);
                pool[_pid].nftLeft--;
                require(nft.ownerOf(_tokenId) == address(this), "NFT is not owned by contract");
                nft.safeTransferFrom(address(this), _to, _tokenId);
                found = true;
                break;
            }
            idx++;
        }
        require(found, "NFT is not existed in pool");
    }
    */

    function getUserStakeCnt(uint256 _pid, address _userAddr) public view validatePoolByPid(_pid) returns(uint) {
        return user[_pid][_userAddr].length;
    }

    function getUserStake(uint256 _pid, address _userAddr, uint256 _index) public view validatePoolByPid(_pid)
    returns(uint256 stakeAmount, uint256 stakeTime, uint256 endTime, bool isCompleted) {
        require(_index < user[_pid][_userAddr].length, "staking is not existed");
        endTime = user[_pid][_userAddr][_index] + pool[_pid].stakeTime;
        if (block.timestamp >= endTime) {
            isCompleted = true;
        }
        return (pool[_pid].stakeAmount, user[_pid][_userAddr][_index], endTime, isCompleted);
    }

    function getUserStakes(uint256 _pid, address _userAddr) public view validatePoolByPid(_pid)
    returns(StakeView[] memory stakes){
        uint cnt = getUserStakeCnt(_pid, _userAddr);
        if(cnt == 0) {
            return stakes;
        }

        stakes = new StakeView[](cnt);
        for(uint i = 0; i < cnt; i++) {
            (uint256 stakeAmount,
            uint256 stakeTime,
            uint256 endTime,
            bool isCompleted) = getUserStake(_pid, _userAddr, i);

            stakes[i] = StakeView({
                pid: _pid,
                amount: stakeAmount,
                beginTime: stakeTime,
                endTime: endTime,
                isCompleted: isCompleted
            });
        }
    }

    function getPoolAmount(uint256 _pid) public view validatePoolByPid(_pid) returns(uint256) {
        return pool[_pid].stakeAmount;
    }

    function getPoolNftLeft(uint256 _pid) public view validatePoolByPid(_pid) returns(uint256) {
        return pool[_pid].nftLeft;
    }

    function getNftListLength(uint256 _pid) public view validatePoolByPid(_pid) returns(uint256) {
        return pool[_pid].nftTokenIds.length;
    }

    function getNftList(uint256 _pid) public view validatePoolByPid(_pid) returns(uint256[] memory) {
        return pool[_pid].nftTokenIds;
    }

    function genRandomTokenId(uint256 _pid) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % pool[_pid].nftTokenIds.length;
    }

    function removeFromUserList(uint256 _pid, uint _sid) private {
        user[_pid][msg.sender][_sid] = user[_pid][msg.sender][user[_pid][msg.sender].length - 1];
        user[_pid][msg.sender].pop();
    }

    function removeFromTokenIdList(uint256 _pid, uint256 _index) private {
        nftInContract[pool[_pid].nftAddress][pool[_pid].nftTokenIds[_index]] = false;
        pool[_pid].nftTokenIds[_index] = pool[_pid].nftTokenIds[pool[_pid].nftTokenIds.length - 1];
        pool[_pid].nftTokenIds.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FragmentToken is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    constructor(string memory name_, string memory symbol_) 
    public ERC20(name_, symbol_) {

    }

    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {

        _mint(_to, _amount);

        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "FragmentToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "FragmentToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "FragmentToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "FragmentToken: caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./DelegateERC20.sol";

contract DSGTokenMapping is DelegateERC20, Ownable {

    event AddWhiteList(address user);
    event RemoveWhiteList(address user);

    address public feeWallet;

    uint256 public vTokenFeeRate = 2;
    uint256 public burnRate = 3;

    mapping(address => bool) _whiteList;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    constructor(address _feeWallet) public ERC20("Dinosaur Eggs Token", "DSG") {
        feeWallet = _feeWallet;
    }

    function setFeeWallet(address _feeWallet) public onlyOwner {
        feeWallet = _feeWallet;
    }

    function setVTokenFeeRate(uint256 rate) public onlyOwner {
        require(rate < 100, "bad num");

        vTokenFeeRate = rate;
    }

    function setBurnRate(uint256 rate) public onlyOwner {
        require(rate < 100, "bad num");

        burnRate = rate;
    }

    function addWhiteList(address user) public onlyOwner {
        _whiteList[user] = true;

        emit AddWhiteList(user);
    }

    function removeWhiteList(address user) public onlyOwner {
        delete _whiteList[user];

        emit RemoveWhiteList(user);
    }

    function isWhiteList(address user) public view returns(bool) {
        return _whiteList[user];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 _amount = amount;
        if(_whiteList[sender] == false && _whiteList[recipient] == false && recipient != address(0)) {
            if(vTokenFeeRate > 0) {
                uint256 fee = _amount.mul(vTokenFeeRate).div(10000);
                amount = amount.sub(fee);
                super._transfer(sender, feeWallet, fee);
            }

            if(burnRate > 0) {
                uint256 burn = _amount.mul(burnRate).div(10000);
                amount = amount.sub(burn);
                _burn(sender, burn);
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {

        _mint(_to, _amount);

        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "Token: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "Token: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "Token: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../token/DSGToken.sol";
import "../interfaces/ISwapPair.sol";
import "../interfaces/ISwapFactory.sol";
import "../libraries/SwapLibrary.sol";

interface IOracle {
    function update(address tokenA, address tokenB) external returns (bool);

    function updateBlockInfo() external returns (bool);

    function getQuantity(address token, uint256 amount) external view returns (uint256);
}

contract TradingPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _pairs;

    // Info of each user.
    struct UserInfo {
        uint256 quantity;
        uint256 accQuantity;
        uint256 pendingReward;
        uint256 rewardDebt; // Reward debt.
        uint256 accRewardAmount; // How many rewards the user has got.
    }

    struct UserView {
        uint256 quantity;
        uint256 accQuantity;
        uint256 unclaimedRewards;
        uint256 accRewardAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        address pair; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. reward tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that reward tokens distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward tokens per share, times 1e12.
        uint256 quantity;
        uint256 accQuantity;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
    }

    struct PoolView {
        uint256 pid;
        address pair;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 quantity;
        uint256 accQuantity;
        address token0;
        string symbol0;
        string name0;
        uint8 decimals0;
        address token1;
        string symbol1;
        string name1;
        uint8 decimals1;
    }

    // The reward token!
    DSGToken public rewardToken;
    // reward tokens created per block.
    uint256 public rewardTokenPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // pid corresponding address
    mapping(address => uint256) public pairOfPid;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    uint256 public totalQuantity = 0;
    IOracle public oracle;
    // router address
    address public router;
    // factory address
    ISwapFactory public factory;
    // The block number when reward token mining starts.
    uint256 public startBlock;
    uint256 public halvingPeriod = 3952800; // half year

    event Swap(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        DSGToken _rewardToken,
        ISwapFactory _factory,
        IOracle _oracle,
        address _router,
        uint256 _rewardTokenPerBlock,
        uint256 _startBlock
    ) public {
        rewardToken = _rewardToken;
        factory = _factory;
        oracle = _oracle;
        router = _router;
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startBlock = _startBlock;
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock)).div(halvingPeriod);
        }
        return 0;
    }

    function getRewardTokenPerBlock(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return rewardTokenPerBlock.div(2**_phase);
    }

    function getRewardTokenBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 lastRewardPhase = phase(_lastRewardBlock);
        uint256 currentPhase = phase(block.number);
        while (lastRewardPhase < currentPhase) {
            lastRewardPhase++;
            uint256 height = lastRewardPhase.mul(halvingPeriod).add(startBlock);
            blockReward = blockReward.add((height.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(height)));
            _lastRewardBlock = height;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(block.number)));
        return blockReward;
    }

    // Add a new pair to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        address _pair,
        bool _withUpdate
    ) public onlyOwner {
        require(_pair != address(0), "TradingPool: _pair is the zero address");

        require(!EnumerableSet.contains(_pairs, _pair), "TradingPool: _pair is already added to the pool");
        // return EnumerableSet.add(_pairs, _pair);
        EnumerableSet.add(_pairs, _pair);

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                pair: _pair,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                quantity: 0,
                accQuantity: 0,
                allocRewardAmount: 0,
                accRewardAmount: 0
            })
        );
        pairOfPid[_pair] = getPoolLength() - 1;
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        require(_pid < poolInfo.length, "overflow");

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.quantity == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);

        if (blockReward <= 0) {
            return;
        }

        uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        pool.lastRewardBlock = block.number;

        pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(pool.quantity));
        pool.allocRewardAmount = pool.allocRewardAmount.add(tokenReward);
        pool.accRewardAmount = pool.accRewardAmount.add(tokenReward);

        require(rewardToken.mint(address(this), tokenReward), "mint error");
    }

    function swap(
        address account,
        address input,
        address output,
        uint256 amount
    ) public onlyRouter returns (bool) {
        require(account != address(0), "TradingPool: swap account is zero address");
        require(input != address(0), "TradingPool: swap input is zero address");
        require(output != address(0), "TradingPool: swap output is zero address");

        if (getPoolLength() <= 0) {
            return false;
        }

        address pair = SwapLibrary.pairFor(address(factory), input, output);

        PoolInfo storage pool = poolInfo[pairOfPid[pair]];
        // If it does not exist or the allocPoint is 0 then return
        if (pool.pair != pair || pool.allocPoint <= 0) {
            return false;
        }

        uint256 quantity = IOracle(oracle).getQuantity(output, amount);
        if (quantity <= 0) {
            return false;
        }

        updatePool(pairOfPid[pair]);
        IOracle(oracle).update(input, output);
        IOracle(oracle).updateBlockInfo();

        UserInfo storage user = userInfo[pairOfPid[pair]][account];
        if (user.quantity > 0) {
            uint256 pendingReward = user.quantity.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingReward > 0) {
                user.pendingReward = user.pendingReward.add(pendingReward);
            }
        }

        if (quantity > 0) {
            pool.quantity = pool.quantity.add(quantity);
            pool.accQuantity = pool.accQuantity.add(quantity);
            totalQuantity = totalQuantity.add(quantity);
            user.quantity = user.quantity.add(quantity);
            user.accQuantity = user.accQuantity.add(quantity);
        }
        user.rewardDebt = user.quantity.mul(pool.accRewardPerShare).div(1e12);
        emit Swap(account, pairOfPid[pair], quantity);

        return true;
    }

    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid <= poolInfo.length - 1, "TradingPool: Can not find this pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (user.quantity > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);
                uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(tokenReward.mul(1e12).div(pool.quantity));
                return user.pendingReward.add(user.quantity.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt));
            }
            if (block.number == pool.lastRewardBlock) {
                return user.pendingReward.add(user.quantity.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt));
            }
        }
        return 0;
    }

    function withdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][tx.origin];

        updatePool(_pid);
        uint256 pendingAmount = pendingRewards(_pid, tx.origin);

        if (pendingAmount > 0) {
            safeRewardTokenTransfer(tx.origin, pendingAmount);
            pool.quantity = pool.quantity.sub(user.quantity);
            pool.allocRewardAmount = pool.allocRewardAmount.sub(pendingAmount);
            user.accRewardAmount = user.accRewardAmount.add(pendingAmount);
            user.quantity = 0;
            user.rewardDebt = 0;
            user.pendingReward = 0;
        }
        emit Withdraw(tx.origin, _pid, pendingAmount);
    }

    function harvestAll() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            withdraw(i);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pendingReward = user.pendingReward;
        pool.quantity = pool.quantity.sub(user.quantity);
        pool.allocRewardAmount = pool.allocRewardAmount.sub(user.pendingReward);
        user.accRewardAmount = user.accRewardAmount.add(user.pendingReward);
        user.quantity = 0;
        user.rewardDebt = 0;
        user.pendingReward = 0;

        safeRewardTokenTransfer(msg.sender, pendingReward);

        emit EmergencyWithdraw(msg.sender, _pid, user.quantity);
    }

    // Safe reward token transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            IERC20(rewardToken).safeTransfer(_to, rewardTokenBalance);
        } else {
            IERC20(rewardToken).safeTransfer(_to, _amount);
        }
    }

    // Set the number of reward token produced by each block
    function setRewardTokenPerBlock(uint256 _newPerBlock) public onlyOwner {
        massUpdatePools();
        rewardTokenPerBlock = _newPerBlock;
    }

    function setHalvingPeriod(uint256 _block) public onlyOwner {
        halvingPeriod = _block;
    }

    function setRouter(address newRouter) public onlyOwner {
        require(newRouter != address(0), "TradingPool: new router is the zero address");
        router = newRouter;
    }

    function setOracle(IOracle _oracle) public onlyOwner {
        require(address(_oracle) != address(0), "TradingPool: new oracle is the zero address");
        oracle = _oracle;
    }

    function getPairsLength() public view returns (uint256) {
        return EnumerableSet.length(_pairs);
    }

    function getPairs(uint256 _index) public view returns (address) {
        require(_index <= getPairsLength() - 1, "TradingPool: index out of bounds");
        return EnumerableSet.at(_pairs, _index);
    }

    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getPoolView(uint256 pid) public view returns (PoolView memory) {
        require(pid < poolInfo.length, "TradingPool: pid out of range");
        PoolInfo memory pool = poolInfo[pid];
        address pair = address(pool.pair);
        ERC20 token0 = ERC20(ISwapPair(pair).token0());
        ERC20 token1 = ERC20(ISwapPair(pair).token1());
        string memory symbol0 = token0.symbol();
        string memory name0 = token0.name();
        uint8 decimals0 = token0.decimals();
        string memory symbol1 = token1.symbol();
        string memory name1 = token1.name();
        uint8 decimals1 = token1.decimals();
        uint256 rewardsPerBlock = pool.allocPoint.mul(rewardTokenPerBlock).div(totalAllocPoint);
        return
            PoolView({
                pid: pid,
                pair: pair,
                allocPoint: pool.allocPoint,
                lastRewardBlock: pool.lastRewardBlock,
                accRewardPerShare: pool.accRewardPerShare,
                rewardsPerBlock: rewardsPerBlock,
                allocRewardAmount: pool.allocRewardAmount,
                accRewardAmount: pool.accRewardAmount,
                quantity: pool.quantity,
                accQuantity: pool.accQuantity,
                token0: address(token0),
                symbol0: symbol0,
                name0: name0,
                decimals0: decimals0,
                token1: address(token1),
                symbol1: symbol1,
                name1: name1,
                decimals1: decimals1
            });
    }

    function getPoolViewByAddress(address pair) public view returns (PoolView memory) {
        uint256 pid = pairOfPid[pair];
        return getPoolView(pid);
    }

    function getAllPoolViews() external view returns (PoolView[] memory) {
        PoolView[] memory views = new PoolView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            views[i] = getPoolView(i);
        }
        return views;
    }

    function getUserView(address pair, address account) public view returns (UserView memory) {
        uint256 pid = pairOfPid[pair];
        UserInfo memory user = userInfo[pid][account];
        uint256 unclaimedRewards = pendingRewards(pid, account);
        return
            UserView({
                quantity: user.quantity,
                accQuantity: user.accQuantity,
                unclaimedRewards: unclaimedRewards,
                accRewardAmount: user.accRewardAmount
            });
    }

    function getUserViews(address account) external view returns (UserView[] memory) {
        address pair;
        UserView[] memory views = new UserView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            pair = address(poolInfo[i].pair);
            views[i] = getUserView(pair, account);
        }
        return views;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "TradingPool: caller is not the router");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './SwapERC20.sol';
import '../libraries/Math.sol';
import '../libraries/UQ112x112.sol';
import '../interfaces/ISwapFactory.sol';
import '../interfaces/ISwapCallee.sol';

contract SwapPair is SwapERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'SwapPair: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SwapPair: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'SwapPair: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'SwapPair: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = ISwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(ISwapFactory(factory).feeToRate()).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'SwapPair: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'SwapPair: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'SwapPair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'SwapPair: INSUFFICIENT_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'SwapPair: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) ISwapCallee(to).SwapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'SwapPair: INSUFFICIENT_INPUT_AMOUNT');
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1000**2),
                'SwapPair: K'
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function getPrice(address token, uint256 baseDecimal) public view returns (uint256) {
        if ((token0 != token && token1 != token) || 0 == reserve0 || 0 == reserve1) {
            return 0;
        }
        if (token0 == token) {
            return uint256(reserve1).mul(baseDecimal).div(uint256(reserve0));
        } else {
            return uint256(reserve0).mul(baseDecimal).div(uint256(reserve1));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract SwapERC20 {
    using SafeMath for uint256;

    string public constant name = 'DSG LP Token';
    string public constant symbol = 'DsgLP';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'SwapERC20: EXPIRED');
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SwapERC20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

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
        } else z = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ISwapCallee {
    function SwapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../governance/InitializableOwner.sol";

interface IvDsg {
    function donate(uint256 dsgAmount) external;
    function redeem(uint256 vDsgAmount, bool all) external;
     function balanceOf(address account) external view returns (uint256 vDsgAmount);
}

contract vDsgReserve is InitializableOwner {

    event Donte(uint256 amount);

    IvDsg public vdsg;
    IERC20 public dsg;

    function initialize (
        address _vDsg,
        address _dsg
    ) public {
        super._initialize();

        vdsg = IvDsg(_vDsg);
        dsg = IERC20(_dsg);
    }

    function donateToVDsg(uint256 amount) public onlyOwner {
        dsg.approve(address(vdsg), uint(-1));
        vdsg.donate(amount);

        emit Donte(amount);
    }

    function donateAllToVDsg() public onlyOwner {
        uint256 amount = dsg.balanceOf(address(this));
        require(amount > 0, "Insufficient balance");

        donateToVDsg(amount);
    }

    function redeem(uint256 vDsgAmount, bool all) public onlyOwner {
        vdsg.redeem(vDsgAmount, all);
    }

    function dsgBalance() public view returns(uint256) {
        return dsg.balanceOf(address(this));
    }

    function vdsgBalance() public view returns(uint256) {
        return vdsg.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../token/DSGToken.sol";

contract DepositPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _tokens;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 accRewardAmount; // How many rewards the user has got.
    }

    struct UserView {
        uint256 stakedAmount;
        uint256 unclaimedRewards;
        uint256 tokenBalance;
        uint256 accRewardAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        address token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Reward token to distribute per block.
        uint256 lastRewardBlock; // Last block number that reward token distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward per share, times 1e12.
        uint256 totalAmount; // Total amount of current pool deposit.
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
    }

    struct PoolView {
        uint256 pid;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 totalAmount;
        address token;
        string symbol;
        string name;
        uint8 decimals;
    }

    // The reward Token
    DSGToken public rewardToken;
    // token created per block.
    uint256 public rewardTokenPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // pid corresponding address
    mapping(address => uint256) public tokenOfPid;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when reward token mining starts.
    uint256 public startBlock;
    uint256 public halvingPeriod = 3952800; // half year, 4s each block

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        DSGToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) public {
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock).sub(1)).div(halvingPeriod);
        }
        return 0;
    }

    function getRewardTokenPerBlock(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return rewardTokenPerBlock.div(2**_phase);
    }

    function getRewardTokenBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 lastRewardPhase = phase(_lastRewardBlock);
        uint256 currentPhase = phase(block.number);
        while (lastRewardPhase < currentPhase) {
            lastRewardPhase++;
            uint256 height = lastRewardPhase.mul(halvingPeriod).add(startBlock);
            blockReward = blockReward.add((height.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(height)));
            _lastRewardBlock = height;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(block.number)));
        return blockReward;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        address _token,
        bool _withUpdate
    ) public onlyOwner {
        require(_token != address(0), "DepositPool: _token is the zero address");

        require(!EnumerableSet.contains(_tokens, _token), "DepositPool: _token is already added to the pool");
        // return EnumerableSet.add(_tokens, _token);
        EnumerableSet.add(_tokens, _token);

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                totalAmount: 0,
                allocRewardAmount: 0,
                accRewardAmount: 0
            })
        );
        tokenOfPid[_token] = getPoolLength() - 1;
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 tokenSupply = ERC20(pool.token).balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);

        if (blockReward <= 0) {
            return;
        }

        uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);

        bool minRet = rewardToken.mint(address(this), tokenReward);
        if (minRet) {
            pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(tokenSupply));
            pool.allocRewardAmount = pool.allocRewardAmount.add(tokenReward);
            pool.accRewardAmount = pool.accRewardAmount.add(tokenReward);
        }
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                safeRewardTokenTransfer(msg.sender, pendingAmount);
                user.accRewardAmount = user.accRewardAmount.add(pendingAmount);
                pool.allocRewardAmount = pool.allocRewardAmount.sub(pendingAmount);
            }
        }
        if (_amount > 0) {
            ERC20(pool.token).safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid <= poolInfo.length - 1, "DepositPool: Can not find this pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accRewardPerShare;
        uint256 tokenSupply = ERC20(pool.token).balanceOf(address(this));
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);
                uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(tokenSupply));
                return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
            }
            if (block.number == pool.lastRewardBlock) {
                return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        return 0;
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][tx.origin];
        require(user.amount >= _amount, "DepositPool: withdraw: not good");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            safeRewardTokenTransfer(tx.origin, pendingAmount);
            user.accRewardAmount = user.accRewardAmount.add(pendingAmount);
            pool.allocRewardAmount = pool.allocRewardAmount.sub(pendingAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            ERC20(pool.token).safeTransfer(tx.origin, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(tx.origin, _pid, _amount);
    }

    function harvestAll() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            withdraw(i, 0);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        ERC20(pool.token).safeTransfer(msg.sender, amount);
        pool.totalAmount = pool.totalAmount.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe reward token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        if (_amount > tokenBalance) {
            rewardToken.transfer(_to, tokenBalance);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    // Set the number of reward token produced by each block
    function setRewardTokenPerBlock(uint256 _newPerBlock) public onlyOwner {
        massUpdatePools();
        rewardTokenPerBlock = _newPerBlock;
    }

    function setHalvingPeriod(uint256 _block) public onlyOwner {
        halvingPeriod = _block;
    }

    function getTokensLength() public view returns (uint256) {
        return EnumerableSet.length(_tokens);
    }

    function getTokens(uint256 _index) public view returns (address) {
        require(_index <= getTokensLength() - 1, "DepositPool: index out of bounds");
        return EnumerableSet.at(_tokens, _index);
    }

    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getPoolView(uint256 pid) public view returns (PoolView memory) {
        require(pid < poolInfo.length, "DepositPool: pid out of range");
        PoolInfo memory pool = poolInfo[pid];
        ERC20 token = ERC20(pool.token);
        string memory symbol = token.symbol();
        string memory name = token.name();
        uint8 decimals = token.decimals();
        uint256 rewardsPerBlock = pool.allocPoint.mul(rewardTokenPerBlock).div(totalAllocPoint);
        return
            PoolView({
                pid: pid,
                allocPoint: pool.allocPoint,
                lastRewardBlock: pool.lastRewardBlock,
                accRewardPerShare: pool.accRewardPerShare,
                rewardsPerBlock: rewardsPerBlock,
                allocRewardAmount: pool.allocRewardAmount,
                accRewardAmount: pool.accRewardAmount,
                totalAmount: pool.totalAmount,
                token: address(token),
                symbol: symbol,
                name: name,
                decimals: decimals
            });
    }

    function getPoolViewByAddress(address token) public view returns (PoolView memory) {
        uint256 pid = tokenOfPid[token];
        return getPoolView(pid);
    }

    function getAllPoolViews() external view returns (PoolView[] memory) {
        PoolView[] memory views = new PoolView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            views[i] = getPoolView(i);
        }
        return views;
    }

    function getUserView(address token_, address account) public view returns (UserView memory) {
        uint256 pid = tokenOfPid[token_];
        UserInfo memory user = userInfo[pid][account];
        uint256 unclaimedRewards = pendingRewards(pid, account);
        uint256 tokenBalance = ERC20(token_).balanceOf(account);
        return
            UserView({
                stakedAmount: user.amount,
                unclaimedRewards: unclaimedRewards,
                tokenBalance: tokenBalance,
                accRewardAmount: user.accRewardAmount
            });
    }

    function getUserViews(address account) external view returns (UserView[] memory) {
        address token;
        UserView[] memory views = new UserView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            token = address(poolInfo[i].token);
            views[i] = getUserView(token, account);
        }
        return views;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../token/DSGToken.sol";

contract GovernorV1 {
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool canceled;
        bool executed;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed}

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice The name of this contract
    string public constant name = "DSG Governor v1";

    /// @notice The address of the dsg Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the dsg governance token
    DSGToken public token;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /// @notice The EIP-712 type hash for the contract's domain
    bytes32 public constant DOMAIN_TYPE_HASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 type hash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPE_HASH = keccak256("Ballot(uint256 proposalId,bool support)");

    constructor(
        address _timelock,
        address _token,
        address _guardian
    ) public {
        timelock = TimelockInterface(_timelock);
        token = DSGToken(_token);
        guardian = _guardian;
    }

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint256) {
        return token.totalSupply() / 25;
    } // 400,000 = 4% of dsg

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public view returns (uint256) {
        return token.totalSupply() / 100;
    } // 100,000 = 1% of dsg

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint256) {
        return 10;
    } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint256) {
        return 1;
    } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint256) {
        return 86400;
    } // ~3 days in blocks (assuming 3s blocks)

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            token.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(),
            "GovernorV1::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "GovernorV1::propose: proposal function information arity mismatch"
        );
        require(targets.length != 0, "GovernorV1::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorV1::propose: too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "GovernorV1::propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "GovernorV1::propose: one live proposal per proposer, found an already pending proposal"
            );
        }

        uint256 startBlock = add256(block.number, votingDelay());
        uint256 endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal memory newProposal =
        Proposal({
            id : proposalCount,
            proposer : msg.sender,
            eta : 0,
            targets : targets,
            values : values,
            signatures : signatures,
            calldatas : calldatas,
            startBlock : startBlock,
            endBlock : endBlock,
            forVotes : 0,
            againstVotes : 0,
            canceled : false,
            executed : false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        return newProposal.id;
    }

    function queue(uint256 proposalId) public {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "GovernorV1::queue: proposal can only be queued if it is succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = add256(block.timestamp, timelock.delay());
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            "GovernorV1::_queueOrRevert: proposal action already queued at eta"
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint256 proposalId) public payable {
        require(
            state(proposalId) == ProposalState.Queued,
            "GovernorV1::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value : proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "GovernorV1::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == guardian ||
            token.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(),
            "GovernorV1::cancel: proposer above threshold"
        );

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint256 proposalId)
    public
    view
    returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorV1::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint256 proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(
        uint256 proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator =
        keccak256(abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPE_HASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorV1::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorV1::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorV1::_castVote: voter already voted");
        uint256 votes = token.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "GovernorV1::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "GovernorV1::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorV1::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorV1::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../token/DSGToken.sol";
import "../interfaces/ISwapPair.sol";
import "../interfaces/IDsgNft.sol";
import "../interfaces/IERC20Metadata.sol";

contract LiquidityPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _pairs;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardPending; //Rewards that have been settled and pending
        uint256 accRewardAmount; // How many rewards the user has got.
        uint256 additionalNftId; //Nft used to increase revenue
        uint256 additionalRate; //nft additional rate of reward, base 10000
        uint256 additionalAmount; //nft additional amount of share
    }

    struct UserView {
        uint256 stakedAmount;
        uint256 unclaimedRewards;
        uint256 lpBalance;
        uint256 accRewardAmount;
        uint256 additionalNftId; //Nft used to increase revenue
        uint256 additionalRate; //nft additional rate of reward
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        address additionalNft; //Nft for users to increase share rate
        uint256 allocPoint; // How many allocation points assigned to this pool. reward tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that reward tokens distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward tokens per share, times 1e12.
        uint256 totalAmount; // Total amount of current pool deposit.
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 accDonateAmount;
    }

    struct PoolView {
        uint256 pid;
        address lpToken;
        address additionalNft;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 totalAmount;
        address token0;
        string symbol0;
        string name0;
        uint8 decimals0;
        address token1;
        string symbol1;
        string name1;
        uint8 decimals1;
    }

    // The reward token!
    DSGToken public rewardToken;
    // reward tokens created per block.
    uint256 public rewardTokenPerBlock;

    address public feeWallet;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // pid corresponding address
    mapping(address => uint256) public LpOfPid;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when token mining starts.
    uint256 public startBlock;
    uint256 public halvingPeriod = 3952800; // half year

    uint256[] public additionalRate = [0, 300, 400, 500, 600, 800, 1000]; //The share ratio that can be increased by each level of nft
    uint256 public nftSlotFee = 1e18; //Additional nft requires a card slot, enable the card slot requires fee

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Donate(address indexed user, uint256 pid, uint256 donateAmount, uint256 realAmount);
    event AdditionalNft(address indexed user, uint256 pid, uint256 nftId);

    constructor(
        DSGToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        address _feeWallet
    ) public {
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        feeWallet = _feeWallet;
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock)).div(halvingPeriod);
        }
        return 0;
    }

    function getRewardTokenPerBlock(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return rewardTokenPerBlock.div(2**_phase);
    }

    function getRewardTokenBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 lastRewardPhase = phase(_lastRewardBlock);
        uint256 currentPhase = phase(block.number);
        while (lastRewardPhase < currentPhase) {
            lastRewardPhase++;
            uint256 height = lastRewardPhase.mul(halvingPeriod).add(startBlock);
            blockReward = blockReward.add((height.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(height)));
            _lastRewardBlock = height;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(getRewardTokenPerBlock(block.number)));
        return blockReward;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _additionalNft,
        bool _withUpdate
    ) public onlyOwner {
        require(_lpToken != address(0), "LiquidityPool: _lpToken is the zero address");
        require(ISwapPair(_lpToken).token0() != address(0), "not lp");

        require(!EnumerableSet.contains(_pairs, _lpToken), "LiquidityPool: _lpToken is already added to the pool");
        // return EnumerableSet.add(_pairs, _lpToken);
        EnumerableSet.add(_pairs, _lpToken);

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                additionalNft: _additionalNft,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                accDonateAmount: 0,
                totalAmount: 0,
                allocRewardAmount: 0,
                accRewardAmount: 0
            })
        );
        LpOfPid[_lpToken] = getPoolLength() - 1;
    }

    function setAdditionalNft(uint256 _pid, address _additionalNft) public onlyOwner {
        require(poolInfo[_pid].additionalNft == address(0), "already set");

        poolInfo[_pid].additionalNft = _additionalNft;
    }

    function setNftSlotFee(uint256 val) public onlyOwner {
        nftSlotFee = val;
    }

    function getAdditionalRates() public view returns(uint256[] memory) {
        return additionalRate;
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);

        if (blockReward <= 0) {
            return;
        }

        uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);

        bool minRet = rewardToken.mint(address(this), tokenReward);
        if (minRet) {
            pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(pool.totalAmount));
            pool.allocRewardAmount = pool.allocRewardAmount.add(tokenReward);
            pool.accRewardAmount = pool.accRewardAmount.add(tokenReward);
        }
        pool.lastRewardBlock = block.number;
    }

    function donate(uint256 donateAmount) public {
        uint256 oldBal = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), donateAmount);
        uint256 realAmount = IERC20(rewardToken).balanceOf(address(this)) - oldBal;

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);

            PoolInfo storage pool = poolInfo[pid];
            if(pool.allocPoint == 0) {
                continue;
            }
            require(pool.totalAmount > 0, "no lp staked");

            uint256 tokenReward = realAmount.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(pool.totalAmount));
            pool.allocRewardAmount = pool.allocRewardAmount.add(tokenReward);
            pool.accDonateAmount = pool.accDonateAmount.add(tokenReward);
        }

        emit Donate(msg.sender, 100000, donateAmount, realAmount);
    }

    function donateToPool(uint256 pid, uint256 donateAmount) public {
        updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        require(pool.allocPoint > 0, "pool closed");

        require(pool.totalAmount > 0, "no lp staked");

        uint256 oldBal = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), donateAmount);
        uint256 realAmount = IERC20(rewardToken).balanceOf(address(this)) - oldBal;

        pool.accRewardPerShare = pool.accRewardPerShare.add(realAmount.mul(1e12).div(pool.totalAmount));
        pool.allocRewardAmount = pool.allocRewardAmount.add(realAmount);
        pool.accDonateAmount = pool.accDonateAmount.add(realAmount);

        emit Donate(msg.sender, pid, donateAmount, realAmount);
    }

    function additionalNft(uint256 _pid, uint256 nftId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.additionalNftId == 0, "nft already set");
        updatePool(_pid);

        uint256 level = IDsgNft(pool.additionalNft).getLevel(nftId);
        require(level > 0, "no level");

        if(nftSlotFee > 0) {
            IERC20(rewardToken).safeTransferFrom(msg.sender, feeWallet, nftSlotFee);
        }

        IDsgNft(pool.additionalNft).safeTransferFrom(msg.sender, address(this), nftId);
        IDsgNft(pool.additionalNft).burn(nftId);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardPending = user.rewardPending.add(pending);
        }

        user.additionalNftId = nftId;
        user.additionalRate = additionalRate[level];
        
        user.additionalAmount = user.amount.mul(user.additionalRate).div(10000);
        pool.totalAmount = pool.totalAmount.add(user.additionalAmount);

        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
        emit AdditionalNft(msg.sender, _pid, nftId);
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        user.rewardPending = user.rewardPending.add(pending);

        if (_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
            if(user.additionalRate > 0) {
                uint256 _add = _amount.mul(user.additionalRate).div(10000);
                user.additionalAmount = user.additionalAmount.add(_add);
                pool.totalAmount = pool.totalAmount.add(_add);
            }
        }

        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function harvest(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        uint256 pendingAmount = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        pendingAmount = pendingAmount.add(user.rewardPending);
        user.rewardPending = 0;
        if (pendingAmount > 0) {
            safeRewardTokenTransfer(msg.sender, pendingAmount);
            user.accRewardAmount = user.accRewardAmount.add(pendingAmount);
            pool.allocRewardAmount = pool.allocRewardAmount.sub(pendingAmount);
        }

        // pool.totalAmount = pool.totalAmount.sub(user.additionalAmount);
        // user.additionalAmount = 0;
        // user.additionalRate = 0;
        // user.additionalNftId = 0;
        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
    }

    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid <= poolInfo.length - 1, "LiquidityPool: Can not find this pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        uint256 pending = 0;
        uint256 amount = user.amount.add(user.additionalAmount);
        if (amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getRewardTokenBlockReward(pool.lastRewardBlock);
                uint256 tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(tokenReward.mul(1e12).div(pool.totalAmount));
                pending = amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            } else if (block.number == pool.lastRewardBlock) {
                pending = amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        pending = pending.add(user.rewardPending);
        return pending;
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "LiquidityPool: withdraw not good");
        updatePool(_pid);

        harvest(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            IERC20(pool.lpToken).safeTransfer(msg.sender, _amount);
            
            pool.totalAmount = pool.totalAmount.sub(user.additionalAmount);
            user.additionalAmount = 0;
            user.additionalRate = 0;
            user.additionalNftId = 0;
        }
        user.rewardDebt = user.amount.add(user.additionalAmount).mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function harvestAll() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            harvest(i);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        uint256 additionalAmount = user.additionalAmount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.additionalAmount = 0;
        user.additionalRate = 0;
        user.additionalNftId = 0;

        IERC20(pool.lpToken).safeTransfer(msg.sender, amount);

        if (pool.totalAmount >= amount) {
            pool.totalAmount = pool.totalAmount.sub(amount);
        }
        
        if(pool.totalAmount >= additionalAmount) {
            pool.totalAmount = pool.totalAmount.sub(additionalAmount);
        }
        
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            IERC20(address(rewardToken)).safeTransfer(_to, rewardTokenBalance);
        } else {
            IERC20(address(rewardToken)).safeTransfer(_to, _amount);
        }
    }

    // Set the number of reward token produced by each block
    function setRewardTokenPerBlock(uint256 _newPerBlock) public onlyOwner {
        massUpdatePools();
        rewardTokenPerBlock = _newPerBlock;
    }

    function setHalvingPeriod(uint256 _block) public onlyOwner {
        halvingPeriod = _block;
    }

    function getPairsLength() public view returns (uint256) {
        return EnumerableSet.length(_pairs);
    }

    function getPairs(uint256 _index) public view returns (address) {
        require(_index <= getPairsLength() - 1, "LiquidityPool: index out of bounds");
        return EnumerableSet.at(_pairs, _index);
    }

    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getPoolView(uint256 pid) public view returns (PoolView memory) {
        require(pid < poolInfo.length, "LiquidityPool: pid out of range");
        PoolInfo memory pool = poolInfo[pid];
        address lpToken = pool.lpToken;
        IERC20 token0 = IERC20(ISwapPair(lpToken).token0());
        IERC20 token1 = IERC20(ISwapPair(lpToken).token1());
        string memory symbol0 = IERC20Metadata(address(token0)).symbol();
        string memory name0 = IERC20Metadata(address(token0)).name();
        uint8 decimals0 = IERC20Metadata(address(token0)).decimals();
        string memory symbol1 = IERC20Metadata(address(token1)).symbol();
        string memory name1 = IERC20Metadata(address(token1)).name();
        uint8 decimals1 = IERC20Metadata(address(token1)).decimals();
        uint256 rewardsPerBlock = pool.allocPoint.mul(rewardTokenPerBlock).div(totalAllocPoint);
        return
            PoolView({
                pid: pid,
                lpToken: lpToken,
                additionalNft: pool.additionalNft,
                allocPoint: pool.allocPoint,
                lastRewardBlock: pool.lastRewardBlock,
                accRewardPerShare: pool.accRewardPerShare,
                rewardsPerBlock: rewardsPerBlock,
                allocRewardAmount: pool.allocRewardAmount,
                accRewardAmount: pool.accRewardAmount,
                totalAmount: pool.totalAmount,
                token0: address(token0),
                symbol0: symbol0,
                name0: name0,
                decimals0: decimals0,
                token1: address(token1),
                symbol1: symbol1,
                name1: name1,
                decimals1: decimals1
            });
    }

    function getPoolViewByAddress(address lpToken) public view returns (PoolView memory) {
        uint256 pid = LpOfPid[lpToken];
        return getPoolView(pid);
    }

    function getAllPoolViews() external view returns (PoolView[] memory) {
        PoolView[] memory views = new PoolView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            views[i] = getPoolView(i);
        }
        return views;
    }

    function getUserView(address lpToken, address account) public view returns (UserView memory) {
        uint256 pid = LpOfPid[lpToken];
        UserInfo memory user = userInfo[pid][account];
        uint256 unclaimedRewards = pendingRewards(pid, account);
        uint256 lpBalance = ERC20(lpToken).balanceOf(account);
        return
            UserView({
                stakedAmount: user.amount,
                unclaimedRewards: unclaimedRewards,
                lpBalance: lpBalance,
                accRewardAmount: user.accRewardAmount,
                additionalNftId: user.additionalNftId,
                additionalRate: user.additionalRate
            });
    }

    function getUserViews(address account) external view returns (UserView[] memory) {
        address lpToken;
        UserView[] memory views = new UserView[](poolInfo.length);
        for (uint256 i = 0; i < poolInfo.length; i++) {
            lpToken = address(poolInfo[i].lpToken);
            views[i] = getUserView(lpToken, account);
        }
        return views;
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./pools/LiquidityPool.sol";
import "./pools/DepositPool.sol";
import "./pools/TradingPool.sol";
import "./governance/Treasury.sol";
import "./governance/InitializableOwner.sol";

contract Aggregator is InitializableOwner{
    struct UserMiningInfo {
        uint256 userAmount;
        uint256 userUnclaimedReward;
        uint256 userAccReward;
        uint8 poolType;
        uint256 pid;
        address pair;
        uint256 totalAmount;
        uint256 rewardsPerBlock;
        uint256 allocPoint;
        address token0;
        string name0;
        string symbol0;
        uint8 decimals0;
        address token1;
        string name1;
        string symbol1;
        uint8 decimals1;
    }

    struct TreasuryInfo {
        uint256 nftBonusRatio;
        uint256 totalFee;
        uint256 nftBonusAmount;
        uint256 totalDistributedFee;
        uint256 totalBurnedDSG;
        uint256 totalRepurchasedUSDT;
    }

    LiquidityPool liquidityPool;
    DepositPool depositPool;
    TradingPool tradingPool;
    Treasury treasury;
    address public DSG;

    constructor() public {
    }

    function initialize(
        address _liquidityPool,
        address _depositPool,
        address _tradingPool,
        address _treasury,
        address _dsg
    ) public {
        super._initialize();

        liquidityPool = LiquidityPool(_liquidityPool);
        depositPool = DepositPool(_depositPool);
        tradingPool = TradingPool(_tradingPool);
        treasury = Treasury(_treasury);
        DSG = _dsg;
    }

    function getCirculationSupply() public view returns (uint256 supply) {
        supply =
            IERC20(DSG).totalSupply();
    }

    function getTreasuryInfo() public view returns (TreasuryInfo memory) {
        return
            TreasuryInfo({
                nftBonusRatio: treasury.nftBonusRatio(),
                totalFee: treasury.totalFee(),
                nftBonusAmount: treasury.nftBonusAmount(),
                totalDistributedFee: treasury.totalDistributedFee(),
                totalBurnedDSG: treasury.totalBurnedDSG(),
                totalRepurchasedUSDT: treasury.totalRepurchasedUSDT()
            });
    }

    function getUserMiningInfos(address _account) public view returns (UserMiningInfo[] memory) {
        UserMiningInfo[] memory infos = new UserMiningInfo[](40);

        uint256 index = 0;

        for (uint256 i = 0; i < liquidityPool.getPoolLength(); i++) {
            LiquidityPool.PoolView memory lpPV = liquidityPool.getPoolView(i);
            LiquidityPool.UserView memory lpUV = liquidityPool.getUserView(lpPV.lpToken, _account);
            uint256 unclaimedRewards = liquidityPool.pendingRewards(i, _account);
            if (unclaimedRewards > 0 || lpUV.accRewardAmount > 0) {
                infos[index] = UserMiningInfo({
                    userAmount: lpUV.stakedAmount,
                    userUnclaimedReward: unclaimedRewards,
                    userAccReward: lpUV.accRewardAmount,
                    poolType: 1,
                    pid: i,
                    pair: lpPV.lpToken,
                    totalAmount: lpPV.totalAmount,
                    rewardsPerBlock: lpPV.rewardsPerBlock,
                    allocPoint: lpPV.allocPoint,
                    token0: lpPV.token0,
                    name0: lpPV.name0,
                    symbol0: lpPV.symbol0,
                    decimals0: lpPV.decimals0,
                    token1: lpPV.token1,
                    name1: lpPV.name1,
                    symbol1: lpPV.symbol1,
                    decimals1: lpPV.decimals1
                });
                index++;
            }
        }

        for (uint256 i = 0; i < tradingPool.getPoolLength(); i++) {
            TradingPool.PoolView memory tPV = tradingPool.getPoolView(i);
            TradingPool.UserView memory tUV = tradingPool.getUserView(tPV.pair, _account);
            uint256 unclaimedRewards = tradingPool.pendingRewards(i, _account);
            if (unclaimedRewards > 0 || tUV.accRewardAmount > 0) {
                infos[index] = UserMiningInfo({
                    userAmount: tUV.quantity,
                    userUnclaimedReward: tUV.unclaimedRewards,
                    userAccReward: tUV.accRewardAmount,
                    poolType: 2,
                    pid: i,
                    pair: tPV.pair,
                    totalAmount: tPV.quantity,
                    rewardsPerBlock: tPV.rewardsPerBlock,
                    allocPoint: tPV.allocPoint,
                    token0: tPV.token0,
                    name0: tPV.name0,
                    symbol0: tPV.symbol0,
                    decimals0: tPV.decimals0,
                    token1: tPV.token1,
                    name1: tPV.name1,
                    symbol1: tPV.symbol1,
                    decimals1: tPV.decimals1
                });
                index++;
            }
        }

        for (uint256 i = 0; i < depositPool.getPoolLength(); i++) {
            DepositPool.PoolView memory dPV = depositPool.getPoolView(i);
            DepositPool.UserView memory dUV = depositPool.getUserView(dPV.token, _account);
            uint256 unclaimedRewards = depositPool.pendingRewards(i, _account);
            if (unclaimedRewards > 0 || dUV.accRewardAmount > 0) {
                infos[index] = UserMiningInfo({
                    userAmount: dUV.stakedAmount,
                    userUnclaimedReward: dUV.unclaimedRewards,
                    userAccReward: dUV.accRewardAmount,
                    poolType: 3,
                    pid: i,
                    pair: address(0),
                    totalAmount: dPV.totalAmount,
                    rewardsPerBlock: dPV.rewardsPerBlock,
                    allocPoint: dPV.allocPoint,
                    token0: dPV.token,
                    name0: dPV.name,
                    symbol0: dPV.symbol,
                    decimals0: dPV.decimals,
                    token1: address(0),
                    name1: "",
                    symbol1: "",
                    decimals1: 0
                });
                index++;
            }
        }

        UserMiningInfo[] memory userInfos = new UserMiningInfo[](index);
        for (uint256 i = 0; i < index; i++) {
            userInfos[i] = infos[i];
        }

        return userInfos;
    }

    function harvestFarm() public {
        liquidityPool.harvestAll();
        depositPool.harvestAll();
    }

    function harvestAll() public {
        liquidityPool.harvestAll();
        depositPool.harvestAll();
        tradingPool.harvestAll();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

interface IDsgNftOwner {
    function initialize(
        string memory name_, 
        string memory symbol_, 
        address feeToken, 
        address feeWallet_, 
        bool _canUpgrade, 
        string memory baseURI_
    ) external;
    
    function transferOwnership(address newOwner) external;
}

contract DsgNftFactory is Ownable {
    
    address public logicImplement;

    event DsgNftCreated(address indexed nft, address indexed logicImplement);

    event SetLogicImplement(address indexed user, address oldLogicImplement, address newLogicImplement);
    
    constructor(address _logicImplement) public {
        logicImplement = _logicImplement;
    }
    
    function createDsgNft(
        string memory name_, 
        string memory symbol_, 
        address feeToken, 
        address feeWallet_, 
        bool _canUpgrade,
        string memory baseURI,
        address owner,
        address proxyAdmin
    ) external onlyOwner returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(logicImplement, proxyAdmin, '');
        IDsgNftOwner nft = IDsgNftOwner(address(proxy));
        nft.initialize(name_, symbol_, feeToken, feeWallet_, _canUpgrade, baseURI);
        nft.transferOwnership(owner);
        emit DsgNftCreated(address(nft), logicImplement);
        return address(nft);
    }

    function setLogicImplement(address _logicImplement) external onlyOwner {
        require(logicImplement != _logicImplement, 'Not need update');
        emit SetLogicImplement(msg.sender, logicImplement, _logicImplement);
        logicImplement = _logicImplement;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract DsgProxy is TransparentUpgradeableProxy {

    constructor(address _logic, address admin_) public TransparentUpgradeableProxy(_logic, admin_, ""){

    }
    
    function nopShowAdmin() public view returns(address) {
        return _admin();
    }
    
    function nopShowImplementation() public view returns(address) {
        return _implementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISwapAdapter.sol";
import "../interfaces/ISwapPair.sol";

contract UniAdapter is ISwapAdapter {
    using SafeMath for uint;

    //fromToken == token0
    function sellBase(address to, address pool, bytes memory) external override {
        address baseToken = ISwapPair(pool).token0();
        (uint reserveIn, uint reserveOut,) = ISwapPair(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'UniAdapter: INSUFFICIENT_LIQUIDITY');

        uint balance0 = IERC20(baseToken).balanceOf(pool);
        uint sellBaseAmount = balance0 - reserveIn;

        uint sellBaseAmountWithFee = sellBaseAmount.mul(997);
        uint numerator = sellBaseAmountWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(sellBaseAmountWithFee);
        uint receiveQuoteAmount = numerator / denominator;
        ISwapPair(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    //fromToken == token1
    function sellQuote(address to, address pool, bytes memory) external override {
        address quoteToken = ISwapPair(pool).token1();
        (uint reserveOut, uint reserveIn,) = ISwapPair(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'UniAdapter: INSUFFICIENT_LIQUIDITY');

        uint balance1 = IERC20(quoteToken).balanceOf(pool);
        uint sellQuoteAmount = balance1 - reserveIn;

        uint sellQuoteAmountWithFee = sellQuoteAmount.mul(997);
        uint numerator = sellQuoteAmountWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(sellQuoteAmountWithFee);
        uint receiveBaseAmount = numerator / denominator;
        ISwapPair(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '../interfaces/ISwapFactory.sol';
import './SwapPair.sol';

contract SwapFactory is ISwapFactory {
    using SafeMath for uint256;

    address public override feeTo;
    address public override feeToSetter;
    uint256 public override feeToRate = 0;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor() public {
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(SwapPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'SwapFactory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SwapFactory: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'SwapFactory: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(SwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        SwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'SwapFactory: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'SwapFactory: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setFeeToRate(uint256 _rate) external override {
        require(msg.sender == feeToSetter, 'SwapFactory: FORBIDDEN');
        require(_rate > 0, 'SwapFactory: FEE_TO_RATE_OVERFLOW');
        feeToRate = _rate.sub(1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '../interfaces/ISwapPair.sol';
import '../interfaces/ISwapFactory.sol';
import './Babylonian.sol';
import './FullMath.sol';
import './SwapLibrary.sol';

// library containing some math for dealing with the liquidity shares of a pair, e.g. computing their exact value
// in terms of the underlying tokens
library LiquidityMathLibrary {
    using SafeMath for uint256;

    // computes the direction and magnitude of the profit-maximizing trade
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) public pure returns (bool aToB, uint256 amountIn) {
        aToB = FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

        uint256 invariant = reserveA.mul(reserveB);

        uint256 leftSide =
            Babylonian.sqrt(
                FullMath.mulDiv(
                    invariant.mul(1000),
                    aToB ? truePriceTokenA : truePriceTokenB,
                    (aToB ? truePriceTokenB : truePriceTokenA).mul(997)
                )
            );
        uint256 rightSide = (aToB ? reserveA.mul(1000) : reserveB.mul(1000)) / 997;

        if (leftSide < rightSide) return (false, 0);

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide.sub(rightSide);
    }

    // gets the reserves after an arbitrage moves the price to the profit-maximizing ratio given an externally observed true price
    function getReservesAfterArbitrage(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        // first get reserves before the swap
        (reserveA, reserveB) = SwapLibrary.getReserves(factory, tokenA, tokenB);

        require(reserveA > 0 && reserveB > 0, 'LiquidityMathLibrary: ZERO_PAIR_RESERVES');

        // then compute how much to swap to arb to the true price
        (bool aToB, uint256 amountIn) =
            computeProfitMaximizingTrade(truePriceTokenA, truePriceTokenB, reserveA, reserveB);

        if (amountIn == 0) {
            return (reserveA, reserveB);
        }

        // now affect the trade to the reserves
        if (aToB) {
            uint256 amountOut = SwapLibrary.getAmountOut(amountIn, reserveA, reserveB);
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            uint256 amountOut = SwapLibrary.getAmountOut(amountIn, reserveB, reserveA);
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }

    // computes liquidity value given all the parameters of the pair
    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint256 kLast
    ) public pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint256 rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            uint256 rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 numerator1 = totalSupply;
                uint256 numerator2 = rootK.sub(rootKLast);
                uint256 denominator = rootK.mul(5).add(rootKLast);
                uint256 feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }
        return (reservesA.mul(liquidityAmount) / totalSupply, reservesB.mul(liquidityAmount) / totalSupply);
    }

    // get all current parameters from the pair and compute value of a liquidity amount
    // **note this is subject to manipulation, e.g. sandwich attacks**. prefer passing a manipulation resistant price to
    // #getLiquidityValueAfterArbitrageToPrice
    function getLiquidityValue(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) public view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (uint256 reservesA, uint256 reservesB) = SwapLibrary.getReserves(factory, tokenA, tokenB);
        ISwapPair pair = ISwapPair(SwapLibrary.pairFor(factory, tokenA, tokenB));
        bool feeOn = ISwapFactory(factory).feeTo() != address(0);
        uint256 kLast = feeOn ? pair.kLast() : 0;
        uint256 totalSupply = pair.totalSupply();
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }

    // given two tokens, tokenA and tokenB, and their "true price", i.e. the observed ratio of value of token A to token B,
    // and a liquidity amount, returns the value of the liquidity in terms of tokenA and tokenB
    function getLiquidityValueAfterArbitrageToPrice(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) public view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        bool feeOn = ISwapFactory(factory).feeTo() != address(0);
        ISwapPair pair = ISwapPair(SwapLibrary.pairFor(factory, tokenA, tokenB));
        uint256 kLast = feeOn ? pair.kLast() : 0;
        uint256 totalSupply = pair.totalSupply();

        // this also checks that totalSupply > 0
        require(totalSupply >= liquidityAmount && liquidityAmount > 0, 'ComputeLiquidityValue: LIQUIDITY_AMOUNT');

        (uint256 reservesA, uint256 reservesB) =
            getReservesAfterArbitrage(factory, tokenA, tokenB, truePriceTokenA, truePriceTokenB);

        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.6.12;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
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
        } else z = 0;
    }
}

// SPDX-License-Identifier: CC-BY-4.0

pragma solidity =0.6.12;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Timelock {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint256 delay_) public {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
    }

    receive() external payable {}

    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}