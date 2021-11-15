// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

struct RoundData {
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
            RoundData memory roundData;
            roundData.roundId = roundId;
            roundData.answer = answer;
            roundData.startedAt = startedAt;
            roundData.updatedAt = updatedAt;
            roundData.answeredInRound = answeredInRound;
            output[i] = roundData;
        }

        return output;
    }
}

