pragma solidity ^0.4.24;

contract BirthDay{
    uint public bday;
    address public dateTimeAddr = 0x56C507dE85b397d55859F9D4957Ba34004572A49;
    DateTime dateTime = DateTime(dateTimeAddr);
    
    constructor () public {
        bday = now;
    }
    
    function getBirthYear() view public returns (uint16){
        return dateTime.getYear(bday);
    }
    
    function getBirthMonth() view public returns (uint8){
        return dateTime.getMonth(bday);
    }
    
    function getBirthDay() view public returns (uint8){
        return dateTime.getDay(bday);
    }
}

contract DateTime{
    function getYear(uint timestamp) public constant returns(uint16);
    function getMonth(uint timestamp) public constant returns(uint8);
    function getDay(uint timestamp) public constant returns(uint8);
}