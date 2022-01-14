/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.8.0;

contract PiggerBank{
    uint public goal;
    address public own;

    constructor(uint _goal){
        goal=_goal;
        own=msg.sender;
    }

    receive() external payable{}

    function getBalance()public view returns(uint){
        return address(this).balance;
    }

    function withdraw()public {
            selfdestruct(msg.sender);
        
    }
   
}