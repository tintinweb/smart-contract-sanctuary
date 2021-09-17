/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

contract Vault {
    
    /********* STATE VARIABLES *********/
    
    /**
    The admin and the factory addresses are stored in admin and factory respectively
    **/
    address admin;
    address factory;
    uint sensor_count;
    
    /********* CONSTRUCTOR *********/
    
    /**
    Constructor to assign the admin address
    **/
    constructor() {
        admin = msg.sender;
        sensor_count = 0;
    }
    
    
    /********* MODIFIERS *********/
    
    /**
    Only the admin is given the access
    **/
    modifier onlyAdmin(){
        require(msg.sender == admin,"only Admin has the access");
        _;
    }
    
    /**
    Only the factory contract is given the access
    **/
    modifier onlyFactory(){
        require(msg.sender == factory,"only Factory Contract has the access");
        _;
    }


    /********* MAPPING *********/
    
    /**
    IP address of a sensor is recorded corresponding to its address
    **/
    mapping( address => bytes32 ) SensorDetails;
    mapping( uint => address) SensorCount;
    
    /********* FUNCTIONS *********/
    
    /**
    Set the factory address by the admin
    **/
    
    function setFactory(address _factory) public onlyAdmin{
        factory = _factory;
    }
    
    /**
    Write the IP address into the mapping
    **/
    
    function writeSensorDetails(address _sensor, bytes32 _details) external onlyFactory{
        SensorCount[sensor_count] = _sensor;
        sensor_count++;
        SensorDetails[_sensor] = _details;
    }
    
    /**
    change ip address of a sensor
    **/
    function changeIpAddress(address _sensor, bytes32 _details) external onlyFactory{
        SensorDetails[_sensor] = _details;
    }


    /**
    Read the data
    **/
    
    function readSensorDetails(address _sensor) public view onlyFactory returns (bytes32 ipAddress) {
        return SensorDetails[_sensor];
    }

    /**
    Read the sensor count
    **/

    function readSensorCount() public view returns (uint _count) {
        return sensor_count;
    }
}