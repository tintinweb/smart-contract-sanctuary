/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract GeoTrackingSystem {
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 datetime;
    }
    
    mapping(address => string) users;
    
    mapping(address => LocationStamp[]) public userLocations;
    
    
    function register(string memory _userName) public {
        users[msg.sender] = _userName;
    }
    
    function getPublicName(address _userAddress) public view returns(string memory) {
        return users[_userAddress];
    }
    
    function track(uint256 _lat, uint256 _long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = _lat;
        currentLocation.long = _long;
        currentLocation.datetime = now; //block.timestamp
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address _userAddress) public view returns(uint256 lat, uint256 long, uint256 dateTime) {
        
        LocationStamp[] storage loacations = userLocations[msg.sender];
        LocationStamp   storage latestLocation = loacations[loacations.length -1];
        
        // return (
        //     latestLocation.lat, 
        //     latestLocation.long, 
        //     latestLocation.datetime
        // )
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.datetime;
        
    }
}