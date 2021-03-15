// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibIUSDPrice.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract USDPrice is IUSDPrice {
    using SafeMath for uint256;

    address private immutable VOKEN_TB = address(0x1234567a022acaa848E7D6bC351d075dBfa76Dd4);
    address private immutable DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IUniswapV2Router02 private immutable UniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    function etherPrice()
        public
        override
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router02.WETH();
        path[1] = DAI;

        return UniswapV2Router02.getAmountsOut(1_000_000, path)[1];
    }

    function vokenPrice()
        public
        override
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = VOKEN_TB;
        path[1] = DAI;
        
        return UniswapV2Router02.getAmountsOut(1_000_000, path)[1].mul(1_000_000_000).div(1 ether);
    }
}