pragma solidity ^0.4.16;

contract AKValueTest
{
    uint256 public someValue;
    
    function setSomeValue(uint256 newValue)
    {
        someValue = newValue;
    }
}