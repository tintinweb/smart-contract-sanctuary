/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity 0.8.0;

contract Likelion_11_2 {
    uint a;
    uint b;
        
    function mul(uint a, uint b) public view returns(uint, uint) {
        return (a/b, a%b);
    }
}