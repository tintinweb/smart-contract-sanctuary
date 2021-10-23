/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity ^0.4.23;

contract Track_record{
    uint latitude;
    uint longitude;
    
    event MapLog(uint indexed latitude, uint indexed longitude, uint lat, uint lon);
    
    function setInfo(uint _latitude, uint _longitude) public{
       latitude = _latitude;
       longitude = _longitude;
       emit MapLog(_latitude, _longitude,_latitude, _longitude);
    }
    function getInfo() public view returns (uint, uint) {
       return (latitude, longitude);
    }
   
   
}