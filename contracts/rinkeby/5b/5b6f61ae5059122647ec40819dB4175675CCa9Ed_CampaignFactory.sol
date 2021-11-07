/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

pragma solidity ^0.4.17;

contract Campaign{
    struct Request{
        string description;
        uint value;
        address recipient;
        bool complete;
        mapping(address=>bool) approvals;
        uint approvalCount;
    }
    
    address public manager;
    uint public minimumContribution;
    mapping(address=>bool) public approvers;
    uint public approversCount;
    Request[] public requests;
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    function Campaign(uint minimum, address campaignCreator) public {
        manager = campaignCreator;
        minimumContribution = minimum;
    }
    
    function contribute() public payable{
        require(msg.value > minimumContribution);
        
        approvers[msg.sender] = true;
        
        approversCount++;
    }
    
    function createRequest(string description, uint value, address recipient) public restricted{
        Request memory newRequest = Request({
            description : description,
            value : value,
            recipient : recipient,
            complete : false,
            approvalCount : 0
        });
        requests.push(newRequest);
    }
    
    function approveRequest(uint index) public{
        Request storage request = requests[index];
        
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
    function finalizeRequest(uint index) public restricted{
        Request storage request = requests[index];
        
        require(!request.complete);
        require(request.approvalCount > (approversCount/2));
        
        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns(uint, uint, uint, uint, address){
       return(
            minimumContribution,
            this.balance,
            requests.length,
            approversCount,
            manager
       );
    }

    function getRequestCount() public view returns(uint){
        return requests.length;
    }
}

contract CampaignFactory{
    address[] deployedCampaigns;
    
    function createCampaign(uint minimum) public{
            address newCampaign = new Campaign(minimum, msg.sender);
            deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (address[]){
        return deployedCampaigns;
    }
}