pragma solidity >=0.6.0;

import "./00_startContract.sol";
import "./01_resources.sol";
import "./01_buildings.sol";

contract trovianContract is firstContract, buildingContract, resourcesContract{
    
    function startGame(uint256 _time) external isOwner(){
        cooldown = _time + block.timestamp;
    }
}