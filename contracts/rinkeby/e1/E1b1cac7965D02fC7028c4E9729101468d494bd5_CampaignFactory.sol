/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint256 minGoal) public {
        deployedCampaigns.push(address(new Campaign(minGoal, msg.sender)));
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool isProcessed;
        uint256 approvalCounter;
        // Mapping below keeps track of the addresses that have approved the request.
        mapping(address => bool) approvals;
    }

    address public manager;
    uint256 public minGoal;
    uint256 public totalAmount;

    uint256 public nbrRequests;
    uint256 public nbrContributors;

    mapping(address => bool) public contributors;

    mapping(uint256 => Request) public requestList;

    modifier isManager() {
        require(msg.sender == manager, "You are not the manager!");
        _;
    }

    constructor(uint256 _minGoal, address creator) {
        manager = creator;
        minGoal = _minGoal;
    }

    function contribute() public payable {
        require(msg.value > .01 ether, "You need to spend more ETH");

        totalAmount += msg.value;
        contributors[msg.sender] = true;
        nbrContributors++;
    }

    function addRequest(
        string memory _description,
        uint256 _value,
        address _recipient
    ) public isManager {
        Request storage r = requestList[nbrRequests++];
        r.description = _description;
        r.value = _value;
        r.recipient = _recipient;
        r.isProcessed = false;
        r.approvalCounter = 0;
    }

    function approveRequest(uint256 requestIndex) public {
        Request storage r = requestList[requestIndex];
        require(contributors[msg.sender]);

        // Check if the user has in fact not yet voted for this request
        require(!r.approvals[msg.sender]);

        r.approvalCounter++;
        r.approvals[msg.sender] = true;
    }

    function finalizeRequest(uint256 requestIndex) public isManager {
        Request storage r = requestList[requestIndex];

        // it cant be processed yet in the beginning
        require(!r.isProcessed);

        // lets say 10 people have contributed and of those 10, 3 have approved for the payout. The result will be 3 > (10/2) => So no payout!
        require(r.approvalCounter > (nbrContributors / 2));

        payable(r.recipient).transfer(r.value);
        r.isProcessed = true;
    }

    function getCampaignDetails()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (minGoal, totalAmount, nbrRequests, nbrContributors, manager);
    }

    function getRequestCounter() public view returns (uint256) {
        return nbrRequests;
    }
}