/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity ^0.5.0;

contract GeoTracking {
    struct Location {
         uint256 lat;
         uint256 long;
         uint256 dateTime;
    }
    
    mapping (address => Location[])  locationStamp;
    
    
    function track(uint256 lat, uint256 long) public {
        Location memory location = Location({
            lat: lat,
            long: long,
            dateTime: now
        });
        
        locationStamp[msg.sender].push(location);
    }
    
    function getLatestLocation() public view returns (uint256 lat, uint256 long, uint256 dateTime){
        Location[] memory senderLocationStamp = locationStamp[msg.sender];
        Location memory latestLocation = senderLocationStamp[senderLocationStamp.length-1];
        
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}