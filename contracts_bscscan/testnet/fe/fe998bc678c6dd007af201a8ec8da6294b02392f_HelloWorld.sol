/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity 0.8.7;

contract HelloWorld {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}