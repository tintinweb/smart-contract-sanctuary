// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../external/IDiaOracle.sol";
import "../external/ICoinGeckoOracle.sol";
import "../external/ICoinMarketCapOracle.sol";
import "./Oracle.sol";

/**
 * @title DiaOracleAdapter
 */
contract ThreeOracleAdapter is Oracle {
    uint public constant WAD = 10 ** 18;
    uint256 public constant DECIMAL_CORRECTION = 10**13;

    IDiaOracle public immutable diaOracle;
    ICoinGeckoOracle public immutable coinGeckoOracle;
    ICoinMarketCapOracle public immutable coinMarketCapOracle;
    string public syntheticDiaFeed;
    string public collateralDiaFeed;
    string public syntheticCoinGeckoFeed;
    string public collateralCoinGeckoFeed;
    string public syntheticCoinMarketCapFeed;
    string public collateralCoinMarketCapFeed;

    constructor(
        IDiaOracle diaOracle_, 
        string memory syntheticDiaFeed_, 
        string memory collateralDiaFeed_,
        ICoinGeckoOracle coinGeckoOracle_,
        string memory syntheticCoinGeckoFeed_, 
        string memory collateralCoinGeckoFeed_,
        ICoinMarketCapOracle coinMarketCapOracle_,
        string memory syntheticCoinMarketCapFeed_, 
        string memory collateralCoinMarketCapFeed_
    ) {
        diaOracle = diaOracle_;
        coinGeckoOracle = coinGeckoOracle_;
        coinMarketCapOracle = coinMarketCapOracle_;
        syntheticDiaFeed = syntheticDiaFeed_;
        collateralDiaFeed = collateralDiaFeed_;
        syntheticCoinGeckoFeed = syntheticCoinGeckoFeed_;
        collateralCoinGeckoFeed = collateralCoinGeckoFeed_;
        syntheticCoinMarketCapFeed = syntheticCoinMarketCapFeed_;
        collateralCoinMarketCapFeed = collateralCoinMarketCapFeed_;
    }

    /**
     * @notice Retrieve the latest price of the price diaOracle.
     * @return price
     */
    function latestPrice() public virtual override view returns (uint price, uint updateTime) {
        (uint256 collateralPrice, uint256 collateralUpdateTime) = getPrice(collateralDiaFeed, collateralCoinGeckoFeed, collateralCoinMarketCapFeed);
        (uint256 syntheticPrice, uint256 syntheticUpdateTime) = getPrice(syntheticDiaFeed, syntheticCoinGeckoFeed, syntheticCoinMarketCapFeed);
        price = collateralPrice * WAD / syntheticPrice;
        // TODO return time
        updateTime = Math.max(collateralUpdateTime, syntheticUpdateTime);
    }

    /**
     * @notice Retrieve the latest price of the price diaOracle.
     * @return price
     */
    function getPrice(string memory diaTicker, string memory coinGeckoTicker, string memory coinMarketCapTicker) private view returns(uint256 price, uint256 updateTime) {
        (uint256 diaPrice, ,uint256 diaTime, ) = diaOracle.getCoinInfo(diaTicker);
        (uint256 coinGeckoPrice, uint256 coinGeckoTime) = coinGeckoOracle.getValue(coinGeckoTicker);
        (uint256 coinMarketCapPrice, uint256 coinMarketCapTime) = coinMarketCapOracle.getValue(coinMarketCapTicker);

        bool p1gtp2 = diaPrice > coinGeckoPrice; // if price 1 is greater than price 2
        bool p2gtp3 = coinGeckoPrice > coinMarketCapPrice;
        bool p3gtp1 = coinMarketCapPrice > diaPrice;

        (price, updateTime) = (p3gtp1 == p1gtp2 ? 
            (diaPrice, diaTime) : 
            (p1gtp2 == p2gtp3 ? 
                (coinGeckoPrice, coinGeckoTime) : 
                (coinMarketCapPrice, coinMarketCapTime)
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IDiaOracle {
    function getCoinInfo(string memory key) external view returns (uint256, uint256, uint256, string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface ICoinGeckoOracle {
    function getValue(string memory key) external view returns (uint128, uint128);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface ICoinMarketCapOracle {
    function getValue(string memory key) external view returns (uint128, uint128);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

abstract contract Oracle {
    function latestPrice() public virtual view returns (uint price, uint updateTime);    // Prices WAD-scaled - 18 dec places

    function refreshPrice() public virtual returns (uint price, uint updateTime) {
        (price, updateTime) = latestPrice();    // Default implementation doesn't do any cacheing.  But override as needed
    }
}

