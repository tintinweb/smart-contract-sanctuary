/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;


contract taskcontract {
    uint  nextid;
    struct task{
        uint id;
        string name;
        string description;    
    }

    task[] tasks;

    function createtask(string memory _name,string memory _description) public { 
        tasks.push(task(nextid, _name, _description));
        nextid++;
    }
    function findindex (uint _id) internal view  returns (uint) {
        for (uint i=0; i < tasks.length; i ++){
            if(tasks[i].id==_id) {
                return i;
            }
        

       } revert('task no encontrado');
    }

    function readtask(uint _id) public view returns (uint, string memory, string memory) {
      uint index = findindex(_id);
      return (tasks[index].id, tasks[index].name, tasks[index].description);
    }

    function updatetasks(uint _id, string memory _name, string memory _description) public{
        uint index = findindex(_id);
        tasks[index].name = _name;
        tasks[index].description = _description;
    }

    function deletetask(uint _id) public {
        uint index = findindex(_id);
        delete tasks[index];
    }
}