/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

pragma solidity ^0.8.11;

contract NewContract{

    string public name = "contract test";

    constructor(string memory _name){
        name = _name;
    }
}