/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

//young do Jang

pragma solidity 0.8.0;

contract Likelion_5 {
    struct TodoList {
        string Todothing;
    }
        uint F;
        uint a;
    
    TodoList [] todolist;
    
    function setthing(string memory _Todothing) public {
        todolist.push(TodoList(_Todothing));
        
         for(uint i =0; i < todolist.length; i++) {
                a += 1;
    }
    }
    function Finished(string memory _Todothing) public {
        todolist.pop();
    }
    function AA() public {
        for(uint i =0; i < todolist.length; i++) {
                F += 1;
    }
    }
    function remainingthing()public view returns(uint,uint) {
        return(F,a -F);
    }
}