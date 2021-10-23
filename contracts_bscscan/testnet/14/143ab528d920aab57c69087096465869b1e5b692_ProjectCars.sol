pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ProjectCars is Ownable {
    event NewManufacturer(uint256 manufacturerId, string name, string country);
    event NewCar(uint256 id, uint256 manufacturerId, string name);

    struct Manufacturer {
        string name;
        string country;
        bool isActive;
    }

    struct Car {
        uint256 manufacturerId;
        string name;
        bool isActive;
    }

    mapping(uint256 => Manufacturer) public manufacturers;
    mapping(uint256 => Car) public cars;

    constructor() {
        _createManufacturer(1, "BMW", "Germany");
        _createManufacturer(2, "Ford", "USA");
        _createManufacturer(3, "Nissan", "Japan");

        _createCar(1, 1, "X5");
        _createCar(2, 2, "Edge");
        _createCar(3, 3, "Qashqai");
    }

    function _createManufacturer(
        uint256 _id,
        string memory _name,
        string memory _country
    ) private {
        manufacturers[_id] = Manufacturer(_name, _country, true);
        emit NewManufacturer(_id, _name, _country);
    }

    function _createCar(
        uint256 _id,
        uint256 _manufacturerId,
        string memory _name
    ) private {
        cars[_id] = Car(_manufacturerId, _name, true);
        emit NewCar(_id, _manufacturerId, _name);
    }

    function addManufacturer(
        uint256 _id,
        string memory _name,
        string memory _country
    ) public onlyOwner returns (bool success) {
        require(
            manufacturers[_id].isActive == false,
            "Manufacturer already exist!"
        );
        _createManufacturer(_id, _name, _country);
        return true;
    }

    function addCar(
        uint256 _id,
        uint256 _manufacturerId,
        string memory _name
    ) public onlyOwner returns (bool success) {
        require(cars[_id].isActive == false, "Car already exist!");
        require(
            manufacturers[_manufacturerId].isActive == true,
            "Manufacturer does not exist!"
        );
        _createCar(_id, _manufacturerId, _name);
        return true;
    }
}