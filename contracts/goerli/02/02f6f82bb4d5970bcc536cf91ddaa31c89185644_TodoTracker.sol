/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title TodoTracker
 * @dev Keep track of ToDos
 */
contract TodoTracker {

    struct Todo {
        uint todoID;
        string workDescription;
        address doneVerifier;
        bool done;        
    }

    /**
    * Todo has been set as done
    */
    event TodoDone(
        uint indexed todoID,
        address indexed doneVerifier,
        string workDescription,
        bool deleted
    );

    /**
    * @notice Todo has been set as done
    * @param doneVerifier Who will need to report this ToDo as done
    * @param workDescription What to do
    */
    event TodoAdded(
        uint indexed todoID,        
        address indexed doneVerifier,
        string workDescription
    );

    event TraceString(string trace);
    event TraceInt(uint trace);

    //Address trying to verify a Todo as done was not who was expected
    error InvalidVerifier(address attemptedVerifier, address validVerifier);

    ///Could not find the ToDo
    error TodoNotFound(uint todoID);

    uint private numTodos;
    mapping (uint => Todo) private todos;

    /**
     * @dev Add a Todo
     * @param workDescription value to store
     */
    function addTodo(string calldata workDescription) external returns (uint todoID)  {
        numTodos++;
        todoID = numTodos;
        todos[todoID] = Todo({todoID: todoID, workDescription: workDescription, doneVerifier: msg.sender, done: false});
        emit TodoAdded(todos[todoID].todoID, todos[todoID].doneVerifier, todos[todoID].workDescription);
    }

    /**
     * @dev Report Todo done
     * @param todoID ID of Todo
     */
    function completeTodo(uint todoID, bool deleteTodo) external {
        Todo storage todo = todos[todoID];
        
        //emit TraceInt(todo.todoID);

        if(todo.todoID == 0){
            revert TodoNotFound(todoID);
        }

        if(!(todo.doneVerifier == msg.sender)){
            revert InvalidVerifier(msg.sender, todo.doneVerifier);
        }
        
        string memory eventWorkDescription = todo.workDescription;
        if(deleteTodo){
            delete todos[todoID];
        } else {
            todo.done = true;
        }

        emit TodoDone(todoID, msg.sender, eventWorkDescription, deleteTodo);
    }


    /**
     * @dev Return value 
     * @return value of 'number'
     */
    /*function retrieve() public view returns (uint256){
        return number;
    }*/
}