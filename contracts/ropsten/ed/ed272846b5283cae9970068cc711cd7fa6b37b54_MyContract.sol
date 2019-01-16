pragma solidity ^0.4.25;
contract MyContract {
    function myFunction() pure public returns(uint256 myNumber, string memory myString) {
        return (12345, "Hello World");
    }
}