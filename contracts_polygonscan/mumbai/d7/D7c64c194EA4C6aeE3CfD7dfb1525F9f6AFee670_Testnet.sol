// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testnet {
    receive() external payable {}
    fallback() external payable {}

    event Deposit(address account, uint256 amount);
    event Withdrawal(address account, uint256 amount);

    mapping (address => uint256) private _balanceOf;

    function balanceTestnet() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOfTestnet(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function depositTestnet(uint256 amount) public payable {
        require(msg.value == amount, "Incorrect amount");

        _balanceOf[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdrawTestnet(uint256 amount) public {
        require(amount <= _balanceOf[msg.sender], "Insufficient funds");

        _balanceOf[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");

        emit Withdrawal(msg.sender, amount);
    }
}