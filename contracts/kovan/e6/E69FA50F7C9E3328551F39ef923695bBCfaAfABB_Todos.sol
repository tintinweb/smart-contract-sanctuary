/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Todos {
    struct Todo {
        string text;
        bool completed;
    }

    // An array of 'Todo' structs
    Todo public todo;

    function set(Todo memory item) public {
        todo = item;
    }

    // Solidity automatically created a getter for 'todos' so
    // you don't actually need this function.
    function get() public view returns (Todo memory) {
        return todo;
    }

}