// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface Erc20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);
}

interface CEth {
    function mint() external payable;

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface Comptroller {
    function markets(address) external returns (bool, uint256);

    //
    function enterMarkets(address[] calldata) 
        external
        returns (uint256[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface PriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

contract Compound {
    event MyLog(string, uint256);

    struct BorrowInfo {
        address payable _cEtherAddress;
        address _comptrollerAddress;
        address _cTokenAddress;
        address _underlyingAddress;
        uint256 _underlyingToSupplyAsCollateral;
        uint256 borrows;
    }

    function borrowEth(
        address payable _cEtherAddress, //
        address _comptrollerAddress,
        address _cTokenAddress, //
        address _underlyingAddress,
        uint256 _underlyingToSupplyAsCollateral
    ) public returns (uint256) {
        BorrowInfo memory borrowInfo;

        borrowInfo._cEtherAddress = _cEtherAddress;
        borrowInfo._comptrollerAddress = _comptrollerAddress;
        borrowInfo._cTokenAddress = _cTokenAddress;
        borrowInfo._underlyingAddress = _underlyingAddress;
        borrowInfo._underlyingToSupplyAsCollateral = _underlyingToSupplyAsCollateral;

        CEth cEth = CEth(borrowInfo._cEtherAddress);
        Comptroller comptroller = Comptroller(borrowInfo._comptrollerAddress);
        CErc20 cToken = CErc20(borrowInfo._cTokenAddress);
        Erc20 underlying = Erc20(borrowInfo._underlyingAddress);
        // Approve transfer of underlying
        underlying.approve(
            borrowInfo._cTokenAddress,
            borrowInfo._underlyingToSupplyAsCollateral
        );

        // Supply underlying as collateral, get cToken in return
        uint256 error = cToken.mint(borrowInfo._underlyingToSupplyAsCollateral);
        require(error != 0, "CErc20.mint Error");

        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = borrowInfo._cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }

        // Get my account's total liquidity value in Compound
        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(msg.sender);
        if (error2 != 0) {
            revert("Comptroller.getAccountLiquidity failed.");
        }
        require(shortfall == 0, "account underwater");
        // require(liquidity > 1, "account has excess collateral");

        // Borrowing near the max amount will result
        // in your account being liquidated instantly
        emit MyLog("Maximum ETH Borrow (borrow far less!)", liquidity);

        // Get the collateral factor for our collateral
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            borrowInfo._cTokenAddress
        );
        emit MyLog("Collateral Factor", collateralFactorMantissa);

        // Get the amount of ETH added to your borrow each block
        uint256 borrowRateMantissa = cEth.borrowRatePerBlock();
        emit MyLog("Current ETH Borrow Rate", borrowRateMantissa);

        // Borrow a fixed amount of ETH below our maximum borrow amount
        uint256 numWeiToBorrow = 2000000000000000; // 0.002 ETH

        // Borrow, then check the underlying balance for this contract's address
        cEth.borrow(numWeiToBorrow);

        borrowInfo.borrows = cEth.borrowBalanceCurrent(msg.sender);
        emit MyLog("Current ETH borrow amount", borrowInfo.borrows);

        return borrowInfo.borrows;
    }
}