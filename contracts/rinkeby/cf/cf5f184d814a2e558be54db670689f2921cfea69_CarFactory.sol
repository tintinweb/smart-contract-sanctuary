/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Car {
    address public owner;
    string public model;

    constructor(address _owner, string memory _model) payable {
        owner = _owner;
        model = _model;
    }
}

contract CarFactory {
    
    Car[] public cars;

    function create(address _owner, string memory _model) public {
        Car car = new Car(_owner, _model);
        cars.push(car);
    }

    function createAndSendEther(address _owner, string memory _model) public payable {
        Car car = (new Car){value: msg.value}(_owner, _model);
        cars.push(car);
    }

    function getCar(uint _index) public view returns (address owner, string memory model, uint balance) {
        Car car = cars[_index];
        return (car.owner(), car.model(), address(car).balance);
    }
}