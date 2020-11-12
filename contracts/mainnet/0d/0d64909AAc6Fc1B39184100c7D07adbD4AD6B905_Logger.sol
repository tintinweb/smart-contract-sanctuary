// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;

contract Logger {
    event Deposit(
        address indexed sender,
        uint8 protocol,
        uint8 coin,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(
        address indexed sender,
        uint8 protocol,
        uint8 coin,
        uint256 amount,
        uint256 timestamp
    );
    event Swap(address indexed sender, uint8 fromProtocol, uint8 toProtocol, uint256 amount);

    function logDeposit(
        address _sender,
        uint8 _protocol,
        uint8 _coin,
        uint256 _amount,
        uint256 _timestamp
    ) external {
        emit Deposit(_sender, _protocol, _coin, _amount, _timestamp);
    }

    function logWithdraw(
        address _sender,
        uint8 _protocol,
        uint8 _coin,
        uint256 _amount,
        uint256 _timestamp
    ) external {
        emit Withdraw(_sender, _protocol, _coin, _amount, _timestamp);
    }

    function logSwap(
        address _sender,
        uint8 _protocolFrom,
        uint8 _protocolTo,
        uint256 _amount
    ) external {
        emit Swap(_sender, _protocolFrom, _protocolTo, _amount);
    }
}