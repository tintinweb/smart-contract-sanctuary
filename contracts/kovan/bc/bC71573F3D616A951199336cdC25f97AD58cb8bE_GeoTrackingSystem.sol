/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.8.0;
contract GeoTrackingSystem {
    struct LocationStamp {
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    mapping (address => LocationStamp[]) public userLocations;
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory location;
        location.lat = lat;
        location.long = long;
        location.dateTime = block.timestamp;
        userLocations[msg.sender].push(location);
    }
    
    function getLatestLocation(address userAddress)
    public view returns (LocationStamp memory location) 
    {
        uint256 length = userLocations[userAddress].length;
        return userLocations[userAddress][length - 1];
    }
}