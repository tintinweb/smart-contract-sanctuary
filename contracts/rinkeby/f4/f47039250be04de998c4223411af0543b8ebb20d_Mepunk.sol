/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.4.24;
contract Mepunk {
    string public name;
    
    constructor() public {
        name = "米香的智能合約！噢噎！！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}