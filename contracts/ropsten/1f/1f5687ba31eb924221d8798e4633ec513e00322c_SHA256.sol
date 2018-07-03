pragma solidity ^0.4.17;

contract SHA256 {
    bytes32 public hash;
    

    function setHash(string m) public {
        hash = sha256(m);
    }
}