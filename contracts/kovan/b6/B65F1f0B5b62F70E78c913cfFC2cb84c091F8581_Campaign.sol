//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Campaign {
  struct Request {
    string description;
    uint value;
    address recipient;
    bool complete;
    uint approvalCount;
    mapping(address => bool) approvals;
  }

  address public manager;
  uint public minimumContribution;
  mapping(address => bool) public approvers;
  uint numRequests;
  mapping(uint => Request) public requests;

  modifier restricted() {
    require(msg.sender == manager, 'manager only');
    _;
  }

  modifier isApprover() {
    require(approvers[msg.sender] == true, 'approvers only');
    _;
  }

  constructor(uint minimum) {
    manager = msg.sender;
    minimumContribution = minimum;
  }

  function contribute() public payable {
    require(msg.value > minimumContribution, 'not enough contribution');
    approvers[msg.sender] = true;
  }

  function createRequest(
    string calldata description,
    uint value,
    address recipient
  ) public restricted {
    Request storage r = requests[numRequests++];
    r.description = description;
    r.value = value;
    r.recipient = recipient;
    r.complete = false;
    r.approvalCount = 0;
  }

  function approveRequest(uint requestId) public isApprover {
    Request storage request = requests[requestId];
    require(!request.approvals[msg.sender], 'already voted');
    request.approvals[msg.sender] = true;
    request.approvalCount++;
  }
}

