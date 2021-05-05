/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.8.1;

contract TestEvent {
    
    mapping(string => string) map;
    
    event orderlog(string indexed action, string indexed key, string value);
    
    function getvalue(string memory key) public view returns (string memory) {
        return map[key];
    }
    
    function setvalue(string memory key, string memory value) public {
        emit orderlog("setvalue haha", key, value);
        map[key] = value;
    }
}