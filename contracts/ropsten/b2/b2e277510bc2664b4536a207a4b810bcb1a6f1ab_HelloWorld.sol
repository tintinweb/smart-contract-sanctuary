/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity >=0.5.0 <0.7.0;

contract HelloWorld{
    
    function get_hello()public pure returns (string memory)
    {
        return 'Hello Contracts';
    }
    uint storedData;

    function set(uint x) public 
    {
        storedData = x;
    }

    function get() public view returns (uint) 
    {
        return storedData;
    }
}