pragma solidity ^0.4.0;

contract MyNamedAccount
{
    uint public storedNumber;
    function name() public pure returns (string) {
        return &quot;chriseth&quot;;
    }
    function storeNumber(uint x) public {
        storedNumber = x;
    }
}