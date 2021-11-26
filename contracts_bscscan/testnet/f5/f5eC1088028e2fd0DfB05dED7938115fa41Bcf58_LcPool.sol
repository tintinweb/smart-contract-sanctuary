// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Auth.sol";
import "./_BnbPool.sol";
import "./_LcPool.sol";
import "./_Depositable.sol";

contract LcPool is Auth, _LcPool {
    uint256 COINS_PER_BNB = 5000;
    uint256 WITHDRAW_FEE = 5;

    mapping(address => uint256) public coins;

    constructor() Auth(msg.sender) {}

    // ****************************************
    // _LcPool implementation
    // ****************************************
    function deposit(address _player_) external payable override onlyAuthorized {
        coins[_player_] += msg.value * COINS_PER_BNB;
    }

    function transferToPlayer(address _from_, address _to_, uint256 _coins_) external override onlyAuthorized {
        require(coins[_from_] >= _coins_, 'INSUFFICIENT_AMOUNT');

        coins[_from_] -= _coins_;
        coins[_to_] += _coins_;
    }

    function transferToContract(address _from_, address _to_, uint256 _coins_) external override onlyAuthorized {
        require(coins[_from_] >= _coins_, 'INSUFFICIENT_AMOUNT');

        uint256 bnb = _coins_ / COINS_PER_BNB;

        coins[_from_] -= _coins_;

        _Depositable(_to_).deposit{ value: bnb }();
    }

    function withdraw(uint256 _coins_) external override {
        require(coins[msg.sender] >= _coins_, 'INSUFFICIENT_AMOUNT');

        uint256 bnb = _coins_ / COINS_PER_BNB;

        coins[msg.sender] -= _coins_;

        payable(msg.sender).transfer(bnb);
    }
}