/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity 0.7.4;


contract math {
    
    event test(uint a, uint b, uint time);
    
    
    function test1(uint _a, uint _b) public returns(bool) {
        emit test(_a,_b,block.timestamp);
        
        return true;
    }
    
}