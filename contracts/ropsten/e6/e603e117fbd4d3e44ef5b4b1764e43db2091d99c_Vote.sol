/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Vote{
   
    struct Voter {
        bool voted;
        uint8 delegate;
    }
    
    uint256 public countForOne;
    uint256 public countForTwo;

    mapping(address => Voter) public voters;
    
    function vote(uint8 _id) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        if(_id==1){
            countForOne+=1;
        }
        else{
            countForTwo+=1;
        }
        sender.voted = true;
        sender.delegate=_id;

    }

}