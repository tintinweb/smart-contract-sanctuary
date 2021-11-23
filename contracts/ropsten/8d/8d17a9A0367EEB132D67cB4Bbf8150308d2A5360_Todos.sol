//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./Todo.sol";

contract Todos {
    Todo[] public todos;

    function create(string memory _text) public {
        // 3 ways to initialize a struct
        // 1. unamed argument
        todos.push(Todo(_text, false));

        // 2. named argument
        // todos.push(Todo({text: _text, completed: false}));

        // 3. assign fields
        // Todo memory todo;
        // todo.text = _text;
        // todo.completed initialized to false
        // todos.push(todo);
    }

    function getLength() public view returns (uint256 length) {
        return todos.length;
    }

    function get(uint _index) public view returns (string memory text, bool completed) {
        Todo storage todo = todos[_index];
        return (todo.text, todo.completed);
    }

    function update(uint _index, string memory _text) public {
        Todo storage todo = todos[_index];
        todo.text = _text;
    }

    function toggleCompleted(uint _index) public {
        Todo storage todo = todos[_index];
        todo.completed = !todo.completed;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

struct Todo {
    string text;
    bool completed;
}