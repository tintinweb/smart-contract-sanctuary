/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;


contract TestICO {
    
    uint256 start_Time=0;
    uint256 target = 9000;
    uint256 reached = 3000;

    constructor() public  {

        start_Time = now + 30 days; 
        
    }
    
    function get_timer() public view returns (uint256){
        return start_Time;
    }
    
    function set_timer(uint256 temp) public {
        start_Time = temp;
    }
    
    function set_target(uint256 t_target, uint256 t_reached) public {
        target = t_target;
        reached = t_reached;
    }
    
    function get_target() public view returns (uint256){
        return target;
    }   
    
    function get_reached() public view returns (uint256){
        return reached;
    }
    
    receive() external payable {

    }
    
    
    
}