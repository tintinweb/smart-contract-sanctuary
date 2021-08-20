/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Kickstarter {
  Campaigns[] public deployedCampaigns;

  function createCampaign(uint256 minimum) public {
    Campaigns newCampaign = new Campaigns(minimum, msg.sender);
    deployedCampaigns.push(newCampaign);
  }

  function getDeployedCampaigns() public view returns(Campaigns[] memory){
    return deployedCampaigns;
  }
}

contract Campaigns {
    struct Request {
      string description;
      uint value;
      address payable recipient;
      bool complete;
      uint approvalCount;
      mapping(address => bool) approvals;
    }

    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    mapping(uint256 => Request) public requests;
    uint256 numRequests;
    uint256 approversCount;

constructor(uint256 minimum, address creator) {
    manager = creator;
    minimumContribution = minimum;
}

modifier managerUser() {
    require(msg.sender == manager);
    _;
}

function setMinimum(uint minimum) public {
    minimumContribution = minimum;
}

function contribute() public payable {
    require(msg.value >= minimumContribution, 'You need to contribute the minimum');
    approvers[msg.sender] = true;
    approversCount++;
}

function createRequest(string memory description, uint256 value, address payable recipient
) public managerUser {
    Request storage r = requests[numRequests++];
    r.description = description;
    r.value = value;
    r.recipient = recipient;
    r.complete = false;
    r.approvalCount = 0;
}

function approveRequest(uint256 index) public {
  Request storage request = requests[index];

  require(approvers[msg.sender]);
  require(!request.approvals[msg.sender]);

  request.approvals[msg.sender] = true;
  request.approvalCount++;
}

function finalizeRequest(uint index) public managerUser {
  Request storage request = requests[index];

  require(request.approvalCount > (approversCount / 2));
  require(!request.complete);

  request.recipient.transfer(request.value);
  request.complete = true;
}
}