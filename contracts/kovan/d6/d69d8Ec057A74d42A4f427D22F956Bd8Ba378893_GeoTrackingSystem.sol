/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem {
    struct LocationStamp { //Obj เก็บค่าตัวแปรแบบกลุ่ม
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // User ชื่อจริงหรือชือ่เล่น
    mapping (address => string) users;
    
    //ประวัติการบันทึก ที่ตั้ง
    mapping (address => LocationStamp[]) public userLocations;
    
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }
    
    function getPublicName(address userAddress) public view returns (string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = now;
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLatestLocation(address userAddress) public view returns (uint256 lat, uint256 long, uint256 dateTime){
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage latestLocation = locations[locations.length-1];
        /*return (
            latestLocation.lat,
            latestLocation.long,
            latestLocation.dateTime
        );*/
        lat = latestLocation.lat;
        long = latestLocation.long;
        dateTime = latestLocation.dateTime;
    }
}