pragma solidity ^0.4.19;

contract Contrat {

    address owner;

    event Sent(string hash);

    constructor() public {
        owner = msg.sender;
    }

    modifier canAddHash() {
        bool isOwner = false;

        if (msg.sender == owner)
            isOwner = true;

        require(isOwner);
        _;
    }

    function addHash(string hashToAdd) canAddHash public {
        emit Sent(hashToAdd);
    }
}