/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

pragma solidity ^0.5.0;


/**
* ILendingRateOracle interface
* -
* Interface for the Populous borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/
interface ILendingRateOracle {
    /**
    @dev returns the market borrow rate in ray
    **/
    function getMarketBorrowRate(address _asset) external view returns (uint256);

    /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
    function setMarketBorrowRate(address _asset, uint256 _rate) external;
}

contract LendingRateOracle is ILendingRateOracle {

    mapping(address => uint256) borrowRates;
    mapping(address => uint256) liquidityRates;


    function getMarketBorrowRate(address _asset) external view returns(uint256) {
        return borrowRates[_asset];
    }

    function setMarketBorrowRate(address _asset, uint256 _rate) external {
        borrowRates[_asset] = _rate;
    }

    function getMarketLiquidityRate(address _asset) external view returns(uint256) {
        return liquidityRates[_asset];
    }

    function setMarketLiquidityRate(address _asset, uint256 _rate) external {
        liquidityRates[_asset] = _rate;
    }
}