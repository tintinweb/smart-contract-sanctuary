/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Likelion_4 {

uint[] scores;

    function Lion_4(uint score) public {
        scores.push(score);
    }
    
    
    
    function Lion_4_1() public view returns(uint, uint, uint, uint) {
        
        uint Ga=0;
        uint Na=0;
        uint Da=0;
        uint La=0;
        
        uint Na_count=0;
        uint Da_count=0;
        uint La_count=0;
        
        
        for(uint i=0; i < scores.length; i++) {
            if(scores[i] >= 70) {
            Na = Na + scores[i];
            Na_count++;
        }else if (scores[i] > 40) {
            La = La + scores[i];
            La_count++;
        } else {
            Da = Da + scores[i];
            Da_count++;
        }
        
        }
        
        for(uint i=0; i < scores.length; i++) {
            Ga = Ga + scores[i];
        }
        
        
        return(Ga/scores.length, Na/Na_count, Da/Da_count, La/La_count);
    }
    
    function getA() public view returns(uint, uint) {
        uint a=0;
        uint a_count=0;
        
        for(uint i = 0; i < scores.length; i++) {
            if(scores[i] >= 80) {
                a = a + scores[i];
                a_count++;
            }
            
            return(a_count, a/a_count);
            
        }
    }
    
        function getB() public view returns(uint, uint) {
        uint b=0;
        uint b_count=0;
        
        for(uint i = 0; i < scores.length; i++) {
            if((scores[i] < 80) && (scores[i] >= 70)) {
                b = b + scores[i];
                b_count++;
            }
            
            return(b_count, b/b_count);
            
        }
    }
    
        function getC() public view returns(uint, uint) {
        uint c=0;
        uint c_count=0;
        
        for(uint i = 0; i < scores.length; i++) {
            if((scores[i] < 70) && (scores[i] >= 50)) {
                c = c + scores[i];
                c_count++;
            }
            
            return(c_count, c/c_count);
            
        }
    }
    
            function getF() public view returns(uint, uint) {
        uint f=0;
        uint f_count=0;
        
        for(uint i = 0; i < scores.length; i++) {
            if(scores[i] < 50) {
                f = f + scores[i];
                f_count++;
            }
            
            return(f_count, f/f_count);
            
        }
    }
    
}