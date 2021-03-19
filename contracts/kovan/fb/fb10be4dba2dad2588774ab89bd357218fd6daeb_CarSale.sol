/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

contract CarSale {

    // 32Byte struct to decrease size
    struct CarInfo {
        uint128 soldTimestamp;
        uint128 price;
    }

    mapping(address => CarInfo) public carList;
    uint public saleableCount;
    uint public soldCount;
    uint public allCount;

    event CarAdded(address carAddress, uint price, uint soldTimestamp);
    event CarSold(address carAddress, uint price, uint soldTimestamp);

    function addCar(address addr, uint128 price) external {
        CarInfo memory carInfo = carList[addr];
        require(carInfo.price == 0, "Existing Car!");
        carInfo.price = price;
        carList[addr] = carInfo;
        saleableCount++;
        allCount++;
        emit CarAdded(addr, price, block.timestamp);
    }

    function sellCar(address addr) external {
        CarInfo memory carInfo = carList[addr];
        require(carInfo.price != 0, "Car does not exist!");
        require(carInfo.soldTimestamp == 0, "Already sold!");
        carInfo.soldTimestamp = uint128(block.timestamp);
        carList[addr] = carInfo;
        saleableCount--;
        soldCount++;
        emit CarSold(addr, carInfo.price, block.timestamp);
    }

    function getPrice(address addr) external view returns (uint128) {
        return carList[addr].price;
    }

    function isSold(address addr) external view returns (bool) {
        CarInfo memory carInfo = carList[addr];
        if (carInfo.soldTimestamp != 0 && carInfo.price != 0) {
            return true;
        } else {
            return false;
        }
    }
}