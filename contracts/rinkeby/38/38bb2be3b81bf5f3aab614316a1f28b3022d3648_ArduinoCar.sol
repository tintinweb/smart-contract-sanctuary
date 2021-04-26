/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;

contract ArduinoCar{
    string private received_command="initial";
    
    function drive() public{
        received_command = "Drive";
    }
    
    function stop() public{
        received_command = "stop";
    }
    
    function left() public{
        received_command = "left";
    }
   
    function right() public{
        received_command = "right";
    }
    
    function get() public view returns(string memory){
        return received_command;
    }
}