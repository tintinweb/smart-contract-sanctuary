/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity ^0.8.4;

contract TestTestImmX {
    string private name;

    constructor(string memory _name) {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}