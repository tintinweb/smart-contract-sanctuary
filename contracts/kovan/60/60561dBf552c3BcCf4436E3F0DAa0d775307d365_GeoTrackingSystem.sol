/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.6.0;

contract GeoTrackingSystem {
    // Record each user location with timetamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }

    // User fullnames / nicknames
    mapping (address => string) users;

    // Historical of all user locations
    mapping (address => LocationStamp[]) public userLocations;

    // Register uesrname
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    // Getter of usernames
    function getPublicName(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }

    // Track realtime user location
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; // Now
        userLocations[msg.sender].push(currentLocation);
    }

    // Get user latest location
    function getLatestLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[userAddress];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}