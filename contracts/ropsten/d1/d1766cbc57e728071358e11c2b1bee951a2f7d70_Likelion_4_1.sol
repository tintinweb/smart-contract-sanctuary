/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// Younwoo Noh

pragma solidity 0.8.0;

contract Likelion_4_1 {
    string group;
    uint[] scores;
    uint a;
    uint students;
    
    function setGrade(uint score) public {
        if(score >= 70) {
            group = "GroupB"; // 나그룹
        } else if (score <= 40) {
            group = "GroupC"; // 다그룹
        } else {
            group = "GroupD"; // 라그룹
        }
        
        scores.push(score);
    }    
        
    function getAverage() public view returns(uint) {
        uint a = 0;
        for(uint i = 0; i<scores.length; i++) {
            a = a + scores[i];
        }
        return (a/scores.length);
    }
}