pragma solidity ^0.4.21;

contract lastalerts {
    mapping(string => string) lastalert;
    
    function getLastAlert(string endpoint) public view returns (string) {
        return lastalert[endpoint];
    }
    
    function setLastAlert(string endpoint, string data) public {
        lastalert[endpoint] = data;
    }
}