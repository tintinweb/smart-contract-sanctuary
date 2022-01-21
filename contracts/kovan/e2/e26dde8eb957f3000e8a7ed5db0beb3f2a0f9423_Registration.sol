/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Registration Smart contract
contract Registration {
    
    //Variables
    address public Regulator; //Ethereum address of the regulator
    mapping(address => bool) public manufacturer; //a mapping that lists all authorized manufacturers
    mapping(address => bool) public distributor; //a mapping that lists all authorized distributors
    mapping(address => bool)  public healthcarecenter; //a mapping for all authorized healthcare centers
    
    //Registration Events
    event RegistrationSCDeployer(address indexed Regulator); //An event to show the address of the registration SC deployer
    event ManufacturerRegistered(address indexed Regulator, address indexed manufacturer);
    event DistributorRegistered(address indexed Regulator, address indexed distributor);
    event HealthCareCenterRegistered(address indexed Regulator, address indexed healthcarecenter);

    //Modifiers
    modifier onlyRegulator() {
        require(Regulator == msg.sender, "Only the Regulator is eligible to run this function");
        _;
    }
    
    //Creating the contract constructor

    constructor() {
        Regulator = msg.sender; //The regulator is the deployer of the registration SC
        emit RegistrationSCDeployer(Regulator);

    }
    
    //Registration Functions

    function manufacturerRegistration (address user) public onlyRegulator {
        require(manufacturer[user] == false, "The user is already registered");
        manufacturer[user] = true;
        emit ManufacturerRegistered(msg.sender, user);

    }
    
    function distributorRegistration (address user) public onlyRegulator {
        require(distributor[user] == false, "The user is already registered");
        distributor[user] = true;
        emit DistributorRegistered(msg.sender, user);
    }

    function healthcarecenterRegistration (address user) public onlyRegulator{
        require(healthcarecenter[user] == false, "The user is already registered");
        healthcarecenter[user] = true;
        emit HealthCareCenterRegistered(msg.sender, user);
    }    
}