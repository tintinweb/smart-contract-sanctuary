/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.5.1;


contract MyToken
{
    
    string public myString = "hello";
    
    mapping(address => uint256) public balance;
    
    
    
    function setMyString(string memory newString) public
    {
        myString = newString;
    }
    
    function mint(address to, uint256 amt) public
    {
        balance[to] += amt;
    }
    
    
}