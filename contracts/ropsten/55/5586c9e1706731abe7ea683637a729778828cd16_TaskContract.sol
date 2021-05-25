/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity  0.8.0;

contract TaskContract {
 
     
    Task[] public tasks;
    uint256[][] public array2D = [[1, 2, 3], [4, 5, 6]];

      enum Status { Plan, Doing, Test, Done }

      struct Task {
        uint256 id;
        string name;
        address assigend;
        Status status;
    }


 
    function addTask(string memory name) public {

        Task memory temp;
        temp.assigend = msg.sender;
        temp.id= 1;
        temp.name = name;
        temp.status = Status.Plan;
        tasks.push(temp);
    }

    function valueCount() public view returns (uint) {
        return tasks.length;
    }


   
   function getTasks() public view returns (Task[] memory) {
       
       Task[] memory temp = tasks;
        return (temp);
    }

 
}