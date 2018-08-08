pragma solidity ^0.4.0;

contract MyNamedAccount
{
    uint public storedNumber;
    function name() public pure returns (string) {
        return "chriseth";
    }
    function storeNumber(uint x) public {
        storedNumber = x;
    }
}