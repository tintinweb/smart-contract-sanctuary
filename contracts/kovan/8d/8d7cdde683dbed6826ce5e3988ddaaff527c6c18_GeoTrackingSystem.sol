/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.5.0; 

contract GeoTrackingSystem {
    // Record each user location with timestamp
    struct locationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // User fullnames / nicknames
    mapping (address => string) users;
    
    // Historical locations of all users
    mapping (address => locationStamp[]) public userLocations;
    
    // Register username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    // Getter of usernames
    function getPublicName(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat, uint long) public {
        locationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        // currentLocation.dateTime = block.timestamp;
        currentLocation.dateTime = now;
        
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLastesLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime) {
        
        locationStamp[] storage locations = userLocations[msg.sender];
        locationStamp storage latestLocation = locations[locations.length -1];
        // return {
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.dateTime
        // };
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}