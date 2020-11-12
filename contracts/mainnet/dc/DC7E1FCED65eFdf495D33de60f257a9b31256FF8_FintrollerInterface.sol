/* SPDX-License-Identifier: LPGL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FintrollerStorage.sol";
import "./FyTokenInterface.sol";

abstract contract FintrollerInterface is FintrollerStorage {
    /**
     * CONSTANT FUNCTIONS
     */

    function getBond(FyTokenInterface fyToken)
        external
        view
        virtual
        returns (
            uint256 debtCeiling,
            uint256 collateralizationRatioMantissa,
            bool isBorrowAllowed,
            bool isDepositCollateralAllowed,
            bool isLiquidateBorrowAllowed,
            bool isListed,
            bool isRedeemFyTokenAllowed,
            bool isRepayBorrowAllowed,
            bool isSupplyUnderlyingAllowed
        );

    function getBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getBondDebtCeiling(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getBondCollateralizationRatio(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getDepositCollateralAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getLiquidateBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getRedeemFyTokensAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getRepayBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getSupplyUnderlyingAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    /**
     * NON-CONSTANT FUNCTIONS
     */

    function listBond(FyTokenInterface fyToken) external virtual returns (bool);

    function setBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setCollateralizationRatio(FyTokenInterface fyToken, uint256 newCollateralizationRatioMantissa)
        external
        virtual
        returns (bool);

    function setDebtCeiling(FyTokenInterface fyToken, uint256 newDebtCeiling) external virtual returns (bool);

    function setDepositCollateralAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setLiquidateBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external virtual returns (bool);

    function setOracle(UniswapAnchoredViewInterface newOracle) external virtual returns (bool);

    function setRedeemFyTokensAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setRepayBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setSupplyUnderlyingAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    /**
     * EVENTS
     */
    event ListBond(address indexed admin, FyTokenInterface indexed fyToken);

    event SetBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetCollateralizationRatio(
        address indexed admin,
        FyTokenInterface indexed fyToken,
        uint256 oldCollateralizationRatio,
        uint256 newCollateralizationRatio
    );

    event SetDebtCeiling(
        address indexed admin,
        FyTokenInterface indexed fyToken,
        uint256 oldDebtCeiling,
        uint256 newDebtCeiling
    );

    event SetDepositCollateralAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetLiquidateBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetLiquidationIncentive(
        address indexed admin,
        uint256 oldLiquidationIncentive,
        uint256 newLiquidationIncentive
    );

    event SetRedeemFyTokensAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetRepayBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetOracle(address indexed admin, address oldOracle, address newOracle);

    event SetSupplyUnderlyingAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);
}
