/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

//im yuri 4-2)
pragma solidity 0.8.0;

contract Likelion_4 {
    string grade;
    uint students;
    uint totalscore;
    uint[] scores;
    
    function setGrade(uint score) public {
        if(score >= 80) {
            grade = "A";
        } else if(score >= 70) {
            grade = "B";
        } else if(score >= 50) {
            grade = "C";
        } else {
            grade = "F";
        }
        
        students++;
        totalscore += score;
    }
    
    function getnumber() public view returns(uint) {
        return totalscore/students;
    }
    
}