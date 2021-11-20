/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    
    // Record each user location with timestmp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // User fullname / nickname
    mapping (address => string) users;
    
    // Historical locations of users
    mapping (address => LocationStamp[]) public userLocations;
    
    // Register
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    // Getter of username
    function getPublicName (address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track (uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        
        currentLocation.lat = lat;
        currentLocation.long = long;
        //currentLocation.dateTime = block.timestmp;
        currentLocation.dateTime = now;
        
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation (address userAddress) 
        public view returns (uint256 lat, uint256 long, uint256 dateTime){
        
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage lastestLocation = locations[locations.length - 1];
        // return (
        //    lastestLocation.lat,
        //    lastestLocation.long,
        //    lastestLocation.dateTime
        // );
        lat = lastestLocation.lat;
        long = lastestLocation.long;
        dateTime = lastestLocation.dateTime;
    }
    
}