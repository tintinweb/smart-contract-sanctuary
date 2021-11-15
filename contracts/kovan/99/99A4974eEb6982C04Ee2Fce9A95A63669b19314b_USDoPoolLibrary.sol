// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Globals.sol";

library USDoPoolLibrary {
    // ================ Functions ================

    // all data mast have G_PRECISIONS

    function calcMint1t1USDo(uint256 collateralPrice_, uint256 collateralAmount_) external pure returns (uint256) {
        return collateralAmount_ * collateralPrice_ / G_PRECISION;
    }

    function calcMintAlgorithmicUSDo(uint256 ORSPrice_, uint256 ORSAmount_) external pure returns (uint256) {
        return ORSAmount_ * ORSPrice_ / G_PRECISION;
    }

    // Must be internal because of the struct
    function calcMintFractionalUSDo(
        uint256 ORSPrice_,
        uint256 collateralPrice_,
        uint256 collateralAmount_,
        uint256 collateralRatio_
    ) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint USDo. We do this by seeing the minimum mintable USDo based on each amount

        uint256 collateralDollarValue = collateralAmount_ * collateralPrice_ / G_PRECISION;

        uint256 calculatedORSDollarValue = (collateralDollarValue * G_PRECISION / collateralRatio_) - collateralDollarValue;

        uint256 calculatedORSNeeded = calculatedORSDollarValue * G_PRECISION / ORSPrice_;

        return (
            collateralDollarValue + calculatedORSDollarValue,
            calculatedORSNeeded
        );
    }

    function calcRedeem1t1USDo(uint256 collateralPrice_, uint256 USDoAmount_) public pure returns (uint256) {
        return USDoAmount_ * G_PRECISION / collateralPrice_;
    }

    // Must be internal because of the struct
    function calcBuyBackORS(uint256 ORSPrice_, uint256 ORSAmount_, uint256 collateralPrice_, uint256 excessCollateralDollarValue_) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible ORS with the desired collateral
        require(excessCollateralDollarValue_ > 0, "USDoPoolLibrary: No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 ORSDollarValue = ORSAmount_ * ORSPrice_ / G_PRECISION;

        require(ORSDollarValue <= excessCollateralDollarValue_, "USDoPoolLibrary: You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of FXS provided 
        return ORSDollarValue * G_PRECISION / collateralPrice_;
    }


    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 totalSupply_, uint256 globalCollateralRatio_, uint256 globalCollateralValue_) public pure returns (uint256) {
        uint256 targetCollateralValue = totalSupply_ * globalCollateralRatio_ / G_PRECISION;
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return targetCollateralValue < globalCollateralValue_ ? 0 : targetCollateralValue - globalCollateralValue_;
    }

    function calcRecollateralizeUSDoInner(
        uint256 collateralAmount_,
        uint256 collateralPrice_,
        uint256 globalCollateralValue_,
        uint256 USDoTotalSupply_,
        uint256 globalCollateralRatio_
    ) public pure returns (uint256, uint256) {
        uint256 collateralValueAttempted = collateralAmount_ * collateralPrice_ / G_PRECISION;
        uint256 effectiveCollateralRatio = globalCollateralValue_ * G_PRECISION / USDoTotalSupply_;
        uint256 recollateralizePossible = ((globalCollateralRatio_ * USDoTotalSupply_) - (effectiveCollateralRatio * USDoTotalSupply_)) / G_PRECISION;
        uint256 amountToRecollateralize = collateralValueAttempted <= recollateralizePossible ? collateralValueAttempted : recollateralizePossible;

        return (amountToRecollateralize * G_PRECISION / collateralPrice_, amountToRecollateralize);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

uint256 constant G_DECIMALS = 8;
uint256 constant G_PRECISION = 10 ** G_DECIMALS;

bytes32 constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
bytes32 constant POOL_ROLE = keccak256("POOL_ROLE");
bytes32 constant ADMIN_USDO_ROLE = keccak256("ADMIN_USDO_ROLE"); // onlyByOwnerGovernanceOrController for Orion Stablecoin

bytes32 constant MINT_PAUSER = keccak256("MINT_PAUSER");
bytes32 constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
bytes32 constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
bytes32 constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
bytes32 constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");

