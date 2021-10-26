/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    // record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // user fullname or nickname
    mapping(address => string) users;
    
    // historical location of all users
    mapping(address => LocationStamp[]) public userLocations;
    
    // register user
    function register(string memory username) public {
        users[msg.sender] = username;
    }
    
    // getter of username
    function getPublicName(address userAddress) public view returns(string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currectLocation;
        currectLocation.lat = lat;
        currectLocation.long = long;
        currectLocation.dateTime = now; // block.timestamp;
        
        userLocations[msg.sender].push(currectLocation);
    }
    
    function getLatestLocation(address userAddress) public view returns(uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[userAddress];
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