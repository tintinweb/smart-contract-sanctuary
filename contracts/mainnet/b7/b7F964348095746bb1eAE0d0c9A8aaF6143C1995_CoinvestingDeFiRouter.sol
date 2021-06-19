// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ICoinvestingDeFiFactory.sol";
import "./IERC20.sol";
import './SafeMath.sol';
import "./ICoinvestingDeFiRouter.sol";
import "./IWETH.sol";
import "./CoinvestingDeFiLibrary.sol";
import "./TransferHelper.sol";

contract CoinvestingDeFiRouter is ICoinvestingDeFiRouter {
    using SafeMath for uint;
    // Variables
    address public immutable override factory;
    address public immutable override WETH;
    
    // Modifiers
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "RTR: EXPD");
        _;
    }

    // Constructor
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    // Receive function
    receive() external payable {
        // only accept ETH via fallback from the WETH contract
        assert(msg.sender == WETH); 
    }

    // External functions
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (
        uint amountA,
        uint amountB,
        uint liquidity
    )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        address pair = CoinvestingDeFiLibrary.pairFor(
            factory,
            tokenA,
            tokenB
        );
        
        TransferHelper.safeTransferFrom(
            tokenA,
            msg.sender,
            pair,
            amountA
        );

        TransferHelper.safeTransferFrom(
            tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = ICoinvestingDeFiPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (
        uint amountToken,
        uint amountETH,
        uint liquidity
    )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        address pair = CoinvestingDeFiLibrary.pairFor(
            factory,
            token,
            WETH
        );

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            pair,
            amountToken
        );

        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(
                pair,
                amountETH
            )
        );

        liquidity = ICoinvestingDeFiPair(pair).mint(to);        
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - amountETH
            );
        }
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    virtual
    override
    returns (
        uint amountToken,
        uint amountETH
    )
    {
        address pair = CoinvestingDeFiLibrary.pairFor(
            factory,
            token,
            WETH
        );

        uint value = approveMax ? type(uint).max : liquidity;
        ICoinvestingDeFiPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    virtual
    override
    returns (uint amountETH)
    {
        address pair = CoinvestingDeFiLibrary.pairFor(
            factory,
            token,
            WETH
        );

        uint value = approveMax ? type(uint).max : liquidity;
        ICoinvestingDeFiPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    virtual
    override
    returns (
        uint amountA,
        uint amountB
    )
    {
        address pair = CoinvestingDeFiLibrary.pairFor(
            factory,
            tokenA,
            tokenB
        );

        uint value = approveMax ? type(uint).max : liquidity;
        ICoinvestingDeFiPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "RTR: INV_P");
        amounts = CoinvestingDeFiLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );

        require(amounts[0] <= msg.value, "RTR: XS_IN_AMT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(
                CoinvestingDeFiLibrary.pairFor(
                    factory,
                    path[0],
                    path[1]
                ),
                amounts[0]
            )
        );

        _swap(
            amounts,
            path,
            to
        );

        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - amounts[0]
            );
        }            
    }

    function swapExactETHForTokens(
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
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "RTR: INV_P");
        amounts = CoinvestingDeFiLibrary.getAmountsOut(
            factory,
            msg.value,
            path
        );
        require(amounts[amounts.length - 1] >= amountOutMin, "RTR: INSUF_OUT_AMT");
        
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(
                CoinvestingDeFiLibrary.pairFor(
                    factory,
                    path[0],
                    path[1]
                ),
                amounts[0]
            )
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
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
        require(path[0] == WETH, "RTR: INV_P");
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(
                CoinvestingDeFiLibrary.pairFor(
                    factory,
                    path[0],
                    path[1]
                ), 
                amountIn
            )
        );
        
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(
            path,
            to
        );

        require(IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin, "RTR: INSUF_OUT_AMT");
    }

    function swapExactTokensForETH(
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
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "RTR: INV_P");
        amounts = CoinvestingDeFiLibrary.getAmountsOut(
            factory,
            amountIn,
            path
        );

        require(amounts[amounts.length - 1] >= amountOutMin, "RTR: INSUF_OUT_AMT");

        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            CoinvestingDeFiLibrary.pairFor(
                factory,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            address(this)
        );

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(
            to,
            amounts[amounts.length - 1]
        );
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        require(path[path.length - 1] == WETH, "RTR: INV_P");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            CoinvestingDeFiLibrary.pairFor(
                factory,
                path[0],
                path[1]
            ),
            amountIn
        );

        _swapSupportingFeeOnTransferTokens(
            path,
            address(this)
        );
        
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "RTR: INSUF_OUT_AMT");

        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(
            to,
            amountOut
        );
    }

    function swapExactTokensForTokens(
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
    returns (uint[] memory amounts) 
    {
        amounts = CoinvestingDeFiLibrary.getAmountsOut(
            factory,
            amountIn,
            path
        );

        require(amounts[amounts.length - 1] >= amountOutMin, "RTR: INSUF_OUT_AMT");
        
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            CoinvestingDeFiLibrary.pairFor(
                factory,
                path[0],
                path[1]
            ), 
            amounts[0]
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
            path[0],
            msg.sender,
            CoinvestingDeFiLibrary.pairFor(
                factory,
                path[0],
                path[1]
            ),
            amountIn
        );

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(
            path,
            to
        );

        require(IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin, "RTR: INSUF_OUT_AMT");
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "RTR: INV_P");
        amounts = CoinvestingDeFiLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );

        require(amounts[0] <= amountInMax, "RTR: XS_IN_AMT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            CoinvestingDeFiLibrary.pairFor(
                factory,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            address(this)
        );

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(
            to,
            amounts[amounts.length - 1]
        );
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        amounts = CoinvestingDeFiLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );

        require(amounts[0] <= amountInMax, "RTR: XS_IN_AMT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            CoinvestingDeFiLibrary.pairFor(
                factory,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    // Public functions
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (
        uint amountA,
        uint amountB
    )
    {
        address pair = CoinvestingDeFiLibrary.pairFor(
            factory,
            tokenA,
            tokenB
        );

        ICoinvestingDeFiPair(pair).transferFrom(
            msg.sender,
            pair,
            liquidity
        );

        (uint amount0, uint amount1) = ICoinvestingDeFiPair(pair).burn(to);
        (address token0,) = CoinvestingDeFiLibrary.sortTokens(
            tokenA,
            tokenB
        );

        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "RTR: INSUF_A_AMT");
        require(amountB >= amountBMin, "RTR: INSUF_B_AMT");
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (
        uint amountToken,
        uint amountETH
    ) 
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        TransferHelper.safeTransfer(
            token,
            to,
            amountToken
        );

        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(
            to,
            amountETH
        );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (uint amountETH)
    {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        TransferHelper.safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );

        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(
            to,
            amountETH
        );
    }

    // Internal functions
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    )
    internal
    virtual
    returns (
        uint amountA,
        uint amountB
    )
    {
        if (ICoinvestingDeFiFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ICoinvestingDeFiFactory(factory).createPair(tokenA, tokenB);
        }
            
        (uint reserveA, uint reserveB) = CoinvestingDeFiLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = CoinvestingDeFiLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "RTR: INSUF_B_AMT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = CoinvestingDeFiLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "RTR: INSUF_A_AMT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    )
    internal
    virtual
    {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = CoinvestingDeFiLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = 
                input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

            address to = 
                i < path.length - 2 ? 
                CoinvestingDeFiLibrary.pairFor(factory, output, path[i + 2]) : _to;

            ICoinvestingDeFiPair(CoinvestingDeFiLibrary.pairFor(
                    factory,
                    input,
                    output
                )
            ).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    )
    internal
    virtual
    {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = CoinvestingDeFiLibrary.sortTokens(input, output);
            ICoinvestingDeFiPair pair = ICoinvestingDeFiPair(CoinvestingDeFiLibrary.pairFor(
                    factory,
                    input,
                    output
                )
            );

            uint amountInput;
            uint amountOutput;
            {
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = 
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = CoinvestingDeFiLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }

            (uint amount0Out, uint amount1Out) = 
                input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            
            address to = 
                i < path.length - 2 ? 
                CoinvestingDeFiLibrary.pairFor(factory, output, path[i + 2]) : _to;
            
            pair.swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    // Public functions that are view
    function getAmountsIn(
        uint amountOut,
        address[] memory path
    )
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return CoinvestingDeFiLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    )
    public 
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return CoinvestingDeFiLibrary.getAmountsOut(
            factory,
            amountIn,
            path
        );
    }

    // Public functions that are pure
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    )
    public
    pure
    virtual
    override
    returns (uint amountIn)
    {
        return CoinvestingDeFiLibrary.getAmountIn(
            amountOut,
            reserveIn,
            reserveOut
        );
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) 
    public
    pure
    virtual
    override
    returns (uint amountOut)
    {
        return CoinvestingDeFiLibrary.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
    }

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    )
    public
    pure
    virtual
    override
    returns (uint amountB)
    {
        return CoinvestingDeFiLibrary.quote(
            amountA,
            reserveA,
            reserveB
        );
    }
}