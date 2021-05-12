/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_11{
    string[] studentList =[ "Ava","Becky","Charles","Devy","Elice","Fabian"];
    
    function totalStudent() public view returns(uint) {
        return studentList.length;
    }
    
    function addStudent() public returns(string memory) {
        if(studentList.length < 9) {
            studentList.push("James");
            studentList.push("Harry");
            return "Complete";
        }
        else return "Fail";
    }
    
    function checkStudent() public view returns(string memory) {
        for(uint i=0; i<studentList.length; i++) {
            if(keccak256(abi.encodePacked(studentList[i])) == keccak256(abi.encodePacked("Sophie"))) {
                return "Exist";
            }
        }
        return "There is no Sophie";
    }
    
    function checkCanAdd() public view returns(uint, uint) {
        return (studentList.length, 10-studentList.length);
    }
    
    function _getStudentName(uint a) public view returns(string memory) {
        return studentList[a-1];
    }
    
    function _AddSophie() public returns(string memory) {
        if(studentList.length < 10) {
            studentList.push("Sophie");
            return "Complete";
        }
        else return "Fail";
    }
}