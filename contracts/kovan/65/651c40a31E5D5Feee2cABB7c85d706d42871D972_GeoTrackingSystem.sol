/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity 0.8.1;

contract GeoTrackingSystem {
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    mapping(address => string) users;
    
    mapping(address => LocationStamp[]) public userLocations;
    
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName() public view returns (string memory userName) {
        userName = users[msg.sender];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getUserLatestLocation() public view returns (uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}