/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.0;


library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Kanban is ReentrancyGuard{
    //Events
    event taskSubmitted(uint task_id, uint funds, string title, string detail);
    event taskRequested(uint task_id, address raider, uint requestId);
    event assigned(uint  task_id,address raiderApproved);
    event taskForReviewed(uint task_id);
    event taskReviewRevoke(uint task_id);
    event taskCompleted(uint task_id, uint fundReleased);

    //Globals
    using Counters for Counters.Counter;
    Counters.Counter private _taskIds;
    address public pm;
    address public funder; //address that transfer ether to the contract
    uint public contractBalance=0; //to check if there is enough fund inthe contract
    
    //setting the PM
    function setPM(address _pm) public {
        require(pm == address(0), "The PM has already been set");
        pm = _pm;
    }
    
    //the contract can receive ether from external contract
    function payContract(uint amount) external payable {
        require(amount == msg.value, "Incorrect amount sent");
        funder = msg.sender;
        contractBalance += msg.value;    
    }

    //task log would record all the task within a Project/contract
    mapping(uint => task) public taskLog;

    //structure of each task which would need to be requested by Raider and approved by PM
    struct task{
        //task details
        string title; //title of the task
        string details; //describing the details of the task
        uint funds; //funds allocated to the task

        //raider details
        address payable[] requests;
        bool assigned;
        address payable raider;
        bool reviewed;
        mapping(address => bool) approvals;
        bool closed;
    }

    // Modfier restricting access to PM
    modifier onlyPM(){
        require(pm != address(0), "This function requires a PM to have been set");
        require(pm == msg.sender, "Only the PM can call this function");
        _;
    }
    
    //Deprecating this since PM is getting automatically assigned in constructo 
    /*setting the PM
    function setPM(address _pm) public {
        require(pm == address(0), "The PM has already been set");
        pm = _pm;
    }*/

    //Submitting a task
    function submitTask(uint _funds, string memory _title, string memory _details) public payable onlyPM {
        require(pm != address(0), "This function requires a PM to have been set");
        require(_funds <= contractBalance,"Not enough funds"); //checking if the contract has enough funds before allocating funds to the task
        uint id = _taskIds.current();

        taskLog[id].funds= _funds;
        taskLog[id].title= _title;
        taskLog[id].details= _details;
        taskLog[id].reviewed=false;
        taskLog[id].closed=false;
        taskLog[id].approvals[pm]=false;
        taskLog[id].approvals[funder]= false;
        
        contractBalance=contractBalance-_funds;
        _taskIds.increment();
        emit taskSubmitted(id, _funds, _title, _details);
    }

    //Task requested by a raider
    function requestTask(uint _id) public{
        taskLog[_id].requests.push(payable(msg.sender));
        uint requestId = taskLog[_id].requests.length;
        emit taskRequested(_id, msg.sender, requestId);
    }

    //View Raider who have requested a Task
    function viewRequests(uint _taskid, uint _requestId) view public returns(address, uint){
        return (taskLog[_taskid].requests[_requestId], taskLog[_taskid].funds);
    }

    //Raider approved by PM
    function assignTaskToRaider(uint _taskid, uint _requestId) public onlyPM{
        taskLog[_taskid].raider = taskLog[_taskid].requests[_requestId];
        taskLog[_taskid].assigned=true;
        emit assigned(_taskid,taskLog[_taskid].requests[_requestId]);
    }

    //task sent for review by PM by Raider
    function taskForReview(uint _taskid) public{
        require((taskLog[_taskid].raider==msg.sender), "Dont have the access to send the task for review");
        taskLog[_taskid].reviewed=true;
        emit taskForReviewed(_taskid);
    }

    //task reviewed and not accepted
    function taskReviewRevoked(uint _taskid) public {
        require(pm != address(0), "This function requires a PM to have been set");
        require(pm==msg.sender || funder == msg.sender,"You are not the approver");
        taskLog[_taskid].reviewed=false;
        emit taskReviewRevoke(_taskid);
    }

     //task Approved by PM and funder
     function taskApproved(uint _taskid) public nonReentrant{
        require(pm != address(0), "This function requires a PM to have been set");
        require(taskLog[_taskid].reviewed==true,"The task has not been sent for review");
        require(pm==msg.sender || funder == msg.sender,"You are not the approver");
        taskLog[_taskid].approvals[msg.sender]= true;
            
        //if both M and funder has approved then the task will be marked complete    
        if(taskLog[_taskid].approvals[funder]== true && taskLog[_taskid].approvals[pm]== true){
            uint funds = taskLog[_taskid].funds;
            address payable raider = taskLog[_taskid].raider;

            raider.transfer(funds);
            taskLog[_taskid].funds=0;
            taskLog[_taskid].closed=true;
            emit taskCompleted(_taskid, funds);    
        }
    }
}