// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./Globals.sol";

contract Prices {
    AggregatorV3Interface internal chainlinkETHtoUSD;
    AggregatorV3Interface internal chainlinkORNtoETH;

    constructor(
        address _ETHToUSDChainlinkAggregator,
        address _ORNToETHChainlinkAggregator
    ) {
        chainlinkETHtoUSD = AggregatorV3Interface(_ETHToUSDChainlinkAggregator);
        chainlinkORNtoETH = AggregatorV3Interface(_ORNToETHChainlinkAggregator);
    }

    function decimals() external pure returns (uint256) {
        return G_DECIMALS;
    }

    function getORNPrice() external view returns (uint256) {
        return _ORNtETHPrice() * _ETHtUSDPrice() / G_PRECISION;
    }

    // ORN:ORS - 1:1
    function getORSPrice() external view returns (uint256) {
        return _ORNtETHPrice() * _ETHtUSDPrice() / G_PRECISION;
    }

    function getUSDoPrice() external view returns (uint256) {
        return G_PRECISION;
    }

    function getChainlinkPrice(address chainlinkAggregatorAddress_) external view returns (uint256) {
        (,int USDCtoUSDPrice,,,) = AggregatorV3Interface(chainlinkAggregatorAddress_).latestRoundData();
        uint8 USDCtoUSDDecimals = AggregatorV3Interface(chainlinkAggregatorAddress_).decimals();
        return uint256(USDCtoUSDPrice) * G_PRECISION / (10 ** USDCtoUSDDecimals);
    }

    function _ORNtETHPrice() private view returns (uint256) {
        (,int ORNtoETHPrice,,,) = chainlinkORNtoETH.latestRoundData();
        uint8 ORNtoETHDecimals = chainlinkORNtoETH.decimals();
        return uint256(ORNtoETHPrice) * G_PRECISION / (10 ** ORNtoETHDecimals);
    }

    function _ETHtUSDPrice() private view returns (uint256) {
        (,int ETHtoUSDPrice,,,) = chainlinkETHtoUSD.latestRoundData();
        uint8 ETHtoUSDDecimals = chainlinkETHtoUSD.decimals();
        return uint256(ETHtoUSDPrice) * G_PRECISION / (10 ** ETHtoUSDDecimals);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

uint256 constant G_DECIMALS = 8;
uint256 constant G_PRECISION = 10 ** G_DECIMALS;

bytes32 constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
bytes32 constant POOL_ROLE = keccak256("POOL_ROLE");
bytes32 constant ADMIN_USDO_ROLE = keccak256("ADMIN_USDO_ROLE"); // onlyByOwnerGovernanceOrController for Orion Stablecoin

bytes32 constant MINT_PAUSER = keccak256("MINT_PAUSER");
bytes32 constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
bytes32 constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
bytes32 constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
bytes32 constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");

{
  "optimizer": {
    "enabled": false,
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