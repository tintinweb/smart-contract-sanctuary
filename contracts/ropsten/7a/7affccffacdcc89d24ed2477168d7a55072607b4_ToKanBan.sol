/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.0;

contract ToKanBan{
    uint public id=0;
    address public pm;

    //Events:
    event taskSubmitted(uint task_id, uint funds, string detail, uint claims);
    event taskClaimed(uint task_id,address raiderToClaim, uint _umberOfClaims);
    event assigned(uint  task_id,address raiderApproved);
    event taskForReviewed(uint task_id);
    event taskReviewRevoke(uint _taskid);
    event taskCompleted(uint task_id, uint fundReleased);

    // event execute (bool success, bytes data);
    // event taskRevoked(uint _id,address revokedBy);
    
    //setting the PM
    function setPM(address _pm) public {
        pm = _pm;
    }
    
    // Modfier restricting access to PM
    modifier onlyPM(){
        require(pm == msg.sender,"Only the ");
        _;
    }
    
    //structure of each task request whihc would need to be claimed by Raider and approved by PM
    struct task{
        //task details
        string details; //describing the details of the task
        uint funds; //funds allocated to the task 

        //raider details
        uint claims;
        address payable[] raidersWhoClaimed;
        bool assigned;
        address payable raider;
        bool reviewed;
        bool close;
    }
    
    //task log would record all the task within a Project/contract
    mapping(uint => task) public taskLog;
        
    //Submitting a task 
    function submitTask(uint _funds,string memory _details) public onlyPM{
        taskLog[id].funds= _funds;
        taskLog[id].details= _details;
        taskLog[id].claims=0;
        taskLog[id].reviewed=false;
        taskLog[id].close=false;
        emit taskSubmitted(id, _funds, _details,0);
        id++;
    }

    //Task claimed by a raider
    function claimTask(uint _id) public{
        taskLog[_id].raidersWhoClaimed.push(payable(msg.sender));
        taskLog[_id].claims=taskLog[_id].raidersWhoClaimed.length;
        emit taskClaimed(_id,msg.sender,taskLog[_id].claims);
    }
    
    //View Raider who have claimed a Task
    function viewClaimants(uint _taskid,uint _claimantid) view public returns(address){
        return taskLog[_taskid].raidersWhoClaimed[_claimantid];
    }

    //Raider approved by PM
    function taskAssignedToRaider(uint _taskid,uint _claimantid) public onlyPM{
        taskLog[_taskid].raider = taskLog[_taskid].raidersWhoClaimed[_claimantid];
        taskLog[_taskid].assigned=true;
        emit assigned(_taskid,taskLog[_taskid].raidersWhoClaimed[_claimantid]);
    }
    
    //task sent for review by PM by Raider
    function taskForReview(uint _taskid) public{
        require((taskLog[_taskid].raider==msg.sender || pm == msg.sender), "Dont have the access to send the task for review"); 
        taskLog[_taskid].reviewed=true;
        emit taskForReviewed(_taskid);
    }
    
    //task reviewed and not accepted
    function taskReviewRevoked(uint _taskid) public onlyPM{
        taskLog[_taskid].reviewed=false;
        emit taskReviewRevoke(_taskid);
    }
    
    //task marked complete by PM
    function taskComplete(uint _taskid) public onlyPM{
        require(taskLog[_taskid].reviewed==true,"The task has not been sent for review");
        taskLog[_taskid].funds=0;
        address payable temp=taskLog[_taskid].raider;
        temp.transfer(taskLog[_taskid].funds);
        taskLog[_taskid].close=true;
        emit taskCompleted(_taskid, taskLog[_taskid].funds );
    }
    
     //the contract can receive ether from external contract
    function payContract() external payable {
    }
    
    //checking the balance of the contract
    function getBalance() view public returns(uint){
        return address(this).balance;
    }
}