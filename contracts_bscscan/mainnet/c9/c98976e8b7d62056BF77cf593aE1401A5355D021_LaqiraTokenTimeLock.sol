/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LaqiraTokenTimeLock {
    address public owner;
    
    uint256 public creationTime;
    
    // Number of tokens which is released after each period.
    uint256 private _periodicReleaseNum;
    
    // Seconds of 6 month, release period is 6 month and all the tokens will be released in 8 periods(8 * 6 month = 4 yaers).
    uint256 public constant period = 15552000;
    
    // Number of tokens that has been withdrawn already.
    uint256 private _withdrawnTokens;
    
    IBEP20 private immutable _token;
    
    constructor(IBEP20 token_, uint256 periodicReleaseNum_) {
        owner = msg.sender;
        _token = token_;
        creationTime = block.timestamp;
        _periodicReleaseNum = periodicReleaseNum_;
    }
    
    function withdraw(uint256 _amount, address beneficiary_) public onlyOwner {
        require(availableTokens() >= _amount);
        token().transfer(beneficiary_, _amount);
        _withdrawnTokens += _amount;
    }
    
    function token() public view returns (IBEP20) {
        return _token;
    }
    
    function periodicReleaseNum() public view returns (uint256) {
        return _periodicReleaseNum;
    }
    
    function withdrawnTokens() public view returns (uint256) {
        return _withdrawnTokens;
    }
    
    function availableTokens() public view returns (uint256) {
        uint256 passedTime = block.timestamp - creationTime;
        return ((passedTime / period) * _periodicReleaseNum) - _withdrawnTokens;
    }
    
    function lockedTokens() public view returns (uint256) {
        uint256 balance = timeLockWalletBalance();
        return balance - availableTokens();
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function timeLockWalletBalance() public view returns (uint256) {
        uint256 balance = token().balanceOf(address(this));
        return balance;
    }
}