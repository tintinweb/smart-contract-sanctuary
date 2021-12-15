/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity ^0.4.24;
contract hello {
    string public name;

    constructor() public {
        name ="i am smart contract. so handsome!!!";
    }

    function setName(string _name) public {
        name = _name;
    }
}