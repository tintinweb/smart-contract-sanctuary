/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// GyungHwan lee

pragma solidity 0.8.0;

contract likelion_4 {
    string grade;
    uint[] scores;
    uint[] A; // score >= 70
    uint[] B; // score <= 40
    uint[] C; // 40 < score < 70
    
    function set(uint score) public returns(uint) {
        if(score >= 70) {
            A.push(score);
        } else if(score <= 40) {
            B.push(score);
        } else {
            C.push(score);
        }
        
        scores.push(score); // put scores in the scores(list)
    }
    
    function getAverageA() public view returns(uint) {
        uint a=0;
        for(uint i=0; i<scores.length; i++) {
            a = a+scores[i];
        }
        
        return (a/scores.length);
    }
    
    function getAverageB() public view returns(uint) {
        uint a=0;
        for(uint i=0; i<A.length; i++) {
            a = a+A[i];
            }
        
        return (a/A.length);
    }
    
    function getAverageC() public view returns(uint) {
        uint a=0;
        for(uint i=0; i<B.length; i++) {
            a = a+B[i];
            }
        
        return (a/B.length);
    }
    
    function getAverageD() public view returns(uint) {
        uint a=0;
        for(uint i=0; i<C.length; i++) {
            a = a+C[i];
            }
        
        return (a/C.length);
    }        
}