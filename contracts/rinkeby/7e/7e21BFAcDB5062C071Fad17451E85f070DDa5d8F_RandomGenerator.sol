/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// File: contracts/lib/RandomGenerator.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

interface IRandomGenerator {
    function random(uint256 seed) external view returns (uint256);
}

interface IDODOMidPrice {
    function getMidPrice() external view returns (uint256 midPrice);
}

contract RandomGenerator {
    address[] public pools;

    constructor(address[] memory _pools) public {
        for (uint256 i = 0; i < _pools.length; i++) {
            pools.push(_pools[i]);
        }
    }

    function random(uint256 seed) external view returns (uint256) {
        uint256 priceSum;
        for (uint256 i = 0; i < pools.length; i++) {
            priceSum += IDODOMidPrice(pools[i]).getMidPrice();
        }
        return uint256(keccak256(abi.encodePacked(blockhash(block.number-1), priceSum, seed)));
    }
}