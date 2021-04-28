/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//Dae Hyuk Kim

pragma solidity 0.8.0;

contract Likelion_1 {
    
    function add(uint a, uint b) public view returns(uint) {
        return a+b;
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