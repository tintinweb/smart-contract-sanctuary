/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";

// import "hardhat/console.sol";
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

contract readPairs {
    address factory;
    address owner;

    constructor() {
        factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // mainnet n rinkeby
        owner = msg.sender;
    }

    function getAllPairs() public view returns (address[] memory) {
        // console.log("here");
        uint256 pairLength = IUniswapV2Factory(factory).allPairsLength();
        address[] memory toReturn = new address[](pairLength);
        for (uint256 i = 0; i < pairLength; i++) {
            toReturn[i] = IUniswapV2Factory(factory).allPairs(i);
        }
        return toReturn;
    }
}