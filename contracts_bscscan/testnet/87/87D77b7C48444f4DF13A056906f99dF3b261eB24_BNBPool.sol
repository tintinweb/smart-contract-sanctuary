// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";
import "./LCPool.sol";

contract BNBPool is Auth {
    LCPool lcPool;

    constructor(address _owner_, address _developer_)
        Auth(_owner_, _developer_)
    { }

    function deposit() external payable {}

    function transfer(address _player_, uint256 _bnb_) external onlyAuthorized {
        require(_bnb_ <= address(this).balance, 'INSUFFICIENT_AMOUNT');
        lcPool.deposit{ value: _bnb_ }(_player_);
    }

    function linkPool(address _lcPoolAddress_) external onlyOwner {
        lcPool = LCPool(_lcPoolAddress_);
    }
}