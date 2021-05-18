/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{
    
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    mapping (address => string) users;
    mapping (address => LocationStamp[]) public userLocations;
    
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLastestLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage lastLocation = locations[locations.length - 1];
        
        lat = lastLocation.lat;
        long = lastLocation.long;
        dateTime = lastLocation.dateTime;
    }
}