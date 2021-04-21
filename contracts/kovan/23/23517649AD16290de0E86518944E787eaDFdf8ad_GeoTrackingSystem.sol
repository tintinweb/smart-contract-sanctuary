/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract GeoTrackingSystem {
    
    struct LocationStamp {
        uint256 latitude;
        uint256 longitude;
        uint256 dateTime;
    }
    
    mapping (address => string) users;
    mapping (address => LocationStamp[]) public userLocations;
    
    function register (string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddress) public view returns(string memory) {
        return users[userAddress];
    }
    
    function track(uint256 currentLatitude, uint256 currentLongitude) public {
        LocationStamp memory currentLocation;
        currentLocation.latitude = currentLatitude;
        currentLocation.longitude = currentLongitude;
        currentLocation.dateTime = now; // block.timestamp
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation () public view returns (uint256 lat, uint256 long, uint256 timestamp) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp memory location = locations[locations.length - 1];
        
        // return
        lat = location.latitude;
        long = location.longitude;
        timestamp = location.dateTime;
        
        // return (location.latitude, location.longitude, location.dateTime);
    }
    
    function getLatestLocation2 () public view returns (LocationStamp memory location) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp memory location = locations[locations.length - 1];
        return location;
    }
}