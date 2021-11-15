// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../protocol/intf/IPriceOracle.sol";
import "../../protocol/intf/AggregatorV3Interface.sol";

contract WethPriceOracle is IPriceOracle {
    // ============ Storage ============

    AggregatorV3Interface public PRICEFEED;

    uint256 constant DECIMALS = 10;

    // ============ Constructor =============

    constructor(address oracle) {
        PRICEFEED = AggregatorV3Interface(oracle);
    }

    // ============ IPriceOracle Functions =============

    function getPrice(
        address /* token */
    ) public view override returns (Monetary.Price memory) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = PRICEFEED.latestRoundData();

        uint256 answerDecimal = uint256(answer) * (10**DECIMALS);

        return Monetary.Price({value: answerDecimal});
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * Library for types involving money
 */

library Monetary {
    /*
     * The price of a base-unit of an asset.
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount).
     */
    struct Value {
        uint256 value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/Monetary.sol";

/**
 * Interface that Price Oracles for DxlnMargin must implement in order to report prices.
 */
abstract contract IPriceOracle {
    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10**36;

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(address token)
        public
        view
        virtual
        returns (Monetary.Price memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

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

