/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

/*
Tracking any sensors data on Ethereum

Blockchain can not detect whether the data is correct or incorrect
*/

pragma solidity ^0.6.0;

contract GeoTrackingSystem {
    /* 
    Store lat, long, timestamp
    */
    // Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    // mapping username and value
    // User fullnames / nicknames
    mapping (address => string) users;
    
    // store LocationStamp of address
    // Historical locations of all users
    mapping (address => LocationStamp[]) public userLocations;
    
    // Register Message(username)
    // cannot disguise to publickey if you don't have privatekey
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    // Getter of usernames
    function getPublicName(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now; //block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    
    // get latest location
    function getLatestLocation(address userAddress) 
        public view returns (uint256 lat, uint256 long, uint256 dateTime) {
        
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length -1];
//        return (
//            latestLocation.lat,
//            latestLocation.long,
//            latestLocation.dateTime
//        );
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}