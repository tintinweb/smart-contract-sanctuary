/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */


contract DEX {
    uint256 public contractBalance;
    event Funded(uint256 amount);

    constructor() public {
        contractBalance=0;
    }
    
    function() payable external  {
        uint256 amountTobuy = msg.value;
        require(amountTobuy > 0, "You need to send some Ether");
        contractBalance+=msg.value;
        emit Funded(amountTobuy);
    }
    
   

}