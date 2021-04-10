/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract CampaignFactory {
    Campain[] public deployedCampaigns;
    
    function createCampaing(uint minimum) public {
        //address newCampaign = address(new Campain(minimum, msg.sender)); 
        Campain newCampaign = new Campain(minimum, msg.sender); // fix baddress for casting
        deployedCampaigns.push(newCampaign);
    }
    // function getDeployedCampaigns() public view returns (address[]) {
    function getDeployedCampaigns() public view returns (Campain[] memory) { // adds memory
        return deployedCampaigns;
    }
}


contract Campain  {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    uint numRequests;
    Request[] public requests;
    
    address public manager;
    uint public minumumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    
    modifier restricted() {
        require(msg.sender == manager, "Access restricted");
        _;
        
    }
    
    constructor(uint minimum, address creator) public {
        manager = creator;
        minumumContribution = minimum; // amount in wei
    }
    
    
    function contribute() public payable {
        require(msg.value > minumumContribution, "Minimum contribution error");
        approvers[msg.sender] = true;
        approversCount++;
    }
    
    function createRequest(string memory description, uint  value, address payable recipient) public restricted  {
        Request storage r = requests[numRequests++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;


        // Old ways before 0.7.0
        // Request storage newRequost = Request({
        //     description: description,
        //     value: value,
        //     recipient: recipient,
        //     complete: false,
        //     approvalCount: 0
        // });
        // requests.push(newRequost);
    }
    
    function approveRequest(uint index) public {
        Request storage r = requests[index];
        
        require(approvers[msg.sender]);
        require(!r.approvals[msg.sender]);
        
        r.approvals[msg.sender] = true;
        approversCount++;
    } 
    
    function finalizeRequest(uint index) public payable restricted  {
        Request storage r = requests[index];
        
        require(!r.complete);
        require( r.approvalCount > (approversCount / 2) );
        
        r.recipient.transfer(r.value);
        r.complete = true;
        
        
        
    }

}