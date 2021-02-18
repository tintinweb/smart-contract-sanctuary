/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
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

// File: contracts/amm/ChainlinkEthUsdProxy.sol

pragma solidity 0.6.12;


/**
Converts prices from ETH/USD and <ASSET>/ETH oracles into <ASSET>/USD price
according to specifyed decimal places
 */
contract ChainlinkEthUsdProxy is AggregatorV3Interface {
    uint8 public override decimals;
    string public override description;
    uint256 public override version;

    AggregatorV3Interface ethUsdOracle;
    AggregatorV3Interface assetEthOracle;

    int256 priceDivisor;

    constructor(
        address _ethUsdOracleAddress,
        address _assetEthOracleAddress,
        uint8 _decimals
    ) public {
        ethUsdOracle = AggregatorV3Interface(_ethUsdOracleAddress);
        assetEthOracle = AggregatorV3Interface(_assetEthOracleAddress);

        decimals = _decimals;
        require(
            ethUsdOracle.decimals() + assetEthOracle.decimals() >= decimals,
            "Decimals is too large"
        );
        uint8 netDecimals =
            ethUsdOracle.decimals() + assetEthOracle.decimals() - decimals;
        require(netDecimals <= 36, "Combined decimals are too large");
        priceDivisor = int256(10)**netDecimals;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(false, "Method not implemented");
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (, int256 ethUsdPrice, , , ) = ethUsdOracle.latestRoundData();
        (, int256 assetEthPrice, , , ) = assetEthOracle.latestRoundData();

        require(ethUsdPrice > 0, "ETH/USD price is 0");
        require(assetEthPrice > 0, "ASSET/ETH price is 0");

        answer = (ethUsdPrice * assetEthPrice) / priceDivisor;
    }
}