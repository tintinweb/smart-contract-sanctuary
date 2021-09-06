/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.4.19;


contract PlayerFactory{
    
    event NewPlayerBuyed(uint playerId, string name, uint adn);
     
    uint adnDigits = 16; 
    uint adnModulus = 10 ** adnDigits;
    
    struct Player{
        string name;
        uint adn; 
    }
    
    Player[] public players;
    
    mapping (uint => address) public playerToOwner; 
    mapping (address => uint) ownerPlayerCount; 
    
    function _createPlayer(string _name, uint _adn) private {
        uint id = players.push(Player(_name, _adn)); 
        playerToOwner[id] = msg.sender; 
        ownerPlayerCount[msg.sender]++; 
        NewPlayerBuyed(id, _name, _adn); 
    }
    
    function _generateRandomAdn(string _str) private view returns(uint){
        uint rand = uint(keccak256(_str)); 
        return rand % adnModulus;
    }
    
    function _buyPlayer(string _name) public{
        uint randAdn = _generateRandomAdn(_name);
        _createPlayer(_name, randAdn);
    }
    
    function getPlayersByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerPlayerCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < players.length; i++) {
      if (playerToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
    
}