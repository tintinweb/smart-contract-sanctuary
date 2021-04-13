// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SettableOracle.sol";
import "../oracles/ChainlinkOracle.sol";

/**
 * @title MockChainlinkOracle
 * @author Jacob Eliosoff (@jacob-eliosoff)
 * @notice A ChainlinkOracle whose price we can override.  Testing purposes only!
 */
contract MockChainlinkOracle is ChainlinkOracle, SettableOracle {
    constructor(AggregatorV3Interface aggregator_) ChainlinkOracle(aggregator_) {}

    function refreshPrice() public override returns (uint price, uint updateTime) {
        (price, updateTime) = (savedPrice != 0) ? (savedPrice, savedUpdateTime) : super.refreshPrice();
    }

    function latestPrice() public override(ChainlinkOracle, Oracle) view returns (uint price, uint updateTime) {
        (price, updateTime) = (savedPrice != 0) ? (savedPrice, savedUpdateTime) : super.latestPrice();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../oracles/Oracle.sol";

abstract contract SettableOracle is Oracle {
    uint public savedPrice;
    uint public savedUpdateTime;

    function setPrice(uint p) public {
        savedPrice = p;
        savedUpdateTime = block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./Oracle.sol";

/**
 * @title ChainlinkOracle
 */
contract ChainlinkOracle is Oracle {

    uint public constant CHAINLINK_SCALE_FACTOR = 1e10; // Since Chainlink has 8 dec places, and latestPrice() needs 18

    AggregatorV3Interface public immutable chainlinkAggregator;

    constructor(AggregatorV3Interface aggregator_)
    {
        chainlinkAggregator = aggregator_;
    }

    /**
     * @notice Retrieve the latest price of the price oracle.
     * @return price
     */
    function latestPrice() public virtual override view returns (uint price, uint updateTime) {
        int rawPrice;
        (, rawPrice,, updateTime,) = chainlinkAggregator.latestRoundData();
        require(rawPrice > 0, "Chainlink price <= 0");
        price = uint(rawPrice) * CHAINLINK_SCALE_FACTOR;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract Oracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * eg, the price cached by the most recent call to `refreshPrice()`.
     * @return price WAD-scaled - 18 dec places
     */
    function latestPrice() public virtual view returns (uint price, uint updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it (typically also caching it
     * for `latestPrice()` callers).
     * @return price WAD-scaled - 18 dec places
     */
    function refreshPrice() public virtual returns (uint price, uint updateTime) {
        (price, updateTime) = latestPrice();    // Default implementation doesn't do any caching.  But override as needed
    }
}

pragma solidity >=0.6.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}