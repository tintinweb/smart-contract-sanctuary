/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.5.16;

contract GeoTrackingSystem {
    //record user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    //User FullName / NickName
    mapping (address => string) users;
    
    //Historical location user 
    mapping (address => LocationStamp[]) public userLocations;
    
    //Register Username
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    //Getter of userName
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; //now;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime){
        
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latesLocation = locations[locations.length - 1];
        /*return(
            latesLocation.lat,
            latesLocation.long,
            latesLocation.dateTime
            );*/
        lat =latesLocation.lat;
        long = latesLocation.long;
        dateTime = latesLocation.dateTime;
    }
 }