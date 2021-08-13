// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IConvex {
  function rewardRate() external view returns (uint);
  function totalSupply() external view returns (uint);
}

interface ICurve {
  function get_virtual_price() external view returns (uint);
}

contract ProfitablePool {
  address public profitablePoolAddress;
  function getProfitablePool(address[] calldata convex, address curve) public {
    uint maxValue = 0;
    uint maxIndex = 0;
    uint rewardRate;
    uint totalSupply;
    uint virtualPrice;
    uint rewards;

    for (uint i = 0; i < convex.length; i++) {
      rewardRate = IConvex(convex[i]).rewardRate();
      totalSupply = IConvex(convex[i]).totalSupply();
      virtualPrice = ICurve(curve).get_virtual_price();
      rewards = totalSupply * virtualPrice / rewardRate;
      rewards = type(uint).max / rewards;
      if (rewards > maxValue) {
        maxValue = rewards;
        maxIndex = i;
      }
    }

    profitablePoolAddress = convex[maxIndex];
  }
}

/**
  Get the rewards value of all pools
 */
// contract ProfitablePool {
//   function getProfitablePool(address[] calldata convex, address curve) public view returns(uint[] memory rewards) {
//     rewards = new uint[](convex.length);
//     uint rewardRate;
//     uint totalSupply;
//     uint virtualPrice;
//     uint reward;

//     for (uint i = 0; i < convex.length; i++) {
//       rewardRate = IConvex(convex[i]).rewardRate();
//       totalSupply = IConvex(convex[i]).totalSupply();
//       virtualPrice = ICurve(curve).get_virtual_price();
//       // reward = totalSupply * virtualPrice / rewardRate;
//       // reward = type(uint).max / reward;
//       reward = rewardRate * (10 ** 40) / totalSupply / virtualPrice;
//       rewards[i] = reward;
//     }
//   }
// }

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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