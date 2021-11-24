/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/* SPDX-License-Identifier: Unlicensed */
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract LPLocker {

    IERC20 private _lpPair;
    address private _owner;
    uint256 private _releaseTime = 0;

    constructor (IERC20 lpPair_)  {
        _lpPair = lpPair_;
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function token() public view returns (IERC20) {
        return _lpPair;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }
    
    function balanceOfOwner() public view returns (uint256) {
        return _lpPair.balanceOf(_owner);
    }
    
    function balanceOfLocker() public view returns (uint256) {
        return _lpPair.balanceOf(address(this));
    }
    
    function lockLP(uint256 releaseTime_) external onlyOwner {
        require(_releaseTime == 0, "LP already locked");
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _releaseTime = releaseTime_;
    }

    function unlockLP() external onlyOwner {
        require(_releaseTime != 0, "LP already unlocked!");
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");
        uint256 amount = _lpPair.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");
        _lpPair.transfer(_owner, amount);
        _releaseTime = 0;
    }
    
    function isLocked() public view returns (bool) {
        return _releaseTime != 0;
    }
}