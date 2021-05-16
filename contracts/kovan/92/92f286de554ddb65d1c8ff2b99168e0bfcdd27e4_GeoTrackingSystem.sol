/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    
    //record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // user fullname , nickname
    mapping(address =>string) users;
    
    // Historical location of users
    mapping(address =>LocationStamp[]) public userLocations;
    
    function register(string memory userName) public {
        users[msg.sender]= userName;
    }
    function getPublicName(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat,uint256 long) public {
        LocationStamp memory c;
        c.lat = lat;
        c.long = long;
        c.dateTime = now;
        userLocations[msg.sender].push(c);
    }
    function getlastestLocation (address userAddress) public view returns (uint256 lat, uint256 long , uint256 dateTime) {
        LocationStamp[] storage location = userLocations[msg.sender];
        LocationStamp storage lastestLocation = location[location.length-1];
        lat = lastestLocation.lat;
        long = lastestLocation.long;
        dateTime =  lastestLocation.dateTime;
    }
}