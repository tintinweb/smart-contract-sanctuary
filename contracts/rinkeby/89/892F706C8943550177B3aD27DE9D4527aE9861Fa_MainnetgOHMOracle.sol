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

interface IOracle {
    function fetchPrice() external view returns (bool, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "../interfaces/AggregatorV3Interface.sol";

library SafeAggregatorV3 {
    uint private constant TARGET_DECIMALS = 18;
    /**
     * @notice returns  the latest price from a chainlink feed
     * @return boolean if call was successful
     * @return the price with 18 decimals
     */
    function safeLatestRoundData(AggregatorV3Interface self) internal view returns (bool, uint) {
        uint8 decimals;

        try self.decimals() returns (uint8 decimals_) {
            decimals = decimals_;
        } catch {
            return (false, 0);
        }

        try self.latestRoundData() returns
        (
            uint80 /* currentRoundId */,
            int256 currentPrice,
            uint256 /* startedAt */,
            uint256 /* timestamp */,
            uint80 /* answeredInRound */
        ) {
            uint price = uint(currentPrice);
            if (decimals < TARGET_DECIMALS) {
                price = price * (10**(TARGET_DECIMALS - decimals));
            } else if (decimals > TARGET_DECIMALS) {
                price = price / (10**(decimals - TARGET_DECIMALS));
            }
            return (true, price);
        } catch {
            return (false, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOracle } from "../interfaces/IOracle.sol";
import { AggregatorV3Interface } from "../interfaces/AggregatorV3Interface.sol";
import { SafeAggregatorV3 } from "../libraries/SafeAggregatorV3.sol";

interface IgOHM {
    /**
        @notice converts OHM amount to gOHM
        @param _amount amount of gOHM
        @return amount of OHM
     */
    function balanceFrom(uint256 _amount) external view returns (uint256);
    function balanceTo(uint256 _amount) external view returns (uint256);
    function index() external view returns (uint);
}

/**
 * @notice price oracle for gOHM-USD on the ethereum mainnet
 */
contract MainnetgOHMOracle is IOracle {
    using SafeAggregatorV3 for AggregatorV3Interface;

    uint256 private constant GOHM_PRECISION = 1e9;
    IgOHM private gOHM;
    AggregatorV3Interface private ohmEthFeed;
    AggregatorV3Interface private ethUsdFeed;

    constructor(
        address _gohm,
        address _ohmEthFeed,
        address _ethUsdFeed
    ) {
        require(_gohm != address(0), "Oracle: 0x0 gOHM address");
        require(_ohmEthFeed != address(0), "Oracle: 0x0 OHM-ETH address");
        require(_ethUsdFeed != address(0), "Oracle: 0x0 ETH-USD address");

        gOHM = IgOHM(_gohm);
        ohmEthFeed = AggregatorV3Interface(_ohmEthFeed);
        ethUsdFeed = AggregatorV3Interface(_ethUsdFeed);
    }

    /**
     * @notice fetches the latest price
     * @return the price with 18 decimals
     */
    function fetchPrice() external view override returns (bool, uint) {
        (bool ethUsdSuccess, uint ethUsdPrice) = ethUsdFeed.safeLatestRoundData();
        (bool ohmEthSuccess, uint ohmEthPrice) = ohmEthFeed.safeLatestRoundData();

        if (!ethUsdSuccess || !ohmEthSuccess) {
            return (false, 0);
        }

         return (true, ((ohmEthPrice * ethUsdPrice / 1e18) * gOHM.index() / 1e9));
    }
}