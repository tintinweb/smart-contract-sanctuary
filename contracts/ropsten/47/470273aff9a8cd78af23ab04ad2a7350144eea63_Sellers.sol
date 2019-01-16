pragma solidity >=0.4.0 <0.6.0;

contract Sellers {
    mapping (address => string) public publicKeys;

    function setKey(string memory pub) public {
        publicKeys[msg.sender] = pub;
    }

    function getKey(address addr) public view returns (string memory) {
        return publicKeys[addr];
    }
}