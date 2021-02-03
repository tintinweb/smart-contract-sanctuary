// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library Constants {
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _launchSupply = 185000 * 10**9;
    uint256 private constant _largeTotal = (MAX - (MAX % _launchSupply));

    uint256 private constant _deployerCost = 10 ether;

    uint256 private constant _baseExpansionFactor = 300;
    uint256 private constant _baseContractionFactor = 100;
    uint256 private constant _baseUtilityFee = 50;
    uint256 private constant _baseContractionCap = 1000;

    uint256 private constant _presaleIndividualCap = 1 ether;
    uint256 private constant _presaleIndividualMin = 1 ether;
    uint256 private constant _presaleCap = 1 * 10**5 * 10**9;
    uint256 private constant _maxPresaleGas = 200000000000;

    uint256 private constant _epochLength = 30 minutes;

    address private constant _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address payable private constant _deployerAddress = 0x083c3b9a697596755834dbEF3D0a70a77c36Ae07;

    string private constant _name = "UPSTABLE.PROTOCOL";
    string private constant _symbol = "UPS";
    uint8 private constant _decimals = 9;


    /****** Getters *******/
    function getLaunchSupply() internal pure returns (uint256) {
        return _launchSupply;
    }
    function getLargeTotal() internal pure returns (uint256) {
        return _largeTotal;
    }
    function getBaseExpansionFactor() internal pure returns (uint256) {
        return _baseExpansionFactor;
    }
    function getBaseContractionFactor() internal pure returns (uint256) {
        return _baseContractionFactor;
    }
    function getBaseContractionCap() internal pure returns (uint256) {
        return _baseContractionCap;
    }
    function getDeployerCost() internal pure returns (uint256) {
        return _deployerCost;
    }
    function getPresaleCap() internal pure returns (uint256) {
        return _presaleCap;
    }
    function getPresaleIndividualMin() internal pure returns (uint256) {
        return _presaleIndividualMin;
    }
    function getPresaleIndividualCap() internal pure returns (uint256) {
        return _presaleIndividualCap;
    }
    function getMaxPresaleGas() internal pure returns (uint256) {
        return _maxPresaleGas;
    }
    function getBaseUtilityFee() internal pure returns (uint256) {
        return _baseUtilityFee;
    }
    function getEpochLength() internal pure returns (uint256) {
        return _epochLength;
    }
    function getRouterAdd() internal pure returns (address) {
        return _routerAddress;
    }
    function getFactoryAdd() internal pure returns (address) {
        return _factoryAddress;
    }
    function getDeployerAdd() internal pure returns (address payable) {
        return _deployerAddress;
    }
    function getName() internal pure returns (string memory)  {
        return _name;
    }
    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }
    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

}