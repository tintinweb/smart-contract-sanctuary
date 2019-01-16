pragma solidity >=0.4.0 <0.6.0;

contract Members {
    struct Key {
        uint blocknumber;
        string publicKey;
        bool isValid;
    }

    mapping(address => Key) public keys;

    address[] public members;
    uint public membersTotal;

    function setKey(string memory pub) public {
        if (!keys[msg.sender].isValid) {
            membersTotal++;
            members.push(msg.sender);
        }
        keys[msg.sender] = Key (block.number, pub, true);
    }

    function getKey(address addr) public view returns (string memory) {
        return keys[addr].publicKey;
    }
}