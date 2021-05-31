/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.4.24;

contract CounterApp {
    /// Events
    event Increment(address indexed entity, uint256 step);
    event Decrement(address indexed entity, uint256 step);
    mapping( address => bool ) public allOwners;
    /// State
    uint256 public value;
    
    constructor() {
        allOwners[msg.sender] = true;
    }

    modifier onlyOwner {
        require(allOwners[msg.sender] == true);
        _;
    }

    function newsOwner(address newOwner) public onlyOwner {
        allOwners[newOwner] = true;
    }
    function deleteOwner(address delOwner) public onlyOwner {
        allOwners[delOwner] = false;
    }




    function increment(uint256 step) public onlyOwner {
        value = value+step;
        emit Increment(msg.sender, step);
    }

    function decrement(uint256 step) public onlyOwner {
        value = value-step;
        emit Decrement(msg.sender, step);
    }
}