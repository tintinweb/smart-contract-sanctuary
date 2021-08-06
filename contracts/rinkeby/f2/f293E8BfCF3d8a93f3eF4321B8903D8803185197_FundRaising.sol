/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-26
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
    address payable immutable public fundRecipient;

     event Donation(
        address _from,
        uint256 _value,
	uint256 _raisedAmount
    );
    
    event GoalReached(
         uint256 _raisedAmount
    );
    
    constructor(uint _deadline,uint _goalInt, uint _goalFloat, address creator, address _fundRecipient){
        minimumContribution = 0;
        deadline= block.number + _deadline;
        goal=_goalInt*1e18 + _goalFloat;
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
        require(block.number > deadline); // deadline is reached
        require(raisedAmount < (goal * 7 / 10)); // raisedAmount is less than minimal goal, minimal goal is 70% of goal
        require(contributions[msg.sender] > 0); // you've donated something
        
        
        payable(msg.sender).transfer(contributions[msg.sender]);
        raisedAmount -= contributions[msg.sender]; // is raisedAmount neccessary?
        contributions[msg.sender] = 0;
       
       
    }
    
    function redirectFunds(address newRecipient) public notCompleted onlyAdmin {
        require(block.number > deadline + 40320);
        payable(newRecipient).transfer(address(this).balance);
        completed = true;
        
    }
    
    function finalPayment() public payable notCompleted {
         require(address(this).balance >= (goal * 7 / 10)); // So this is to ensure us that we can call finalPayment when minimalGoal is reached
         fundRecipient.transfer(raisedAmount);
         completed = true;
    }
   
}