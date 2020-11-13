pragma solidity ^0.6.0;

contract SavingsLogger {
    event Deposit(address indexed sender, uint8 protocol, uint256 amount);
    event Withdraw(address indexed sender, uint8 protocol, uint256 amount);
    event Swap(address indexed sender, uint8 fromProtocol, uint8 toProtocol, uint256 amount);

    function logDeposit(address _sender, uint8 _protocol, uint256 _amount) external {
        emit Deposit(_sender, _protocol, _amount);
    }

    function logWithdraw(address _sender, uint8 _protocol, uint256 _amount) external {
        emit Withdraw(_sender, _protocol, _amount);
    }

    function logSwap(address _sender, uint8 _protocolFrom, uint8 _protocolTo, uint256 _amount)
        external
    {
        emit Swap(_sender, _protocolFrom, _protocolTo, _amount);
    }
}
