pragma solidity ^0.4.19;

contract owned {
    address public owner;
    address public candidate;

    function owned() payable public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }
    
    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

contract CryptaurMigrations is owned
{
    address backend;
    modifier backendOrOwner {
        require(backend == msg.sender || msg.sender == owner);
        _;
    }

    mapping(bytes => address) addressByServices;
    mapping(address => bytes) servicesbyAddress;

    event AddService(uint dateTime, bytes serviceName, address serviceAddress);

    function CryptaurMigrations() public owned() { }
    
    function setBackend(address _backend) onlyOwner public {
        backend = _backend;
    }
    
    function setService(bytes serviceName, address serviceAddress) public backendOrOwner
    {
		addressByServices[serviceName] = serviceAddress;
		servicesbyAddress[serviceAddress] = serviceName;
		AddService(now, serviceName, serviceAddress);
    }
    
    function getServiceAddress(bytes serviceName) public view returns(address)
    {
		return addressByServices[serviceName];
    }

    function getServiceName(address serviceAddress) public view returns(bytes)
    {
		return servicesbyAddress[serviceAddress];
    }
}