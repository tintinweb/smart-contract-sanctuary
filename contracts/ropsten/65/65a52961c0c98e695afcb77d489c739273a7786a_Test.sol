pragma solidity ^0.4.22;

contract Test {
    function test(uint timeElapsed, uint pastNum) pure public returns (int) {
        return int((86400 - timeElapsed) * pastNum);
    }
}