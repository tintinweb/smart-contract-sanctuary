// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";
import "./BNBPool.sol";
import "./DevPool.sol";

contract LCPool is Auth {
    uint256 COINS_PER_BNB = 5000;
    uint256 TRADE_FEE = 5;
    uint256 TRANSFER_FEE = 5;
    uint256 WITHDRAW_FEE = 5;

    BNBPool public bnbPool;
    DevPool public devPool;
    mapping(address => uint256) public coins;

    constructor(address _owner_, address _devPoolAddress_) Auth(_owner_) {
        devPool = DevPool(_devPoolAddress_);
    }

    function linkPool(address _bnbPoolAddress_) external onlyOwner {
        bnbPool = BNBPool(_bnbPoolAddress_);
        authorized[_bnbPoolAddress_] = true;
    }

    function deposit(address _player_) external payable onlyAuthorized {
        coins[_player_] += msg.value * COINS_PER_BNB;
    }

    // marketplace trades
    function trade(address _buyer_, address _seller_, uint256 _coins_) external onlyAuthorized {
        require(coins[_buyer_] >= _coins_, 'INSUFFICIENT_AMOUNT');

        uint256 bnb = _coins_ / COINS_PER_BNB;
        uint256 poolFee = bnb * TRADE_FEE / 100;
        uint256 freeTaxCoins = (bnb - poolFee) * COINS_PER_BNB;

        coins[_buyer_] -= _coins_;
        coins[_seller_] += freeTaxCoins;

        bnbPool.deposit{ value: poolFee }();
    }

    // event tickets
    function transfer(address _player_, address _contract_, uint256 _coins_) external onlyAuthorized {
        require(coins[_player_] >= _coins_, 'INSUFFICIENT_AMOUNT');

        uint256 bnb = _coins_ / COINS_PER_BNB;
        uint256 poolFee = bnb * TRANSFER_FEE / 100;
        uint256 freeTaxCoins = (bnb - poolFee) * COINS_PER_BNB;

        coins[_player_] -= _coins_;

        bnbPool.deposit{ value: poolFee }();
        payable(_contract_).transfer(freeTaxCoins);
    }

    // withdraw bnb
    function withdraw(uint256 _coins_) external {
        require(coins[msg.sender] >= _coins_, 'INSUFFICIENT_AMOUNT');

        uint256 bnb = _coins_ / COINS_PER_BNB;
        uint256 devFee = bnb * WITHDRAW_FEE / 100;
        uint256 freeTaxBnb = bnb - devFee;

        coins[msg.sender] -= _coins_;

        devPool.deposit{ value: devFee }();
        payable(msg.sender).transfer(freeTaxBnb);
    }

    function adjustFees(uint256 _tradeFee_, uint256 _transferFee_, uint256 _withdrawFee_) external onlyOwner {
        TRADE_FEE = _tradeFee_;
        TRANSFER_FEE = _transferFee_;
        WITHDRAW_FEE = _withdrawFee_;
    }
}