/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract SymbolOracleBalancerWP2T {

    address public vault;
    bytes32 public poolId;
    address public pool;
    uint256 public weight0;
    uint256 public weight1;


    constructor (address vault_, bytes32 poolId_) {
        vault = vault_;
        poolId = poolId_;
        (pool, ) = IVault(vault).getPool(poolId_);

        uint256[] memory weights = IWeightedPool2Tokens(pool).getNormalizedWeights();
        weight0 = weights[0];
        weight1 = weights[1];
    }

    function getPrice() external view returns (uint256 price) {
        (, uint256[] memory balances, uint256 lastChangeBlock) = IVault(vault).getPoolTokens(poolId);
        if (block.number == lastChangeBlock) {
            price = IWeightedPool2Tokens(pool).getLastest(0);
        } else {
            price = balances[0] * weight1 / weight0 * (10**18) / balances[1];
        }
        return price;
    }

}

interface IVault {
    function getPool(bytes32 poolId_) external view returns (address, uint256);
    function getPoolTokens(bytes32 poolId_) external view returns (address[] memory, uint256[] memory, uint256);
}

interface IWeightedPool2Tokens {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getLastest(uint8 v) external view returns (uint256);
}