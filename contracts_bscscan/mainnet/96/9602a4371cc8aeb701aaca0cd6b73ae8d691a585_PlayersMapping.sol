/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
/*
****************      **************    ****************    ***            ***  ******************   **************      ****************  ***            ***  ****
*****************    ****************   *****************    ***          ***   ******************  ****************    ****************   ***            ***  ****
**             ***  ***            ***  **             ***    ***        ***    ****************** ******************  ****************    ***            ***  **** 
**              **  **              **  **              **     ***      ***            ****        **              **   ***********        ***            ***  ****
**              **  **              **  **              **      ***    ***             ****        **              **    ***********       ***            ***  
*****************   ******************  *****************        ********              ****        **              **     ***********      ******************  ****
*****************   ******************  *****************         ******               ****        **              **      ***********     ******************  ****     
**              **  **              **  **              **         ****                ****        **              **       ***********    ***            ***  ****
**              **  **              **  **              **         ****                ****        **              **        ***********   ***            ***  ****    
**             ***  **              **  **             ***         ****                ****        ******************    ****************  ***            ***  ****
*****************   **              **  *****************          ****                ****         ****************    ****************   ***            ***  ****
****************    **              **  ****************           ****                ****          **************    ****************    ***            ***  ****

******************   **************      ****************  ***            ***  ****  ******************  ***                 ***  ****************
******************  ****************    ****************   ***            ***  ****  ******************  ***                 ***  *****************
       ****        ******************  ****************    ***            ***  ****  ******************  ***                 ***  ******************
       ****        **              **   ***********        ***            ***  ****  ***                 ***                 ***  ***            ***
       ****        **              **    ***********       ***            ***        ***                 ***                 ***  ***            ***
       ****        **              **     ***********      ******************  ****  ******************  ***                 ***  *****************
       ****        **              **      ***********     ******************  ****  ******************  ***                 ***  **************** 
       ****        **              **       ***********    ***            ***  ****  ***                 ***                 ***  ***
       ****        **              **        ***********   ***            ***  ****  ***                 ***                 ***  ***
       ****        ******************    ****************  ***            ***  ****  ***                 ******************  ***  ***
       ****         ****************    ****************   ***            ***  ****  ***                 ******************  ***  ***
       ****          **************    ****************    ***            ***  ****  ***                 ******************  ***  ***
*/ 
/**
 * @dev Is library to manage players and their stats.
 * 
 * This contract is linked with Toshiflip Contract.
 * Dont send funds to this contract !!!
**/

library PlayersMapping {
    // Iterable mapping from address to uint;
    struct Players{
        address[] keys;
        mapping(address => uint256) wins;
        mapping(address => uint256) looses;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    /**
     * @dev Add a player
     */
    function add(Players storage players, address key) internal {
        if( players.inserted[key] )
            return;
        
        players.wins[key] = 0;
        players.looses[key] = 0;
        players.indexOf[key] = players.keys.length;
        players.inserted[key] = true;
        players.keys.push(key);  
    }

    /**
     * @dev Get informations of a player
     */
    function getPlayer(Players storage players, address player) public view returns(address key, uint256 wins, uint256 looses){
        if( !players.inserted[player] ){
            return (address(0), 0, 0);
        }
        return (player, players.wins[player], players.looses[player]);
    }
    /**
     * @dev Get all players
     * Can only be called by the owner
     */
    function getPlayers(Players storage players) public view returns(address[] memory keys){
        return players.keys;
    }
    
    /**
     * @dev Verify if a player exists
     */
    function contains(Players storage players, address key) public view returns(bool isPlayer){
        return players.inserted[key];
    }

    /**
     * @dev Get players size
     */
    function size(Players storage players) public view returns (uint length) {
        return players.keys.length;
    }
    
    /**
     * @dev Update player stats.
     * Can only be called by allowed contracts.
     */
    function incrementWin(Players storage players, address key) public {
        if( !players.inserted[key] ){
            return;
        }
        players.wins[key] += 1;
    }
    /**
     * @dev Update player stats.
     * Can only be called by allowed contracts.
     */
    function incrementLoose(Players storage players, address key) public {
        if( !players.inserted[key] ){
            return;
        }
        players.looses[key] += 1;
    }
}