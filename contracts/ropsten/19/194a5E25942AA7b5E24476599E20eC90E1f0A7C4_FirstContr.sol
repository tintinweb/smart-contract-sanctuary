/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.5.1;

contract FirstContr {
    string value;

    function get() public view returns(string memory) {
        return value;
    }

    function set(string memory _value) public {
        value = _value;
    }

    constructor() public {
        value = "my str";
    }
}