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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

/*
 * Manages price feeds from different oracle implementations.
 */
interface IOracleManager {
  function updatePrice() external returns (int256);

  /*
   *Returns the latest price from the oracle feed.
   */
  function getLatestPrice() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

import "../interfaces/IOracleManager.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
 * Implementation of an OracleManager that fetches prices from a Chainlink aggregate price feed.
 */
contract OracleManagerChainlink is IOracleManager {
  // Admin addresses.
  address public admin;
  // Global state.
  AggregatorV3Interface public chainlinkOracle;
  uint8 public oracleDecimals;

  ////////////////////////////////////
  /////////// MODIFIERS //////////////
  ////////////////////////////////////

  modifier adminOnly() {
    require(msg.sender == admin, "Not admin");
    _;
  }

  ////////////////////////////////////
  ///// CONTRACT SET-UP //////////////
  ////////////////////////////////////
  constructor(address _admin, address _chainlinkOracle) {
    admin = _admin;
    chainlinkOracle = AggregatorV3Interface(_chainlinkOracle);
    oracleDecimals = chainlinkOracle.decimals();
  }

  ////////////////////////////////////
  /// MULTISIG ADMIN FUNCTIONS ///////
  ////////////////////////////////////

  function changeAdmin(address _admin) external adminOnly {
    admin = _admin;
  }

  ////////////////////////////////////
  ///// IMPLEMENTATION ///////////////
  ////////////////////////////////////
  function _getLatestPrice() internal view returns (int256) {
    (, int256 price, , , ) = chainlinkOracle.latestRoundData();
    return price;
  }

  function getLatestPrice() external view override returns (int256) {
    return _getLatestPrice();
  }

  function updatePrice() external virtual override returns (int256) {
    return _getLatestPrice();
  }
}