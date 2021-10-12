//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

contract PriceConsumerV3 {

    function getLatestPrice() public view returns (int256) {
        int256 ethUsd = AggregatorInterface(0x0715A7794a1dc8e42615F059dD6e406A6594651A).latestAnswer();
        int256 usdEth = 1e26 / ethUsd;

        int256 UsdcUsd = AggregatorInterface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0).latestAnswer();
        int256 ethUsdc = UsdcUsd * usdEth / 1e8;

        return ethUsdc;
    }
}



// BTC / USD  1 BTC cuanto USD es

// ETH / USD 1 ETH cuanto USD es
// USD / ETH 1 USD cuanto ETH es

// BTC / ETH 1 BTC cuanto ETH es
// ETH / BTC

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}