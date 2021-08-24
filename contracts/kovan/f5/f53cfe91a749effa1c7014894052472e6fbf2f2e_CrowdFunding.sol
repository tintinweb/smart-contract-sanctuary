/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

//SPDX-License-Identifier: GPL-3.int208

pragma solidity >=0.6.0 <0.9.0;


    /*
    *@author Alain Perez
    *@tittle Crowd Funding Contract
    */

contract CrowdFunding{
    
    mapping (address => uint) public contributors;
    address public admin;
    uint public numOfContributors;
    uint public minContribution;
    uint public deadLine; //timestamp
    uint public goal; //monetary goal
    uint public raisedAmount;
    
    /*
    * @notice handles the Spending Request 
    *
    */
    struct Request{
        string description; //description of the spending request
        address payable recipient; //the person that will recieve the amount 
        uint value; //the value that will be send to that person
        bool completed; //by default false so the request is not done untill completed is true
        uint numOfVoters; // the number of voters in the request
        mapping (address => bool) voters; // a mapping containing all voters and their decisions 
    }
    
    //@dev cannot be an array because the latest version of solidity does not allow mappings in arrays.
    mapping (uint => Request) public requests;
    uint public numOfRequest;
    
    /*
    *@params goal of the crowd funding and the deadline in seconds
    *@dev deadline is in seconds and should be converted so in the front end
    */
    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadLine = block.timestamp + _deadline; //added in seconds , we could change in front end apply
        minContribution = 100;
        admin = msg.sender;
    }
    
    
    event ContributeEvent(address _sender, uint value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    /*
    * @notice function that deals with contributions.
    * @dev must be before deadline and has a contribution Minimum, also emits event
    */
    function contribute() public payable{ // must be payable because this function sends money to the contract 
    
        require(block.timestamp < deadLine, "DeadLine has pased"); // Deadline has passed is said when the timestamp is over the designated money
        require(msg.value >= minContribution, "Minimum contribution not met!");
        
        if(contributors[msg.sender] == 0){// checks to see if this is the first time a user contributes
            //this is so we only incriment the numOfContributors once per user
            numOfContributors++;
        }
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        //emits the event
        emit ContributeEvent(msg.sender, msg.value); //emits event
    }
    
    receive() payable external{
        contribute();
    }
    
    /*
    * @notice Returns the balance of the contract
    */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    
    function getRefund() public {
        require(block.timestamp > deadLine && raisedAmount < goal, "The deadline has not arrive, or raised amount was met"); //Goal was not reached and deadline passed
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);
        
        // @dev for more optimal code 
        // payable(msg.sender).tranfer(contributors[msg.sender]);
        
        contributors[msg.sender] = 0; //reste amount from address
    }
    
    /*
    * @dev requires msg.sender to be the admin, add to function as modifier to make work
    */
    modifier onlyAdmin() {
        require( msg.sender == admin,"Only admin can call this function");
        _;
    }
    
    /*
    * @notice creates spending request from parameters
    * @dev uses the newRequest as a reference to update the actual request[numOfRequest] struct 
    * @param decription will hold the request description, recipient holds the address that the balance will be sent to, value is the amount that will be sent
    */
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numOfRequest]; //creates new request
        numOfRequest++;
        
        //initializing the Request struct
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numOfVoters = 0;
        
        //emits the event
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    /*
    * @notice allows users to vote on request
    * @dev users must have contributed and can only vote once, rn they CANT revert their voteRequest
    * @param requestNum is the number of the request
    */ 
    function voteRequest( uint _requestNum) public{
        require(contributors[msg.sender] > 0 , "You must be a contributor to vote");
        Request storage thisRequest = requests[_requestNum]; // this is a call by rence and will change the requests mapping
        
        require(thisRequest.voters[msg.sender] == false, "You can only vote once");
        thisRequest.voters[msg.sender] = true; //votes for the requests
        thisRequest.numOfVoters++;
        
    }
    
    /*
    * @notice sends the fund to the recipient mentioned in the spending request 
    * @dev make sure that the corect request number is passed for a succesfull payment
    */
    function makePayment(uint _requestNum) public onlyAdmin {
        require(raisedAmount >= goal); // makes sure that the goal was met else you cant tranfer funds
        Request storage thisRequest = requests[_requestNum]; //reference to the contract's request strcut
        require(thisRequest.completed == false, "The request has been completed"); // checks if the request was completed
        require(thisRequest.numOfVoters > numOfContributors / 2); //%50 voted for this request
        
        //tranfers funds to the recipient
        thisRequest.recipient.transfer(thisRequest.value);
        //completion of request
        thisRequest.completed = true;
        
        //emits the event
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
    
    
    
    
    
}