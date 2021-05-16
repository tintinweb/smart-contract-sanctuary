/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.5.0;

contract geotrackingsystem {
    
    //record each user location with timestamp
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    //
    // User fullname/nickname
    mapping (address=>string) users;
    // Location
    mapping (address=>LocationStamp[]) public userLocations;
    // for counting number of add location
    uint256 countlocation;
    
    // Register users
    function register(string memory username) public {
        // msg.sender is a address of user who call smart contract
        users[msg.sender] = username;
    }
    
    // Getter of usernames
    function getPublicname(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }
    
    function track(uint256 lat,uint256 long) public {
        LocationStamp memory currentlocation;
        currentlocation.lat = lat;
        currentlocation.long = long;
        // block.timestamp or now is a timestamp when create the blockchain
        currentlocation.dateTime = block.timestamp;
        // Add location to userLocations mapping with the wallet user address
        userLocations[msg.sender].push(currentlocation);
        countlocation +=1;
    }
    
    function getLatestLocation(address userAddress) public view returns (uint256 lat,uint256 long, uint256 dateTime) {
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestlocation = locations[locations.length - 1];
        //return (
        //    latestlocation.lat,
        //    latestlocation.long,
        //    latestlocation.dateTime
        //    );
        lat = latestlocation.lat;
        long = latestlocation.long;
        latestlocation.dateTime;
    }
}