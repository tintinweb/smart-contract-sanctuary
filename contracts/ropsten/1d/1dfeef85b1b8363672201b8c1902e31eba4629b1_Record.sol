/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.4.25;

contract Record
{
    string public name;
    
    function getName() public view returns (string)
    {
        return name;
    }
    
    function setName(string newName) public{
        name=newName;
        
    }
    
}