pragma solidity ^0.4.25;

contract stringsha {
    function sha(string s) public constant returns (bytes32 b) {
        return sha256(abi.encodePacked(s));
    }
}