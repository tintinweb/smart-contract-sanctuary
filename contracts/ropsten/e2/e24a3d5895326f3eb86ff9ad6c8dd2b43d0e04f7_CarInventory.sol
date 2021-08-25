/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

contract Car {
    uint public price;
    string public infoURI;
    
    constructor(uint _price, string memory _infoURI) {
        price = _price;
        infoURI = _infoURI;
    }
}

contract CarInventory {
    struct CarSale {
       address carAddress;
       uint price;
    }

    struct CarInfo {
        address carAddress;
        uint price;
        string infoURI;
    }

    CarSale[] public carSales;
    mapping(address => CarInfo) public carInfos;
    
    event CarAdded(address indexed carAddress, uint price);

    function recordSales(address _carAddress) public {
        CarInfo storage info = carInfos[_carAddress];
        
        require(info.carAddress != address(0), "CarInventory::recordSales: invalid car address");

        CarSale storage newSale;
        newSale.carAddress = _carAddress;
        newSale.price = info.price;

        carSales.push(newSale);
    }

    function addCar(uint _price, string memory _infoURI) public returns(address newCarAddress) {
        Car newCar = new Car(_price, _infoURI);
        
        newCarAddress = address(newCar);

        CarInfo storage newInfo = carInfos[newCarAddress];
        newInfo.carAddress = newCarAddress;
        newInfo.price = _price;
        newInfo.infoURI = _infoURI;
        
        emit CarAdded(newCarAddress, _price);
    }
}