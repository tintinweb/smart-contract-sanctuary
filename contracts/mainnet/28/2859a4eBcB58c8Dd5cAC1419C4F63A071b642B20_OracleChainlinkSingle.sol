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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IOracle
/// @author Angle Core Team
/// @notice Interface for Angle's oracle contracts reading oracle rates from both UniswapV3 and Chainlink
/// from just UniswapV3 or from just Chainlink
interface IOracle {
    function read() external view returns (uint256);

    function readAll() external view returns (uint256 lowerRate, uint256 upperRate);

    function readLower() external view returns (uint256);

    function readUpper() external view returns (uint256);

    function readQuote(uint256 baseAmount) external view returns (uint256);

    function readQuoteLower(uint256 baseAmount) external view returns (uint256);

    function inBase() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "../interfaces/IOracle.sol";

/// @title OracleAbstract
/// @author Angle Core Team
/// @notice Abstract Oracle contract that contains some of the functions that are used across all oracle contracts
/// @dev This is the most generic form of oracle contract
/// @dev A rate gives the price of the out-currency with respect to the in-currency in base `BASE`. For instance
/// if the out-currency is ETH worth 1000 USD, then the rate ETH-USD is 10**21
abstract contract OracleAbstract is IOracle {
    /// @notice Base used for computation
    uint256 public constant BASE = 10**18;
    /// @notice Unit of the in-currency
    uint256 public override inBase;
    /// @notice Description of the assets concerned by the oracle and the price outputted
    bytes32 public description;

    /// @notice Reads one of the rates from the circuits given
    /// @return rate The current rate between the in-currency and out-currency
    /// @dev By default if the oracle involves a Uniswap price and a Chainlink price
    /// this function will return the Uniswap price
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function read() external view virtual override returns (uint256 rate);

    /// @notice Read rates from the circuit of both Uniswap and Chainlink if there are both circuits
    /// else returns twice the same price
    /// @return Return all available rates (Chainlink and Uniswap) with the lowest rate returned first.
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function readAll() external view override returns (uint256, uint256) {
        return _readAll(inBase);
    }

    /// @notice Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits
    /// and returns either the highest of both rates or the lowest
    /// @return rate The lower rate between Chainlink and Uniswap
    /// @dev If there is only one rate computed in an oracle contract, then the only rate is returned
    /// regardless of the value of the `lower` parameter
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function readLower() external view override returns (uint256 rate) {
        (rate, ) = _readAll(inBase);
    }

    /// @notice Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits
    /// and returns either the highest of both rates or the lowest
    /// @return rate The upper rate between Chainlink and Uniswap
    /// @dev If there is only one rate computed in an oracle contract, then the only rate is returned
    /// regardless of the value of the `lower` parameter
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function readUpper() external view override returns (uint256 rate) {
        (, rate) = _readAll(inBase);
    }

    /// @notice Converts an in-currency quote amount to out-currency using one of the rates available in the oracle
    /// contract
    /// @param quoteAmount Amount (in the input collateral) to be converted to be converted in out-currency
    /// @return Quote amount in out-currency from the base amount in in-currency
    /// @dev Like in the read function, if the oracle involves a Uniswap and a Chainlink price, this function
    /// will use the Uniswap price to compute the out quoteAmount
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function readQuote(uint256 quoteAmount) external view virtual override returns (uint256);

    /// @notice Returns the lowest quote amount between Uniswap and Chainlink circuits (if possible). If the oracle
    /// contract only involves a single feed, then this returns the value of this feed
    /// @param quoteAmount Amount (in the input collateral) to be converted
    /// @return The lowest quote amount from the quote amount in in-currency
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function readQuoteLower(uint256 quoteAmount) external view override returns (uint256) {
        (uint256 quoteSmall, ) = _readAll(quoteAmount);
        return quoteSmall;
    }

    /// @notice Returns Uniswap and Chainlink values (with the first one being the smallest one) or twice the same value
    /// if just Uniswap or just Chainlink is used
    /// @param quoteAmount Amount expressed in the in-currency base.
    /// @dev If `quoteAmount` is `inBase`, rates are returned
    /// @return The first return value is the lowest value and the second parameter is the highest
    /// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readAll(uint256 quoteAmount) internal view virtual returns (uint256, uint256) {}
}

// SPDX-License-Identifier: GPL-3.0

// contracts/oracle/OracleChainlinkSingle.sol
pragma solidity ^0.8.7;

import "./OracleAbstract.sol";
import "./modules/ModuleChainlinkSingle.sol";

/// @title OracleChainlinkSingle
/// @author Angle Core Team
/// @notice Oracle contract, one contract is deployed per collateral/stablecoin pair
/// @dev This contract concerns an oracle that only uses Chainlink and a single pool
/// @dev This is mainly going to be the contract used for the USD/EUR pool (or for other fiat currencies)
/// @dev Like all oracle contracts, this contract is an instance of `OracleAstract` that contains some
/// base functions
contract OracleChainlinkSingle is OracleAbstract, ModuleChainlinkSingle {
    /// @notice Constructor for the oracle using a single Chainlink pool
    /// @param _poolChainlink Chainlink pool address
    /// @param _isChainlinkMultiplied Whether we should multiply or divide by the Chainlink rate the
    /// in-currency amount to get the out-currency amount
    /// @param _inBase Number of units of the in-currency
    /// @param _description Description of the assets concerned by the oracle
    constructor(
        address _poolChainlink,
        uint8 _isChainlinkMultiplied,
        uint256 _inBase,
        bytes32 _description
    ) ModuleChainlinkSingle(_poolChainlink, _isChainlinkMultiplied) {
        inBase = _inBase;
        description = _description;
    }

    /// @notice Reads the rate from the Chainlink feed
    /// @return rate The current rate between the in-currency and out-currency
    function read() external view override returns (uint256 rate) {
        (rate, ) = _quoteChainlink(BASE);
    }

    /// @notice Converts an in-currency quote amount to out-currency using Chainlink's feed
    /// @param quoteAmount Amount (in the input collateral) to be converted in out-currency
    /// @return Quote amount in out-currency from the base amount in in-currency
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function readQuote(uint256 quoteAmount) external view override returns (uint256) {
        return _readQuote(quoteAmount);
    }

    /// @notice Returns Chainlink quote value twice
    /// @param quoteAmount Amount expressed in the in-currency base.
    /// @dev If quoteAmount is `inBase`, rates are returned
    /// @return The two return values are similar in this case
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readAll(uint256 quoteAmount) internal view override returns (uint256, uint256) {
        uint256 quote = _readQuote(quoteAmount);
        return (quote, quote);
    }

    /// @notice Internal function to convert an in-currency quote amount to out-currency using Chainlink's feed
    /// @param quoteAmount Amount (in the input collateral) to be converted
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readQuote(uint256 quoteAmount) internal view returns (uint256) {
        quoteAmount = (quoteAmount * BASE) / inBase;
        (quoteAmount, ) = _quoteChainlink(quoteAmount);
        // We return only rates with base BASE
        return quoteAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "../utils/ChainlinkUtils.sol";

/// @title ModuleChainlinkSingle
/// @author Angle Core Team
/// @notice Module Contract that is going to be used to help compute Chainlink prices
/// @dev This contract will help for an oracle using a single Chainlink price
/// @dev An oracle using Chainlink is either going to be a `ModuleChainlinkSingle` or a `ModuleChainlinkMulti`
abstract contract ModuleChainlinkSingle is ChainlinkUtils {
    /// @notice Chainlink pool to look for in the contract
    AggregatorV3Interface public immutable poolChainlink;
    /// @notice Whether the rate computed using the Chainlink pool should be multiplied to the quote amount or not
    uint8 public immutable isChainlinkMultiplied;
    /// @notice Decimals for each Chainlink pairs
    uint8 public immutable chainlinkDecimals;

    /// @notice Constructor for an oracle using only a single Chainlink
    /// @param _poolChainlink Chainlink pool address
    /// @param _isChainlinkMultiplied Whether we should multiply or divide the quote amount by the rate
    constructor(address _poolChainlink, uint8 _isChainlinkMultiplied) {
        require(_poolChainlink != address(0), "105");
        poolChainlink = AggregatorV3Interface(_poolChainlink);
        chainlinkDecimals = AggregatorV3Interface(_poolChainlink).decimals();
        isChainlinkMultiplied = _isChainlinkMultiplied;
    }

    /// @notice Reads oracle price using a single Chainlink pool
    /// @param quoteAmount Amount expressed with base decimal
    /// @dev If `quoteAmount` is base, the output is the oracle rate
    function _quoteChainlink(uint256 quoteAmount) internal view returns (uint256, uint256) {
        // No need for a for loop here as there is only a single pool we are looking at
        return _readChainlinkFeed(quoteAmount, poolChainlink, isChainlinkMultiplied, chainlinkDecimals, 0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title ChainlinkUtils
/// @author Angle Core Team
/// @notice Utility contract that is used across the different module contracts using Chainlink
abstract contract ChainlinkUtils {
    /// @notice Reads a Chainlink feed using a quote amount and converts the quote amount to
    /// the out-currency
    /// @param quoteAmount The amount for which to compute the price expressed with base decimal
    /// @param feed Chainlink feed to query
    /// @param multiplied Whether the ratio outputted by Chainlink should be multiplied or divided
    /// to the `quoteAmount`
    /// @param decimals Number of decimals of the corresponding Chainlink pair
    /// @param castedRatio Whether a previous rate has already been computed for this feed
    /// This is mostly used in the `_changeUniswapNotFinal` function of the oracles
    /// @return The `quoteAmount` converted in out-currency (computed using the second return value)
    /// @return The value obtained with the Chainlink feed queried casted to uint
    function _readChainlinkFeed(
        uint256 quoteAmount,
        AggregatorV3Interface feed,
        uint8 multiplied,
        uint256 decimals,
        uint256 castedRatio
    ) internal view returns (uint256, uint256) {
        if (castedRatio == 0) {
            (, int256 ratio, , , ) = feed.latestRoundData();
            require(ratio > 0, "100");
            castedRatio = uint256(ratio);
        }
        // Checking whether we should multiply or divide by the ratio computed
        if (multiplied == 1) quoteAmount = (quoteAmount * castedRatio) / (10**decimals);
        else quoteAmount = (quoteAmount * (10**decimals)) / castedRatio;
        return (quoteAmount, castedRatio);
    }
}