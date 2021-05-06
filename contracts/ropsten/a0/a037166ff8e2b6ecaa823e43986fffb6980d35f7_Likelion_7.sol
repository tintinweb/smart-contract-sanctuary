/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity 0.8.0;


contract Likelion_7 {
    //YunJun Lee
    
    //7_1번
    function f(uint i) public view returns(uint){
        if (i <=3){
            return i*i;
        }
        else if(i<=6){
            return i*2;
        }
        else if(i<=9){
            return i%3;
        }
        else{
            require(i !=10,"Error");
        }
    }
    uint count =0       ;         
    bytes32 pre ;
    //7_2번
    //a값을 찾을 때는 a를 0으로 넣으면됩니다.
    function f2(uint a, uint b) public returns(uint)  {
                
                if (count==0){
                    pre = keccak256(abi.encodePacked(a, b)) ;
                    count+=1;
                    return 0;
                }
                
                while(true){
                    bytes32 hash2 = keccak256(abi.encodePacked(a, b , pre)) ;
                    if (hash2 <= pre){
                        return a;
                    }
                    a+=1;
                }
    }
    

    
    
}