/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.8.0;

contract Bank {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {} // fallback to get ethers

    function changeOwner(address _owner) external {
        require(owner == msg.sender);

        _changeOwner(_owner);
    }

    function withdraw(uint _amount) external {
        require(owner == msg.sender);

        payable(msg.sender).transfer(_amount);
    }


    function _changeOwner(address _owner) public {
        owner = _owner;
    }
}