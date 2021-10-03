/**
 *Submitted for verification at polygonscan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
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
interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

contract ArbitrageV2 is IUniswapV2Callee {
    address public sushiFactory;
    address public quickFactory;
    IUniswapV2Router02 public sushiRouter;
    IUniswapV2Router02 public quickRouter;
    uint256 private DEX_SUSHI = 0;
    uint256 private DEX_QUICK = 1;

    constructor(
        address _sushiFactory,
        address _quickFactory,
        IUniswapV2Router02 _sushiRouter,
        IUniswapV2Router02 _quickRouter
    ) public {
        sushiFactory = _sushiFactory;
        quickFactory = _quickFactory;
        sushiRouter = _sushiRouter;
        quickRouter = _quickRouter;
    }

    function startArbitrage(
        address weth,
        address dai,
        uint256 wethAmount,
        uint256 onExchange
    ) external {
        address factoryToUse = onExchange == DEX_SUSHI
            ? sushiFactory
            : quickFactory;
        address pairAddress = IUniswapV2Factory(factoryToUse).getPair(
            weth,
            dai
        );
        require(pairAddress != address(0), "This pool does not exist");
        IUniswapV2Pair(pairAddress).swap(
            wethAmount,
            0,
            address(this),
            bytes("not empty") //not empty bytes param will trigger flashloan
        );
    }
    address[] private path;
    uint256 public amountToken;
    address private token0;
    address private token1;
    address private sushiPairAddress;
    address private quickPairAddress;
    uint256 public dexLended;
    uint256 public loanedEth;
    uint256 public returnDai;
    uint256 public swappedDai;
    uint256 public dustEth;
    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external virtual override {
        path = new address[](2);
        amountToken = _amount0;
        loanedEth = amountToken;
        require(amountToken>0, "Expected token not received");
        token0 = IUniswapV2Pair(msg.sender).token0();
        token1 = IUniswapV2Pair(msg.sender).token1();

        sushiPairAddress = IUniswapV2Factory(sushiFactory).getPair(
            token0,
            token1
        );
        quickPairAddress = IUniswapV2Factory(quickFactory).getPair(
            token0,
            token1
        );

        dexLended = sushiPairAddress == address(msg.sender)
            ? DEX_SUSHI
            : DEX_QUICK;
        require(_amount0 != 0 && _amount1 == 0, "Wrong fund dispatched");

        //swap on other exchange
        path[0] = token0;
        path[1] = token1;
        IERC20 weth = IERC20(token0);
        IERC20 dai = IERC20(token1);
        uint256 amountRequiredToReturn;
        if (dexLended == DEX_SUSHI) {

                IUniswapV2Pair sushiPair = IUniswapV2Pair(sushiPairAddress);
                (uint256 wethReserve, uint256 daiReserve, )= sushiPair.getReserves();
                amountRequiredToReturn = sushiRouter.getAmountIn(amountToken, daiReserve, wethReserve);
            
            require(amountRequiredToReturn>0 , "amount required to return not valid");
            uint256[] memory minOuts2 = quickRouter.getAmountsOut(
                amountToken,
                path
            );
            require(minOuts2[1]>0 , "amount estimated from swap not valid");
            weth.approve(address(quickRouter), amountToken);
            quickRouter.swapExactTokensForTokens(amountToken, minOuts2[1], path, address(this), block.timestamp);
            swappedDai = dai.balanceOf(address(this));
        }
        if (dexLended == DEX_QUICK) {
                IUniswapV2Pair quickPair = IUniswapV2Pair(sushiPairAddress);
                (uint256 wethReserveq, uint256 daiReserveq ,) = quickPair.getReserves();
                amountRequiredToReturn = quickRouter.getAmountIn(amountToken, daiReserveq, wethReserveq);
            require(amountRequiredToReturn>0 , "amount required to return not valid");
            uint256[] memory minOuts2 = sushiRouter.getAmountsOut(
                weth.balanceOf(address(this)),
                path
            );
             require(minOuts2[1]>0 , "amount estimated from swap not valid");
            weth.approve(address(sushiRouter), amountToken);
            sushiRouter.swapExactTokensForTokens(weth.balanceOf(address(this)), minOuts2[1], path, address(this), block.timestamp);
            swappedDai = dai.balanceOf(address(this));
        }
        returnDai = amountRequiredToReturn;
        dustEth = weth.balanceOf(address(this));
        require(dai.balanceOf(address(this))> amountRequiredToReturn, "Transaction with loss");
        dai.transfer(msg.sender, amountRequiredToReturn);
    }

    function withdraw(IERC20 dai) external {
        dai.transfer(msg.sender, dai.balanceOf(address(this)));
    }
}