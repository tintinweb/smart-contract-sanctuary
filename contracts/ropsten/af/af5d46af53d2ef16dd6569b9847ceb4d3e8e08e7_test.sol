pragma solidity ^0.4.20;

contract test{
    uint notMe;
    
    function maybeAnotherTime (uint disgrace) public{
        notMe = disgrace;
    }
    
    function tryAnotherOne() public view returns(uint){
        return notMe;
    }
}