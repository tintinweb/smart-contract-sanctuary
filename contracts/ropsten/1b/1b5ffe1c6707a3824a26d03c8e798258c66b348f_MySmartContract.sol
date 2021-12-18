/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

pragma solidity ^0.5.0;

contract MySmartContract {

    uint32 public counter;
    bool private stopped = false;
    address private owner;

    modifier isNotStopped {
        require(!stopped, 'Contract is stopped.');
        _;
    }

    modifier isOwner {
        require(msg.sender == owner, 'Sender is not owner.');
        _;
    }

    constructor() public {
        counter = 0;
        owner = msg.sender;
    }

    function incrementCounter() isNotStopped public {
        counter += 2;
    }

    function toggleContractStopped() isOwner public {
        stopped = !stopped;
    }
}