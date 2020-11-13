// SPDX-License-Identifier: MIT

  /**
   * LYNC Network
   * https://lync.network
   *
   * Additional details for contract and wallet information:
   * https://lync.network/tracking/
   *
   * The cryptocurrency network designed for passive token rewards for its community.
   */

pragma solidity ^0.7.0;

import "./lynctoken.sol";

contract LYNCTokenLock {

    //Enable SafeMath
    using SafeMath for uint256;

    address public owner;
    address public contractAddress;
    uint256 public oneDay = 86400;      // in seconds
    uint256 public currentLockTimer;    // in seconds

    LYNCToken public tokenContract;

    //Events
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipRenounced(address indexed _previousOwner, address indexed _newOwner);

    //On deployment
    constructor(LYNCToken _tokenContract) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        contractAddress = address(this);
        currentLockTimer = block.timestamp;
    }

    //Withdraw tokens
    function withdrawTokens(uint256 _numberOfTokens) public onlyOwner {
        require(block.timestamp > currentLockTimer, "Tokens are currently locked even to the contract admin");
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
    }

    //Increase lock duration in days
    function increaseLock(uint256 _numberOfDays) public onlyOwner {
        uint256 _increaseLockDays = _numberOfDays.mul(oneDay);
        currentLockTimer = currentLockTimer.add(_increaseLockDays);
    }

    //Transfer ownership to new owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //Remove owner from the contract
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner, address(0));
        owner = address(0);
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only current owner can call this function");
        _;
    }
}
