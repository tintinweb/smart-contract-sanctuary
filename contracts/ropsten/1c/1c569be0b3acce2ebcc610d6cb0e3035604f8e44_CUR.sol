pragma solidity ^0.4.24;

contract CUR {
    struct Manufacturer {
        string name;
        string logo;
        bool exists;
    }

    struct Car {
        string model;
        bytes17 VIN;
        uint dateCreated;
        uint warrantyUntil;
        address manufacturerAddress;
        bool exists;
    }

    struct Service {
        string name;
        string serviceAddress;
        bool exists;
        mapping(address => bool) authorizedManufacturers;
    }

    address private owner;
    mapping(address => Manufacturer) manufacturers;
    mapping(address => Service) services;
    mapping(bytes17 => Car) cars;

    constructor() public {
        owner = msg.sender;
    }

    event carCreated(string model, bytes17 indexed VIN, address indexed manufaturerAddress, uint dateCreated, uint warrantyUntil);
    event carRepaired(bytes17 indexed VIN, address indexed repairService, bool authorised, string documentLink, uint date,
        string details, uint mileage);
    event manufacturerCreated(address indexed _address, string name, string logo);
    event serviceCreated(address _address, string name, string serviceLocation);
    event serviceAuthorized(address indexed serviceAddress, address indexed manufaturerAddress);
    event warrantyCanceled(bytes17 indexed VIN);

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isManufacturer() {
        require(manufacturers[msg.sender].exists);
        _;
    }

    modifier isService() {
        require(services[msg.sender].exists);
        _;
    }

    function isContractOwner() view public returns (bool) {
        return msg.sender == owner;
    }

    function isManufacturerAddress() view public returns (bool) {
        return manufacturers[msg.sender].exists;
    }

    function isServiceAddress() view public returns (bool) {
        return services[msg.sender].exists;
    }

    function createManufacturer(address _address, string _name, string _logo) isOwner public {
        require(manufacturers[_address].exists == false);
        manufacturers[_address] = Manufacturer({name : _name, exists : true, logo : _logo});
        emit manufacturerCreated(_address, _name, _logo);
    }

    function newCar(string _model, bytes17 _VIN) public isManufacturer {
        require(cars[_VIN].exists == false);
        cars[_VIN] = Car({
            model : _model,
            VIN : _VIN,
            manufacturerAddress : msg.sender,
            exists : true,
            dateCreated : now,
            warrantyUntil : now + 365 days
            });
        emit carCreated(_model, _VIN, msg.sender, now, now + 365 days);
    }

    function newService(string _name, string _serviceAddress) public {
        require(services[msg.sender].exists == false);
        services[msg.sender] = Service({name : _name, exists : true, serviceAddress : _serviceAddress});
        if(manufacturers[msg.sender].exists) {
            services[msg.sender].authorizedManufacturers[msg.sender] = true;
            emit serviceAuthorized(msg.sender, msg.sender);
        }
        emit serviceCreated(msg.sender, _name, _serviceAddress);
    }

    function verifyService(address _serviceAddress) public isManufacturer {
        services[_serviceAddress].authorizedManufacturers[msg.sender] = true;
        emit serviceAuthorized(_serviceAddress, msg.sender);
    }

    function repairCar(bytes17 _carVIN, string documentLink, string _details, uint mileage) isService public {
        address carManufacturer = cars[_carVIN].manufacturerAddress;
        bool isAuthorizedService = services[msg.sender].authorizedManufacturers[carManufacturer];
        if (!isAuthorizedService && cars[_carVIN].warrantyUntil > block.timestamp) {
            emit warrantyCanceled(_carVIN);
        }
        emit carRepaired(_carVIN, msg.sender, isAuthorizedService, documentLink, block.timestamp,
            _details, mileage);
    }
}