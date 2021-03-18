/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// File: contracts/IPriceStorage.sol

pragma solidity ^0.6.12;

abstract contract IPriceStorage {

    function getAssetPrices(address asset) virtual external view returns (uint);
}

// File: contracts/PriceStorage.sol

pragma solidity ^0.6.12;


contract PriceStorage is IPriceStorage {
    mapping(address => uint) prices;

    function setDirectPrice(address asset, uint price) public {
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function getAssetPrices(address asset) external override view returns (uint) {
        return prices[asset];
    }
}