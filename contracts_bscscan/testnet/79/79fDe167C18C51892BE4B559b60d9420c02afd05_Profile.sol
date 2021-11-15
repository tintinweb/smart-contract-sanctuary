// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Profile {
    event save(address user, string data);
    mapping(address => string) public profiles;
    mapping(address => string[]) public playersHistory;
    
    function saveProfile (string calldata _data) external{
        profiles[msg.sender] = _data;
        emit save(msg.sender,_data);
    }
    function updatePlayers (string calldata _data) external{
        playersHistory[msg.sender].push(_data);
    }
    function getPlayersHistory (
        address _address
    )
    external view returns (string[] memory)
    {
        string[] memory tempList = playersHistory[_address];
        return tempList;
    }
}

