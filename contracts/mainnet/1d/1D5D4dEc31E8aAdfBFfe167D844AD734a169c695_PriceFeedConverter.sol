// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {AggregatorInterface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

contract PriceFeedConverter {
    address private immutable QUOTE;
    address private immutable BASE;
    uint8 private immutable QUOTE_DECIMALS;
    uint8 private immutable BASE_DECIMALS;

    constructor(
        address quote,
        address base,
        uint8 quoteDecimals,
        uint8 baseDecimals
    ) {
        QUOTE = quote;
        BASE = base;
        QUOTE_DECIMALS = quoteDecimals;
        BASE_DECIMALS = baseDecimals;
    }

    function latestAnswer() external view returns (int256) {
        int256 quotePrice = AggregatorInterface(QUOTE).latestAnswer();
        int256 basePrice = AggregatorInterface(BASE).latestAnswer();

        return (quotePrice * basePrice) / int256(10**(uint256(QUOTE_DECIMALS)));
    }

    function decimals() external view returns (uint8) {
        return BASE_DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}