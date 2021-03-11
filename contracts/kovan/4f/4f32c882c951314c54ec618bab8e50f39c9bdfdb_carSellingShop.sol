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

    event Added(address car, uint256 price);
    event Saled(address car, uint256 price);
    
    modifier onlyGovernance() {
        require(msg.sender == gov, "!governance");
        _;
    }
    
    constructor () {
        gov = msg.sender;
    }

    function addCar(Car memory new_car) external onlyGovernance {
        cars.push(new_car);
        emit Added(new_car.thisCarAddress, new_car.price);
    }

    function saleCar(address car_address) external {
        uint256 numberOfcars = cars.length;
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
        emit Saled(cars[i].thisCarAddress, cars[i].price);
    }
}