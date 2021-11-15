// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Referrer {
    mapping(address => address) private _referrers;
    mapping(address => bool) hasChanged;

    event Bind(address indexed user, address referrer);
    event ChangeBinding(
        address indexed user,
        address oldReferrer,
        address newReferrer
    );

    constructor() public {}

    function bind(address referrer) external {
        address account = msg.sender;
        require(account != referrer, "Can't invitation myself");
        require(_referrers[account] == address(0), "Has binded");
        require(referrer != address(0), "Address error");

        _referrers[account] = referrer;

        emit Bind(account, referrer);
    }

    function changeBinding(address referrer) external {
        address account = msg.sender;
        require(account != referrer, "Can't invitation myself");
        require(!hasChanged[account], "Only change once");
        require(referrer != address(0), "Address error");
        require(referrer != _referrers[account], "same old referrer");

        address old = _referrers[account];
        _referrers[account] = referrer;

        emit ChangeBinding(account, old, referrer);
    }

    function referrer(address account) public view returns (address) {
        return _referrers[account];
    }
}

