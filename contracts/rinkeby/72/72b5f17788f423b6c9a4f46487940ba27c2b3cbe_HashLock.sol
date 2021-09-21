// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashLock is Ownable {
    address public hashTokenAddress;

    struct Lock {
        address beneficiary;
        uint amount;
        uint timestamp;
        bool withdrawn;
    }
    Lock[] public locks;

    event NewTimeLock(uint indexed id, address indexed beneficiary, uint amount, uint timestamp);
    event Withdraw(address indexed beneficiary, uint amount);

    constructor(address _hashTokenAddress) {
        hashTokenAddress = _hashTokenAddress;
    }

    function addTimeLock(address _beneficiary, uint _amount, uint _timestamp) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_beneficiary != address(0), "Incorrect address");
        uint id = locks.length;
        locks.push(Lock(_beneficiary, _amount, _timestamp, false));
        TransferHelper.safeTransferFrom(hashTokenAddress, msg.sender, address(this), _amount);
        emit NewTimeLock(id, _beneficiary, _amount, _timestamp);
    }

    function withdraw() external {
        uint amount = 0;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].timestamp < block.timestamp && locks[i].beneficiary == msg.sender && locks[i].withdrawn == false) {
                amount += locks[i].amount;
                locks[i].withdrawn = true;
            }
        }
        require(amount > 0, "You have nothing to withdraw now");
        TransferHelper.safeTransfer(hashTokenAddress, msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function checkLockedAmount(address _beneficiary) external view returns(uint amount) {
        amount = 0;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].timestamp >= block.timestamp && locks[i].beneficiary == _beneficiary && locks[i].withdrawn == false) {
                amount += locks[i].amount;
            }
        }
    }

    function checkUnlockedAmount(address _beneficiary) external view returns(uint amount) {
        amount = 0;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].timestamp < block.timestamp && locks[i].beneficiary == _beneficiary && locks[i].withdrawn == false) {
                amount += locks[i].amount;
            }
        }
    }
}