/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract UserPool {

    address payable[] public players;
    address public admin;
    uint public createTime;
    enum POOL_STATE {
        OPEN, CLOSED
    }
    POOL_STATE public pool_state;
    uint count = 0;

    struct User {
        address user;
        uint score;
    }

    constructor() {
        admin = msg.sender;
        pool_state = POOL_STATE.CLOSED;
    }

    // this is required to receive ETH. any amount of ETH
    receive () payable external {

    }

    function payPool() public payable {
        require(pool_state == POOL_STATE.OPEN, "Pool is closed");
        require(msg.value > 0 ether, "Please pay something to join pool");
        players.push(payable(msg.sender));
        count = count+1;
    }

    function startPool() public {
        require(msg.sender == admin, "Only admin can start the pool");
        require(pool_state == POOL_STATE.CLOSED, "The pool is already open");
        pool_state = POOL_STATE.OPEN;
    }

    function endPool() public {
        require(msg.sender == admin, "Only admin can close the pool");
        require(pool_state == POOL_STATE.OPEN, "The pool is already closed");
        pool_state = POOL_STATE.CLOSED;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function adminWithdraw() public {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(getBalance());
    }
}