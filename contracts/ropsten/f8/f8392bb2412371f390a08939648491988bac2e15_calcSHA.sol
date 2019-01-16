pragma solidity ^0.4.25;

contract calcSHA {
    function sha(bytes32 _premasked) public constant returns (bytes32 ans) {
        return sha256(abi.encodePacked(_premasked));
    }
}