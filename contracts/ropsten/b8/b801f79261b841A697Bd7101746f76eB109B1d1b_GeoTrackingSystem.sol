/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    // Record each user timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // User fullname or nickname
    
    mapping (address => string ) users; 
    // Histotical location of user
    mapping (address => LocationStamp[]) public userLocations;
    
    // register username into system
    function register(string memory userName) public{
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddess) public view returns(string memory) {
        return users[userAddess];
    }
    
    function track(uint256 lat, uint256 long) public{
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime =  now;  ///block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddess) public view returns (uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latesLocation = locations[locations.length - 1 ];
        //return (
        //    latesLocation.lat,
        //    latesLocation.long,
        //    latesLocation.dateTime
        //    );
        lat = latesLocation.lat;
        long = latesLocation.long;
        dateTime = latesLocation.dateTime;
    }
}