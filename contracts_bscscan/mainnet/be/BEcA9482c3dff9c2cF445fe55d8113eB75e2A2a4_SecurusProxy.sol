/**
 * @title Securus Proxy
 * @dev SecurusProxy contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/
import "./Ownable.sol";
import "./IStrategy.sol";

pragma solidity ^0.6.12;

// Test Proxy for trigger 
// trigger later more Strategys
contract SecurusProxy is Ownable{


    /**
     * @dev outputs the external contracts.
     */
    IStrategy public strategy;
    uint256 public counter = 0;


    function triggerProxy() public {

        counter++;

        if (counter == 1){
        strategy = IStrategy(0xF445405bdF2e3767E03f3e9a460771bBFC34916E);
        strategy.harvest();
        }

         if (counter == 2){
        counter = 0;   
        strategy = IStrategy(0x60083543De7FaE5b097b914e9d8Ab6988A17fB7a);
        strategy.harvest();
        }   
    }
}