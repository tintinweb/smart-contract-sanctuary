pragma solidity ^0.8.0;

import "../external/IUniswapV2Factory.sol";

contract UniswapFactoryMock{
    mapping(address => mapping (address => address)) internal pairs;

    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return pairs[token0][token1];
    }

    // Mock function able to add pair with particular pair address
    function addPair(address tokenA, address tokenB, address pairAddress) external {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pairs[token0][token1] = pairAddress;
    }

    // NOT REQUIRED IN TESTS
//    function feeTo() override external view returns (address) {
//        return address(0);
//    }
//
//    function feeToSetter() override external view returns (address) {
//        return address(0);
//    }
//
//    function allPairs(uint) override external view returns (address pair) {
//        return address(0);
//    }
//
//    function allPairsLength() override external view returns (uint) {
//        return 0;
//    }
//
//    function createPair(address tokenA, address tokenB) override external returns (address pair) {
//        return address(0);
//    }
//
//    function setFeeTo(address) override external {}
//    function setFeeToSetter(address) override external {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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