/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

pragma solidity ^0.5.0;

contract SolidityTest {
    string public mensagem = "";
    
    function wait_a_bit(uint tempo, string memory text) public{
        uint start_time = block.timestamp;
        while(start_time+tempo>=block.timestamp){
        }
        mensagem = text;
    }
}