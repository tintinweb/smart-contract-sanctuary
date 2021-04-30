/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity ^0.8.0;

contract GeoTrackingSystem{
    
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    mapping(address => string) users;
    
    mapping(address => LocationStamp[]) public userLocation;
    
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }     
    
    function track(uint256 lat,uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; //now
        userLocation[msg.sender].push(currentLocation);
        
    }
    
    function getLatestLocation(address userAddress) public view returns (uint256 lat,uint256 long,uint256 dateTime){
        LocationStamp[] storage location = userLocation[msg.sender];
        LocationStamp storage lastestLocation = location[location.length -1];
        return (lastestLocation.lat,
                lastestLocation.long,
                lastestLocation.dateTime
                );
    }
    
}