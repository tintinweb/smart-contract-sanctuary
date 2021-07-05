/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;
    
    function createCampaign(uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return deployedCampaigns;
    }
}


contract Campaign {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    /* Request[] public requests; */
    uint numRequests = 0;
    mapping(uint => Request) public requests;
    
    address public manager;
    uint public minimumContritbution;
    mapping(address => bool) public approvers;
    uint public approversCount = 0;
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    constructor (uint minimum, address creator) {
        manager = creator;
        minimumContritbution = minimum;
    }
    
    function contribute() public payable {
        require(msg.value > minimumContritbution);
        approvers[msg.sender] = true;
        approversCount++;
    }
    
    function createRequest(string memory description, uint value, address payable recipient) public restricted {
        Request storage r = requests[numRequests];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;
        numRequests++;
    }
    
    function approveRequest(uint index) public payable {
        Request storage request = requests[index];
        
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
    function finalizeRequest(uint index) public payable restricted {
        Request storage request = requests[index];
        
        require(!request.complete);
        
        require(request.approvalCount > (approversCount/2) );
        
        request.recipient.transfer(request.value);
        
        request.complete = true;
    }
}