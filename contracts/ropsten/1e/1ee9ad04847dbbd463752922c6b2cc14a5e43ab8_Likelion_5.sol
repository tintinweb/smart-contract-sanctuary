/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// Seo Sangcheol

pragma solidity >=0.7.0 <0.9.0;

contract Likelion_5 {
    string[] todo;
    string[] listdel;
    
    function add(string memory a) public returns(string memory) {
        todo.push(a);
    }
    
    function del(string memory b) public returns(string memory) {
        todo.push(b);
        listdel.push(b);
    }
    
    function todocnt() public view returns(uint) {
        return todo.length;
    }
    
    function delcnt() public view returns(uint) {
        return listdel.length;
    }
}