/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity ^0.5.0;
 
contract GeoTrakingSystem{
    
    //Record each user loacation with timestamp 
    struct LocationStamp{
        uint256 lat; 
        uint256 long;
        uint256 dateTime;
    }
    
    // User fullnames / nicknames
    mapping (address => string) users ;
    
    //Historical location of all users 
    mapping (address => LocationStamp[]) public userLocations; 
    
    //Register usernames 
    function register(string memory userName) public{
        users[msg.sender] = userName ; 
    }
    //Getter of usernames 
    function getPublicName(address userAddress) 
    public view returns (string memory){
        return users[userAddress]; 
    } 
    
    function track(uint256 lat, uint256 long) public{
        LocationStamp memory currentLocation; 
        currentLocation.lat = lat; 
        currentLocation.long = long ; 
        currentLocation.dateTime = now; //หรือ block.timestamp
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress) 
        public view returns (uint256 lat, uint256 long, uint256 dateTime){
            LocationStamp[] storage locations= userLocations[msg.sender]; 
            LocationStamp storage latestLocation = locations[locations.length-1]; 
            
            /*return (latestLocation.lat ,
                    latestLocation.long,
                    latestLocation.dateTime);*/
                    
            lat = latestLocation.lat; 
            long = latestLocation.long; 
            dateTime = latestLocation.dateTime;
    }
    
    
}