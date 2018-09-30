pragma solidity ^0.4.21;

contract lastregistrations {
    mapping(string => uint256) lastregistration;
    
    function getLastRegistration(string endpoint) public view returns (uint256) {
        return lastregistration[endpoint];
    }
    
    function setLastRegistration(string endpoint, uint256 regtime) public {
        lastregistration[endpoint] = regtime;
    }
}