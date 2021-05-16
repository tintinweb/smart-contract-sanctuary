/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    //Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 datetime;
    }
        
        //user fullnames / nicknames
        mapping (address =>string) users;
        // Historical Location of all users
        mapping (address => LocationStamp[]) public userLocations;
        
    
        // Register username
        function register(string memory userName)public{
            users[msg.sender] = userName;
        }
        
        function getPublicName(address userAddress) public view returns (string memory){
            return users[userAddress];
        }
        function track (uint256 lat,uint256 long) public  {
            LocationStamp memory currentLocation;
            currentLocation.lat = lat;
            currentLocation.long = long;
            currentLocation.datetime = now;
            userLocations[msg.sender].push(currentLocation);
            
        }
        function getLatestLocation(address userAddress) 
            public view returns(uint256 lat,uint256 long, uint256 datetime){
                
                LocationStamp[] storage locations = userLocations[msg.sender];
                LocationStamp storage latestLocation = locations[locations.length - 1];
                
                lat = latestLocation.lat;
                long = latestLocation.long;
                datetime = latestLocation.datetime;
                
            }
}