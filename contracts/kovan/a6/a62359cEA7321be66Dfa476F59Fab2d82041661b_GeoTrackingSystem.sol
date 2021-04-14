/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{
    // Record a user loacation with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    // Reporter name
    mapping(address=>string) users;
    
    // Historical location of all users
    mapping(address=>LocationStamp[]) public userLocations;
    
    // Register
    function register(string memory userName)public{
        users[msg.sender] = userName;
    }
    
    // Get user's name
    function getPublicName(address userAddress) 
    public view returns(string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat,uint256 long)public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; //now;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress)
    public view returns(uint256 lat,uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length-1];
        // return(
        //     latestLocation.lat,
        //     latestLocation.long,
        //     latestLocation.dateTime;
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}