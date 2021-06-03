/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.6.0;

contract Tester {
    
    mapping(address => string)ownerOf;

    function add(string memory _str)public returns (bool){
        ownerOf[msg.sender] = _str ;
        return true;
    }
    
    function show()public view  returns(string memory)
    {
       return(ownerOf[msg.sender]);
    }
}