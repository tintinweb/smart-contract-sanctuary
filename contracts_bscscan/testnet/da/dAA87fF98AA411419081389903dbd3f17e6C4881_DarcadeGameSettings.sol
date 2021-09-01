/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.5.0;


contract DarcadeGameSettings {

    mapping (address => GameSettings) public gameSettings;

    struct GameSettings {
        uint256 scoreToTokenDivisor;
    }
    
    function setGameSettings(uint256 scoreToTokenDivisor) public {
        gameSettings[msg.sender] = GameSettings(scoreToTokenDivisor);
    }

}