/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.3;

contract Tricks {
    
    string public trick;
    
    constructor (string memory initTrick) {
        trick=initTrick;
    }
    
    function setTrick(string memory newTrick) public {
        trick=newTrick;
    }
    
    function proposeMe () public view returns(string memory){
        return trick;
    }
}