/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: FeeBankContract.sol

/// @title A contract that stores fees for later withdrawal
contract FeeBankContract {
    /// @notice The event emitted whenever ETH is deposited.
    /// @param depositor The address of the account making the deposit.
    /// @param receiver The address of the account eligible for withdrawal.
    /// @param amount The newly deposited amount.
    /// @param totalAmount The total amount the receiver can withdraw, including the new deposit.
    event DepositEvent(
        address depositor,
        address receiver,
        uint64 amount,
        uint64 totalAmount
    );

    /// @notice The event emitted whenever ETH is withdrawn.
    /// @param sender The address of the account that triggered the withdrawal.
    /// @param receiver The address of the account to which the ETH is sent.
    /// @param amount The withdrawn amount.
    /// @param totalAmount The remaining deposit.
    event WithdrawEvent(
        address sender,
        address receiver,
        uint64 amount,
        uint64 totalAmount
    );

    mapping(address => uint64) public deposits;

    /// @notice Deposit ETH for later withdrawal
    /// @param receiver Address of the account that is eligible for withdrawal.
    function deposit(address receiver) external payable {
        require(receiver != address(0), "FeeBank: receiver is zero address");
        require(msg.value > 0, "FeeBank: fee is zero");
        require(
            msg.value <= type(uint64).max - deposits[receiver],
            "FeeBank: balance would exceed uint64"
        );
        deposits[receiver] += uint64(msg.value);

        emit DepositEvent(
            msg.sender,
            receiver,
            uint64(msg.value),
            deposits[receiver]
        );
    }

    /// @notice Withdraw ETH previously deposited in favor of the caller.
    /// @param receiver The address to which the ETH will be sent.
    /// @param amount The amount to withdraw (must not be greater than the deposited amount)
    function withdraw(address receiver, uint64 amount) external {
        _withdraw(receiver, amount);
    }

    /// @notice Withdraw all ETH previously deposited in favor of the caller and send it to them.
    function withdraw() external {
        _withdraw(msg.sender, deposits[msg.sender]);
    }

    function _withdraw(address receiver, uint64 amount) internal {
        require(receiver != address(0), "FeeBank: receiver is zero address");
        uint64 depositBefore = deposits[msg.sender];
        require(depositBefore > 0, "FeeBank: deposit is empty");
        require(amount <= depositBefore, "FeeBank: amount exceeds deposit");
        deposits[msg.sender] = depositBefore - amount;
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "FeeBank: withdrawal call failed");
        emit WithdrawEvent(msg.sender, receiver, amount, deposits[msg.sender]);
    }
}