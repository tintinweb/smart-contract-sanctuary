pragma solidity ^0.4.21;
contract Simple {
 
    uint public simpleNumber;
 
    function Temp() public {
        simpleNumber = 5;
    }
 
    function getSimple() public view returns(uint) {
        return simpleNumber;
    }
}