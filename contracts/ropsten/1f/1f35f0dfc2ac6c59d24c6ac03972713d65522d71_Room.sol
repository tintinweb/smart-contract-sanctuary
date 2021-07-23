/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Room {

    bool public lightsOn = false;
    
    event Switch (
        bool lightsOn
    );

    function turnLightsOn() public {
        lightsOn = true;
        
        emit Switch( lightsOn );
    }
    
    function turnLightsOff() public {
        lightsOn = false;
        
        emit Switch( lightsOn );
    }
}