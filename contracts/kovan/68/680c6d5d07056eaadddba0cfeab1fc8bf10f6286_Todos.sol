/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;


contract Todos {
    // 宣告 Todo 結構
    struct Todo {
        string text;
        bool completed;
    }

    // 宣告為 Todo[] 陣列
    Todo[] public todos;

    function create(string memory _text) public {

        // 初始化結構有 3 種方式
        // 1. 像 function 般賦值
        todos.push(Todo(_text, false));

        // 2. key value 映射
        todos.push(Todo({text: _text, completed: false}));

        // 3. 先建立 default(Todo) 物件再賦值
        Todo memory todo;
        todo.text = _text;
        // todo.completed, default(T)=false

        todos.push(todo);
    }
    
    // 因為 todos 陣列可見度為 public, 
    // Solidity 會因此而幫 todos 建立一個 getter function
    // 所以其實不需要 get() function 了
    function get(uint _index) public view returns (string memory text, bool completed) {
        Todo storage todo = todos[_index];
        return (todo.text, todo.completed);
    }

    // 更新 Todos[_index].text
    function update(uint _index, string memory _text) public {
        Todo storage todo = todos[_index];
        todo.text = _text;
    }

    // 更新 Todos[_index].completed
    function toggleCompleted(uint _index) public {
        Todo storage todo = todos[_index];
        todo.completed = !todo.completed;
    }
}