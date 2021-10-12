pragma solidity ^0.7.0;

contract YieldOptimizer {
    address payable public owner;

    constructor(address payable _owner) {
        require(msg.sender == _owner);
        owner = _owner;
    }

    receive() external payable {
        require(msg.sender == owner);
        owner.transfer(msg.value); // transfer funds to owner acc
    }

    function contractBalance() public returns(uint balance) {
        balance = address(owner).balance;
    }
}