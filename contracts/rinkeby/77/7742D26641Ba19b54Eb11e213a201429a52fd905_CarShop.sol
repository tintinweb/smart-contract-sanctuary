//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

contract CarShop {

    struct Car {
        uint price;
        address buyerAddress;
    }

    event CarSold (
        uint indexed carId,
        uint price,
        address indexed buyerAddress
    );

    Car[] public inventory;

    function addCarToInventory(uint _price) external {
        Car memory car = Car({price: _price, buyerAddress: address(0)});
        inventory.push(car);
    }

    function recordSale(uint carId, address buyerAddress) external {
        Car storage car = inventory[carId];
        car.buyerAddress = buyerAddress;
        inventory[carId] = car;
        emit CarSold(carId, car.price, buyerAddress);
    }

    function getInventoryCount() public view returns(uint) {
        return inventory.length;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}