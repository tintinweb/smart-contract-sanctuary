// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";

contract AjudaMutua {

    using SafeMath for uint;

    struct User {
        address payable inviter;
        address payable self;
    }

    mapping(address => User) public tree;
    address payable public top;
    address payable public owner;
    uint public feePercentage = 10;
    uint public feePercentage2 = 90;
        
    constructor() public {
        tree[msg.sender] = User(msg.sender, msg.sender);
        top = msg.sender;
        owner = 0xf85DF3538c098E2F2BF829DAf40CEa7917391C68;
    }

    function enter(address payable inviter, uint value) external payable {
        require(value == 1 ether/1000, "Must be 1 ether");
        require(tree[msg.sender].inviter == address(0), "Sender can't already exist in tree");
        require(tree[inviter].self == inviter, "Inviter must exist");
        tree[msg.sender] = User(inviter, msg.sender);

        uint fee = value.mul(feePercentage).div(100);
        owner.transfer(fee);

        address payable current = inviter;
        uint amount = value.mul(feePercentage2).div(100);
        while(current != top) {
            amount = amount.div(2);
            current.transfer(amount);
            current = tree[current].inviter;
        }
        top.transfer(amount);
    }
}