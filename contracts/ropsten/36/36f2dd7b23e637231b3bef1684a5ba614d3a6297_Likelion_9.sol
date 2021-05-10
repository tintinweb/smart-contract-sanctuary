/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity 0.8.0;


contract Likelion_9 {
    //YunJun Lee
    

    
    function f(uint a) public view returns(uint){
        uint count = 0;
        while(a>0){
            uint b = a%10000;
            a/=10000;
            if(b%4==0)
            count+=1;
        }
        return count;
        
    }
}