// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface ISeniorRateModel {
    function getRates(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256, uint256);
    function getUpsideExposureRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256);
    function getDownsideProtectionRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "../interfaces/ISeniorRateModel.sol";

contract SeniorRateModelV3 is ISeniorRateModel {
    uint256 constant public scaleFactor = 10 ** 18;

    /// @notice m1, b1 and m2, b2 are the coefficients corresponding to the lines used to calculate the rate sum
    /// @dev The equation of the line is calculated using the y = mx + b formula where m is the slope of the line and b is the y-intercept
    // f(x) = -18*x + 1
    uint256 constant public m1 = 18 * scaleFactor; // -18
    uint256 constant public b1 = scaleFactor; // +1

    // f(x) = (18/19)*x + 1/19
    uint256 constant public m2 = 18 * scaleFactor / 19; // 18/19
    uint256 constant public b2 = scaleFactor / 19; // 1/19

    uint256 constant splitPoint = 5 * scaleFactor / 100;

    uint256 constant maxProtectionPercentage = 80 * scaleFactor / 100;
    uint256 constant maxProtectionAbsolute = 35 * scaleFactor / 100;

    // @notice Get the rates offered to seniors based on the current pool conditions
    /// @param juniorLiquidity The total amount of junior liquidity in the pool
    /// @param seniorLiquidity The total amount of senior liquidity in the pool
    /// @return (uint256, uint256) The upside exposure rate and downside protection rate scaled by `scaleFactor`
    function getRates(uint256 juniorLiquidity, uint256 seniorLiquidity) external pure override returns (uint256, uint256) {
        uint256 sum = calcRateSum(juniorLiquidity, seniorLiquidity);
        uint256 protection = getDownsideProtectionRate(juniorLiquidity, seniorLiquidity);

        return (sum - protection, protection);
    }

    /// @notice Get the upside exposure rate based on the current pool conditions
    /// @param juniorLiquidity The total amount of junior liquidity in the pool
    /// @param seniorLiquidity The total amount of senior liquidity in the pool
    /// @return uint256 The upside exposure rate, scaled by `scaleFactor`
    function getUpsideExposureRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external pure override returns (uint256) {
        uint256 sum = calcRateSum(juniorLiquidity, seniorLiquidity);
        uint256 protection = getDownsideProtectionRate(juniorLiquidity, seniorLiquidity);

        return sum - protection;
    }

    /// @notice Get the downside protection rate based on the current pool conditions
    /// @param juniorLiquidity The total amount of junior liquidity in the pool
    /// @param seniorLiquidity The total amount of senior liquidity in the pool
    /// @return uint256 The downside protection rate, scaled by `scaleFactor`
    function getDownsideProtectionRate(uint256 juniorLiquidity, uint256 seniorLiquidity) public pure override returns (uint256) {
        uint256 total = juniorLiquidity + seniorLiquidity;
        if (total == 0) {
            return 0;
        }

        uint256 protection = maxProtectionPercentage * juniorLiquidity / total;

        if (protection <= maxProtectionAbsolute) {
            return protection;
        }

        return maxProtectionAbsolute;
    }

    /// @notice Calculate the sum of upside exposure rate and downside protection rate
    /// @param juniorLiquidity The total amount of junior liquidity in the pool
    /// @param seniorLiquidity The total amount of senior liquidity in the pool
    /// @return uint256 The sum available to split between protection and exposure, scaled by scaleFactor
    /// @dev Leave this function last in the contract to circumvent a bug in the docgen procedure
    function calcRateSum(uint256 juniorLiquidity, uint256 seniorLiquidity) public pure returns (uint256) {
        uint256 total = juniorLiquidity + seniorLiquidity;
        if (total == 0) {
            return scaleFactor;
        }

        uint256 juniorDominance = juniorLiquidity * scaleFactor / total;

        if (juniorDominance < splitPoint) {
            return b1 - m1 * juniorLiquidity / total;
        }

        return m2 * juniorLiquidity / total + b2;
    }
}

