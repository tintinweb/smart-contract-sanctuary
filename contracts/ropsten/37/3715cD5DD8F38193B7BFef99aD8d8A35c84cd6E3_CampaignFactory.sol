/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
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
        mapping(address => bool) approvals; // No need to initialize this in a new Request
    }

    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint numRequests;
    uint public approversCount;
    mapping(uint => Request) public requests;

    modifier restricted() {
        require(msg.sender == manager, "Not allowed");
        _;
    }

    constructor (uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        // Ensure correct contribution
        require(msg.value > minimumContribution, "Not enough funds are being contributed!");

        // Keep track of number of contributors
        if(!approvers[msg.sender]) {
            approversCount++;
        }

        // Add contributor to mapping
        approvers[msg.sender] = true;
    }

    function createRequest(string memory _description, uint _value, address _recipient) public restricted {
        require(_value <= address(this).balance, "Cannot request more than what the contract has.");
        
        Request storage newRequest = requests[numRequests++];
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = payable(_recipient);
        newRequest.complete = false;
        newRequest.approvalCount = 0;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender], "Not a contributor, hence ineligible to approve request");

        require(!request.approvals[msg.sender], "This address has already voted");

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public restricted payable {
        Request storage request = requests[index];
        
        require(request.approvalCount > (approversCount / 2), "The majority hasn't approved of this request");

        require(!request.complete, "Request has already completed");

        request.recipient.transfer(request.value);
        request.complete = true;

    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
        ) {
        return (
            minimumContribution,
            address(this).balance,
            numRequests,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return numRequests;
    }

}