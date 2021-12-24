/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    uint numRequests;
    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;

    modifier restricted() {
        require(msg.sender == manager,"This function is restricted");
        _;
    }

    constructor(uint minimum) {
        manager = msg.sender;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution, "over value of miniContribution");
        approvers[msg.sender] = true;
    }

    function createRequest(address recipient) external restricted {            
        Request storage r = requests[numRequests];
        r.value = 10;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;
        r.approvals[msg.sender] = true;
        numRequests = numRequests++;
    }

    function approveRequest(uint index) external {
        Request storage request = requests[index];
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
}