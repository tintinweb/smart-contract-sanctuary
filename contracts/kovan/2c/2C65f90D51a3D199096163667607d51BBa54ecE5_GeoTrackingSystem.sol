/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.8.0;

contract GeoTrackingSystem {
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    mapping (address => LocationStamp[]) public userLocations;
    
    mapping (address => string) users;

    function register (string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName (address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress) public
        view returns (uint256 lat, uint256 long, uint256 dateTime)
    {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        
        // same name variable in function signature will as return value
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}