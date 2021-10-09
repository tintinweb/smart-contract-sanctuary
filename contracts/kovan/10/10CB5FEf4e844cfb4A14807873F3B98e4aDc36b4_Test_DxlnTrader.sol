// SPDX-License-Identifier: MIT

/*
    Copyright 2020 dYdX Trading Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnTypes.sol";
import "./I_DxlnTrader.sol";

/**
 * @title Test_DxlnTrader
 * @author dYdX
 *
 * @notice I_DxlnTrader implementation for testing.
 */
/* solium-disable-next-line camelcase */
contract Test_DxlnTrader is I_DxlnTrader {
    DxlnTypes.TradeResult public _TRADE_RESULT_;
    DxlnTypes.TradeResult public _TRADE_RESULT_2_;

    // Special testing-only trader flag that will cause the second result to be returned.
    bytes32 public constant TRADER_FLAG_RESULT_2 = bytes32(~uint256(0));

    function trade(
        address, // sender
        address, // maker
        address, // taker
        uint256, // price
        bytes calldata, // data
        bytes32 traderFlags
    ) external override returns (DxlnTypes.TradeResult memory) {
        if (traderFlags == TRADER_FLAG_RESULT_2) {
            return _TRADE_RESULT_2_;
        }
        return _TRADE_RESULT_;
    }

    function setTradeResult(
        uint256 marginAmount,
        uint256 positionAmount,
        bool isBuy,
        bytes32 traderFlags
    ) external {
        _TRADE_RESULT_ = DxlnTypes.TradeResult({
            marginAmount: marginAmount,
            positionAmount: positionAmount,
            isBuy: isBuy,
            traderFlags: traderFlags
        });
    }

    /**
     * Sets a second trade result which can be triggered by the trader flags of the first trade.
     */
    function setSecondTradeResult(
        uint256 marginAmount,
        uint256 positionAmount,
        bool isBuy,
        bytes32 traderFlags
    ) external {
        _TRADE_RESULT_2_ = DxlnTypes.TradeResult({
            marginAmount: marginAmount,
            positionAmount: positionAmount,
            isBuy: isBuy,
            traderFlags: traderFlags
        });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnTypes.sol";

/**
 * @notice Interface that PerpetualV1 Traders must implement.
 */
interface I_DxlnTrader {
    /**
     * @notice Returns the result of the trade between the maker and the taker. Expected to be
     *  called by PerpetualV1. Reverts if the trade is disallowed.
     *
     * @param  sender       The address that called the `trade()` function of PerpetualV1.
     * @param  maker        The address of the passive maker account.
     * @param  taker        The address of the active taker account.
     * @param  price        The current oracle price of the underlying asset.
     * @param  data         Arbitrary data passed in to the `trade()` function of PerpetualV1.
     * @param  traderFlags  Any flags that have been set by other I_P1Trader contracts during the
     *                      same call to the `trade()` function of PerpetualV1.
     * @return              The result of the trade from the perspective of the taker.
     */
    function trade(
        address sender,
        address maker,
        address taker,
        uint256 price,
        bytes calldata data,
        bytes32 traderFlags
    ) external returns (DxlnTypes.TradeResult memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Library for common types used in PerpetualV1 contracts.
 */

library DxlnTypes {
    // ============ Structs ============

    /**
     * @dev Used to represent the global index and each account's cached index.
     *  Used to settle funding payments on a per-account basis.
     */
    struct Index {
        uint32 timestamp;
        bool isPositive;
        uint128 value;
    }

    /**
     * @dev Used to track the signed margin balance and position balance values for each account.
     */
    struct Balance {
        bool marginIsPositive;
        bool positionIsPositive;
        uint120 margin;
        uint120 position;
    }

    /**
     * @dev Used to cache commonly-used variables that are relatively gas-intensive to obtain.
     */
    struct Context {
        uint256 price;
        uint256 minCollateral;
        Index index;
    }

    /**
     * @dev Used by contracts implementing the I_DxlnTrader interface to return the result of a trade.
     */
    struct TradeResult {
        uint256 marginAmount;
        uint256 positionAmount;
        bool isBuy; // From taker's perspective.
        bytes32 traderFlags;
    }
}