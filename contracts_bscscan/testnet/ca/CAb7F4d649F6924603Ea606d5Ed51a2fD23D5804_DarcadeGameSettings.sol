// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DarcadeGameSettings {

    mapping (address => GameSettings) public machine;

    struct GameSettings {
        uint256 scoreToTokenDivisor;
        uint256 scoreToTokenMultiplier;
    }

    event GameSettingsUpdated(address sender, GameSettings settings);

    function setGameSettings(uint256 scoreToTokenDivisor, uint256 scoreToTokenMultiplier) public {
        machine[msg.sender] = GameSettings(scoreToTokenDivisor, scoreToTokenMultiplier);
        emit GameSettingsUpdated(msg.sender, machine[msg.sender]);
    }

}

