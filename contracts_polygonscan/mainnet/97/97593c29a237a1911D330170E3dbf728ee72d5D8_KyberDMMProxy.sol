/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface KyberDMMPool {
    function kLast() external view returns (uint256);
}

interface KyberDMMFactory {
    function getPools(address tokenA, address tokenB)
        external
        view
        returns (address[] memory tokenPools);
}

contract KyberDMMProxy {
    address public immutable kyber_factory;

    constructor(address _factory) {
        kyber_factory = _factory;
    }

    function factory() external view returns (address) {
        return address(this);
    }

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address)
    {
        address[] memory poolAddresses = KyberDMMFactory(kyber_factory)
            .getPools(tokenA, tokenB);
        address bestPool = address(0);
        uint256 highestKLast = 0;
        uint256 bestIndex = 0;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            uint256 currentKLast = KyberDMMPool(poolAddresses[i]).kLast();
            if (currentKLast > highestKLast) {
                highestKLast = currentKLast;
                bestIndex = i;
            }
        }
        if (highestKLast > 0) {
            bestPool = poolAddresses[bestIndex];
        }
        return bestPool;
    }
}