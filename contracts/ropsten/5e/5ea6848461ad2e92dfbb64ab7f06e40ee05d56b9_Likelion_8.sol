/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// Ko Eun NA

pragma solidity 0.8.0;

contract Likelion_8 {
    
    uint[] x2;
    uint[] x3;
    uint[] x5;
    uint[] x9;
    uint[] x11;
    
    uint i ;
    
    function what(uint i) public returns(uint, uint, uint, uint, uint) {
        
        if(i>9){
            uint a = i/10;
            uint b = i%10;
            uint c = a + b;
            
            for(uint j = 0; j <= c ; j++){
           
               if(j/2 == 0) {
                   x2.push(j);
               }else if(j/3 == 0){
                   x3.push(j);
               }else if(j/5 == 0){
                   x5.push(j);
               }else if(j/9 == 0){
                   x9.push(j);
               }else if(j/11 == 0){
                   x11.push(j);
               }
            }
        }
       
       return (x2.length, x3.length, x5.length, x9.length, x11.length);
    }
}