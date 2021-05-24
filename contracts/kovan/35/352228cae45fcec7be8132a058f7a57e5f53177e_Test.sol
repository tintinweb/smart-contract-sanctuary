/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.5.16;

contract Test {
    event Debug(uint x);
    
    function ori(uint x) public payable returns(uint) {
        emit Debug(x + msg.value);
        return x*2;
    }
    
    function liran(uint x) public payable returns(uint) {
        emit Debug(x + msg.value);
        return x*3;
    }    
}