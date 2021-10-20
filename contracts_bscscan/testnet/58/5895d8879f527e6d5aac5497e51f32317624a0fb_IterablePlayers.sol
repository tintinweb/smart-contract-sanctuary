/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
 * @dev 
 * This library is required to manage available players on ToshiGames
 * dataAggregator is used to pick a random user
 *
 * The declaration of the variable is on "ContextGames.sol"
 * Only BabyToshi owner can exclude a player
 * Only players of ToshiFlip can execute some functions
 * Only new players can register to ToshiFlip
 */
library IterablePlayers {
    struct Players{
        uint nbRandom;
        address[] keys;
        mapping(address => uint256) win;
        mapping(address => uint256) loose;
        mapping(address => bool) excluded;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
    function get(Players storage players, address key) external view returns(address player, uint256 win, uint256 loose, bool excluded){
        if( !players.inserted[key] ){
            return (address(0), 0, 0, false);
        }
        return (key, players.win[key], players.loose[key], players.excluded[key]);
    }
    
    function getRandom(Players storage players, address key) external returns (address randomPlayer) {
        if( players.keys.length == 0 ){
            return address(0);
        }
        players.nbRandom++;
        uint random = uint(keccak256(abi.encodePacked(players.nbRandom, key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))%players.keys.length; //blockhash(block.number), block.difficulty
        return players.keys[random];
    }
    function getAll(Players storage players) external view returns(address[] memory player, uint256[] memory win, uint256[] memory loose, bool[] memory excluded){
        uint nPlayers = players.keys.length;
        (address[] memory _player, uint256[] memory _win, uint256[] memory _loose, bool[] memory _excluded) = (new address[](nPlayers), new uint256[](nPlayers), new uint256[](nPlayers), new bool[](nPlayers));
        for(uint i=0; i < nPlayers; i++ ){
            address key = players.keys[i];
            _player[i] = key;
            _win[i] = players.win[key];
            _loose[i] = players.loose[key];
            _excluded[i] = players.excluded[key];
        }
        return (_player, _win, _loose, _excluded);
    }
    function getAvailables(Players storage players) external view returns(address[] memory player, uint256[] memory win, uint256[] memory loose, bool[] memory excluded){
        uint nPlayers = players.keys.length;
        (address[] memory _player, uint256[] memory _win, uint256[] memory _loose, bool[] memory _excluded) = (new address[](nPlayers), new uint256[](nPlayers), new uint256[](nPlayers), new bool[](nPlayers));
        for(uint i=0; i < nPlayers; i++ ){
            address key = players.keys[i];
            if( !players.excluded[key] ){
                _player[i] = key;
                _win[i] = players.win[key];
                _loose[i] = players.loose[key];
                _excluded[i] = players.excluded[key];
            }
        }
        return (_player, _win, _loose, _excluded);
    }

    function isPlayer(Players storage players, address key) external view returns(bool _isPlayer){
        return players.inserted[key];
    }
    
    function add(Players storage players, address key) public returns(bool added){
        if( players.inserted[key] ){
            return false;
        }
        players.keys.push(key);
        players.win[key] = 0;
        players.loose[key] = 0;
        players.excluded[key] = false;
        players.indexOf[key] = players.keys.length - 1;
        players.inserted[key] = true;
        
        return true;
    }
    function remove(Players storage players, address key) external returns (bool removed){
        if (players.inserted[key]) {
            delete players.win[key];
            delete players.loose[key];
            delete players.excluded[key];
            delete players.inserted[key];
            uint index = players.indexOf[key];
            uint lastIndex = players.keys.length - 1;
            address lastKey = players.keys[lastIndex];
            players.indexOf[lastKey] = index;
            players.keys[index] = lastKey;
            delete players.indexOf[key];
            players.keys.pop();
            return true;
        }else{
            return false;
        }
    }
    
    function getIndexOfKey(Players storage players, address key) external view returns (int index) {
        if(!players.inserted[key]) {
            return -1;
        }
        return int(players.indexOf[key]);
    }
    function getKeyAtIndex(Players storage players, uint index) external view returns (address playerAddress) {
        return players.keys[index];
    }


    function incrementWin(Players storage players, address key) external returns(bool updated){
        if( !players.inserted[key] ){
            return false;
        }
        players.win[key] += 1;
        return true;
    }
    function incrementLoose(Players storage players, address key) external returns(bool updated){
        if( !players.inserted[key] ){
            return false;
        }
        players.loose[key] += 1;
        return true;
    }
    function updateExcluded(Players storage players, address key, bool excluded) external returns(bool updated){
        if( !players.inserted[key] || players.excluded[key] == excluded ){
            return false;
        }
        players.excluded[key] = excluded;
        return true;
    }
    function size(Players storage players) external view returns (uint length) {
        return players.keys.length;
    }
}