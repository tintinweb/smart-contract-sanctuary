/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    mapping(address => LocationStamp[]) public userLocations ;
    mapping(address => string) users;
    
    
    function register(string memory userName) public{
        users[msg.sender] = userName;
        
    }
    
    function getPublicName(address userAddress) public view returns(string memory){
        
        return users[userAddress];
    }
    
    function track( uint256 lat, uint256 long) public {
      LocationStamp memory currentLocation;
      currentLocation.lat = lat ;
      currentLocation.long = long;
      currentLocation.dateTime = now;// block.timestamp;
      userLocations[msg.sender].push(currentLocation);
        
    }
    
    function getLatestLocation(address userAddress) public view returns(uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage location = userLocations[msg.sender];
        LocationStamp storage LatestLocation = location[location.length -  1];
        
        // return(
        //     LatestLocation.lat,
        //     LatestLocation.long,
        //     LatestLocation.dateTime
        //     );
        lat = LatestLocation.lat;
        long =    LatestLocation.long;
        dateTime =    LatestLocation.dateTime;
        
    }
}