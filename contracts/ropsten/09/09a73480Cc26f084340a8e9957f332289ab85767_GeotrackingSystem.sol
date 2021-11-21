/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GeotrackingSystem {
    // records
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // user fullnames / nicname
    mapping (address => string) users;
    
    // history location user
    mapping (address => LocationStamp[]) public userLocations;
    
    // register username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }
    
    function tract(uint256 lat,uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; // now
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLastLocation(address userAddress) public view returns (uint256 lat,uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage lastLocation = locations[locations.length -1];
        // return (
        //     lastLocation.lat,
        //     lastLocation.long,
        //     lastLocation.dateTime,
        //     );
        lat = lastLocation.lat;
        long = lastLocation.long;
        dateTime = lastLocation.dateTime;
    }
}