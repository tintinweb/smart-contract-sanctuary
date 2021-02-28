/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity ^0.6.0;

contract Mycontract{
    
    uint256 public a;
    
    function add(uint _a)public{
        a=_a;
    }
    function get()public view returns(uint){
        return a;
    }
}