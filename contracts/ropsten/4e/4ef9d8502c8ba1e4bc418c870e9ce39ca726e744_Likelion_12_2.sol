/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//young do jang
pragma solidity 0.8.0;

contract Likelion_12_2 {
    function calculate(uint a, uint b) public view returns(uint, uint) {
        return(a*b, a**b);
    }
}