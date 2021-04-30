/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// Ko Eun NA 

pragma solidity 0.8.0;

contract likelion5 {
    
    string grade;
    uint[] scorelist = [70,55,25,15,95,85,90,40,35,90];
    
    // number of students && group average
     function setGrade(uint score) public {
        
        if(score>=80){
            grade =  "A";
        }else if(score>=70){
            grade = "B";
        }else if(score>=50){
            grade = "C";
        }else{
            grade = "F";
        }
    }
    
    
    // function getGrade() public  view returns(uint, uint, uint, uint, uint, uint, uint, uint){
        
    //     uint aa; uint bb;
    //     uint cc; uint ff;
    //     uint a; uint b; uint c; uint f;
        
    //     if(grade ==  "A"){
    //         a++;
    //         aa +=aa;
    //     }else if(grade == "B"){
    //         b++;
    //         bb +=bb;
    //     }else if(grade == "C"){
    //         c++;
    //         cc +=cc;
    //     }else{
    //         f++;
    //         ff +=ff;
    //     }
        
    //     return(a,b,c,f,aa/a,bb/b,cc/c,ff/f);
    // }
    
    
    
 
    
    // average
    function average_ga() public view returns(uint) {
        uint a = 0;
        for (uint i=0; i<scorelist.length;i++){
            a += scorelist[i];
        }
        return a/scorelist.length;
    }
    
    function average_na() public view returns(uint) {
        uint a = 0;
        for (uint i=0; i<scorelist.length;i++){
            if(scorelist[i]>=70){
                a += scorelist[i];
            }
        }
        return a/scorelist.length;
    }
    
    function average_da() public view returns(uint) {
        uint a = 0;
        for (uint i=0; i<scorelist.length;i++){
            if(scorelist[i]<=40){
                a += scorelist[i];
            }
        }
        return a/scorelist.length;
    }
    
     function average_la() public view returns(uint) {
        uint a = 0;
        for (uint i=0; i<scorelist.length;i++){
            if(scorelist[i]>40 && scorelist[i]<70){
                a += scorelist[i];
            }
        }
        return a/scorelist.length;
    }
    
}