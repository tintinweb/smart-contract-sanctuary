/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.4.0;

contract Btrack {
    string storedData;
    
    constructor() public {
        storedData = "this is litttttt!";
    }
    function set(string x) public {
        storedData = x;
    }

    function get() public view returns (string) {
        return storedData;
    }
}