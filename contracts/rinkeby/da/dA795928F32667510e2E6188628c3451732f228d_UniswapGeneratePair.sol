/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// File: contracts/pcv/UniswapGeneratePair.sol

pragma solidity 0.6.6;


contract UniswapGeneratePair {

        IUniswapV2Factory public constant UNISWAP_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

        event createPair(address _pair);

    
    constructor(
    ) public {}

    function createPairs(address token0,address token1) external returns (address) {

         address pair = UNISWAP_FACTORY.createPair(token0, token1);
         emit createPair(pair);
         return pair;
    }
}