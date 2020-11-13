// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.1;

import "./ZeppelinERC20.sol";


// Uniswap V2 Router Interface. 
// Used on the Main-Net, and Public Test-Nets.
interface IUniswapRouter
{
    // Get Factory and WETH addresses.
    function factory()  external pure returns (address);
    function WETH()     external pure returns (address);

    // Create/add to a liquidity pair using ETH.
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline )                 
                                        external 
                                        payable 
        returns (
            uint amountToken, 
            uint amountETH, 
            uint liquidity 
        );

    // Remove liquidity pair.
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline ) 
                                        external
        returns (
            uint amountETH
        );

    // Get trade output amount, given an input.
    function getAmountsOut(
        uint amountIn, 
        address[] memory path ) 
                                        external view 
        returns (
            uint[] memory amounts
        );

    // Get trade input amount, given an output.
    function getAmountsIn(
        uint amountOut, 
        address[] memory path )
                                        external view
        returns (
            uint[] memory amounts
        );
}


// Uniswap Factory interface.
// We use it only to obtain the Token Exchange Pair address.
interface IUniswapFactory
{
    function getPair(
        address tokenA, 
        address tokenB )
                                        external view 
    returns ( address pair );
}

// Uniswap Pair interface (it's also an ERC20 token).
// Used to get reserves, and token price.
interface IUniswapPair is IERC20
{
    // Addresses of the first and second pool-kens.
    function token0() external view returns (address);
    function token1() external view returns (address);

    // Get the pair's token pool reserves.
    function getReserves() 
                                        external view 
    returns (
        uint112 reserve0, 
        uint112 reserve1,
        uint32 blockTimestampLast
    );
}



