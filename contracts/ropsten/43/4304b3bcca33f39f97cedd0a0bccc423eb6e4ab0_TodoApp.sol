/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity ^0.5.0;

contract TodoApp {
    uint num = 0;
    
    struct Todo {
        uint taskid;
        string task;
        bool flag;
    }
    
    Todo[] public todos;
    
    mapping (uint => address) public todoToOwner;
    
    mapping (address => uint) public ownerTodoCount;
    
    function TodoCreate(string memory _task) public {
        uint id = todos.push(Todo(num, _task, true)) - 1;
        todoToOwner[id] = msg.sender;
        ownerTodoCount[msg.sender]++;
        num++;
    }
    
    function TodoRemove(uint id) external {
        require(todoToOwner[id] == msg.sender);
        require(todos[id].flag);
        todos[id].flag = false;
    }
    
    function getTodosByOwner(address owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerTodoCount[owner]);
        uint counter = 0;
        for (uint i = 0; i < todos.length; i++) {
            if (todoToOwner[i] == owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}