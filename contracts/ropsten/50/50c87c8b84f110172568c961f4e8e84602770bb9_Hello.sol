/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    constructor() public {
        name = "106403012!";
    }
    function setName(string _name) public {
        name = _name;
    }
}