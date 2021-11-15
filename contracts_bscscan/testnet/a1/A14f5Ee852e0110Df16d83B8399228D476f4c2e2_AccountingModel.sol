// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IAccountingModel {
    function calcJuniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 upsideExposureRate,
        uint256 totalSeniors,
        uint256 totalBalance
    ) external pure returns (uint256);

    function calcSeniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 downsideProtectionRate,
        uint256 totalSeniors,
        uint256 totalBalance
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "../interfaces/IAccountingModel.sol";

contract AccountingModel is IAccountingModel {
    uint256 constant public scaleFactor = 10 ** 18;

    function calcJuniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 upsideExposureRate,
        uint256 totalSeniors,
        uint256 //totalBalance
    ) public pure override returns (uint256) {
        // price went down => there are no profits for the juniors
        if (currentPrice <= entryPrice) {
            return 0;
        }

        uint256 x = currentPrice - entryPrice;
        uint256 y = scaleFactor - upsideExposureRate;

        // (current price - entry price) * (1 - upside rate) * total seniors / current price
        return x * y * totalSeniors / currentPrice / scaleFactor;
    }

    /// @notice Calculates the junior losses (in other words, senior profits) based on the current pool conditions
    /// @dev It always returns 0 if the price went up.
    /// @return The amount, in pool tokens, that is considered loss for the juniors
    function calcSeniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 downsideProtectionRate,
        uint256 totalSeniors,
        uint256 //totalBalance
    ) public pure override returns (uint256) {
        // price went up => there are no losses for the juniors
        if (entryPrice <= currentPrice) {
            return 0;
        }

        // entryPrice * (1 - downsideProtectionRate) + 1
        // adding +1 to avoid rounding errors that would cause it to return profits that are greater than the junior liquidity
        // minPrice would end up equal to 0 if the downsideProtectionRate is 100%
        uint256 minPrice = entryPrice * (scaleFactor - downsideProtectionRate) / scaleFactor + 1;

        // when there are no juniors in the pool and the downside protection rate is 0,
        // the minPrice would be equal to `entryPrice + 1`
        if (entryPrice <= minPrice) {
            return 0;
        }

        uint256 calcPrice = currentPrice;
        if (calcPrice < minPrice) {
            calcPrice = minPrice;
        }

        return totalSeniors * entryPrice / calcPrice - totalSeniors;
    }
}

