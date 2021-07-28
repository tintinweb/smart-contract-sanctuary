/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


contract HeadOrTail {
    bool public chosen; // True if head/tail has been chosen.
  
    address payable public party; // The last parti who chose.

    bool lastChoiceHead;
    
    /** @dev Must be send 1 ETH.
     *  Choose head or tail to be guessed by the other player.
     *  @param _chooseHead True if head was chosen, false if tail was chosen.
     */
    function choose(bool _chooseHead) public payable {
        require(!chosen);
        require(msg.value == 1 ether);
        
        chosen=true;
        lastChoiceHead=_chooseHead;
        party=payable(msg.sender);
    }
    
    
    function guess(bool _guessHead) public payable {
        require(chosen);
        require(msg.value == 1 ether);
        
        if (_guessHead == lastChoiceHead)
            payable(msg.sender).transfer(2 ether);
        else
            party.transfer(2 ether);
            
        chosen=false;
    }
}