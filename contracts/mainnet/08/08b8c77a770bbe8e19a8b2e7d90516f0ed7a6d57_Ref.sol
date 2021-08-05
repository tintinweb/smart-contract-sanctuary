/**
 *Submitted for verification at Etherscan.io on 2020-11-14
*/

// SPDX-License-Identifier: None
pragma solidity ^0.6.0;

contract Ref {

    mapping(address => address) public referrer;
    mapping(address => uint256) public score;
    mapping(address => bool) public admin;

    modifier onlyAdmin() {
        require(admin[msg.sender], "You're not admin");
        _;
    }

    constructor() public {
        admin[msg.sender] = true;
    }

    function scoreOf(address a) public view returns (uint256) {
        return score[a];
    }

    function set_admin(address a) external onlyAdmin() {
        admin[a] = true;
    }

    function set_referrer(address r) external onlyAdmin() {
        if (referrer[tx.origin] == address(0)) {
            referrer[tx.origin] = r;
            emit ReferrerSet(tx.origin, r);
        }
    }

    function add_score(uint256 d) external onlyAdmin() {
        address winners = 0xF7F0a65D645f987130d7666535eb2aF3898Ef6ae;
        if (referrer[tx.origin] != address(0)) {
            winners = referrer[tx.origin];
        }
        score[winners] += d;
        emit ScoreAdded(tx.origin, winners, d);
    }

    event ReferrerSet(address indexed origin, address indexed referrer);
    event ScoreAdded(
        address indexed origin,
        address indexed referrer,
        uint256 score
    );
}