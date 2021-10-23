pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ProjectCars is Ownable {
    event NewManufacturer(uint256 manufacturerId, string name, string country);
    event NewCar(uint256 id, uint256 manufacturerId, string name);

    struct Manufacturer {
        string name;
        string country;
    }

    struct Car {
        uint256 manufacturerId;
        string name;
    }

    mapping(uint256 => Manufacturer) manufacturers;
    mapping(uint256 => Car) cars;

    function addManufacturer(
        uint256 _id,
        string memory _name,
        string memory _country
    ) public onlyOwner returns (bool success) {
        manufacturers[_id] = Manufacturer(_name, _country);
        emit NewManufacturer(_id, _name, _country);
        return true;
    }

    function addCar(
        uint256 _id,
        uint256 _manufacturerId,
        string memory _name
    ) public onlyOwner returns (bool success) {
        cars[_id] = Car(_manufacturerId, _name);
        emit NewCar(_id, _manufacturerId, _name);
        return true;
    }
}