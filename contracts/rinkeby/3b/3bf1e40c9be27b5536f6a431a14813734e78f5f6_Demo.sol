/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity 0.6.12;

contract Demo {
    string public name;
    string public symbol;
    string public baseURI;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) public {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }
}