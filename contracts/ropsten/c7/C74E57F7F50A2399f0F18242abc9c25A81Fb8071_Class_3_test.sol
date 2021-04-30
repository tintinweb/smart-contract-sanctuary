/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity 0.8.0;

contract Class_3_test {
    string groups;
    uint[] scores;
    
    function setgroups(uint score) public {
        
        if(score >= 70) {
        
            groups = "NA";
        
            
        } else if(score <= 40) {
            
            groups = "DA";
        
            
        } else if(score > 40) {
           
            groups = "RA";
        
            
        } else if(score < 70) {
            
            groups = "RA";
    
         }
        
        scores.push(score); // put scores in the scores(list)
    }
    
    function getAverage() public view returns(uint) {
    
        uint a=0;
   
       for(uint i=0; i<scores.length; i++) {
   
            a=a+scores[i];
  
        }
        
        return (a/scores.length);
  
    }
    

    function getScore(uint a) public view returns(uint) {
  
        return scores[a-1];
  
    }

    
}