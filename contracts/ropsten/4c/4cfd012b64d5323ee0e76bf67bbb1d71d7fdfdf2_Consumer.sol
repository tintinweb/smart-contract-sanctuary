/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

/**
 *Submitted for verification at Etherscan.io on 2017-09-27
*/

pragma solidity ^0.4.11;
contract simpleMath{
    //Simple add function,try a divide action?
    function add(uint x, uint y) returns (uint z){
        z = x + y;
    }
}
contract Consumer {
    
    function deposit() payable returns (uint){
        return msg.value;
    } 
}