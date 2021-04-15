/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Use a contract to deploy another contract
contract CampaignFactory {
    address[] public deployedCampaigns;
    
    // Deploys a new instance of a Campaign and stores the resulting address
    function createCampaign(uint minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender)); // msg.sender is the user who click on `Create Campaign`
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

// we are not creating campaign ourselfves directly. We let user to call CampaignFactory.createCampaign() to create a compaign indirectly
contract Campaign {
    
    struct Request {
        string description;
        uint value;
        address payable recipient;          // (vendor) address the money will be sent to
        bool complete;
        uint approvalCount;                 // count only the number of `yes`
        address[] approvalsAddresses;
        mapping(address => uint) approvals; // value = approvals[key], location = keccat256(key, (approvals' slot)) 
        //mapping(address => bool) approvals; // value = approvals[key], location = keccat256(key, (approvals' slot)) 
    }

    //Request[] public requests;
    mapping (uint => Request) public requests;
    uint public requestsCount;

    address public manager;
    uint public minimumContribution;
    //mapping(address => bool) public donors;  // bool default to false
    mapping(address => uint) public donors;

    uint public donorsCount;
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    constructor (uint minimum, address creator)  {
        minimumContribution = minimum;
        manager = creator;
    }

    // Contribute for the campaign
    // 1. Existing contributor -> add to the contribution amount
    // 2. New contributor -> take contribution and increment donors count
    function contribute() public payable {        
        require(msg.value >= minimumContribution);
        if (donors[msg.sender] > 0) {
            uint origContribution = donors[msg.sender];
            donors[msg.sender] = origContribution + msg.value;
        } else {
            donors[msg.sender] = msg.value;
            donorsCount++;
        }
    }

   
    // Struct containing a (nested) mapping cannot be constructed
    function createRequest(string memory description, uint value, address payable recipient) public restricted {
        Request storage newRequest = requests[requestsCount++]; // read: value = mapping var[key]  
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
        //requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index]; // lookup once and ref to instance level `requests`

        //require(donors[msg.sender]);             // make sure the person calling this function has donated
        //require(!request.approvals[msg.sender]); // make sure the person calling this function has not voted before
        require(donors[msg.sender] > 0);                 // make sure the person calling this function has donated
        require(!(request.approvals[msg.sender] > 0));   // make sure the person calling this function has not voted before

        //request.approvals[msg.sender] = true;      // add to the approval smapping for this request in the instance level `requests`
        request.approvals[msg.sender] = donors[msg.sender];      // add to the approval smapping for this request in the instance level `requests`
        request.approvalCount++;
        request.approvalsAddresses.push(msg.sender);
    }
    
    function finalizeRequest(uint index) public payable restricted {
        Request storage request = requests[index];
        uint totalVotedValue;
        for (uint i = 0; i < request.approvalCount; i++) {
            totalVotedValue += request.approvals[request.approvalsAddresses[i]];
        }
        require(totalVotedValue > (address(this).balance / 2) && request.approvalCount > (donorsCount / 2)); // over half of the donors has approved
        //require(request.approvalCount > (donorsCount / 2)); // over half of the donors has approved
        require(!request.complete);                // make sure the request has not been completed

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns ( uint, uint, uint, uint, address ) {
        return (
            minimumContribution,
            address(this).balance,
            requestsCount,
            donorsCount,
            manager
        );
    } 

    function getEnoughVote(uint index) public view returns (bool, uint, uint, uint, uint) {
        Request storage request = requests[index];
        uint totalVotedValue;
        for (uint i = 0; i < request.approvalCount; i++) {
            totalVotedValue += request.approvals[request.approvalsAddresses[i]];
        }
        bool enough = totalVotedValue > (address(this).balance / 2) && request.approvalCount > (donorsCount / 2);
        return (
            enough, totalVotedValue, address(this).balance, request.approvalCount, donorsCount
        );
    }
}