/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;

    function createCampaign (uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Campaign[] memory){
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

    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    // refactoring due to mapping in struct error
    uint public numRequests;
    mapping (uint => Request) public requests;

    function getRequest(uint id) public view returns (string memory){
        return requests[id].description;
    }
    
    function getApproval(uint id, address input) public view returns (bool){
        return requests[id].approvals[input];
    }
    

    modifier restricted () {
        require(msg.sender == manager, "ERR: NOT MANAGER");
        _;
    }

    constructor(uint minimum, address creator){
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;

    }

    function createRequest(string calldata description, uint value, address payable recipient)
        public restricted returns (uint requestID){
        requestID = numRequests++;
            
        // We cannot use "requests[requestID] = Request(...)"
        // because the RHS creates a memory-struct "Request" that contains a mapping.
        // https://docs.soliditylang.org/en/v0.7.0/types.html?highlight=struct#structs
        Request storage r = requests[requestID];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;
    }

    function approveRequest(uint index) public {
        Request storage r = requests[index];

        require(approvers[msg.sender], "ERR: NOT APPROVED");
        require(!requests[index].approvals[msg.sender], "ERR: ALREADY VOTED");
        
        r.approvals[msg.sender] = true;
        r.approvalCount++;

    }

    function finalizeRequest(uint index) public restricted {
        Request storage r = requests[index];

        require(r.approvalCount > (approversCount / 2), "ERR: INSUFFICIENT APPROVALS");
        require(!r.complete, "ERR: ALREADY FINAL");

        r.recipient.transfer(r.value);
        r.complete = true;
    }

}