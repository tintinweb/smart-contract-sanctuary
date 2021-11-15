// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../protocol/intf/IPriceOracle.sol";

/**
 * PriceOracle that returns the price of USDC in USD
 */
contract UsdcPriceOracle is IPriceOracle {
    // ============ Constants ============

    uint256 constant DECIMALS = 6;

    uint256 constant EXPECTED_PRICE = ONE_DOLLAR / (10**DECIMALS);

    // ============ IPriceOracle Functions =============

    function getPrice(
        address /* token */
    ) public pure override returns (Monetary.Price memory) {
        return Monetary.Price({value: EXPECTED_PRICE});
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

