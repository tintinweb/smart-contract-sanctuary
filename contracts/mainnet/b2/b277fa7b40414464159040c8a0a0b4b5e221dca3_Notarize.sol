pragma solidity ^0.4.13;

// File: contracts/Owned.sol

contract Owned {
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner() {
        require(newOwner != 0x0);
        owner = newOwner;
    }
}

// File: contracts/Notarize.sol

contract Notarize is Owned {
    
    mapping(bytes32 => uint) public notaryBook;
    uint public notaryBookSize;

    event RecordAdded(bytes32 hash, uint timestamp);

    function notarize(bytes32 _hash, uint _timestamp) public onlyOwner {
        require(!isNotarized(_hash));
        notaryBook[_hash] = _timestamp;
        notaryBookSize++;
        RecordAdded(_hash, _timestamp);
    }

    function isNotarized(bytes32 _hash) public view returns(bool) {
        return (notaryBook[_hash] > 0);
    }

    function getTimestamp(bytes32 _hash) public view returns(uint) {
        return notaryBook[_hash];
    }
}