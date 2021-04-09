/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "我叫做謝昌諺！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}