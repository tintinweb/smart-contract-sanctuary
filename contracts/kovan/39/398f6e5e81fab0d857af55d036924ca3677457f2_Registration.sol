/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity 0.8.7;

contract Registration {
    struct Student {
        string name;
        uint256 rollNo;
    }
    
    Student[] public students;
    address public collegeAuthority;
    
    constructor() {
        collegeAuthority = msg.sender;
    }
    
    function register(string memory studentName, uint256 studentRollNo) public payable {
        require(msg.value == 0.01 ether, "Please send proper amount, i.e. 0.01 ether");
        
        students.push(Student({
            name: studentName,
            rollNo: studentRollNo
        }));
    }
    
    function getNumberOfRegistrations() public view returns (uint256) {
        return students.length;
    }
    
    function withdraw() public {
        require(msg.sender == collegeAuthority, "only college person can withdraw");
        
        payable(msg.sender).transfer(address(this).balance);
    }
}