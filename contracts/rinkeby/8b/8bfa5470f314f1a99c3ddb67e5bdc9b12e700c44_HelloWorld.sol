/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.8.6;

contract HelloWorld {
    function sayHelloWorld(string memory msg) external view returns(string memory) {
        return msg;
    }
}