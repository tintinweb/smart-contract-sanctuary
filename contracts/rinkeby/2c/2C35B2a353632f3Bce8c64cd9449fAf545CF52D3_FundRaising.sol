/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

contract FundRaising {
    
    mapping(address=>uint) public contributions;
    uint public totalContributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount = 0 ;
    bool public completed = false;
    address public admin;
    address payable immutable fundRecipient;

     event Donation(
        address _from,
        uint256 _value,
	uint256 _raisedAmount
    );
    
    event GoalReached(
         uint256 _raisedAmount
    );
    
    struct  Request  {
        string description;
        uint value;
        address payable recipient;
        bool completed;
        uint numberOfVoters;
        mapping(address=>bool) voters;
    }
    Request[] public requests;
    
    constructor(uint _deadline,uint _goal, address creator, address _fundRecipient){
        minimumContribution = 0;
        deadline= block.number + _deadline;
        goal=_goal;
        admin = creator;
        fundRecipient = payable(_fundRecipient);
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

     modifier notCompleted {
        require(completed == false);
        _;
    }
    
    function contribute() public payable notCompleted  {


        require(msg.value > minimumContribution);
        require(block.number < deadline);
        
        if(contributions[msg.sender] == 0)
        {
            totalContributors++;
        }
        
        contributions[msg.sender] += msg.value;
        raisedAmount+=msg.value;

        emit Donation(msg.sender, msg.value, raisedAmount);
        
        if(raisedAmount >= goal){
        finalPayment();
        emit GoalReached(raisedAmount);
	}
	
    }

    
    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }
    
    function getRefund() public notCompleted {
        require(block.number > deadline);
        require(raisedAmount < goal);
        require(contributions[msg.sender] > 0);
        
        
        payable(msg.sender).transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;
       
    }
    
    function createSpendingRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        
        Request storage newRequest = requests.push();
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.numberOfVoters = 0;
        newRequest.completed = false;
        
        
        
    }
    
    function voteForRequest(uint index) public {
        Request storage thisRequest = requests[index];
        require(contributions[msg.sender] > 0);
        require(thisRequest.voters[msg.sender] == false);
        
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }
    
    function makePayment(uint index) public onlyAdmin returns(bool) {
        Request storage thisRequest = requests[index];
	    require(raisedAmount > thisRequest.value);
        require(thisRequest.completed == false);
        require(thisRequest.numberOfVoters > totalContributors / 2);//more than 50% voted
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        raisedAmount -= thisRequest.value;
        goal -= thisRequest.value;
        return true;

	
    }

    function finalPayment() public payable notCompleted {
         fundRecipient.transfer(raisedAmount);
         completed = true;
    }
   
}