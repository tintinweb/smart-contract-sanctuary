/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    // record each user's location
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    struct user {
        string name;
        uint256 num;
    }
    
    // user's fullname/ nicknames
    mapping (address => user) users;
    
    // historical location of all users
    mapping (address => LocationStamp[]) public userLocations;
    
    // register username to the system
    function register(string memory userName, uint256 userNum) public {
        users[msg.sender].name = userName;
        users[msg.sender].num = userNum;
    }
    
    // get username
    function getPublicName(address userAddress) public view returns(string memory, uint256) {
        return (users[userAddress].name, users[userAddress].num);
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now; //block.timestamp
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation() public view returns(uint256 lat, uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length-1];
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;

    }
    
}