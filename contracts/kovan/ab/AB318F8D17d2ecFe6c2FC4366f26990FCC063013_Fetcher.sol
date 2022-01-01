// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract Fetcher {
    enum Coin{ ETH, BTC }

    struct FeedInfo {
        AggregatorV2V3Interface feed;
        uint dataPointsToFetchPerDay;
    }

    // TODO: use address for correct chain before launch

    // Rinkeby price feed info 
    // FeedInfo internal priceFeedETH = FeedInfo(
    //     AggregatorV2V3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e),
    //     8*MEASURES
    // );
    // FeedInfo internal priceFeedBTC = FeedInfo(
    //     AggregatorV2V3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404),
    //     4*MEASURES
    // );

    // Kovan price feed info
    FeedInfo internal priceFeedETH = FeedInfo(
        AggregatorV2V3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331),
        8*MEASURES
    );
    FeedInfo internal priceFeedBTC = FeedInfo(
        AggregatorV2V3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e),
        4*MEASURES
    );
    
    /* // Polygon mumbai price feed info 
    FeedInfo internal priceFeedETH = FeedInfo(
        AggregatorV2V3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A),
        8*MEASURES
    );
    FeedInfo internal priceFeedBTC = FeedInfo(
        AggregatorV2V3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b),
        4*MEASURES
    );
    */

    function feedInfoForCoin(Coin coin) internal view returns (FeedInfo memory) {
        if (coin == Coin.ETH) {
            return priceFeedETH;
        } else {
            return priceFeedBTC;
        }
    }

    uint80 constant PERPETUAL_JAM_DAYS = 2;

    uint80 constant MEASURES = 3;
    uint80 constant SECONDS_PER_DAY = 3600*24;

    function perpetualDataStartTime() public view returns (uint256) {
        return (block.timestamp - PERPETUAL_JAM_DAYS*SECONDS_PER_DAY);
    }

    // function aa_testGuessRoundForTimestamp() public view returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch) {
    //     uint256 testTimestamp = 1637625600; /* 11/23/2021 */
    //     return guessSearchRoundsForTimestamp(priceFeedBTC, testTimestamp, 1);
    // }

    // Given a timestamp, return the first round to search and the number of rounds to search for that timestamp.

    function guessSearchRoundsForTimestamp(Coin coin, uint256 fromTime, uint80 daysToFetch) internal view returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch) {
        FeedInfo memory priceFeed = feedInfoForCoin(coin);

        uint256 toTime = fromTime + SECONDS_PER_DAY*daysToFetch;

        // TODO: Do simple backwards search to find correct phase

        (uint80 rhRound,,uint256 rhTime,,) = priceFeed.feed.latestRoundData();
        uint80 lhRound;
        uint256 lhTime;
        {
            uint16 phase = uint16(rhRound >> 64); // Assume current phase
            lhRound = uint80(phase << 64) + 1;
            lhTime = priceFeed.feed.getTimestamp(lhRound);
        }
        
        uint80 fromRound = binarySearchForTimestamp(coin, fromTime, lhRound, lhTime, rhRound, rhTime);
        uint80 toRound = binarySearchForTimestamp(coin, toTime, fromRound, fromTime, rhRound, rhTime);
        return (fromRound, toRound-fromRound);
    }

    function binarySearchForTimestamp(Coin coin, uint256 targetTime, uint80 lhRound, uint256 lhTime, uint80 rhRound, uint256 rhTime) internal view returns (uint80 targetRound) {
        AggregatorV2V3Interface feed = feedInfoForCoin(coin).feed;
        if (targetTime >= rhTime) {
            return rhRound;
        }
        require(lhTime <= targetTime);

        uint80 guessRound = rhRound;
        while (rhRound - lhRound > 1) {
            guessRound = uint80(int80(lhRound) + int80(rhRound - lhRound)/2);
            uint256 guessTime = feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0) {
                return 0;
            } else if (guessTime > targetTime) {
                (rhRound, rhTime) = (guessRound, guessTime);
            } else if (guessTime < targetTime) {
                (lhRound, lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    // function aa_testFetchPriceData() public view returns (int32[] memory) {
    //     return fetchPriceData(priceFeedETH, 48, 1, 1639257591);
    // }

    function roundIdsToSearch(Coin coin, uint256 fromTimestamp, uint80 daysToFetch, uint dataPointsToFetchPerDay) internal view returns (uint80[] memory ) {
        (uint80 startingId, uint80 numRoundsToSearch) = guessSearchRoundsForTimestamp(coin, fromTimestamp, daysToFetch);
        uint80 fetchFilter = uint80(numRoundsToSearch / (daysToFetch*dataPointsToFetchPerDay));
        if (fetchFilter < 1) {
            fetchFilter = 1;
        }
        uint80[] memory roundIds = new uint80[](numRoundsToSearch / fetchFilter);

        // Snap startingId to a round that is a multiple of fetchFilter. This prevents the perpetual jam from changing more often than
        // necessary, and keeps it aligned with the daily prints.
        startingId -= startingId % fetchFilter;

        for (uint80 i = 0; i < roundIds.length; i++) {
            roundIds[i] = startingId + i*fetchFilter;
        }
        return roundIds;
    }

    // TODO: need tests for fetchFilter to make sure this doesn't misbehave on mainnet
    // TODO: implement multiple fetch since this will inefficiently fetch the same Chainlink data a bunch of times?

    function fetchPriceData(Coin coin, uint80 daysToFetch, uint256 fromTimestamp) internal view returns (int32[] memory) {
        FeedInfo memory priceFeed = feedInfoForCoin(coin);
        uint80[] memory roundIds = roundIdsToSearch(coin, fromTimestamp, daysToFetch, priceFeed.dataPointsToFetchPerDay);
        uint dataPointsToReturn = priceFeed.dataPointsToFetchPerDay * daysToFetch; // Number of data points to return
        uint secondsBetweenDataPoints = SECONDS_PER_DAY / priceFeed.dataPointsToFetchPerDay;

        int32[] memory prices = new int32[](dataPointsToReturn);

        uint80 latestRoundId = uint80(priceFeed.feed.latestRound());
        for (uint80 i = 0; i < roundIds.length; i++) {
            if (roundIds[i] != 0 && roundIds[i] < latestRoundId) {
                (
                    ,
                    int price,
                    uint timestamp,,
                ) = priceFeed.feed.getRoundData(roundIds[i]);

                if (timestamp >= fromTimestamp) {
                    uint segmentsSinceStart = (timestamp - fromTimestamp) / secondsBetweenDataPoints;
                    if (segmentsSinceStart < prices.length) {
                        prices[segmentsSinceStart] = int32(price / 10**8);
                    }
                }
            }
        }

        return prices;
    }

    function fetchCoinPriceData(uint fromTimestamp, Coin coin) external view returns (int32[] memory) {
        uint80 daysToFetch = 1;
        if (fromTimestamp == 0) {
            fromTimestamp = perpetualDataStartTime();
            daysToFetch = PERPETUAL_JAM_DAYS;
        }

        int32[] memory prices = fetchPriceData(coin, daysToFetch, fromTimestamp);
        return prices;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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