// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol';

import "./libraries/UQ112x112.sol";
import "./interfaces/IChainlinkPriceOracle.sol";

contract ChainlinkPriceOracle is IChainlinkPriceOracle {
    using UQ112x112 for uint224;

    address public constant USD = address(840);

    address public immutable override feedRegistry;
    address public immutable override base;

    mapping(address => address) public override aggregatorOf;

    constructor(address _feedRegistry, address _base) {
        aggregatorOf[_base] = address(FeedRegistryInterface(_feedRegistry).getFeed(_base, USD));

        feedRegistry = _feedRegistry;
        base = _base;
    }

    function initializeAssetPerBaseInUQ(address _asset) external override {
        require(_asset != base, "PhutureChainlinkOracle: BASE");

        aggregatorOf[_asset] = address(FeedRegistryInterface(feedRegistry).getFeed(_asset, USD));
    }

    function refreshedAssetPerBaseInUQ(address _asset) public view override returns (uint) {
        return _priceInBPOf(_asset);
    }

    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        return _priceInBPOf(_asset);
    }

    function _priceInBPOf(address _asset) private view returns (uint) {
        if (_asset == base) {
            return UQ112x112.Q112;
        }

        require(aggregatorOf[_asset] != address(0), "PhutureChainlinkOracle: INIT");

        unchecked {
            (, int256 basePrice, , ,) = AggregatorV3Interface(aggregatorOf[base]).latestRoundData();
            uint112 basePrice112 = _scalePrice(basePrice, AggregatorV3Interface(aggregatorOf[base]).decimals());

            (, int256 quotePrice, , ,) = AggregatorV3Interface(aggregatorOf[_asset]).latestRoundData();
            uint112 quotePrice112 = _scalePrice(quotePrice, AggregatorV3Interface(aggregatorOf[_asset]).decimals());

            return UQ112x112.encode(quotePrice112 * uint112(10 ** 18)).uqdiv(basePrice112);
        }
    }

    function _scalePrice(int256 _price, uint8 _priceDecimals) internal pure returns (uint112) {
        if (_priceDecimals < 18) {
            _price *= int256(10 ** uint256(18 - _priceDecimals));
        } else if (_priceDecimals > 18) {
            _price /= int256(10 ** uint256(_priceDecimals - 18));
        }

        return uint112(uint(_price));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "./IPriceOracle.sol";

interface IChainlinkPriceOracle is IPriceOracle {
    function feedRegistry() external view returns (address);

    function base() external view returns (address);

    function aggregatorOf(address) external view returns (address);
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: Apache-2.0

import "../interfaces/IGasPriceOracle.sol";

pragma solidity >=0.8.0;

interface IPriceOracle {
    function initializeAssetPerBaseInUQ(address _asset) external;
    function refreshedAssetPerBaseInUQ(address _asset) external returns (uint);
    function lastAssetPerBaseInUQ(address _asset) external view returns (uint);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

interface IGasPriceOracle {
    function getFastGasInWei() external view returns (uint);
}