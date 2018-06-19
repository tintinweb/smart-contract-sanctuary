pragma solidity ^0.4.18;

contract Exponent {
    function checkMultOverflow(uint x, uint y) public pure returns(bool) {
        if(y == 0) return false;
        return (((x*y) / y) != x);
    }
    
    function exp(uint p, uint q, uint precision) public pure returns(uint){
        uint n = 0;
        uint nFact = 1;
        uint currentP = 1;
        uint currentQ = 1;
        
        uint sum = 0;
        
        while(true) {
            if(checkMultOverflow(currentP, precision)) return sum; 
            if(checkMultOverflow(currentQ, nFact)) return sum;            
            
            sum += (currentP * precision ) / (currentQ * nFact);
            
            n++;
            
            if(checkMultOverflow(currentP,p)) return sum;            
            if(checkMultOverflow(currentQ,q)) return sum;
            if(checkMultOverflow(nFact,n)) return sum;
            
            currentP *= p;
            currentQ *= q;
            nFact *= n;
        }

    }
    
    event ExpResult(uint result, uint precision);
    
    function expTx(uint p, uint q, uint precision) public {
        ExpResult(exp(p,q,precision),precision);
    }
    
}