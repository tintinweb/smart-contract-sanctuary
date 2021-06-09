/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageStructure {
    address public implementation;
    address public owner;
    mapping (address => uint) internal points;
    uint internal totalPlayers;
}

contract ImplementationV2 is StorageStructure {
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
 
    function addPlayer(address _player, uint _points) 
        public onlyOwner 
    {
        require (points[_player] == 0);
        points[_player] = _points;
        totalPlayers++;
    }

    function setPoints(address _player, uint _points) 
        public onlyOwner 
    {
        require (points[_player] != 0);
        points[_player] = _points;
    }

    function fetchPlayersCount() public view returns(uint){
        return totalPlayers;
    }
}