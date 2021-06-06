/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    
    struct LocationStamp {
        uint256 lat;
        uint256 lng;
        uint256 dateTime;
    }
    
    struct UserInfo {
        string name;
        string lastName;
        string fullName;
        string organization;
    }
    
    mapping (address => LocationStamp[]) public userLocation;
    
    // mapping (address => string) users;
    
    // function register(string memory userName) public {
    //     users[msg.sender] = userName;
    // }
    
    mapping (address => UserInfo) usersInfo;
    
    function register(string memory name, string memory lastName, string memory organization) public {
        UserInfo memory userInfo;
        userInfo.name = name;
        userInfo.lastName = lastName;
        userInfo.fullName = string(abi.encodePacked(name," ",lastName));
        userInfo.organization = organization;
        usersInfo[msg.sender] = userInfo;
    }
    
    function getPublicName(address userAddress) public view returns (string memory fullName, string memory organization) {
        UserInfo memory userInfo = usersInfo[msg.sender];
        fullName = userInfo.fullName;
        organization = userInfo.organization;
    }
    
    function track(uint256 lat, uint256 lng) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.lng = lng;
        currentLocation.dateTime = block.timestamp; // now;
        userLocation[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress) public view returns (uint256 lat, uint256 lng, uint256 dateTime) {
        LocationStamp[] storage locations = userLocation[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length - 1];
        // return (
        //     latestLocation.lat,
        //     latestLocation.lng,
        //     latestLocation.dateTime 
        //     );
        lat = latestLocation.lat;
        lng = latestLocation.lng;
        dateTime = latestLocation.dateTime;
    }
}