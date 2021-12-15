/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GeoTracking {
    struct LocationStamp {
        uint dateTime;
        uint lat;
        uint long;
    }

    mapping(address => string) users;

    // Historical location of all users
    mapping(address => LocationStamp[]) public userLocations;


    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    function getPublicName(address userAddress) public view returns(string memory) {
        return users[userAddress];
    }

    function track(uint lat, uint long) public {
        // currentLocation เป็นตัวแปรพักค่าชั่วคราว พักไว้ใน memory
        LocationStamp memory currentLocation;

        currentLocation.dateTime = block.timestamp;
        currentLocation.lat = lat;
        currentLocation.long = long; 
        userLocations[msg.sender].push(currentLocation);
    }

    function getLatestLocation() public view returns(uint lat, uint long, uint dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        return (
            latestLocation.lat,
            latestLocation.long,
            latestLocation.dateTime
        );
    }
}