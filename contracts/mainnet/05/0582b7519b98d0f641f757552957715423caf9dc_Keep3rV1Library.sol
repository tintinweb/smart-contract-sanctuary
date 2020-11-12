// File: contracts/interfaces/Uniswap/IUniswapV2PairLight.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IUniswapV2PairLight {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// File: contracts/libraries/Keep3rV1Library.sol
pragma solidity ^0.6.6;


library Keep3rV1Library{
    function getReserve(address pair, address reserve) external view returns (uint) {
        (uint _r0, uint _r1,) = IUniswapV2PairLight(pair).getReserves();
        if (IUniswapV2PairLight(pair).token0() == reserve) {
            return _r0;
        } else if (IUniswapV2PairLight(pair).token1() == reserve) {
            return _r1;
        } else {
            return 0;
        }
    }
}