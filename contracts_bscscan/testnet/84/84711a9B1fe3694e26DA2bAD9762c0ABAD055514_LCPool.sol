// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";

contract LCPool is Auth {
    uint256 public COINS_PER_BNB = 5000;

    mapping(address => uint256) public coins;

    constructor(address _owner_, address _developer_)
        Auth(_owner_, _developer_)
    { }

    function deposit(address _player_) external payable {
        coins[_player_] += msg.value * COINS_PER_BNB;
    }

    function transfer(address _player_, address _to_, uint256 _coins_) external onlyAuthorized {
        require(coins[_player_] >= _coins_, 'INSUFFICIENT_AMOUNT');
        coins[_player_] -= _coins_;
        payable(_to_).transfer(_coins_ / COINS_PER_BNB);
    }

    function withdraw(uint256 _coins_) external {
        require(coins[msg.sender] >= _coins_, 'INSUFFICIENT_AMOUNT');
        coins[msg.sender] -= _coins_;
        payable(msg.sender).transfer(_coins_ / COINS_PER_BNB);
    }
}