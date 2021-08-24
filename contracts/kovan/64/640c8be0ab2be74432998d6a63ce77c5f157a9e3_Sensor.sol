/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// contracts/simple_vote.sol
// SPDX-License-Identifier: GPL-3.0

// Todo:
// Maybe store timestamp map value by timestamp or latlon might be more useful.
// Store data size for query.
// Store number of submitters.
pragma solidity ^0.8.0;

contract Sensor{
    // struct
    struct ValueStamp {
        uint256 lat;
        uint256 lon;
        uint256 temperature;
        uint256 humidity;
        uint256 pm2_5;
        uint256 pm10;
        uint256 timestamp;
    }
    // address
    // address can be smart contract address or user address depend on caller.
    mapping (address => string) submitter;

    // historical sensor values from submitters;
    mapping (address => ValueStamp[]) public valueStamps;
    
    // global msg variable:
    // msg is envaroment variable that always exist when call contract.
    // msg.sender is public key of caller.
    // memory type defined variable use for create new temporary variable.

    //store submitter profile
    function register(string memory sumitterName) public {
        submitter[msg.sender] = sumitterName;
    }

    // get submitter profile
    // decoded output	{ "0": "string: sumitterProfile a" } 
    function getSumitterProfile(address sumitterAddress) public view returns (string memory sumitterProfile) {
        //sumitterProfile = submitter[sumitterAddress];
        return submitter[sumitterAddress];
    }
    
    // decoded output	{ "0": "string: sumitterProfile a" } 
    function getSumitterProfile2(address sumitterAddress) public view returns (string memory sumitterProfile) {
        sumitterProfile = submitter[sumitterAddress];
    }
    
    // decoded output	{ "0": "string: a" } 
    function getSumitterProfile3(address sumitterAddress) public view returns (string memory) {
        //sumitterProfile = submitter[sumitterAddress];
        return submitter[sumitterAddress];
    }

    // dataTime in blockchain can get by block.timestamp or now.
    //  block.timestamp and now have same value.
    // array can insert value with .push(value) function.

    // store sensor value
    function storeSensorValue(uint256 lat, uint256 lon, uint256 temperature, uint256 humidity, uint256 pm2_5, uint256 pm10) public{
        ValueStamp memory currentValue;
        currentValue.lat = lat;
        currentValue.lon = lon;
        currentValue.temperature = temperature;
        currentValue.humidity = humidity;
        currentValue.pm2_5 = pm2_5;
        currentValue.pm10 = pm10;
        currentValue.timestamp = block.timestamp; // =now;
        valueStamps[msg.sender].push(currentValue);
    }

    // storage type defined variable use for access stored persistance variable.
    // contract development don't have to concern about transaction concurrency because blockchain miner
    //  manage transaction order at least on etherium(Atomic) so contract level development doesn't 
    //  have to concern about race condition.
    
    // get values by submitter address
    function getLastValues(address submitterAddress)
        public view returns (uint256 lat, uint256 lon, uint256 temperature, uint256 humidity, uint256 pm2_5, uint256 pm10, uint256 timestamp){
        ValueStamp[] storage values = valueStamps[submitterAddress];
        ValueStamp storage value = values[values.length - 1];
        lat = value.lat;
        lon = value.lon;
        temperature = value.temperature;
        humidity = value.humidity;
        pm2_5 = value.pm2_5;
        pm10 = value.pm10;
        timestamp = value.timestamp;
    }
    
    // decoded output	{ "error": "Failed to decode output: Error: data out-of-bounds (length=36, offset=64, code=BUFFER_OVERRUN, version=abi/5.4.0)" } 
    /*
    function getLastValues(address submitterAddress)
        public view returns (ValueStamp memory valueStamp){
        ValueStamp[] storage values = valueStamps[submitterAddress];
		// return values[values.length - 1];
        // same as
        valueStamp = values[values.length - 1];
    }
    //*/
}