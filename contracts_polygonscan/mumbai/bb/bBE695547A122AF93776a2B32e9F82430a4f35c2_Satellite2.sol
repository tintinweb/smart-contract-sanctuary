/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

pragma solidity ^0.6.0;
//Now lets say we want to upgrade contract B and we create B2
contract Satellite2 {
    //these state variables need to be in the exact same order of contract A when performing a delegate call
    uint public num;
    address public sender;
    uint public value;
    
    constructor() public { owner = msg.sender; }
    address payable owner;
    
    //capture the following data and save it in the state variables
    function setVars(uint _num) public payable {
        //lets multiply the num by 2 so we can see a change
        num = 2 * _num;
        sender = msg.sender;
        value = msg.value;
    }
    
     //send funds back to the owner and destroy the contract
    function Destruct() public {
        selfdestruct(owner);
    }
}


contract MainContract {
    uint public num;
    address public sender;
    uint public value;

    //this is a delegate call to contract B
    //we are going to send ether to contract so we are making it payable
    function setVars(address _contract, uint _num) public payable {
        
        //this is to make a delegate call to another contract
        //the delegate call will produce 2 outputs.  success if there are no errors and the output of the function in bytes 
      (bool success, bytes memory data) = _contract.delegatecall(
            
            //in abi sig we need to pass in the function signature that we are calling
            abi.encodeWithSignature("setVars(uint256)", _num)
            );
    }
}