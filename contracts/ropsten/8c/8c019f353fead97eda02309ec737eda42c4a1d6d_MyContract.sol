/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity >=0.7.0 <0.9.0;

contract MyContract
{
    
    string value;
    

    constructor() public
    {
        value = "test";
    }
    
    
    function getValue() public view returns(string memory)
    {
        return value;
    }
    
    function setValue(string memory _value) public
    {
        value = _value;
    }
    
    
}