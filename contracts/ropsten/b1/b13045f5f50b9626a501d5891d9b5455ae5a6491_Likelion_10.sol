/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_10 {
    uint pwd = 429;
    
    function ChangePwd(uint n) public {
        pwd = n;
    }
    
    function findPwd() public view returns(uint) {
        for(uint i=0; i<100; i++){
            if(i == pwd%100){
                return i;
            }
        }
    }
}