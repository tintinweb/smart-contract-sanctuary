// SPDX-License-Identifier: MIT

/*
Gen: 
HDXXGhHP1JpnBk3b
*/
// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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
}


// File contracts/Flashswap.sol

pragma solidity >=0.8.0;




// @author Daniel Espendiller - https://github.com/Haehnchen/uniswap-arbitrage-flash-swap - espend.de
//
// e00: out of block
// e01: no profit
// e10: Requested pair is not available
// e11: token0 / token1 does not exist
// e12: src/target router empty
// e13: pancakeCall not enough tokens for buyback
// e14: pancakeCall msg.sender transfer failed
// e15: pancakeCall owner transfer failed
// e16: invalid sender
contract Flashswap {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function startArbitrage(
        // uint maxBlockNumber,
        address tokenIn, // example BUSD
        address tokenOut, // our profit and what we will get; example BNB
        uint256 amountTokenOut, // example: BNB => 10 * 1e18
        address sourceFactory,
        address sourceRouter,
        address targetRouter
    ) external {
        // require(block.number <= maxBlockNumber, 'e00');

        // recheck for stopping and gas usage
        (int256 profit, uint256 tokenInAmount) = validateArbitrage(tokenIn, tokenOut, amountTokenOut, sourceRouter, targetRouter);
        require(profit > 0, 'e01');

        address pairAddress = IUniswapV2Factory(sourceFactory).getPair(tokenIn, tokenOut); // is it cheaper to compute this locally?
        require(pairAddress != address(0), 'e10');

        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();

        require(token0 != address(0) && token1 != address(0), 'e11');

        IUniswapV2Pair(pairAddress).swap(
            tokenIn == token0 ? tokenInAmount : 0,
            tokenIn == token1 ? tokenInAmount : 0,
            address(this),
            abi.encode(sourceRouter, targetRouter)
        );
    }

    function validateArbitrage(
        address tokenIn, // example: BUSD
        address tokenOut, // example: BNB
        uint256 amountTokenOut, // example: BNB => 10 * 1e18
        address sourceRouter,
        address targetRouter
    ) public view returns(int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = tokenOut;
        path1[1] = path2[0] = tokenIn;

        uint256 amountOut = IUniswapV2Router02(sourceRouter).getAmountsOut(amountTokenOut, path1)[1];
        uint256 amountRepay = IUniswapV2Router02(targetRouter).getAmountsOut(amountOut, path2)[1];

        return (
            int256(amountRepay - amountTokenOut), // our profit or loss; example output: BNB amount
            amountOut // the amount we get from our input "amountTokenOut"; example: BUSD amount
        );
    }

    function execute(address sender, uint256 amount0, uint256 amount1, bytes calldata data) internal {
        // obtain an amount of token that you exchanged
        uint256 amountToken = amount0 == 0 ? amount1 : amount0;

        IUniswapV2Pair iUniswapV2Pair = IUniswapV2Pair(msg.sender);
        address token0 = iUniswapV2Pair.token0();
        address token1 = iUniswapV2Pair.token1();

        // require(token0 != address(0) && token1 != address(0), 'e16');
        
        // if amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        address[] memory path1 = new address[](2);
        address[] memory path = new address[](2);
        path[0] = path1[1] = amount0 == 0 ? token1 : token0; // c&p
        path[1] = path1[0] = amount0 == 0 ? token0 : token1; // c&p

        (address sourceRouter, address targetRouter) = abi.decode(data, (address, address));
        require(sourceRouter != address(0) && targetRouter != address(0), 'e12');

        //require(
        //    msg.sender == UniswapV2Library.pairFor(factory, token0, token1), 
        //    'e16'
        //); 

        // IERC20 token that we will sell for otherToken
        IERC20 token = IERC20(amount0 == 0 ? token1 : token0);
        token.approve(targetRouter, amountToken);

        // calculate the amount of token how much input token should be reimbursed
        uint256 amountRequired = IUniswapV2Router02(sourceRouter).getAmountsIn(amountToken, path1)[0];

        // swap token and obtain equivalent otherToken amountRequired as a result
        uint256 amountReceived = IUniswapV2Router02(targetRouter).swapExactTokensForTokens(
            amountToken,
            amountRequired, // we already know what we need at least for payback; get less is a fail; slippage can be done via - ((amountRequired * 19) / 981) + 1,
            path,
            address(this), // its a foreign call; from router but we need contract address also equal to "sender"
            block.timestamp + 60
        )[1];

        // fail if we didn't get enough tokens
        require(amountReceived > amountRequired, 'e13');

        IERC20 otherToken = IERC20(amount0 == 0 ? token0 : token1);

        // transfer failing already have error message
        otherToken.transfer(msg.sender, amountRequired); // send back borrow
        otherToken.transfer(tx.origin, amountReceived - amountRequired); // our win
    }

    // pancake, pancakeV2, apeswap, kebab
    function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    function waultSwapCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    // mdex
    function swapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    // pantherswap
    function pantherCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    // jetswap
    function jetswapCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    // cafeswap
    function cafeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    // @TODO: pending release
    function BiswapCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    // @TODO: pending release
    function wardenCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }
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