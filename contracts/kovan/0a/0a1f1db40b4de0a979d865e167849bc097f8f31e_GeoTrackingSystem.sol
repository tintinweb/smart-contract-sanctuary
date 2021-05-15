/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    
    // Record each user with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 lon;
        uint256 dateTime;
    }
    
    // User fullname / nickname
    mapping (address => string) users;
    
    // Historical location of users
    mapping (address => LocationStamp[]) public userLocations;
    
    // Register username
    function register (string memory userName) public {
        users[msg.sender] = userName;
    }
    
    // Getter of username
    function getPublicName (address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    // Tracking
    function track (uint256 lat, uint256 lon) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.lon = lon;
        currentLocation.dateTime = block.timestamp; // now;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation () public view returns (uint256 lat, uint256 lon, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        
        // return (
        //     latestLocation.lat,
        //     latestLocation.lon,
        //     latestLocation.dateTime
        // );
        
        lat = latestLocation.lat;
        lon = latestLocation.lon;
        dateTime = latestLocation.dateTime;
    }
    
    
}