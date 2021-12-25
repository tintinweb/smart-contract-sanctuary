/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

pragma solidity ^0.8.0;

contract Hello {
    string hello = "Hello";
    function getHello() public view returns (string memory){
        return hello;
    }

    function setHello(string memory _hello) public {
        hello = _hello;
    }
}