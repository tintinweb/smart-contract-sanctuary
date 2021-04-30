/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// Younwoo Noh

//4_2 test

pragma solidity 0.8.0;

contract Likelion_4_2 {
    string grade;
    uint[] scores;
    uint a;
    uint students;
    
    function setGrade(uint score) public {
        if(score >= 80) {
            grade = "A";
        } else if (score >= 70) {
            grade ="B";
        } else if (score >= 50) {
            grade ="C";
        } else {
            grade ="F";
        }
        
        scores.push(score);
        students++;
    }    
        
    function getAverage() public view returns(uint) {
        uint a = 0;
        for(uint i = 0; i<scores.length; i++) {
            a = a + scores[i];
        }
        return (a/scores.length);
    }
    function getCount() public view returns(uint) {
        return students;
    }
}