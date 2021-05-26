/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity 0.8.0;
 
contract TaskContract {
 
     
    
    string[] public tasksIds;
    Task[] public tasksArray;

     mapping(string => Task) public tasks;
    

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
        temp.name = name;
        temp.id = id ;
        temp.status = Status.Plan;

        tasksIds.push(id);
        tasksArray.push(temp);
        tasks[id]= temp;
    }


 


    function startTask(string memory id)  public returns (bool){


           tasks[id].status = Status.Doing;
           tasks[id].assigend = msg.sender;
       

        return true;
        
    }

    function taskCount() public view returns (uint) {
        return tasksIds.length;
    }
 
   function getTasks() public  returns (Task[] memory) {

       
       for(uint i=0;i<tasksIds.length;i++){
           tasksArray[i] = tasks[tasksIds[i]];
       }

       return tasksArray;
       
    }

 
}