/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity 0.8.0;


contract Likelion_10 {
    //YunJun Lee
    
    
    
    function f(uint password) public view returns(uint){
        uint pre = (password/100) *100;
        uint a = 0;
        while(a<100){
            
            if (pre+a == password)
                return a;
            a+=1;
        }
        return 0;
        
    }
}