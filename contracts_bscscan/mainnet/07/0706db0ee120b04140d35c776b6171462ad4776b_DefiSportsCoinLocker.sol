// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20TokenTransfer.sol";

contract DefiSportsCoinLocker {
    uint256 public releaseTime;
    address constant OWNER = 0xc08adaFf0e9EA1cD0ac2A1E5A3a0960AB96d9025;

    event UpdatedReleaseTime(uint256 oldReleaseTime, uint256 newReleaseTime);
    event TokensReleased(address token, uint256 amount, address beneficiary);

    modifier onlyOwner() {
        require(msg.sender == OWNER);
        _;
    }

    constructor() {
        releaseTime = block.timestamp + 20 weeks;
    }

    function extendLock(uint256 newReleaseTime) external onlyOwner {
        require(newReleaseTime > block.timestamp, "Release time must be in the future");
        require(newReleaseTime > releaseTime, "Can't make release time shorter");

        emit UpdatedReleaseTime(releaseTime, newReleaseTime);
        releaseTime = newReleaseTime;
    }

    function distributeTokens(IBEP20TokenTransfer token) external onlyOwner {
        require(block.timestamp >= releaseTime, "Lock is not expired");

        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(OWNER, amount));
        emit TokensReleased(address(token), amount, OWNER);
    }
}