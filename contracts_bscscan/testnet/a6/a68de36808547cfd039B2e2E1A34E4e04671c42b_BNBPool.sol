// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";
import "./LCPool.sol";
import "./DevPool.sol";

contract BNBPool is Auth {
    uint256 DEPOSIT_FEE = 5;

    LCPool public lcPool;
    DevPool public devPool;

    constructor(address _owner_, address _devPoolAddress_) Auth(_owner_) {
        devPool = DevPool(_devPoolAddress_);
    }

    function linkPool(address _lcPoolAddress_) external onlyOwner {
        lcPool = LCPool(_lcPoolAddress_);
        authorized[_lcPoolAddress_] = true;
    }

    function deposit() external payable {
        uint256 bnb = msg.value;
        uint256 devFee = bnb * DEPOSIT_FEE / 100;

        devPool.deposit{ value: devFee }();
    }

    function transfer(address _player_, uint256 _bnb_) external onlyAuthorized {
        require(_bnb_ <= address(this).balance, 'INSUFFICIENT_AMOUNT');
        lcPool.deposit{ value: _bnb_ }(_player_);
    }

    function adjustFees(uint256 _depositFee_) external onlyOwner {
        DEPOSIT_FEE = _depositFee_;
    }
}