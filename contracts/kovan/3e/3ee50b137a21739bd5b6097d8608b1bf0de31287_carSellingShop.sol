/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract carSellingShop {

    struct Car {
        address thisCarAddress;
        uint256 price;
    }
    
    address public gov;

    Car[] public cars;

    event Added(address car, uint256 price, uint256 timestamp);
    event Saled(address car, uint256 price, uint256 timestamp, address buyer);
    
    modifier onlyGovernance() {
        require(msg.sender == gov, "!governance");
        _;
    }
    
    constructor () {
        gov = msg.sender;
    }

    function addCar(address newCarAddress, uint256 newCarPrice) external onlyGovernance {
        
        uint256 current_timestamp = block.timestamp;
        uint256 numberOfcars = cars.length;
        uint256 i;
        
        // check if newCarAddress is valid
        while (i < numberOfcars) {
            if (cars[i].thisCarAddress == newCarAddress) {
                break;
            }
            else {
                i++;
            }
        }
        require(i == numberOfcars, "This car's address is already exist.");
        
        Car memory new_car;
        new_car = Car(newCarAddress, newCarPrice);
        cars.push(new_car);
        emit Added(new_car.thisCarAddress, new_car.price, current_timestamp);
    }

    function saleCar(address car_address) external {
        uint256 numberOfcars = cars.length;
        require(numberOfcars > 0, "Currently, There is not any car.");
        uint256 i;
        while (i < numberOfcars) {
            if (cars[i].thisCarAddress == car_address) {
                for (i; i < numberOfcars - 1; i++) {
                    cars[i] = cars[i+1];
                }
                cars.pop();
                break;
            }
            else {
                i++;
            }
        }
        require(i < numberOfcars, "The car is not exist");
        uint256 current_timestamp = block.timestamp;
        emit Saled(cars[i].thisCarAddress, cars[i].price, current_timestamp, msg.sender);
    }
    
    function viewCars() public view returns (Car[] memory) {
        return cars;
    }
}