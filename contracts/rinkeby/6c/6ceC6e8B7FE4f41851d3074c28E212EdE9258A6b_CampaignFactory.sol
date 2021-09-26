/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        Campaign newCampaign = new Campaign({
            minimum: minimum,
            sender: msg.sender
        });

        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) requestApprovers;
    }

    address public manager;
    uint256 public minimumContribution;
    address[] public approvers;
    mapping(address => uint256) public approversToFundedAmount;

    mapping(uint256 => Request) public requests;
    uint256 numRequests;

    modifier isManager() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint256 minimum, address sender) {
        manager = sender;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(
            msg.value >= minimumContribution,
            "Contribution must be more than the minimumContribution"
        );

        approvers.push(msg.sender);
        approversToFundedAmount[msg.sender] = msg.value;
    }

    function createRequest(
        string memory _description,
        uint256 _value,
        address payable _recipient
    ) public isManager {
        Request storage r = requests[numRequests++];

        r.description = _description;
        r.value = _value;
        r.recipient = _recipient;
        r.complete = false;
        r.approvalCount = 0;
    }

    modifier isApprover() {
        require(approversToFundedAmount[msg.sender] > 0);
        _;
    }

    function approveRequest(uint256 requestIndex) public isApprover {
        Request storage tempRequest = requests[requestIndex];
        require(!tempRequest.complete, "reqest was completed");
        require(!tempRequest.requestApprovers[msg.sender], "you have voted");

        tempRequest.requestApprovers[msg.sender] = true;
        tempRequest.approvalCount++;
    }

    function finalizeRequest(uint256 requestIndex) public isManager {
        Request storage tempRequest = requests[requestIndex];

        require(!tempRequest.complete, "reqest was completed");
        require(
            tempRequest.approvalCount > (approvers.length / 2),
            "need more than 50% vote"
        );

        tempRequest.recipient.transfer(tempRequest.value);
        tempRequest.complete = true;
    }
}