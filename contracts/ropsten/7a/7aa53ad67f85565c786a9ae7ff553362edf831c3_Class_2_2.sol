/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity 0.8.0;

contract Class_2_2 {
    
    string grade;
    
    uint students;
    
    uint totalscore;
    
    function setgrade(uint score) public {
        
        if(score >= 90) {
            
            grade = "A";
            
        } else if (score >= 80) {
            
            grade = "B";
            
        } else if (score >= 70) {
            
            grade = "C";
            
        } else if (score >= 60) {
            
            grade = "D";
        
        } else {
            
            grade = "F";
        
        }
        
        students++; //students +=1, students++, students = students +1
        
        totalscore += score; // totalscore += score, totalscore = totalscore+score
        
        
    }
    
    function getgrade() public view returns(uint) {
        
        return totalscore/students;
        
    }
    
}