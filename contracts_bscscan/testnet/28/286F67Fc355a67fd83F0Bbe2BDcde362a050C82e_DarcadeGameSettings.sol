/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DarcadeGameSettings {

    mapping (address => GameSettings) public machine;

    struct GameSettings {
        uint256 scoreToTokenDivisor;
    }
    
    event GameSettingsUpdated(address sender, GameSettings settings);
        
    function setGameSettings(uint256 scoreToTokenDivisor) public {
        machine[msg.sender] = GameSettings(scoreToTokenDivisor);
        emit GameSettingsUpdated(msg.sender, machine[msg.sender]);
    }

}