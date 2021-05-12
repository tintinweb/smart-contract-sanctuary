/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//daehyuk

pragma solidity 0.8.0;

contract Class_10_1 {
    
    struct student {
    
        string  name;
        
    }
    
    student[] students;
    
    function setStudent(string memory _name) public {
    
        students.push(student(_name));
    
    }
    
    function howmanyStudent() public view returns(uint) {
        
        uint i=0;

        for(uint i=0; i<students.length; i++) {
            
            i=students.length;
    
        }
        
        return students.length;
        
    }
    
    function Sophiahere(uint i) public view returns(string memory) {
        
        return students[i].name;
        
    }

}