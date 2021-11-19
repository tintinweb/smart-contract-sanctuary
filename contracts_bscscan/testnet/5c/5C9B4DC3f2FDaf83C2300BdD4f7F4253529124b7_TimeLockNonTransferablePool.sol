// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TimeLockPool.sol";

contract TimeLockNonTransferablePool is TimeLockPool {
    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration,
        uint256 _maxBonus,
        uint256 _maxLockDuration
    ) TimeLockPool(_name, _symbol, _depositToken, _rewardToken, _escrowPool, _escrowPortion, _escrowDuration, _maxBonus, _maxLockDuration) {

    }

    // disable transfers
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("NON_TRANSFERABLE");
    }
}