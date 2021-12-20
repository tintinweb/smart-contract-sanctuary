/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;
contract Todos {
    struct Todo {
        string text;
        bool completed;
    }
    //  An array of 'Todo' structs
    Todo[] public todos;
    //  3 ways to init a struct
    function create(string memory _text) public  {
        //  call constructor
        todos.push(Todo(_text,false));
        //  key value mapping
        todos.push(Todo({text: _text, completed: false}));
        //  intit an empty struct and update it
        Todo memory todo;
        todo.text = _text;
        //  todo.completed default false
        todos.push(todo);
    }
    //  update text
    function update(uint _index, string memory _text) public {
        //  Todo storage todo = todos[_index];
        //  todo.text = _text;
        todos[_index].text = _text;
    }
    //  update completed
    function toggleCompleted(uint _index) public {
        Todo storage todo = todos[_index];
        todo.completed = !todo.completed;
    }
}