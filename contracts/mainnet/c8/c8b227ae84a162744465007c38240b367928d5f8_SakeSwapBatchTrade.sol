// File: contracts/sakeswap/interfaces/ISakeSwapRouter.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface ISakeSwapRouter {
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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH
        );

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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB
        );

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
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
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
        uint256 deadline,
        bool ifmint
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool ifmint
    ) external;
}

// File: contracts/sakeswap/interfaces/IERC20.sol

pragma solidity >=0.5.0;

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
    function mint(address to, uint value) external returns (bool);
    function burn(address from, uint value) external returns (bool);
}

// File: contracts/sakeswap/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/sakeswap/interfaces/ISakeSwapFactory.sol

pragma solidity >=0.5.0;

interface ISakeSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// File: contracts/sakeswap/interfaces/ISakeSwapPair.sol

pragma solidity >=0.5.0;

interface ISakeSwapPair {
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
    function stoken() external view returns (address);
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
    function dealSlippageWithIn(address[] calldata path, uint amountIn, address to, bool ifmint) external returns (uint amountOut);
    function dealSlippageWithOut(address[] calldata path, uint amountOut, address to, bool ifmint) external returns (uint extra);
    function getAmountOutMarket(address token, uint amountIn) external view returns (uint _out, uint t0Price);
    function getAmountInMarket(address token, uint amountOut) external view returns (uint _in, uint t0Price);
    function getAmountOutFinal(address token, uint256 amountIn) external view returns (uint256 amountOut, uint256 stokenAmount);
    function getAmountInFinal(address token, uint256 amountOut) external view returns (uint256 amountIn, uint256 stokenAmount);
    function getTokenMarketPrice(address token) external view returns (uint price);
}

// File: contracts/sakeswap/libraries/SafeMath.sol

pragma solidity =0.6.12;

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

// File: contracts/tools/SakeSwapBatchTrade.sol

pragma solidity 0.6.12;







contract SakeSwapBatchTrade {
    using SafeMath for uint256;
    ISakeSwapFactory public factory = ISakeSwapFactory(0x75e48C954594d64ef9613AeEF97Ad85370F13807);
    ISakeSwapRouter public router = ISakeSwapRouter(0x9C578b573EdE001b95d51a55A3FAfb45f5608b1f);
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // constructor(address _router, address _weth, address _factory) public {
    //     router = ISakeSwapRouter(_router);
    //     weth = _weth;
    //     factory = ISakeSwapFactory(_factory);
    // }

    event MultiSwap(address indexed user, uint256 consume, uint256 stoken, uint256 lptoken);

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    function swapExactETHForTokens(
        address token,
        uint8 swapTimes,
        bool addLiquidity
    )
        external
        payable
        returns (
            uint256 consumeAmount,
            uint256 stokenAmount,
            uint256 lptokenAmount
        )
    {
        require(msg.value > 0 && (swapTimes > 0 || addLiquidity == true), "invalid params");
        consumeAmount = msg.value;
        address pair = factory.getPair(weth, token);
        address stoken = ISakeSwapPair(pair).stoken();
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(address(router), uint256(-1));
        IERC20(token).approve(address(router), uint256(-1));
        if (swapTimes > 0) _swapExactTokensForTokens(weth, token, swapTimes);
        uint256 remain = IERC20(weth).balanceOf(address(this));
        if (addLiquidity) {
            lptokenAmount = _addLiquidity(weth, token, remain);
            uint256 wethDust = IERC20(weth).balanceOf(address(this));
            if (wethDust > 0) {
                IWETH(weth).withdraw(wethDust);
                msg.sender.transfer(wethDust);
            }
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
            consumeAmount = consumeAmount.sub(wethDust);
        } else {
            IWETH(weth).withdraw(remain);
            msg.sender.transfer(remain);
            consumeAmount = consumeAmount.sub(remain);
        }
        stokenAmount = IERC20(stoken).balanceOf(address(this));
        IERC20(stoken).transfer(msg.sender, stokenAmount);
        emit MultiSwap(msg.sender, consumeAmount, stokenAmount, lptokenAmount);
    }

    // function swapExactTokensForTokens(
    //     address tokenA,
    //     address tokenB,
    //     uint256 amountIn,
    //     uint8 swapTimes,
    //     bool addLiquidity
    // )
    //     external
    //     returns (
    //         uint256 consumeAmount,
    //         uint256 stokenAmount,
    //         uint256 lptokenAmount
    //     )
    // {
    //     require(amountIn > 0 && (swapTimes > 0 || addLiquidity == true), "invalid params");
    //     IERC20(tokenA).approve(address(router), uint256(-1));
    //     IERC20(tokenB).approve(address(router), uint256(-1));
    //     address pair = factory.getPair(tokenA, tokenB);
    //     address stoken = ISakeSwapPair(pair).stoken();
    //     IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
    //     if (swapTimes > 0) _swapExactTokensForTokens(tokenA, tokenB, swapTimes);
    //     if (addLiquidity) lptokenAmount = _addLiquidity(tokenA, tokenB, IERC20(tokenA).balanceOf(address(this)));
    //     consumeAmount = amountIn.sub(IERC20(tokenA).balanceOf(address(this)));
    //     stokenAmount = IERC20(stoken).balanceOf(address(this));
    //     IERC20(tokenA).transfer(msg.sender, IERC20(tokenA).balanceOf(address(this)));
    //     IERC20(tokenB).transfer(msg.sender, IERC20(tokenB).balanceOf(address(this)));
    //     IERC20(stoken).transfer(msg.sender, stokenAmount);
    //     emit MultiSwap(msg.sender, consumeAmount, stokenAmount, lptokenAmount);
    // }

    function _swapExactTokensForTokens(
        address tokenA,
        address tokenB,
        uint8 swapTimes
    ) internal {
        address[] memory pathForward = new address[](2);
        address[] memory pathBackward = new address[](2);
        pathForward[0] = tokenA;
        pathForward[1] = tokenB;
        pathBackward[0] = tokenB;
        pathBackward[1] = tokenA;
        for (uint8 i = 0; i < swapTimes; i++) {
            uint256 amountA = IERC20(tokenA).balanceOf(address(this));
            router.swapExactTokensForTokens(amountA, 0, pathForward, address(this), now + 60, true);
            uint256 amountB = IERC20(tokenB).balanceOf(address(this));
            router.swapExactTokensForTokens(amountB, 0, pathBackward, address(this), now + 60, true);
        }
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amount
    ) internal returns (uint256 liquidity) {
        uint256 half = amount / 2;
        uint256 swapAmount = amount.sub(half);
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        router.swapExactTokensForTokens(swapAmount, 0, path, address(this), now + 60, false);
        (, , liquidity) = router.addLiquidity(
            tokenA,
            tokenB,
            half,
            IERC20(tokenB).balanceOf(address(this)),
            0,
            0,
            msg.sender,
            now + 60
        );
    }
}