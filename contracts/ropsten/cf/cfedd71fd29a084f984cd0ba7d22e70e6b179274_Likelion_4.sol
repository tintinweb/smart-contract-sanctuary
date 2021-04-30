/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// Seo Sangcheol

pragma solidity >=0.7.0 <0.9.0;

contract Likelion_4 {
    string gradeA;
    string gradeB;
    string gradeC;
    string gradeF;
    string grade;
    
    uint[] scoresAll = [70,55,25,15,95,85,90,40,35,90];
    uint[] scores70 = [70,95,85,90,90];
    uint[] scores40 = [25,15,40,35] ;
    uint[] scores41 = [55] ;
    
    function getAverage() public view returns(uint,uint,uint,uint) {
    uint a=0;
    uint b=0;
    uint c=0;
    uint d=0;
    
        for(uint i=0; i<scoresAll.length; i++) {
            a = a+scoresAll[i];
        }
        
        for(uint j=0; j<scores70.length; j++) {
            b = b+scores70[j];
        }
        
        for(uint k=0; k<scores40.length; k++) {
            c = c+scores40[k];
        }
        
        for(uint l=0; l<scores41.length; l++) {
            d = d+scores41[l];
        }
        
        return (a/scoresAll.length, b/scores70.length, c/scores40.length, d/scores41.length);

    }
    
}