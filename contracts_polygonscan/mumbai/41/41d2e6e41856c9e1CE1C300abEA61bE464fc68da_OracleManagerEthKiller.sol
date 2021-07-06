// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.3;
pragma abicoder v2;

/* Standard Band oracle interface. Prices are queried by pair, i.e. what is
 * the price of the given base currency in units of the quote currency?
 *    see:
 *  https://kovan.etherscan.io/address/0xDA7a001b254CD22e46d3eAB04d937489c93174C3#code
 *  https://docs.matic.network/docs/develop/oracles/bandstandarddataset/
 */
interface IBandOracle {
    struct ReferenceData {
        uint256 rate; // exchange rate for base/quote in 1e18 scale
        uint256 lastUpdatedBase; // secs after epoch, last time base updated
        uint256 lastUpdatedQuote; // secs after epoch, last time quote updated
    }

    /*
     *Returns price data for given base/quote pair. Reverts if not available.
     */
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /*
     * Batch version of getReferenceData(...).
     */
    function getReferenceDataBulk(
        string[] memory _bases,
        string[] memory _quotes
    ) external view returns (ReferenceData[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.3;

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

pragma solidity 0.8.3;

// import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IBandOracle.sol";
import "../interfaces/IOracleManager.sol";

contract OracleManagerEthKiller is IOracleManager {
    address public admin; // This will likely be the Gnosis safe

    // Oracle price, changes by average of the underlying asset changes.
    uint256 public indexPrice;

    // Underlying asset prices.
    uint256 public tronPrice;
    uint256 public eosPrice;
    uint256 public xrpPrice;

    // Band oracle address.
    IBandOracle public oracle;

    ////////////////////////////////////
    /////////// MODIFIERS //////////////
    ////////////////////////////////////

    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

    ////////////////////////////////////
    ///// CONTRACT SET-UP //////////////
    ////////////////////////////////////

    constructor(address _admin, address _bandOracle) {
        admin = _admin;
        oracle = IBandOracle(_bandOracle);

        // Initial asset prices.
        (tronPrice, eosPrice, xrpPrice) = _getAssetPrices();

        // Initial base index price.
        indexPrice = 1e18;
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

    function _getAssetPrices()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        string[] memory baseSymbols = new string[](3);
        baseSymbols[0] = "TRX"; // tron
        baseSymbols[1] = "EOS"; // eos
        baseSymbols[2] = "XRP"; // ripple

        string[] memory quoteSymbols = new string[](3);
        quoteSymbols[0] = "BUSD";
        quoteSymbols[1] = "BUSD";
        quoteSymbols[2] = "BUSD";

        IBandOracle.ReferenceData[] memory data =
            oracle.getReferenceDataBulk(baseSymbols, quoteSymbols);

        return (data[0].rate, data[1].rate, data[2].rate);
    }

    function updatePrice() external override returns (int256) {
        (uint256 newTronPrice, uint256 newEosPrice, uint256 newXrpPrice) =
            _getAssetPrices();

        int256 valueOfChangeInIndex =
            (int256(indexPrice) *
                (_calcAbsolutePercentageChange(newTronPrice, tronPrice) +
                    _calcAbsolutePercentageChange(newEosPrice, eosPrice) +
                    _calcAbsolutePercentageChange(newXrpPrice, xrpPrice))) /
                (3 * 1e18);

        tronPrice = newTronPrice;
        eosPrice = newEosPrice;
        xrpPrice = newXrpPrice;

        indexPrice = uint256(int256(indexPrice) + valueOfChangeInIndex);

        return int256(indexPrice);
    }

    function _calcAbsolutePercentageChange(uint256 newPrice, uint256 basePrice)
        internal
        pure
        returns (int256)
    {
        return
            ((int256(newPrice) - int256(basePrice)) * (1e18)) /
            (int256(basePrice));
    }

    function getLatestPrice() external view override returns (int256) {
        return int256(indexPrice);
    }
}

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