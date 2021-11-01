// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        Campaign deployed = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(address(deployed));
    }

    function getDeploayedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    address public manager;
    uint256 public minimumContribution;

    uint256 public requestCount;
    mapping(uint256 => Request) public requests;

    uint256 public approverCount;
    mapping(address => bool) public approvers;

    modifier onlyManager() {
        require(msg.sender == manager, "Only avaiable for manager");
        _;
    }

    modifier alreadyContributed() {
        _;
    }

    constructor(uint256 minimum, address creator) {
        manager = creator; // msg.sender;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution);
        approvers[msg.sender] = true;
        approverCount++;
    }

    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public onlyManager {
        uint256 key = requestCount++;
        Request storage newReq = requests[key];
        newReq.description = description;
        newReq.value = value;
        newReq.recipient = recipient;
        newReq.complete = false;
        newReq.approvalCount = 0;
    }

    function approveRequest(uint256 index) public alreadyContributed {
        require(index < requestCount);

        Request storage req = requests[index];
        require(!req.approvals[msg.sender]);

        req.approvals[msg.sender] = true;
        req.approvalCount++;
    }

    function completeRequest(uint256 index) public onlyManager {
        require(index < requestCount);

        Request storage req = requests[index];

        require(req.approvalCount >= (approverCount / 2));
        require(!req.complete);

        // req.recipient.transfer(req.value);
        (bool success, ) = req.recipient.call{value: req.value}("");
        require(success, "Transfer failed.");
        req.complete = true;
    }
}