/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./BalanceSheetStorage.sol";

/**
 * @title BalanceSheetInterface
 * @author Mainframe
 */
abstract contract BalanceSheetInterface is BalanceSheetStorage {
    /**
     * CONSTANT FUNCTIONS
     */
    function getClutchableCollateral(FyTokenInterface fyToken, uint256 repayAmount)
        external
        view
        virtual
        returns (uint256);

    function getCurrentCollateralizationRatio(FyTokenInterface fyToken, address account)
        public
        view
        virtual
        returns (uint256);

    function getHypotheticalCollateralizationRatio(
        FyTokenInterface fyToken,
        address account,
        uint256 lockedCollateral,
        uint256 debt
    ) public view virtual returns (uint256);

    function getVault(FyTokenInterface fyToken, address account)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function getVaultDebt(FyTokenInterface fyToken, address account) external view virtual returns (uint256);

    function getVaultLockedCollateral(FyTokenInterface fyToken, address account)
        external
        view
        virtual
        returns (uint256);

    function isAccountUnderwater(FyTokenInterface fyToken, address account) external view virtual returns (bool);

    function isVaultOpen(FyTokenInterface fyToken, address account) external view virtual returns (bool);

    /**
     * NON-CONSTANT FUNCTIONS
     */

    function clutchCollateral(
        FyTokenInterface fyToken,
        address liquidator,
        address borrower,
        uint256 clutchedCollateralAmount
    ) external virtual returns (bool);

    function depositCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    function freeCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    function lockCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    function openVault(FyTokenInterface fyToken) external virtual returns (bool);

    function setVaultDebt(
        FyTokenInterface fyToken,
        address account,
        uint256 newVaultDebt
    ) external virtual returns (bool);

    function withdrawCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    /**
     * EVENTS
     */

    event ClutchCollateral(
        FyTokenInterface indexed fyToken,
        address indexed liquidator,
        address indexed borrower,
        uint256 clutchedCollateralAmount
    );

    event DepositCollateral(FyTokenInterface indexed fyToken, address indexed account, uint256 collateralAmount);

    event FreeCollateral(FyTokenInterface indexed fyToken, address indexed account, uint256 collateralAmount);

    event LockCollateral(FyTokenInterface indexed fyToken, address indexed account, uint256 collateralAmount);

    event OpenVault(FyTokenInterface indexed fyToken, address indexed account);

    event SetVaultDebt(FyTokenInterface indexed fyToken, address indexed account, uint256 oldDebt, uint256 newDebt);

    event WithdrawCollateral(FyTokenInterface indexed fyToken, address indexed account, uint256 collateralAmount);
}
