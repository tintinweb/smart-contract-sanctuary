/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

//young do jang

pragma solidity 0.8.0;

contract Likelion_9 {
    
    function Cutting(uint a) public view returns (uint) {
        uint count;
            if((a/1000000000000)%4 ==0) {
                count++;
            }
            if((a/100000000)%4 ==0){
                count++;
            } 
            if((a/10000)%4 ==0) {
                count++;
            }
            if((a%10000)%4 == 0) {
                count++;
            }
            if(a==0) {
                count++;
            }
            return count;
        }
        
       
    }