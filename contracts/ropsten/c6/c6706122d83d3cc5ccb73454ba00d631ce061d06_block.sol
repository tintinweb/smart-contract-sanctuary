/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// Ko Eun NA

pragma solidity 0.8.0;

contract block {
    
    struct header {
       
        uint block_number;
        uint previous_hash;
        string input;
        string block_hash;
    }
}


/*
블록구조를 구현하세요. 블록 헤더만 구현하시면 
블록번호, 이전 블록 해시, 문자열(입력), 블록 해시가 포함되어야 합니다. 
블록 구로를 기반으로 하여 체인도 구성하십시오.  
*/


contract ez {
    
    function cal(uint a, uint b) public view returns(uint, uint) {
   
        return (a*b , a**b);
    }
}