// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./SafeMath.sol";

contract Tree {

    using SafeMath for uint;

    struct User {
        address payable inviter;
        address payable self;
    }

    mapping(address => User) public tree;
    address payable public top;

    constructor() public {
        tree[msg.sender] = User(msg.sender, msg.sender);
        top = msg.sender;
    }

    function enter(address payable inviter) external payable {
        require(msg.value == 1 ether/1000, "Must be at least 1 ether");
        require(tree[msg.sender].inviter == address(0), "Sender can't already exist in tree");
        require(tree[inviter].self == inviter, "Inviter must exist");
        tree[msg.sender] = User(inviter, msg.sender);

        address payable current = inviter;
        uint amount = msg.value;
        while(current != top) {
            amount = amount.div(2);
            current.transfer(amount);
            current = tree[current].inviter;
        }
        top.transfer(amount);
    }
}