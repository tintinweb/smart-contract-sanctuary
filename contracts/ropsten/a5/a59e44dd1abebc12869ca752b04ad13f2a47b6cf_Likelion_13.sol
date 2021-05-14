/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

//young do jang
pragma solidity 0.8.0;

contract Likelion_13 {
    
    function Primenumber(uint a) public view returns(uint) {
        uint count;
        uint b =2;
       
        while (b <= a) {
            for (uint i = 2; i <= b; i++) {
                if (b % i == 0 && i != b) {
                    break;
                }
                if (b % i ==0 && i == b) { 
                    count++; 
                }
            }
            b++;
        }
        return count;
    }
}
       


/*contract Likelion_13_2 {
    function Calendar(uint a) public view return(uint) {
        
    }
}*/