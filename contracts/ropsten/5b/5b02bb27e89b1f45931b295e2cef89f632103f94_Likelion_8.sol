/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

//young do jang

pragma solidity 0.8.0;

contract Likelion_8 {
    function setNumber(uint a) public view returns(uint){
        uint count;
        
        for(uint i=1;i <= a;i++) {
            if(i%2 == 0) {
                count++;
            }else if(i%3 == 0) {
                count++;
            }else if(i%5 == 0) {
                count++;
            }else if(((i/10)+(i%10))%9 == 0) {
                count++;
            }else if(((i/10)+(i%10))%11 == 0) {
                count++;
            }  
        }
        return count;
    }
}