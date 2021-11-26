// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Auth.sol";
import "./_BnbPool.sol";
import "./_LcPool.sol";

contract BnbPool is Auth, _BnbPool {
    uint256 DEPOSIT_FEE = 5;

    _LcPool public lcPool;

    constructor() Auth(msg.sender) {}

    function link(address _lcPoolAddress_) external onlyOwner {
        lcPool = _LcPool(_lcPoolAddress_);
    }

    // ****************************************
    // _BnbPool implementation
    // ****************************************
    function deposit() external override payable {}

    function claimBnbAndTransferToLc(address _player_, uint256 _bnb_) external override onlyAuthorized {
        require(_bnb_ <= address(this).balance, 'INSUFFICIENT_AMOUNT');
        lcPool.deposit{ value: _bnb_ }(_player_);
    }
}