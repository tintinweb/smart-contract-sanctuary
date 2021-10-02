/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

//to make this work I needed to use a lot of gas in the test environment or it will fail

pragma solidity ^0.6.0;

//Original contract
contract Satellite1 {
    //these state variables need to be in the exact same order of contract A when performing a delegate call
    uint public num;
    address public sender;
    uint public value;
    
    constructor() public { owner = msg.sender; }
    address payable owner;
    
    //capture the following data and save it in the state variables
    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
    
    //send funds back to the owner and destroy the contract
    function Destruct() public {
        selfdestruct(owner);
    }
    

}