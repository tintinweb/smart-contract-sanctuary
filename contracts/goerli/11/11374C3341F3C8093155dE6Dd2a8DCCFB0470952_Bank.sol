//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "./IBank.sol";
import "./IPriceOracle.sol";

contract Bank is IBank {

    constructor(address _priceOracle, address _hakToken) {

    }
    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {}

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {}

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {}

    function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) {}

    function liquidate(address token, address account)
        payable
        external
        override
        returns (bool) {}

    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) {}

    function getBalance(address token)
        view
        public
        override
        returns (uint256) {}
}