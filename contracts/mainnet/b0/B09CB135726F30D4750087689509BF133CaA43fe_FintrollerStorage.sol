/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Exponential.sol";
import "./FyTokenInterface.sol";
import "./UniswapAnchoredViewInterface.sol";

abstract contract FintrollerStorage is Exponential {
    struct Bond {
        Exp collateralizationRatio;
        uint256 debtCeiling;
        bool isBorrowAllowed;
        bool isDepositCollateralAllowed;
        bool isLiquidateBorrowAllowed;
        bool isListed;
        bool isRedeemFyTokenAllowed;
        bool isRepayBorrowAllowed;
        bool isSupplyUnderlyingAllowed;
    }

    /**
     * @dev Maps the fyToken address to the Bond structs.
     */
    mapping(FyTokenInterface => Bond) internal bonds;

    /**
     * @notice The contract that provides price data for the collateral and the underlying asset.
     */
    UniswapAnchoredViewInterface public oracle;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives.
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice The ratio between mantissa precision (1e18) and the oracle price precision (1e6).
     */
    uint256 public constant oraclePricePrecisionScalar = 1.0e12;

    /**
     * @dev The threshold below which the collateralization ratio cannot be set, equivalent to 100%.
     */
    uint256 internal constant collateralizationRatioLowerBoundMantissa = 1.0e18;

    /**
     * @dev The threshold above which the collateralization ratio cannot be set, equivalent to 10,000%.
     */
    uint256 internal constant collateralizationRatioUpperBoundMantissa = 1.0e20;

    /**
     * @dev The dafault collateralization ratio set when a new bond is listed, equivalent to 150%.
     */
    uint256 internal constant defaultCollateralizationRatioMantissa = 1.5e18;

    /**
     * @dev The threshold below which the liquidation incentive cannot be set, equivalent to 100%.
     */
    uint256 internal constant liquidationIncentiveLowerBoundMantissa = 1.0e18;

    /**
     * @dev The threshold above which the liquidation incentive cannot be set, equivalent to 150%.
     */
    uint256 internal constant liquidationIncentiveUpperBoundMantissa = 1.5e18;

    /**
     * @notice Indicator that this is a Fintroller contract, for inspection.
     */
    bool public constant isFintroller = true;
}
