/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract ECLaunch {
    
    string description = "Seconds until Ether Cards Launch";
    
    uint launch_date = 1616072400;
    
    function how_long_more() public view returns (uint Days, uint Hours, uint Minutes, uint Seconds) {
        require(block.timestamp < launch_date,"Missed It");
        uint gap = launch_date - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap %  (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days,Hours,Minutes,Seconds);
    }
    
    
    
    
    
    
}