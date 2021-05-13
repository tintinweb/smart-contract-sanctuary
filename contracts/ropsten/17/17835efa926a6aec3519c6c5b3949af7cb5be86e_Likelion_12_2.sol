/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//younwoo noh
//a,b 2개의 input 값을 넣으면 a곱하기 b와 a의 b승의 결과물을 내는 함수를 구현하시오

pragma solidity 0.8.0;

contract Likelion_12_2 {
    
    function mul(uint a, uint b) public view returns(uint, uint) {
        return (a*b, a**b);
    }
}