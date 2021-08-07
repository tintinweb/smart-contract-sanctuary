/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract GeoTrackingSystem {
    //Record eash user locaiton with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // User fulllnames / nicknames
    mapping (address => string) users;
    mapping (address => LocationStamp[]) public userLocations;
    
    // Register username
    function register(string memory userName) public {
        //sender is caller 
        users[msg.sender] = userName;
    }
    
    function getPublickName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp;
        userLocations[msg.sender].push(currentLocation);
        
    }
    
    function getLatestLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime) {
        
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        
        return(
                latestLocation.lat,
                latestLocation.long,
                latestLocation.dateTime
            );
    }
    
}