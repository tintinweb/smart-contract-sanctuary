/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract TodoList {
    // This will be the contract for the Todo list.
    // It will be able to do the following:
    // 1. createTodo(string): creates a todo item
    // 2. done(uint): marks a todo as done. Emits an event.
    // 3. pause(): pauses the contract. Only the contract owner can invoke this function.
    // 4. unpause(): unpauses the contract. Only the contract owner can invoke this function. 

    struct Todo {
        string name;
        bool done;
        address owner;
    }
    address contractOwner;
    bool public paused;
    Todo[] public todos;

    constructor() {
        contractOwner = msg.sender;
        paused = false;
    }

    event TodoDone(string _name, address _owner);

    modifier onlyContractOwner {
        require(msg.sender == contractOwner, 'can only be called by contract owner');
        _;
    }

    function createTodo(string memory _name) public {
        require(!paused, 'contract currently paused');
        Todo memory newTodo = Todo({
            name: _name,
            done: false,
            owner: msg.sender
        });
        todos.push(newTodo);
    }

    function done(uint _index) public {
        require(!paused, 'contract currently paused');
        Todo storage todo = todos[_index];
        require(msg.sender == todo.owner, 'can only be marked done by owner');
        todo.done = true;
        emit TodoDone(todo.name, todo.owner);
    }

    function pause() public onlyContractOwner {
        paused = true;
    }

    function unpause() public onlyContractOwner {
        paused = false;
    }
}