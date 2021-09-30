/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

////SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    address payable private owner;

    event ForwarderDeposited(address from, uint value);
    event ForwarderDepositedWithParam(address from, uint value, uint param);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        emit OwnerSet(address(0), address(owner));
    }

    function changeOwner(address payable newOwner) public isOwner {
        emit OwnerSet(owner, address(newOwner));
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function test(uint param) external payable {
        owner.transfer(msg.value);
        emit ForwarderDepositedWithParam(msg.sender, msg.value, param);
    }

    receive() external payable {
        owner.transfer(msg.value);
        emit ForwarderDeposited(msg.sender, msg.value);
    }
}