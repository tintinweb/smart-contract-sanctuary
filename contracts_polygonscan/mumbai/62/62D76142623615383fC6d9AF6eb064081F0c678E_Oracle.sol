pragma solidity ^0.8.7;

contract Oracle {
    address private admin;
    uint256 public rand;

    constructor() {
        admin = msg.sender;
    }

    function feedRandomness(uint256 _rand) external {
        require(msg.sender == admin);
        rand = _rand;
    }
}

