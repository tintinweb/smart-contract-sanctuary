/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_4 {
    string[] todolist;
    uint count = 0;
    function add(string memory todo) public {
        todolist.push(todo);
    }
    function remove(uint i) public {
        delete todolist[i];
        count++;
    }
    function remain() public view returns(uint){
        return (todolist.length-count);
    }
    function compl() public view returns(uint){
        return count;
    }
    // function get(uint a) public view returns(string memory){
    //     return todolist[a];
    // }
}