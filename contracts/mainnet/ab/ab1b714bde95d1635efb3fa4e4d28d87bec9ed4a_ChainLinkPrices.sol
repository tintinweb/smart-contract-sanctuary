// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

struct RoundData {
    address contractAddr;
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

interface IChainLinkPrices {
    function latestRoundData() external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract ChainLinkPrices {
    constructor () public {

    }

    function getAllRoundData(address[] memory pairs) public view returns (RoundData[] memory) {
        RoundData[] memory output = new RoundData[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IChainLinkPrices pair = IChainLinkPrices(pairs[i]);
            (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = pair.latestRoundData();
            output[i] = RoundData(pairs[i], roundId, answer, startedAt, updatedAt, answeredInRound);
        }

        return output;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}