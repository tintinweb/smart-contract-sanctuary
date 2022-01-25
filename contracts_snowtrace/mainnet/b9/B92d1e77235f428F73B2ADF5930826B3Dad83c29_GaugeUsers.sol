// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface Gauge {
    function balanceOf(address user) external view returns (uint256);
    function user_checkpoint(address user) external returns (bool);
}

contract GaugeUsers {

    mapping (address => mapping (address => bool)) private _isGaugeUser;
    mapping (address => address[]) private _users;

    function isGaugeUser(address gauge, address user) public view returns (bool) {
        return _isGaugeUser[gauge][user];
    }

    function users(address gauge) public view returns (address[] memory) {
        return _users[gauge];
    }

    function addUser(address user) external {
        if (!_isGaugeUser[msg.sender][user]) {
            _isGaugeUser[msg.sender][user] = true;
            _users[msg.sender].push(user);
        }
    }

    function checkpointUsers(address _gauge, address[] memory users) external {
        Gauge gauge = Gauge(_gauge);
        address user;
        for (uint i=0; i<users.length; i++) {
            user = users[i];
            if (gauge.balanceOf(user) > 0) {
                gauge.user_checkpoint(user);
            }
        }
    }
}