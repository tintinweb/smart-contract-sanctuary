/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.8.0;


contract Likelion_8 {
    //YunJun Lee
    

    
    function f(uint a) public view returns(uint){
        uint sum =0;
        while(a>=10){
            sum += a%10;
            a= a/10;
        }
        sum +=a;
        return sum;
        
    }

    function f2(uint k) public view returns(uint, uint,uint,uint,uint) {
        uint num2;
        uint num3;
        uint num5;
        uint num9 =0;
        uint num11 =0;
        uint a;
        num2 = k/2;
        num3 = k/3;
        num5 = k/5;

        uint b = 0;
        while (b<k){
            b+=1;
            a =f(b);
            if (a%9 ==0){
            num9+=1;
        }
            if (a%11 ==0){
            num11+=1;
        }
        }

        
        
        return (num2,num3,num5,num9, num11);
    }

    
    
}