/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.6.12;

contract Tracking{
    
    // Record each user location with timestamp
    struct LocationStamp{
        uint256 lat;
        uint256 long;
        uint256 dateTime;
    }
    
    // fullname / nickname
    mapping(address => string) users;
    
    //Historical locations of all users
    mapping(address => LocationStamp[]) public userLocations;
    
    
    function register(string memory userName) public{
        users[msg.sender] = userName;
    }
    
    // getter of userName
    function getPubilcName(address userAddress) public view returns(string memory){
        return users[userAddress];
    }
    
    function track(uint256 lat, uint256 long) public {
        LocationStamp memory currentLocation; // ตัวแปลชั่วคร่าว (เป็นตัวแปลทีสร้างใหม่)
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.dateTime = block.timestamp; // now; // หรือใช้ now ก็ได้เหมือนกัน
        userLocations[msg.sender].push(currentLocation);
    }
    
    function getLastestLocation() public view returns(uint256 lat, uint256 long, uint256 dateTime){
        // storagedคือการเข้าถึงข้อมูลตัวแปลที่สร้างมาแล้ว
        // get array and keep in locations
        // lastestLocation is data of msg.sender find last array
        LocationStamp[] storage locations = userLocations[msg.sender];
        LocationStamp storage lastestLocation = locations[locations.length -1];
        
        lat = lastestLocation.lat;
        long = lastestLocation.long;
        dateTime = lastestLocation.dateTime;

    }
    
}