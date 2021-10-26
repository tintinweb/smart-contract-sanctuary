/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity >=0.6.0;

contract Crowdsale{
    uint public noOfContributors;
    address public admin;
    mapping(address=>uint)public contributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;
    
    event Contributeevent(address _sender,uint _value);
    event Requestevent(string description,address _recepient,uint _value);
    event Paymentevent(address _recepient,uint _value);
    
    struct Request{
        string description;
        address payable recepient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
        
        
    }
        mapping(uint=> Request) public Requests;
        uint public numRequests;
        
    constructor(uint _goal, uint _deadline){
        deadline=block.timestamp + _deadline;
        goal=_goal;
        minimumContribution = 100 wei;
        admin=msg.sender;
        
    }
    modifier onlyAdmin() {
        require(msg.sender==admin,"Only admin can call this function");
        _;
    }
 
    
    function contribute() public payable {
        require(block.timestamp<deadline,"The Deadline is passed");
        require(msg.value>=minimumContribution,"minimum Contribution not met");
        
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
        
        emit Contributeevent(msg.sender,msg.value);
    }
    receive() payable external{
        contribute();
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function getRefund() public{
        require(block.timestamp>deadline && raisedAmount<goal);
        require(contributors[msg.sender]>0);
        
        address payable recepient = payable(msg.sender);
        uint value= contributors[msg.sender];
        recepient.transfer(value);
        
        contributors[msg.sender]=0;
    }
       function createRequest(string memory _description,address payable _recepient,uint _value) public onlyAdmin{
       Request storage newRequest = Requests[numRequests]; 
       numRequests++;
       newRequest.description=_description;
       newRequest.recepient=_recepient;
       newRequest.value=_value;
       newRequest.completed=false;
       newRequest.noOfVoters=0;
       emit Requestevent(_description,_recepient,_value);
    }
    
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor to vote");
        
        Request storage thisRequest=Requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    } 
    
    function makePayment(uint _requestno) public onlyAdmin{
        require(raisedAmount>=goal,"Goal is not met");
        Request storage thisRequest = Requests[_requestno];
        require(thisRequest.completed==false,"This request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2);
        
        thisRequest.recepient.transfer(thisRequest.value);
        thisRequest.completed=true;
        
        emit Paymentevent(thisRequest.recepient,thisRequest.value);
    }
}