/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity 0.8.0;
 
contract TaskContract {
 
     
    Task[] public tasks;
    

      enum Status { Plan, Doing, Test, Done }

      struct Task {
        string id;
        string name; 
        address assigend;
        Status status;
    }


 
    function addTask(string memory name,string memory  id) public {

        Task memory temp;
        temp.assigend = msg.sender;
        temp.id= id;
        temp.name = name;
        temp.status = Status.Plan;
        tasks.push(temp);
    }

    function taskCount() public view returns (uint) {
        return tasks.length;
    }
 
   function getTasks() public view returns (Task[] memory) {
        return (tasks);
    }

 
}