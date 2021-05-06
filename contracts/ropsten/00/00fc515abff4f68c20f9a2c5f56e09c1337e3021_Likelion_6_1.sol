/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity 0.8.0;

contract Likelion_6_1 {
    
    function pushNum(uint num) public view returns(uint) {
        if( num > 0 && num < 10){
            if(num <= 3){
                return num**2;
            }
            else if(num <= 6){
                return num*2;
            }
            else if(num <= 9){
                return num%3;
            }
        }
        else{
           return 404;
        }
    
    }
    
}