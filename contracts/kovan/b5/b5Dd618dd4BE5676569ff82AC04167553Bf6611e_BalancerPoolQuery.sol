//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface BalancerPool {
    function getBalance(address) external view returns (uint256);
    function getDenormalizedWeight(address) external view returns (uint256);
}

contract BalancerPoolQuery {
    function getPoolInfo(address[][] calldata _poolTokens, uint256 numToken) external view returns (uint256[2][] memory) {
        uint256[2][]  memory results = new uint256[2][](numToken);
        uint256 num = 0;
        for (uint256 i = 0; i < _poolTokens.length; i++) {
            address[] memory pool  = _poolTokens[i];
            for(uint256 j = 1; j < pool.length; j++ ){
                results[num][0] = BalancerPool(pool[0]).getBalance(pool[j]);
                results[num][1] = BalancerPool(pool[0]).getDenormalizedWeight(pool[j]);
                num ++;
            }
        }
        return results;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}