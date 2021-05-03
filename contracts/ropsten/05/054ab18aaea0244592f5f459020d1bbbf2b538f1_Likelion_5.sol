/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.8.0;

contract Likelion_5 {
    struct student {
        string work;
    }
    
    student[] students;
    
    function setStudent(string memory _work) public {
        students.push(student(_work));
    }
   
}