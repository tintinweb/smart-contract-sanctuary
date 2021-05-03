/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_5 {
    
    string[] todo_list;
    uint pastcnt=0;
    
    function addList(string memory _add) public {
        todo_list.push(_add);
    }
    
    /*function deleteList(string memory _delete) public {
        for(uint i = todo_list.length; i>0; i--){
            if(keccak256(abi.encodePacked(todo_list[i])) == keccak256(abi.encodePacked(_delete))) {
                delete todo_list[i];
            }
        }
        pastcnt--;
    }*/
    
    function countList() public view returns(uint) {
        return todo_list.length;
    }
    
    function countPastList() public view returns(uint) {
        return pastcnt;
    }
    
}