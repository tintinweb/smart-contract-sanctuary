pragma solidity ^0.4.19;

contract Readonly {
    uint a = 1;
    function () payable public {
        uint b = a;
        b++;
        if (b == 10) {
            selfdestruct(msg.sender);
        }
    }
}