/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract CompoundLogger {
    event Repay(
        address indexed owner,
        uint256 collateralAmount,
        uint256 borrowAmount,
        address collAddr,
        address borrowAddr
    );

    event Boost(
        address indexed owner,
        uint256 borrowAmount,
        uint256 collateralAmount,
        address collAddr,
        address borrowAddr
    );

    // solhint-disable-next-line func-name-mixedcase
    function LogRepay(address _owner, uint256 _collateralAmount, uint256 _borrowAmount, address _collAddr, address _borrowAddr)
        public
    {
        emit Repay(_owner, _collateralAmount, _borrowAmount, _collAddr, _borrowAddr);
    }

    // solhint-disable-next-line func-name-mixedcase
    function LogBoost(address _owner, uint256 _borrowAmount, uint256 _collateralAmount, address _collAddr, address _borrowAddr)
        public
    {
        emit Boost(_owner, _borrowAmount, _collateralAmount, _collAddr, _borrowAddr);
    }
}