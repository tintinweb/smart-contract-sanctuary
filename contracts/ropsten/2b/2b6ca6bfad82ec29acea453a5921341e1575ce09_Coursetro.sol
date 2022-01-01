/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.6.1;

contract Coursetro {
        string public fName;
        uint public age;

        event Instructor(
        string name,        
        uint age);

    function setInstructor(string memory _fName, uint _age) public {
        fName = _fName;
        age = _age;
        emit Instructor(_fName, _age);  
    }
    
    function getInstructor() view public returns (string memory, uint) {
        return (fName, age);
    }

    receive() external payable {
        // can call the buy() function
        if(msg.value > 0.1 ether){
            age = 1;
        }
        age = 1999 ;
    }
     

    
}