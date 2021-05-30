/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    // Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 datetime;
    }
    
    // User fullnames / nicknames
    mapping (address => string) users;
    
    // Historical location of all users
    mapping (address => LocationStamp[]) public userLocations;
    
    // Register username
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
        currentLocation.datetime = now; // block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLastestLocation(address userAddress) 
        public view returns (uint256 lat, uint256 long, uint256 datetime) {
        
        // LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp[] storage locations = userLocations[userAddress];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        // return (
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.datetime
        // );
        lat = latestLocation.lat;
        long = latestLocation.long;
        datetime = latestLocation.datetime;
    }
}