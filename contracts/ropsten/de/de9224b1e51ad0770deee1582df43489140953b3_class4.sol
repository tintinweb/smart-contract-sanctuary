/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity >=0.7.0 <0.9.0;

contract class4 {
    
    string grade;
    uint[] scorelist;

    function setGrade(uint score) public  {
        
        if(score>=90){
            grade =  "A";
        }else if(score>=80){
            grade = "B";
        }else if(score>=70){
            grade = "C";
        }else if(score>=60){
            grade = "D";
        }else{
            grade = "F";
        }
        scorelist.push(score);
    }
    
    function average() public view returns(uint) {
        uint a = 0;
        for (uint i=0; i<scorelist.length;i++){
            a += scorelist[i];
        }
        
        return a/scorelist.length;
    }
    
    function sum() public view returns(uint) {
        uint a = 0;
        for (uint i=0; i<scorelist.length;i++){
            a += scorelist[i];
        }
        return a;
    }
}