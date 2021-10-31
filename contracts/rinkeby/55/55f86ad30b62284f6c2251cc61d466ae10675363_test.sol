/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

pragma solidity ^0.4.24;

contract test 
{

    string public name;

    constructor()public
    {
        name = "這是一個測試" ;
    }

    function setName(string _name) public 
    {
        name=_name;
    }
}