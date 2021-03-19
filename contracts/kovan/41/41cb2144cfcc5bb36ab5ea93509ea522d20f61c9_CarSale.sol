/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

contract CarSale {

    struct CarInfo {
        uint128 soldTimestamp;
        uint128 price;
    }

    mapping(address => CarInfo) public carList;

    function addCar(address addr, uint128 price) external {
        CarInfo memory carInfo = carList[addr];
        require(carInfo.price == 0, "Existing Car!");
        carInfo.price = price;
        carList[addr] = carInfo;
    }

    function sellCar(address addr) external {
        CarInfo memory carInfo = carList[addr];
        require(carInfo.price != 0, "Car does not exist!");
        require(carInfo.soldTimestamp == 0, "Already sold!");
        carInfo.soldTimestamp = uint128(block.timestamp);
        carList[addr] = carInfo;
    }

    function getPrice(address addr) external view returns (uint128){
        return carList[addr].price;
    }
}