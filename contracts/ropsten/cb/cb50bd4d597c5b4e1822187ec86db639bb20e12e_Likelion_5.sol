/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.8.0;


contract Likelion_5 {
    //YunJun Lee
    string [] todos;
    string [] dones;
    
    function pushTodo(string memory d) public{
        todos.push(d);
    }
    
    function removeTodo(string memory d) public{

        dones.push();
        todos.pop();

    }
    
    
    
    function getTodos() public view returns(uint, uint){


        return (todos.length, dones.length);
    }



}