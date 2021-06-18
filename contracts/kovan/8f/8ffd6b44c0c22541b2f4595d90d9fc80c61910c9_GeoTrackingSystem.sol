/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem{
    //Record each user location with timestamp
    struct LocationStamp{
        uint256 lat; uint256 long;uint256 dateTime;
        
    }
    
    //user fi=ullname/nickname
    mapping ( address => string) users;
    mapping (address => LocationStamp[]) public userLocations;
    
    function regiter(string memory userName) public{
        //msg.sender == address of the sender 
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddress) public view  returns(string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long)public {
        LocationStamp memory currentLocation;
        currentLocation.lat  = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now;// or block.timestamp;
        userLocations[msg.sender].push(currentLocation);
    }
    function getLatestLocation(address userAddress) 
        public view returns(uint256 lat, uint256 long, uint256 dateTime){
            LocationStamp[] storage locations = userLocations[msg.sender];
            LocationStamp storage latestLocation = locations[locations.length -1];
            // return (
            //     latestLocation.lat,
            //     latestLocation.long,
            //     latestLocation.dateTime 
            // );
            //or
            lat = latestLocation.lat;
            long  = latestLocation.long;
            dateTime = latestLocation.dateTime;
    }
}