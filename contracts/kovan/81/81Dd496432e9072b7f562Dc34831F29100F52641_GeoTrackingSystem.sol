/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract GeoTrackingSystem {
    //Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    //User fullnames / nicknames
    mapping(address => string) users;
    
    //Historical locations of all users
    mapping(address => LocationStamp[]) public userLocation;
    
    //Register username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    //Getter of usernames
    function getPublicName(address userAddress) public view returns(string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp;
        userLocation[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress) 
        public view returns(uint256 lat,uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocation[userAddress];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        // return (
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.dateTime
        // );
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}