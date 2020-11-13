/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FyTokenStorage.sol";

/**
 * @title FyTokenInterface
 * @author Mainframe
 */
abstract contract FyTokenInterface is FyTokenStorage {
    /**
     * NON-CONSTANT FUNCTIONS
     */
    function borrow(uint256 borrowAmount) external virtual returns (bool);

    function burn(address holder, uint256 burnAmount) external virtual returns (bool);

    function liquidateBorrow(address borrower, uint256 repayAmount) external virtual returns (bool);

    function mint(address beneficiary, uint256 borrowAmount) external virtual returns (bool);

    function repayBorrow(uint256 repayAmount) external virtual returns (bool);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (bool);

    function _setFintroller(FintrollerInterface newFintroller) external virtual returns (bool);

    /**
     * EVENTS
     */
    event Borrow(address indexed account, uint256 repayAmount);

    event LiquidateBorrow(
        address indexed liquidator,
        address indexed borrower,
        uint256 repayAmount,
        uint256 clutchedCollateralAmount
    );

    event RepayBorrow(address indexed payer, address indexed borrower, uint256 repayAmount, uint256 newDebt);

    event SetFintroller(address indexed admin, FintrollerInterface oldFintroller, FintrollerInterface newFintroller);
}
