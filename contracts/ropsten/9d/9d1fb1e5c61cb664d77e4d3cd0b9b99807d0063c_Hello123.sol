/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma solidity ^0.4.24;
contract Hello123{
    string public name;
    
    constructor() public{
        name = "106501005 ㄉ智慧合約!";
    }
    
    function setName(string _name) public{
        name = _name;
    }
}