/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Crowdfunding
 * @dev Crowdfunding on blockchain
 */
contract CrowdfundingCampaign {
    
    address payable owner;
    uint goal;
    mapping (address => uint) backers;

    constructor(uint _goal) {
        owner = payable(msg.sender);
        goal = _goal;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function backCampaign() public payable {
        require(msg.value != 0);
        backers[msg.sender] += msg.value;
    }

    function getFundedCampaignFunds() public {
        require(msg.sender == owner, "Only owner can withdraw funds.");
        require(address(this).balance >= goal, "Goal is not yet reached.");
        
        owner.transfer(address(this).balance);
    }
    
    function refund() public {
        require(backers[msg.sender] != 0);
        
        payable(msg.sender).transfer(backers[msg.sender]);
    }
}