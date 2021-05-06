/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;

contract GeoTrackingSystem {
    // Record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 lng;
        uint256 dateTime;
    }
    
    // User fullname 
    mapping (address => string) users;
    mapping (address => LocationStamp[]) public userLocations;
    
    function register(string memory userName) public{
        users[msg.sender] = userName;
    }
    // Getter of userName
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 lng) public{
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.lng = lng;
        currentLocation.dateTime = block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    function getLatestLocation(address userAddress)
        public view returns(uint256 lat, uint256 lng, uint256  dateTime){
            LocationStamp[] storage locations = userLocations[msg.sender];
            LocationStamp storage latestLocation = locations[locations.length- 1];
            // return (
            //     latestLocation.lat,
            //     latestLocation.lng,
            //     latestLocation.dateTime
            //     );
            lat=latestLocation.lat;
            lng=latestLocation.lng;
            dateTime=latestLocation.dateTime;
        
    }
}