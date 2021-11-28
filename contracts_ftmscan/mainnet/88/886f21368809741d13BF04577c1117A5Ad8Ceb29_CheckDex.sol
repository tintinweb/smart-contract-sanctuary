/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import "UniswapInterfaces.sol";
import "UniswapLibrary.sol";


/**
 * @title BeraTemplate
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Welcome to the Bera Gang!
 */
contract CheckDex {
    // IUniswapV2Router02 spirit_router = IUniswapV2Router02("0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52");
    // IUniswapV2Router02 spooky_router = IUniswapV2Router02("0xF491e7B69E4244ad4002BC14e878a34207E38c29");
    // address CRV = "0x1e4f97b9f9f913c46f1632781732927b9019c68b";
    // address WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
    function query(
        address router1Address,
        address router2Address,
        uint256 inAmount,
        address inToken,
        address outToken
    ) public view virtual returns (uint256, uint256) {
        IUniswapV2Router02 router1 = IUniswapV2Router02(router1Address);
        (uint112 inReserves1, uint112 outReserves1) = UniswapLibrary.getReserves(router1.factory(), inToken, outToken);
        IUniswapV2Router02 router2 = IUniswapV2Router02(router2Address);
        (uint112 inReserves2, uint112 outReserves2) = UniswapLibrary.getReserves(router2.factory(), inToken, outToken);
        return (UniswapLibrary.quote(inAmount, inReserves1, outReserves1), UniswapLibrary.quote(inAmount, inReserves2, outReserves2));
    }

    function executeArb(address router1Address, address router2Address, address[] calldata inPath, address[] calldata outPath, uint256 max_can_sell_tokenA,uint256 max_buy_tokenB) external {
        IERC20(inPath[0]).transferFrom(msg.sender, address(this), max_can_sell_tokenA);
        IUniswapV2Router02 router1 = IUniswapV2Router02(router1Address);
        IUniswapV2Router02 router2 = IUniswapV2Router02(router2Address);
        IERC20(inPath[0]).approve(address(router1), 10**30);
        IERC20(outPath[0]).approve(address(router2), 10**30);
        router1.swapExactTokensForTokensSupportingFeeOnTransferTokens(max_can_sell_tokenA ,max_buy_tokenB, inPath, address(this), block.timestamp + 1638007916);
        router2.swapExactTokensForTokensSupportingFeeOnTransferTokens(max_buy_tokenB, max_can_sell_tokenA, outPath, msg.sender, block.timestamp + 1638007916);
        IERC20(inPath[0]).transfer(msg.sender, IERC20(inPath[0]).balanceOf(address(this))); // no token left behind
    }

    function rescueTokens(address token, uint256 amount) external {
        IERC20(token).transfer(msg.sender, amount);
    }}

//     constructor() {
//         IERC20(CRV).approve(address(spirit_router), type(uint256).max);
//         IERC20(WFTM).approve(address(spooky_router), type(uint256).max);
//         IERC20(CRV).approve(address(spirit_router), type(uint256).max);
//         IERC20(WFTM).approve(address(spooky_router), type(uint256).max);
//     }

//      function executeArb(uint256 direction, uint256 max_can_sell_tokenA,uint256 max_buy_tokenB) external {
//         IERC20(inPath[0]).transferFrom(msg.sender, address(this), max_can_sell_tokenA);
//         if (direction) {
//             spiritTrade(max_can_sell_tokenA, max_buy_tokenB, _getInPath(), block.timestamp+10000);
//             sop(max_can_sell_tokenA, max_buy_tokenB, _getInPath(), block.timestamp+10000);
//         } else {

//         }
//         router1.swapTokensForExactTokens(max_buy_tokenB, max_can_sell_tokenA, inPath, address(this), block.timestamp + 1638007916);
//         router2.swapExactTokensForTokensSupportingFeeOnTransferTokens(max_buy_tokenB, max_can_sell_tokenA, outPath, msg.sender, block.timestamp + 1638007916);
//         IERC20(inPath[0]).transfer(msg.sender, IERC20(inPath[0]).balanceOf(address(this))); // no token left behind
//     }



//     function spiritTrade(uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256 deadline) private {
//         address recipient = address(this);
            
//         spirit_router.swapExactTokensForTokens(
//             amountIn,
//             amountOutMin,
//             path,
//             recipient,
//             deadline
//         );
//     }

//     function spookyTrade(uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256 deadline) private {
//         address recipient = address(this);
            
//         spooky_router.swapExactTokensForTokens(
//             amountIn,
//             amountOutMin,
//             path,
//             recipient,
//             deadline
//         );
//     }

//     function _getInPath() private view returns (address[] memory) {
//         address[] memory path = new address[](2);
//         path[0] = CRV;
//         path[1] = WFTM;
//         return path;
//     }

//     function _getOutPath() private view returns (address[] memory) {
//         address[] memory path = new address[](2);
//         path[0] = CRV;
//         path[1] = WFTM;
//         return path;
//     }
// }

/**
 *Submitted for verification at FtmScan.com on 2021-04-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

import "UniswapInterfaces.sol";

library UniswapLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return IUniswapV2Factory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint112 reserveA, uint112 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }
}