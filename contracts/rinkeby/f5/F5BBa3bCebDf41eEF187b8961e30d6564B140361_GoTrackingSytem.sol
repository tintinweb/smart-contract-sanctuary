/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.5.1;

contract GoTrackingSytem {
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    mapping (address => string) users;
    
    mapping (address => LocationStamp[]) public userLocation;
    
    function register(string memory UserName) public{
        users[msg.sender] = UserName;
    }
    
    function getPublicName(address userAdress) public view returns (string memory){
        return users[userAdress];
    }
    
    function track(uint256 lat,uint256 long) public{
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now;
        userLocation[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAdress) public view returns (uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocation[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}