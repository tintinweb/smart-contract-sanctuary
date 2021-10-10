/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract OurTodoApp {

    string public appName = "Our Todo App";

        struct Todo{
            uint id;
            string content;
            bool completed;
            uint date;
        }

        mapping(address=>uint) internal totalTodoItems;
        mapping(address=>mapping(uint => Todo)) internal TodoList;

        event TodoCreated(
            uint id,
            bool completed
        );
        event TodoCompleted(
            uint _id,
            bool completed
        );

        function getTotalTodo()public view returns(uint){
            return totalTodoItems[msg.sender];
        }

        function getTodo(uint _id) public view returns(Todo memory){
            Todo memory _todo = TodoList[msg.sender][_id];
            return _todo;
        }

        function createTodo(string memory _content) public{

            totalTodoItems[msg.sender] += 1;
            TodoList[msg.sender][totalTodoItems[msg.sender]] = Todo(totalTodoItems[msg.sender],_content,false,block.timestamp);
            emit TodoCreated(totalTodoItems[msg.sender],false);
        }

        function setTodoCompleted(uint _id) public {
            Todo memory _todo = TodoList[msg.sender][_id];
            _todo.completed = !_todo.completed;
            TodoList[msg.sender][_id] = _todo;

            emit TodoCompleted(_id,_todo.completed);

        }
}