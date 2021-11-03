/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract rulet
{
    // bytes32 password;
    // uint password_value
    // password == keccak256(abi.encodePacked(password_value)
    uint x;
    bytes32 hash;
    
    struct player{
        address playerAddress;
        string playerName;
        uint8 bet;
    }
    
    player[] players;
    
    function makeBet(string memory _playerName, uint8 _bet)public{
        players.push(player(msg.sender, _playerName, _bet));
        //keccak256(abi.encodePacked(_bet)) + keccak256(bytes(_playerName));
        x = uint(blockhash(block.number)) + _bet + uint(keccak256(bytes(_playerName)));// + keccak256(bytes32(_playerName));
    }
    
    function getX()public view returns(uint, uint){
        return (block.number, block.timestamp);
    }
    
    function getHash()public view returns(bytes32){
        uint x = block.number - 1;
        bytes32 hash1 = blockhash(block.number - 1);
        return blockhash(block.number - 2);
    }
    
    function deleteAdresses()public{
        delete players;
    }
}