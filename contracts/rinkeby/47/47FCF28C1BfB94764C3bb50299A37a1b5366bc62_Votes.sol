/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract Votes {

    uint256 votes_for_1 = 0;
    uint256 votes_for_2 = 0;
    address owner;
    
    constructor () { owner = msg.sender; }

    function vote_for(uint256 candidate) public payable {
        require(msg.value==10000000000000000, "The price of a vote is 0.01 ETH");
        require(candidate==1 || candidate==2, "Please vote for 1 or 2");
        if (candidate==1) votes_for_1 ++;
        if (candidate==2) votes_for_2 ++;
    }

    function voted_for(uint256 candidate) public view returns (uint256 votes){
        require(candidate==1 || candidate==2, "Please vote for 1 or 2");
        if (candidate==1) return votes_for_1;
        if (candidate==2) return votes_for_2;
    }
    
    function withdraw(address payable recipient, uint256 amount) public {
        require(msg.sender==owner, "You are not the owner");
        recipient.transfer(amount);
    }
}