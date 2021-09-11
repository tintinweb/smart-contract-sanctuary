/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;

contract Car {

    string public model;
    address public owner;

    constructor(string memory _model, address _owner) {

        model = _model;
        owner = _owner;

    }

    function get_owner() public view returns (address) {
        return owner;
    }

}


contract contractFactory {

    Car[] public cars;

    function create_car(string memory model, address owner) public {

        Car c = new Car(model, owner);

        cars.push(c);

    }

    function get_car_owner() public view returns (address) {
        return cars[0].get_owner();
    }

}