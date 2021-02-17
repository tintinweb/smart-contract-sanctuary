/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.1;

interface IKeep3rV1Oracle {
    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint);
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint);
}

contract Keep3rV1OracleUSD  {
    
    IKeep3rV1Oracle public constant sushiswapV1Oracle = IKeep3rV1Oracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);
    IKeep3rV1Oracle public constant uniswapV1Oracle = IKeep3rV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    function assetToUsd(address asset, uint amount, uint granularity) public view returns (uint) {
        return ethToUsd(assetToEth(asset, amount, granularity), granularity);
    }
    
    function assetToEth(address asset, uint amount, uint granularity) public view returns (uint) {
        if (amount == 0) {
            return 0;
        }
        if (asset == WETH) {
            return amount;
        }
        return quote(asset, amount, granularity);
    }
    
    function quote(address tokenIn, uint amountIn, uint granularity) public view returns (uint amountOut) {
        uint sTWAP = sushiswapV1Oracle.quote(tokenIn, amountIn, WETH, granularity);
        uint uTWAP = uniswapV1Oracle.quote(tokenIn, amountIn, WETH, granularity);
        return (sTWAP + uTWAP) / 2;
    }
    
    function ethToUsd(uint ethAmount, uint granularity) public view returns (uint) {
        uint sTWAP = sushiswapV1Oracle.quote(WETH, ethAmount, DAI, granularity);
        uint uTWAP = uniswapV1Oracle.quote(WETH, ethAmount, DAI, granularity);
        return (sTWAP + uTWAP) / 2;
    }
}