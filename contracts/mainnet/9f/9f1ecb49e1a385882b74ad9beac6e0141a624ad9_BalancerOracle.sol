/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface RegistryInterface {
    function getBestPools(address fromToken, address destToken) external view returns(address[] memory);
    function getPoolsWithLimit(address fromToken, address destToken, uint256 offset, uint256 limit) external view returns(address[] memory);
}

interface BPool {
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256);
}

contract BalancerOracle {
    // address public constant BALANCER_REGISTRY = 0xC5570FC7C828A8400605e9843106aBD675006093; // Kovan
    address public constant BALANCER_REGISTRY = 0x7226DaaF09B3972320Db05f5aB81FF38417Dd687; // Mainnet

    function getSpotPrice(address quote, address base) public view returns (uint256 price) {
        RegistryInterface reg = RegistryInterface(BALANCER_REGISTRY);
        address[] memory pools = reg.getBestPools(quote, base);
        uint256 _length = pools.length;

        if (_length == 0) {
            pools = reg.getPoolsWithLimit(quote, base, 0, 32);
            _length = pools.length;
            if (_length == 0) {
                return 0;
            }
        }
        
        uint256 _price = 0;

        for (uint i = 0; i < _length; i++) {
            _price += BPool(pools[i]).getSpotPrice(quote, base);
        }

        price = _price / _length;
    }
}