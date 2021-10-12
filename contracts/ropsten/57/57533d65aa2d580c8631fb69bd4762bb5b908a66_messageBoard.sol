/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity >=0.4.22 <0.7.0;

contract messageBoard 
{    
    string public message;    
    constructor(string memory initMessage) public {
        message = initMessage;    
    }    
    function editMessage(string memory _editMessage) public{
        message = _editMessage;   
    }
    
}