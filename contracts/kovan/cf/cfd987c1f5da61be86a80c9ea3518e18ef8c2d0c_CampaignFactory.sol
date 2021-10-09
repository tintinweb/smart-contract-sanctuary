/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity ^0.4.25;

contract CampaignFactory{
    address[] public deployedCampaigns;
    function createCampaign(uint minimum)public{
        address newCampaign=new Campaign(minimum,msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    function getDeployedCampaigns()public view returns(address[]){
        return deployedCampaigns;
    }
}


//not voting means no vote
contract Campaign{
    address public manager;
    mapping(address=>bool)public approvers;
    uint public approversCount;
    uint public minimumContribution;
    modifier restricted(){
        require(msg.sender==manager);
        _;
    }

    struct Request{
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        //approvalCount only count number of yes votes
        mapping(address=>bool) approvals;
    }
    Request [] public requests;

    constructor(uint minimum,address CampaignCreator) public{
        manager=CampaignCreator;
        minimumContribution=minimum;
    }
    function contribute() public payable{
        require (msg.value >= minimumContribution);
        approvers[msg.sender]=true;
        approversCount++;
    }


    function createRequest(string description,uint value,address recipient)
    public restricted
    {
      Request memory newRequest=Request({
          description:description,
          value:value,
          recipient:recipient,
          complete:false,
          approvalCount:0
      });
      //Request(description,value,recipient,false);
        requests.push(newRequest);


    }
    function approveRequest(uint index) public
    {
        Request storage request=requests[index];
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        request.approvals[msg.sender]=true;
        request.approvalCount++;
    }
    function finalizeRequest(uint index) public restricted
    {
        Request storage request=requests[index];
        require(request.approvalCount>(approversCount/2));
        require(!request.complete);
        request.complete=true;
        //uint etherValue = request.value/(1 ether);
        //uint ether_to_wei=request.value*(1 ether);
        request.recipient.transfer(request.value);

        }
      function getSummary() public view returns(uint,uint,uint,uint,address){
        return(
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
      }
      function getRequestCount() public view returns(uint){
        return requests.length;
      }
}