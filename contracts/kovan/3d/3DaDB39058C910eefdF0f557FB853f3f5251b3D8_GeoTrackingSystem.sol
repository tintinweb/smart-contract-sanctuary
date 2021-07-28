/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity ^0.5.0;

contract GeoTrackingSystem
{
    struct LocationStamp
    {
     uint256 lat;
     uint256 long;
     uint256 dateTime;
    }
    
    mapping (address => string) users;
    mapping (address => LocationStamp[]) public userLocation;
    function register(string memory userName) public
    {
        users[msg.sender] = userName; //msg คือตัว message ที่ call เข้ามาใน function เป็น global มันคือ address ที่ call เข้ามา
    }
    function GetPublicName(address userAddress) public view returns(string memory)
    {
        return users[userAddress];
    }
    function GetPublicName() public view returns(string memory)
    {
        return users[msg.sender];
    }
    function track(uint256 lat, uint256 long) public
    {
        LocationStamp memory _location;
        _location.lat = lat;
        _location.long = long;
        _location.dateTime = now; //block.timestamp; ใช้อะไรก็ได้เลือกเอา
        userLocation[msg.sender].push( _location ); 
    }
    function GetLatestLocation() public view returns(uint256 lat,uint256 long, uint256 datetime)
    {
        //storage เพราะมันเป็นการเชื่อมโยงว่า เฮ้ยตัวแปรนี้อะ ลิ้งไปที่ตัวที่มาเท่ากับ แต่ถ้าใช้ memory มันจะสร้างตัวแปรมาใหม่แล้วเอาตัวที่เท่ากับมาใส่ เดาล้วนๆ+++
        LocationStamp[] storage location = userLocation[msg.sender];
        LocationStamp storage latestLocation = location[location.length - 1];
        //return ได้ 2 แบบ
        //====>1.
        // return
        // (
        //     latestLocation.lat, latestLocation.long, latestLocation.dateTime
        // );
        //====>2.
        lat = latestLocation.lat;
        long = latestLocation.long;
        datetime = latestLocation.dateTime;
    }
}