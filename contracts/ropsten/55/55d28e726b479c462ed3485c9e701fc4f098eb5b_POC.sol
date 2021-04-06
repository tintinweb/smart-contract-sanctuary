/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: contracts/POC.sol

pragma solidity ^0.5.0;


contract POC  {

    struct IoTInfo {
        string geo;
        uint timestamps;
        bool behavior;
        string events;
        address user;
    }
    
    mapping(uint => IoTInfo) public infoByIndex;
    
    event infoAdded(address _user, string _geo, uint _timestamps, bool _behavior, string _events);
    
    function addInfo(uint _index, string memory _geo, bool _behavior) public {
        
        infoByIndex[_index].geo = _geo;
        infoByIndex[_index].timestamps = now;
        infoByIndex[_index].behavior = _behavior;
        if (_behavior == true) {
            infoByIndex[_index].events = "Lights On";
        } else {
            infoByIndex[_index].events = "Lights Off";
        }
        infoByIndex[_index].user = msg.sender;
      
        emit infoAdded(msg.sender, _geo, now, _behavior, infoByIndex[_index].events);
    }
}