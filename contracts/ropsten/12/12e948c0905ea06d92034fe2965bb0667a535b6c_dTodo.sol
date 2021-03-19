/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity >=0.5.0 <0.6.0;

contract dTodo {
    struct Todo {
        string content;
        uint time;
        bool completed;
    }
    
    event TodoCreated(uint todoId, string content, uint time, bool completed);
    event TodoCompleted(uint todoId, string content, uint time, bool completed);
    
    mapping (address => Todo[]) public todos;
    
    function createTodo(string memory _content) public {
        uint id = todos[msg.sender].push(Todo(_content, now, false)) - 1;
        emit TodoCreated(id, _content, now, false);
    }
    
    function completeTodo(uint _id) public {
        require(todos[msg.sender].length > _id);
        Todo storage fetchedTodo = todos[msg.sender][_id];
        fetchedTodo.completed = true;
        emit TodoCompleted(_id, fetchedTodo.content, fetchedTodo.time, true);
    }
}