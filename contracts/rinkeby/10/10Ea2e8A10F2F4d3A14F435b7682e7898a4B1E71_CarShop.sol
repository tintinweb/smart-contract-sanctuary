//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Contract for a fictitious car selling shop
contract CarShop {

    /// @notice Car entity definition
    struct Car {
        uint price;
        address buyerAddress;
    }

    /// @notice Sale record event definition
    event CarSold (
        uint indexed carId,
        uint price,
        address indexed buyerAddress
    );

    /// @notice Inventory
    Car[] public inventory;

    /// @notice Adds a new car to the inventory
    /// @dev The buyerAddress is set to address 0, which means no one has bought the car
    /// @param price The price of the car
    function addCarToInventory(uint price) external {
        Car memory car = Car({price: price, buyerAddress: address(0)});
        inventory.push(car);
    }

    /// @notice Record car sales record with the car identity
    /// @dev The car identifiers map to the positions in the array
    /// @param carId The identifier of the car
    /// @param buyerAddress The address of the person who bought the car
    function recordSale(uint carId, address buyerAddress) external {
        require(carId < inventory.length, "car identity does not exist");
        Car storage car = inventory[carId];
        car.buyerAddress = buyerAddress;
        inventory[carId] = car;
        emit CarSold(carId, car.price, buyerAddress);
    }

    /// @notice Returns the amount of cars in the inventory
    /// @dev Returns the length of the inventory array
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