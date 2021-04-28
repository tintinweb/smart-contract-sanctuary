/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// choiseonmin

pragma solidity >=0.7.0 <0.9.0;

contract Likelion_2 {
    function sample() public view returns(uint) {
        return 1;
    }
    function sub(uint a, uint b) public view returns(uint) {
        return a-b;
    }
        function mul(uint a, uint b) public view returns(uint) {
        return a*b;
    }
        function div(uint a, uint b) public view returns(uint, uint) {
        return (a/b, a%b);
    }
}