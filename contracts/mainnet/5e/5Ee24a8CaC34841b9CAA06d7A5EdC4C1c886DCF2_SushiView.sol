/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;




interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}





abstract contract IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external virtual view returns (address pair);
    function allPairs(uint) external virtual view returns (address pair);
    function allPairsLength() external virtual view returns (uint);
    function feeTo() external virtual view returns (address);
    function feeToSetter() external virtual view returns (address);
}





contract SushiView {
    address constant public UNISWAP_V2_FACTORY_ADDR = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    IUniswapV2Factory constant public UniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY_ADDR);

    function getPairInfo(address _pair) external view returns (
        address token0,
        address token1,
        uint112 reserve0,
        uint112 reserve1
    ) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
        (reserve0, reserve1, ) = pair.getReserves();
    }

    function getPair(address _token0, address _token1) external view returns (address) {
        return UniswapV2Factory.getPair(_token0, _token1);
    }
}