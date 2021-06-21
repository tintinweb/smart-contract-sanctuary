// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

// TODO: connect with @liquifi
import './liquifi-core/interfaces/PoolFactory.sol';
import './liquifi-core/interfaces/DelayedExchangePool.sol';
import {WETH as IWETH} from './liquifi-core/interfaces/WETH.sol';
import {ERC20 as IERC20} from './liquifi-core/interfaces/ERC20.sol';

import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './libraries/LiquifiLibrary.sol';
import { ConvertETH } from './interfaces/ILiquifiRouter01.sol';
import './interfaces/ILiquifiRouter02.sol';


contract LiquifiRouter is ILiquifiRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'LiquifiRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) {
        factory =_factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    /* ---- ADD LIQUIDITY ---- */
    function _addLiquidity(
        address tokenA,      address tokenB,
        uint amountADesired, uint amountBDesired,
        uint amountAMin,     uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pool if it doesn't exist yet
        // if (LiquifiLibrary.poolFor(factory, tokenA, tokenB) == address(0)) {
        //     (address token0, address token1) = LiquifiLibrary.sortTokens(tokenA, tokenB);
        //     PoolFactory(factory).getPool(token0, token1);
        // }

        (address token0,) = LiquifiLibrary.sortTokens(tokenA, tokenB);
        address pool = LiquifiLibrary.poolFor(factory, tokenA, tokenB);
        DelayedExchangePool(pool).processDelayedOrders();

        (uint reserve0, uint reserve1) = LiquifiLibrary.getReserves(pool);
        (uint reserveA, uint reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = LiquifiLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'LiquifiRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = LiquifiLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'LiquifiRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _emitMint(address tokenA, uint amountA, address tokenB, uint amountB, uint liquidity, address to, ConvertETH convertETH) internal virtual {
        (address token0, address token1) = LiquifiLibrary.sortTokens(tokenA, tokenB);
        (uint amount0, uint amount1) = tokenA == token0 ? (amountA, amountB) : (amountB, amountA);
        emit Mint(token0, amount0, token1, amount1, liquidity, to, convertETH);
    }

    function addLiquidity(
        address tokenA,      address tokenB,
        uint amountADesired, uint amountBDesired,
        uint amountAMin,     uint amountBMin,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(
            tokenA,         tokenB,
            amountADesired, amountBDesired,
            amountAMin,     amountBMin
        );

        address pool = LiquifiLibrary.poolFor(factory, tokenA, tokenB);
        TransferHelper.smartTransferFrom(tokenA, msg.sender, pool, amountA);
        TransferHelper.smartTransferFrom(tokenB, msg.sender, pool, amountB);
        liquidity = DelayedExchangePool(pool).mint(to);
        _emitMint(tokenA, amountA, tokenB, amountB, liquidity, to, ConvertETH.NONE);
    }

    function addLiquidityETH(
        address token, uint amountTokenDesired, uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline)
    returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,              WETH,
            amountTokenDesired, msg.value,
            amountTokenMin,     amountETHMin
        );

        address pool = LiquifiLibrary.poolFor(factory, token, WETH);

        TransferHelper.smartTransferFrom(token, msg.sender, pool, amountToken);

        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pool, amountETH));

        liquidity = DelayedExchangePool(pool).mint(to);
        _emitMint(WETH, amountETH, token, amountToken, liquidity, to, ConvertETH.IN_ETH);

        if (msg.value > amountETH) {
            TransferHelper.smartTransferETH(msg.sender, msg.value - amountETH);
        }
    }


    /* ---- REMOVE LIQUIDITY ---- */
    function _removeLiquidity(
        address tokenA,  address tokenB,  uint liquidity,
        uint amountAMin, uint amountBMin,
        address to, ConvertETH convertETH
    ) internal virtual returns (uint amountA, uint amountB) {
        address pool = LiquifiLibrary.poolFor(factory, tokenA, tokenB);
        require(
            DelayedExchangePool(pool).transferFrom(msg.sender, pool, liquidity), // send liquidity to pool
            "LiquifiRouter: TRANSFER_FROM_FAILED"
        );
        
        (uint amount0, uint amount1) = DelayedExchangePool(pool).burn(to, false);
        (address token0, address token1) = LiquifiLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'LiquifiRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'LiquifiRouter: INSUFFICIENT_B_AMOUNT');
    }

    function _emitBurn(address tokenA, uint amountA, address tokenB, uint amountB, uint liquidity, address to, ConvertETH convertETH) internal virtual {
        (address token0, address token1) = LiquifiLibrary.sortTokens(tokenA, tokenB);
        (uint amount0, uint amount1) = tokenA == token0 ? (amountA, amountB) : (amountB, amountA);
        emit Burn(token0, amount0, token1, amount1, liquidity, to, convertETH);
    }

    function removeLiquidity(
        address tokenA,  address tokenB,  uint liquidity,
        uint amountAMin, uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        (amountA, amountB) = _removeLiquidity(
            tokenA,     tokenB,     liquidity,
            amountAMin, amountBMin,
            to, ConvertETH.NONE
        );
        _emitBurn(tokenA, amountA, tokenB, amountB, liquidity, to, ConvertETH.NONE);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = _removeLiquidity(
            token,          WETH,           liquidity,
            amountTokenMin, amountETHMin,
            address(this),  ConvertETH.OUT_ETH
        );
        TransferHelper.smartTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.smartTransferETH(to, amountETH);
        _emitBurn(token, amountToken, WETH, amountETH, liquidity, to, ConvertETH.OUT_ETH);
    }

    // not supported
    function removeLiquidityWithPermit(
        address tokenA,     address tokenB, uint liquidity,
        uint amountAMin,    uint amountBMin,
        address to, uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) public  virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        require(false, "LiquifiRouter: UNSUPPORTED_METHOD");
        (amountA, amountB) = (0, 0);
    }
    
    // not supported
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) public  virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        require(false, "LiquifiRouter: USING_UNSUPPORTED_METHOD");
        (amountToken, amountETH) = (0, 0);
    }

    /* ---- REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ---- */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = _removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            ConvertETH.OUT_ETH
        );
        uint amountToken = IERC20(token).balanceOf(address(this));
        TransferHelper.smartTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.smartTransferETH(to, amountETH);
        _emitBurn(token, amountToken, WETH, amountETH, liquidity, to, ConvertETH.OUT_ETH);
    }

    // not supported
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        require(false, "LiquifiRouter: UNSUPPORTED_METHOD");
        amountETH = 0;
    }


    /* ---- SWAP ---- */
    // requires the initial amount to have already been sent to the first pool
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = LiquifiLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? LiquifiLibrary.poolFor(factory, output, path[i + 2]) : _to;
            
            // TODO: false not forever. Fix it
            DelayedExchangePool(LiquifiLibrary.poolFor(factory, input, output)).swap(
                to, false, amount0Out, amount1Out, new bytes(0)
            );
            _emitSwap(input, amount0Out, output, amount1Out, to, ConvertETH.NONE);
        }
    }

    function _emitSwap(address tokenIn, uint amountIn, address tokenOut, uint amountOut, address to, ConvertETH convertETH) internal virtual {
        uint fee = LiquifiLibrary.getInstantSwapFee(LiquifiLibrary.poolFor(factory, tokenIn, tokenOut));
        emit Swap(tokenIn, amountIn, tokenOut, amountOut, to, convertETH, fee);
    }

    function _processDelayedOrders(address factory, address[] memory path) internal virtual {
        require(path.length >= 2, 'LiquifiRouter: INVALID_PATH');
        for (uint i = 0; i < path.length - 1; i++) {
            address pool = LiquifiLibrary.poolFor(factory, path[i], path[i + 1]);
            DelayedExchangePool(pool).processDelayedOrders();
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        _processDelayedOrders(factory, path);

        amounts = LiquifiLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'LiquifiRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.smartTransferFrom(path[0], msg.sender, LiquifiLibrary.poolFor(factory, path[0], path[1]), amounts[0]);

        // bool isTokenAIn = properOrder(tokenIn, tokenOut);
        // (uint amountAOut, uint amountBOut, uint fee) = getAmountsOut(pool, isTokenAIn, amountIn, minAmountOut);
        // DelayedExchangePool(pool).swap(to, convertETH == ConvertETH.OUT_ETH, amountAOut, amountBOut, new bytes(0));
        // amountOut = isTokenAIn ? amountBOut : amountAOut;
        // emit Swap(tokenIn, amountIn, tokenOut, amountOut, to, convertETH, fee);

        // DelayedExchangePool(LiquifiLibrary.poolFor(factory, input, output)).swap(
        //     to, false, amount0Out, amount1Out, new bytes(0)
        // );

        // _emitSwap(path[0], amountIn, path[1], amounts[0], to, ConvertETH.NONE);
        // _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // address pool = LiquifiLibrary.poolFor(factory, input, output);
        // DelayedExchangePool(pool).processDelayedOrders();

        amounts = LiquifiLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'LiquifiRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.smartTransferFrom(
            path[0], msg.sender, LiquifiLibrary.poolFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, 'LiquifiRouter: INVALID_PATH');

        // address pool = LiquifiLibrary.poolFor(factory, input, output);
        // DelayedExchangePool(pool).processDelayedOrders();

        amounts = LiquifiLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'LiquifiRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(LiquifiLibrary.poolFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'LiquifiRouter: INVALID_PATH');

        // address pool = LiquifiLibrary.poolFor(factory, input, output);
        // DelayedExchangePool(pool).processDelayedOrders();

        amounts = LiquifiLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'LiquifiRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.smartTransferFrom(
            path[0], msg.sender, LiquifiLibrary.poolFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.smartTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'LiquifiRouter: INVALID_PATH');

        // address pool = LiquifiLibrary.poolFor(factory, input, output);
        // DelayedExchangePool(pool).processDelayedOrders();

        amounts = LiquifiLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'LiquifiRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.smartTransferFrom(
            path[0], msg.sender, LiquifiLibrary.poolFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.smartTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, 'LiquifiRouter: INVALID_PATH');

        // address pool = LiquifiLibrary.poolFor(factory, input, output);
        // DelayedExchangePool(pool).processDelayedOrders();

        amounts = LiquifiLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'LiquifiRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(LiquifiLibrary.poolFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.smartTransferETH(msg.sender, msg.value - amounts[0]);
    }

    /* ---- SWAP (supporting fee-on-transfer tokens) ---- */
    // requires the initial amount to have already been sent to the first pair
    // TODO: check it
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = LiquifiLibrary.sortTokens(input, output);
            address pool = LiquifiLibrary.poolFor(factory, input, output);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                // process long swaps
                DelayedExchangePool(pool).processDelayedOrders();

                (uint reserve0, uint reserve1) = LiquifiLibrary.getReserves(factory, input, output);
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = ERC20(input).balanceOf(pool).sub(reserveInput);
                uint fee = LiquifiLibrary.getInstantSwapFee(pool);
                amountOutput = LiquifiLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, 1000 - fee);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? LiquifiLibrary.poolFor(factory, output, path[i + 2]) : _to;
            // TODO: again false?
            DelayedExchangePool(pool).swap(to, false, amount0Out, amount1Out, new bytes(0));
            emit Swap(input, amount0Out, output, amount1Out, to, ConvertETH.NONE, LiquifiLibrary.getInstantSwapFee(pool)); // TODO: check it
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.smartTransferFrom(
            path[0], msg.sender, LiquifiLibrary.poolFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = ERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'LiquifiRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'LiquifiRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(LiquifiLibrary.poolFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = ERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'LiquifiRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, 'LiquififRouter: INVALID_PATH');
        TransferHelper.smartTransferFrom(
            path[0], msg.sender, LiquifiLibrary.poolFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = ERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'LiquififRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.smartTransferETH(to, amountOut);
    }



    /* ---- LIBRARY FUNCTIONS ---- */
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override
    returns (uint amountB) {
        return LiquifiLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure virtual override
    returns (uint amountOut) {
        return LiquifiLibrary.getAmountOut(amountIn, reserveIn, reserveOut, 997); // TODO: for some pool have same fee, update it
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure virtual override
    returns (uint amountIn) {
        return LiquifiLibrary.getAmountIn(amountOut, reserveIn, reserveOut, 997); // TODO: for some pool have same fee, update it
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view virtual override
    returns (uint[] memory amounts) {
        return LiquifiLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view virtual override 
    returns (uint[] memory amounts) {
        return LiquifiLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >= 0.7.0;

interface PoolFactory {
    event PoolCreatedEvent(address tokenA, address tokenB, bool aIsWETH, address indexed pool);

    function getPool(address tokenA, address tokenB) external returns (address);
    function findPool(address tokenA, address tokenB) external view returns (address);
    function pools(uint poolIndex) external view returns (address pool);
    function getPoolCount() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

import { LiquidityPool } from "./LiquidityPool.sol";

interface DelayedExchangePool is LiquidityPool {
    event FlowBreakEvent( 
        address sender, 
        // total balance contains 128 bit of totalBalanceA and 128 bit of totalBalanceB
        uint totalBalance, 
        // contains 128 bits of rootKLast and 128 bits of totalSupply
        uint rootKLastTotalSupply, 
        uint indexed orderId,
        // breakHash is computed over all fields below
        
        bytes32 lastBreakHash,
        // availableBalance consists of 128 bits of availableBalanceA and 128 bits of availableBalanceB
        uint availableBalance, 
        // flowSpeed consists of 144 bits of poolFlowSpeedA and 112 higher bits of poolFlowSpeedB
        uint flowSpeed,
        // others consists of 32 lower bits of poolFlowSpeedB, 16 bit of notFee, 64 bit of time, 64 bit of orderId, 76 higher bits of packed and 4 bit of reason (BreakReason)
        uint others      
    );

    event OrderClaimedEvent(uint indexed orderId, address to);
    event OperatingInInvalidState(uint location, uint invalidStateReason);
    event GovernanceApplied(uint packedGovernance);
    
    function addOrder(
        address owner, uint orderFlags, uint prevByStopLoss, uint prevByTimeout, 
        uint stopLossAmount, uint period
    ) external returns (uint id);

    // availableBalance contains 128 bits of availableBalanceA and 128 bits of availableBalanceB
    // delayedSwapsIncome contains 128 bits of delayedSwapsIncomeA and 128 bits of delayedSwapsIncomeB
    function processDelayedOrders() external payable returns (uint availableBalance, uint delayedSwapsIncome, uint packed);

    function claimOrder (
        bytes32 previousBreakHash,
        // see LiquifyPoolRegister.claimOrder for breaks list details
        uint[] calldata breaksHistory
    ) external returns (address owner, uint amountAOut, uint amountBOut);

    function applyGovernance(uint packedGovernanceFields) external;
    function sync() external;
    function closeOrder(uint id) external;

    function poolQueue() external view returns (
        uint firstByTokenAStopLoss, uint lastByTokenAStopLoss, // linked list of orders sorted by (amountAIn/stopLossAmount) ascending
        uint firstByTokenBStopLoss, uint lastByTokenBStopLoss, // linked list of orders sorted by (amountBIn/stopLossAmount) ascending
    
        uint firstByTimeout, uint lastByTimeout // linked list of orders sorted by timeouts ascending
    );

    function lastBreakHash() external view returns (bytes32);

    function poolState() external view returns (
        bytes32 _prevBlockBreakHash,
        uint packed, // see Liquifi.PoolState for details
        uint notFee,

        uint lastBalanceUpdateTime,
        uint nextBreakTime,
        uint maxHistory,
        uint ordersToClaimCount,
        uint breaksCount
    );

    function findOrder(uint orderId) external view returns (        
        uint nextByTimeout, uint prevByTimeout,
        uint nextByStopLoss, uint prevByStopLoss,
        
        uint stopLossAmount,
        uint amountIn,
        uint period,
        
        address owner,
        uint timeout,
        uint flags
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

import { ERC20 } from "./ERC20.sol";

interface WETH is ERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256 supply);

    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "./../liquifi-core/interfaces/ERC20.sol";


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function smartApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.approve.selector /*0x095ea7b3*/, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function smartTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    function smartTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.transfer.selector /*0xa9059cbb*/, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TOKEN_TRANSFER_FAILED"
        );
    }

    function smartTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.transferFrom.selector /*0x23b872dd*/, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import './../liquifi-core/interfaces/PoolFactory.sol';
import './../liquifi-core/interfaces/LiquidityPool.sol';
import './../liquifi-core/interfaces/DelayedExchangePool.sol';

import "./SafeMath.sol";

library LiquifiLibrary {
    using SafeMath for uint;

    // deprecated
    // Registry always creates pools with tokens in proper order
    // function properOrder(address tokenA, address tokenB) internal view returns (bool) {
    //     return (tokenA == address(weth) ? address(0) : tokenA) < (tokenB == address(weth) ? address(0) : tokenB);
    // }

    // returns sorted token addresses, used to handle return values from pools sorted in this order
    function sortTokens(address tokenA, address tokenB)
    internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'LiquifiLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'LiquifiLibrary: ZERO_ADDRESS');
    }

/* TODO: improve with hash code
    // calculates the address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
            ))));
    }
*/
    // calculates the address for a pool
    function poolFor(address factory, address tokenA, address tokenB) internal view returns (address pool) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pool = PoolFactory(factory).findPool(token0, token1);
        require(pool != address(0), 'LiquifiLibrary: INVALID_POOL_ADDRESS');
    }

    // fetches the reserves for a pool
    // ATTENTION: call DelayedExchangePool(pool).processDelayedOrders() before use this method
    function getReserves(address pool)
    internal view returns (uint reserve0, uint reserve1) {
        (uint balance0Locked, , uint balance1Locked, , uint totalBalance0, uint totalBalance1, ,) = LiquidityPool(pool).poolBalances();
        reserve0 = totalBalance0.sub(balance0Locked);
        reserve1 = totalBalance1.sub(balance1Locked);
    }

    // fetches and sorts the reserves for a pool
    // ATTENTION: call DelayedExchangePool(pool).processDelayedOrders() before use this method
    function getReserves(address factory, address tokenA, address tokenB)
    internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve1, uint reserve0) = getReserves(poolFor(factory, tokenA, tokenB));
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pool reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'LiquifiLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'LiquifiLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // fetches the instant swap fee for a pool
    function getInstantSwapFee(address pool) internal view returns (uint8 instantSwapFee) {
        (, uint packed, ,,,,,) = DelayedExchangePool(pool).poolState();
        instantSwapFee = uint8(packed >> 88);
    }

    // given an input amount of an asset and pool reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint notFee)
    internal pure returns (uint amountOut) {
        require(0 <= notFee && notFee <= 1000, 'LiquifiLibrary: INSUFFICIENT_FEE');
        require(amountIn > 0, 'LiquifiLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'LiquifiLibrary: INSUFFICIENT_LIQUIDITY');

        uint amountInWithFee = amountIn.mul(notFee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pool reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint notFee)
    internal pure returns (uint amountIn) {
        require(0 <= notFee && notFee <= 1000, 'LiquifiLibrary: INSUFFICIENT_FEE');
        require(amountOut > 0, 'LiquifiLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'LiquifiLibrary: INSUFFICIENT_LIQUIDITY');

        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(notFee);
        amountIn = (numerator / denominator).add(1); // TODO: ().add(1) for what?
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path)
    internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'LiquifiLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            uint fee = getInstantSwapFee(poolFor(factory, path[i], path[i + 1]));
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, 1000 - fee);
        }
    }

/* TODO: fee for multiple exchange
    // deprecated
    function swapPaysFee(uint availableBalance, uint delayedSwapsIncome, uint amountAOut, uint amountBOut) private pure returns (bool) {
        uint availableBalanceA = uint128(availableBalance >> 128);
        uint availableBalanceB = uint128(availableBalance);

        uint delayedSwapsIncomeA = uint128(delayedSwapsIncome >> 128);
        uint delayedSwapsIncomeB = uint128(delayedSwapsIncome);
        
        uint exceedingAIncome = availableBalanceB == 0 ? 0 : uint(delayedSwapsIncomeA).subWithClip(uint(delayedSwapsIncomeB) * availableBalanceA / availableBalanceB);
        uint exceedingBIncome = availableBalanceA == 0 ? 0 : uint(delayedSwapsIncomeB).subWithClip(uint(delayedSwapsIncomeA) * availableBalanceB / availableBalanceA);
        
        return amountAOut > exceedingAIncome || amountBOut > exceedingBIncome;
    }

    // deprecated
    function getAmountsOut(address pool, bool isTokenAIn, uint amountIn, uint minAmountOut) private returns (uint amountAOut, uint amountBOut, uint fee) {
        (uint availableBalance, uint delayedSwapsIncome, uint packed) = DelayedExchangePool(pool).processDelayedOrders();
        uint availableBalanceA = uint128(availableBalance >> 128);
        uint availableBalanceB = uint128(availableBalance);
        (uint instantSwapFee) = unpackGovernance(packed);

        uint amountOut;
        if (isTokenAIn) {
            amountOut = getAmountOut(amountIn, availableBalanceA, availableBalanceB, 1000);
            if (swapPaysFee(availableBalance, delayedSwapsIncome, 0, amountOut)) {
                amountOut = getAmountOut(amountIn, availableBalanceA, availableBalanceB, 1000 - instantSwapFee);
                fee = instantSwapFee;
            }    
            amountBOut = amountOut;
        } else { 
            amountOut = getAmountOut(amountIn, availableBalanceB, availableBalanceA, 1000);
            if (swapPaysFee(availableBalance, delayedSwapsIncome, amountOut, 0)) {
                amountOut = getAmountOut(amountIn, availableBalanceB, availableBalanceA, 1000 - instantSwapFee);
                fee = instantSwapFee;
            }
            amountAOut = amountOut;
        }
        require(amountOut >= minAmountOut, "LIQIFI: INSUFFICIENT_OUTPUT_AMOUNT");
    }
*/

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path)
    internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'LiquifiLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            uint fee = getInstantSwapFee(poolFor(factory, path[i - 1], path[i]));
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, 1000 - fee);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

enum ConvertETH { NONE, IN_ETH, OUT_ETH }

interface ILiquifiRouter01 {
    /* ---- Events ---- */
    event Mint(address token1, uint amount1, address token2, uint amount2, uint liquidityOut, address to, ConvertETH convertETH);
    event Burn(address token1, uint amount1, address token2, uint amount2, uint liquidityIn, address to, ConvertETH convertETH);
    event Swap(address tokenIn, uint amountIn, address tokenOut, uint amountOut, address to, ConvertETH convertETH, uint fee);
    event DelayedSwap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, ConvertETH convertETH, uint16 period, uint64 orderId);
    event OrderClaimed(uint orderId, address tokenA, uint amountAOut, address tokenB, uint amountBOut, address to);

    /* ---- Read-Only Functions ---- */
    /// Returns factory address
    function factory() external view returns (address);

    /// Returns the canonical WETH\WBNB address on the Blockchain network
    function WETH() external view returns (address);
    
    /// Given some asset amount and reserves, returns an amount of the other asset representing equivalent value.
    /// - Useful for calculating optimal token amounts before calling mint.
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    /// Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves.
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    /// Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves.
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    
    /// Given an input asset amount and an array of token addresses, calculates all subsequent maximum
    /// output token amounts by calling getReserves for each pair of token addresses in the path in turn,
    /// and using these to call getAmountOut.
    /// - Useful for calculating optimal token amounts before calling swap.
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    /// Given an output asset amount and an array of token addresses, calculates all preceding minimum
    /// input token amounts by calling getReserves for each pair of token addresses in the path in turn,
    /// and using these to call getAmountIn.
    /// - Useful for calculating optimal token amounts before calling swap.
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);


    /* ---- State-Changing Functions ---- */
    function addLiquidity(
        address tokenA,      address tokenB,
        uint amountADesired, uint amountBDesired,
        uint amountAMin,     uint amountBMin,
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
    
    // Not supported
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
    
    // Not supported
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    
    /// Swaps an exact amount of input tokens for as many output tokens as possible, along the route
    /// determined by the path. The first element of path is the input token, the last is the output token,
    /// and any intermediate elements represent intermediate pairs to trade through (if, for example,
    /// a direct pair does not exist).
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /// Receive an exact amount of output tokens for as few input tokens as possible, along the route
    /// determined by the path. The first element of path is the input token, the last is the output token,
    /// and any intermediate elements represent intermediate tokens to trade through (if, for example,
    /// a direct pair does not exist).
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /// Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path.
    /// The first element of path must be WETH, the last is the output token, and any intermediate elements represent
    /// intermediate pairs to trade through (if, for example, a direct pair does not exist).
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /// Receive an exact amount of ETH for as few input tokens as possible, along the route determined by the path.
    /// The first element of path is the input token, the last must be WETH, and any intermediate elements represent
    /// intermediate pairs to trade through (if, for example, a direct pair does not exist).    
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    
    /// Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path.
    /// The first element of path is the input token, the last must be WETH, and any intermediate elements represent
    /// intermediate pairs to trade through (if, for example, a direct pair does not exist).
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    
    /// Receive an exact amount of tokens for as little ETH as possible, along the route determined by the path.
    /// The first element of path must be WETH, the last is the output token and any intermediate elements represent
    /// intermediate pairs to trade through (if, for example, a direct pair does not exist).
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import './ILiquifiRouter01.sol';

interface ILiquifiRouter02 is ILiquifiRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    // Not supported
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    /// Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    /// Identical to swapExactETHForTokens, but succeeds for tokens that take a fee on transfer.
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    /// Identical to swapExactTokensForETH, but succeeds for tokens that take a fee on transfer.
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

import { ERC20 } from "./ERC20.sol";
import { GovernanceRouter } from "./GovernanceRouter.sol";

interface LiquidityPool is ERC20 {
    enum MintReason { DEPOSIT, PROTOCOL_FEE, INITIAL_LIQUIDITY }
    event Mint(address indexed to, uint256 value, MintReason reason);

    // ORDER_CLOSED reasons are all odd, other reasons are even
    // it allows to check ORDER_CLOSED reasons as (reason & ORDER_CLOSED) != 0
    enum BreakReason { 
        NONE,        ORDER_CLOSED, 
        ORDER_ADDED, ORDER_CLOSED_BY_STOP_LOSS, 
        SWAP,        ORDER_CLOSED_BY_REQUEST,
        MINT,        ORDER_CLOSED_BY_HISTORY_LIMIT,
        BURN,        ORDER_CLOSED_BY_GOVERNOR
    }

    function poolBalances() external view returns (
        uint balanceALocked,
        uint poolFlowSpeedA, // flow speed: (amountAIn * 2^32)/second

        uint balanceBLocked,
        uint poolFlowSpeedB, // flow speed: (amountBIn * 2^32)/second

        uint totalBalanceA,
        uint totalBalanceB,

        uint delayedSwapsIncome,
        uint rootKLastTotalSupply
    );

    function governanceRouter() external returns (GovernanceRouter);
    function minimumLiquidity() external returns (uint);
    function aIsWETH() external returns (bool);

    function mint(address to) external returns (uint liquidityOut);
    function burn(address to, bool extractETH) external returns (uint amountAOut, uint amountBOut);
    function swap(address to, bool extractETH, uint amountAOut, uint amountBOut, bytes calldata externalData) external returns (uint amountAIn, uint amountBIn);

    function tokenA() external view returns (ERC20);
    function tokenB() external view returns (ERC20);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

import { ActivityMeter } from "./ActivityMeter.sol";
import { Minter } from "./Minter.sol";
import { PoolFactory } from "./PoolFactory.sol";
import { WETH } from './WETH.sol';
import { ERC20 } from "./ERC20.sol";

interface GovernanceRouter {
    event GovernanceApplied(uint packedGovernance);
    event GovernorChanged(address covernor);
    event ProtocolFeeReceiverChanged(address protocolFeeReceiver);
    event PoolFactoryChanged(address poolFactory);

    function schedule() external returns(uint timeZero, uint miningPeriod);
    function creator() external returns(address);
    function weth() external returns(WETH);

    function activityMeter() external returns(ActivityMeter);
    function setActivityMeter(ActivityMeter _activityMeter) external;

    function minter() external returns(Minter);
    function setMinter(Minter _minter) external;

    function poolFactory() external returns(PoolFactory);
    function setPoolFactory(PoolFactory _poolFactory) external;

    function protocolFeeReceiver() external returns(address);
    function setProtocolFeeReceiver(address _protocolFeeReceiver) external;

    function governance() external view returns (address _governor, uint96 _defaultGovernancePacked);
    function setGovernor(address _governor) external;
    function applyGovernance(uint96 _defaultGovernancePacked) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;
import { GovernanceRouter } from "./GovernanceRouter.sol";

interface ActivityMeter {
    event Deposit(address indexed user, address indexed pool, uint amount);
    event Withdraw(address indexed user, address indexed pool, uint amount);

    function actualizeUserPool(uint endPeriod, address user, address pool) external returns (uint ethLocked, uint mintedAmount) ;  
    function deposit(address pool, uint128 amount) external returns (uint ethLocked, uint mintedAmount);
    function withdraw(address pool, uint128 amount) external returns (uint ethLocked, uint mintedAmount);
    function actualizeUserPools() external returns (uint ethLocked, uint mintedAmount);
    function liquidityEthPriceChanged(uint effectiveTime, uint availableBalanceEth, uint totalSupply) external;
    function effectivePeriod(uint effectiveTime) external view returns (uint periodNumber, uint quantaElapsed);
    function governanceRouter() external view returns (GovernanceRouter);
    function userEthLocked(address user) external view returns (uint ethLockedPeriod, uint ethLocked, uint totalEthLocked);
    
    function ethLockedHistory(uint period) external view returns (uint ethLockedTotal);

    function poolsPriceHistory(uint period, address pool) external view returns (
        uint cumulativeEthPrice,
        uint240 lastEthPrice,
        uint16 timeRef
    );

    function userPoolsSummaries(address user, address pool) external view returns (
        uint144 cumulativeAmountLocked,
        uint16 amountChangeQuantaElapsed,

        uint128 lastAmountLocked,
        uint16 firstPeriod,
        uint16 lastPriceRecord,
        uint16 earnedForPeriod
    );

    function userPools(address user, uint poolIndex) external view returns (address pool);
    function userPoolsLength(address user) external view returns (uint length);

    function userSummaries(address user) external view returns (
        uint128 ethLocked,
        uint16 ethLockedPeriod,
        uint16 firstPeriod
    );
    
    function poolSummaries(address pool) external view returns (
        uint16 lastPriceRecord
    );
    
    function users(uint userIndex) external view returns (address user);
    function usersLength() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;
import { GovernanceRouter } from "./GovernanceRouter.sol";
import { ActivityMeter } from "./ActivityMeter.sol";
import { ERC20 } from "./ERC20.sol";

interface Minter is ERC20 {
    event Mint(address indexed to, uint256 value, uint indexed period, uint userEthLocked, uint totalEthLocked);

    function governanceRouter() external view returns (GovernanceRouter);
    function mint(address to, uint period, uint128 userEthLocked, uint totalEthLocked) external returns (uint amount);
    function userTokensToClaim(address user) external view returns (uint amount);
    function periodTokens(uint period) external pure returns (uint128);
    function periodDecayK() external pure returns (uint decayK);
    function initialPeriodTokens() external pure returns (uint128);
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